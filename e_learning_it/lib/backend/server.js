// Your existing imports...
require('dotenv').config({ path: '.env' });
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bcrypt = require('bcrypt');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const ffmpeg = require('fluent-ffmpeg');
const os = require('os');

// Ensure ffmpeg paths are correct for your system
ffmpeg.setFfmpegPath('C:/ffmpeg/bin/ffmpeg.exe');
ffmpeg.setFfprobePath('C:/ffmpeg/bin/ffprobe.exe');

const app = express();
const port = process.env.PORT || 3006;
const UPLOAD_DIR = 'C:\\Users\\atSine\\Desktop\\ปัญหาพิเศษ\\Web\\data';

// Middleware
app.use(cors());
app.use(express.json());
app.use('/data', express.static(UPLOAD_DIR));
app.use('/data', express.static(path.join(__dirname, 'data')));

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_DATABASE,
    password: process.env.DB_PASSWORD,
    port: parseInt(process.env.DB_PORT),
});

pool.connect((err, client, done) => {
    if (err) {
        console.error('Error connecting to the database:', err.stack);
        return;
    }
    console.log('Connected to PostgreSQL database successfully!');
    done();
});

// Endpoint สำหรับเข้าสู่ระบบ
app.post('/api/login', async (req, res) => {
    const { identifier, password } = req.body;
    try {
        if (!identifier || !password) {
            return res.status(400).json({ message: 'กรุณากรอก Email/รหัสนิสิต และรหัสผ่าน' });
        }
        const query = `
            SELECT * FROM users
            WHERE email = $1 OR student_id = $2
        `;
        const values = [identifier, identifier];
        const result = await pool.query(query, values);
        const user = result.rows[0];
        if (!user) {
            return res.status(401).json({ message: 'ไม่พบผู้ใช้ในระบบ' });
        }
        console.log('User data from database:', user);
        if (!user.password_hash) {
            console.error('Error: User found but password field is missing or null.');
            return res.status(500).json({ message: 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์: ข้อมูลผู้ใช้ไม่สมบูรณ์' });
        }
        const passwordMatch = await bcrypt.compare(password, user.password_hash);
        if (!passwordMatch) {
            return res.status(401).json({ message: 'รหัสผ่านไม่ถูกต้อง' });
        }
        return res.status(200).json({
            message: 'เข้าสู่ระบบสำเร็จ',
            user: {
                first_name: user.first_name,
                last_name: user.last_name,
                user_id: user.user_id.toString(),
                role: user.role
            }
        });
    } catch (error) {
        console.error('Error during login:', error);
        return res.status(500).json({ message: 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์' });
    }
});

// Endpoint สำหรับสร้างผู้ใช้ใหม่
app.post('/api/users', async (req, res) => {
    const { first_name, last_name, email, password, role, student_id } = req.body;
    try {
        const saltRounds = 10;
        const password_hash = await bcrypt.hash(password, saltRounds);
        const insertUserQuery = `
            INSERT INTO users (first_name, last_name, email, password_hash, role, student_id, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, NOW())
            RETURNING user_id, first_name, last_name, email, role, student_id, created_at;
        `;
        const values = [
            first_name,
            last_name,
            email,
            password_hash,
            role,
            student_id,
        ];
        const result = await pool.query(insertUserQuery, values);
        const newUser = result.rows[0];
        return res.status(201).json({
            message: "User created successfully",
            user: newUser
        });
    } catch (error) {
        console.error("Error creating user:", error);
        if (error.code === '23505') {
            if (error.constraint === 'users_email_key') {
                return res.status(409).json({ error: "อีเมลนี้มีผู้ใช้งานแล้ว" });
            } else if (error.constraint === 'users_student_id_key') {
                return res.status(409).json({ error: `รหัสนิสิต '${student_id}' มีผู้ใช้งานแล้ว` });
            }
        }
        return res.status(500).json({ error: "เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์" });
    }
});
// ใช้ multer.memoryStorage() สำหรับการเก็บไฟล์ใน RAM ชั่วคราว
const upload = multer({ storage: multer.memoryStorage() });

// **ENDPOINT ที่ 1: อัปโหลดข้อมูลหลักสูตรและรูปภาพ**
app.post('/api/courses', upload.single('name_image'), async (req, res) => {
    const { course_code, course_name, short_description, description, objective, user_id } = req.body;
    if (!user_id || !course_code) {
        return res.status(400).json({ message: 'User ID and Course Code are required.' });
    }

    try {
        const checkCourseCodeQuery = 'SELECT COUNT(*) FROM subject_master WHERE course_code = $1';
        const courseCodeExists = await pool.query(checkCourseCodeQuery, [course_code]);
        const count = parseInt(courseCodeExists.rows[0].count);

        if (count === 0) {
            return res.status(404).json({ message: 'รหัสวิชาไม่ถูกต้อง หรือไม่มีอยู่ในระบบ' });
        }

        const query = `
            INSERT INTO courses (course_code, course_name, short_description, description, objective, user_id, upload_date)
            VALUES ($1, $2, $3, $4, $5, $6, NOW())
            RETURNING course_id;
        `;
        const values = [course_code, course_name, short_description, description, objective, user_id];
        const result = await pool.query(query, values);
        const courseId = result.rows[0].course_id;

        const courseFolderPath = path.join(UPLOAD_DIR, user_id.toString(), courseId.toString());
        const imageFolderPath = path.join(courseFolderPath, 'image');
        fs.mkdirSync(imageFolderPath, { recursive: true });

        let imageName = null;
        if (req.file) {
            imageName = `course_image${path.extname(req.file.originalname)}`;
            const imagePath = path.join(imageFolderPath, imageName);
            fs.writeFileSync(imagePath, req.file.buffer);
        }

        const updateCourseQuery = `
            UPDATE courses
            SET name_image = $1
            WHERE course_id = $2;
        `;
        await pool.query(updateCourseQuery, [imageName, courseId]);

        res.status(201).json({
            message: 'Course details uploaded successfully! You can now upload video lessons.',
            course_id: courseId,
        });
    } catch (error) {
        console.error('Error uploading course details:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
});

// **ENDPOINT ที่ 2: อัปโหลดวิดีโอและ PDF ของแต่ละบทเรียน**
app.post('/api/upload-video', upload.fields([{ name: 'video' }, { name: 'pdf' }]), async (req, res) => {
    const { course_id, video_name, short_description } = req.body;
    const videoFile = req.files['video'] ? req.files['video'][0] : null;
    const pdfFile = req.files['pdf'] ? req.files['pdf'][0] : null;

    if (!course_id || !video_name || !videoFile) {
        return res.status(400).json({ message: 'Course ID, video name, and video file are required.' });
    }

    try {
        const courseQuery = 'SELECT user_id FROM courses WHERE course_id = $1';
        const courseResult = await pool.query(courseQuery, [course_id]);
        if (courseResult.rows.length === 0) {
            return res.status(404).json({ message: 'Course not found.' });
        }
        const userId = courseResult.rows[0].user_id;

        const countQuery = 'SELECT COUNT(*) FROM video_lessons WHERE course_id = $1';
        const countResult = await pool.query(countQuery, [course_id]);
        const lessonNumber = parseInt(countResult.rows[0].count) + 1;

        const lessonsFolderPath = path.join(UPLOAD_DIR, userId.toString(), course_id, 'lessons');
        const lessonFolder = path.join(lessonsFolderPath, `lesson_${lessonNumber}`);
        fs.mkdirSync(lessonFolder, { recursive: true });

        let videoFileName = null;
        if (videoFile) {
            videoFileName = `lesson_${lessonNumber}_vdo${path.extname(videoFile.originalname)}`;
            const videoPath = path.join(lessonFolder, videoFileName);
            fs.writeFileSync(videoPath, videoFile.buffer);
        }

        let pdfFileName = null;
        if (pdfFile) {
            pdfFileName = `lesson_${lessonNumber}_file${path.extname(pdfFile.originalname)}`;
            const pdfPath = path.join(lessonFolder, pdfFileName);
            fs.writeFileSync(pdfPath, pdfFile.buffer);
        }

        const query = `
            INSERT INTO video_lessons (course_id, video_name, short_description, video_path, pdf_path)
            VALUES ($1, $2, $3, $4, $5)
        `;
        const values = [course_id, video_name, short_description, videoFileName, pdfFileName];
        await pool.query(query, values);

        res.status(201).json({
            message: `Video lesson ${lessonNumber} uploaded successfully!`,
            video_path: videoFileName,
            pdf_path: pdfFileName,
        });
    } catch (error) {
        console.error('Error uploading video lesson:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
});


// Endpoint สำหรับแสดงรายการคอร์สที่ถูกปรับปรุง
app.get('/api/show_courses', async (req, res) => {
    try {
        const sql = `
        SELECT
          c.course_id,
          c.course_code,
          c.course_name,
          c.short_description,
          c.name_image,
          c.user_id,
          u.first_name,
          u.last_name
        FROM courses c
        JOIN users u ON c.user_id = u.user_id
        `;
        const result = await pool.query(sql);

        const courses = result.rows.map(row => {
            const image_url = row.name_image
                ? `http://${req.hostname}:${port}/data/${row.user_id}/${row.course_id}/image/${row.name_image}`
                : null;
            return {
                course_id: row.course_id.toString(),
                course_code: row.course_code,
                course_name: row.course_name,
                short_description: row.short_description,
                image_url: image_url,
                professor_name: `${row.first_name} ${row.last_name}`
            };
        });
        res.json(courses);
    } catch (error) {
        console.error('Error fetching courses:', error);
        res.status(500).json({ error: 'Database query failed' });
    }
});

// Endpoint สำหรับดึงรายละเอียดหลักสูตรตาม ID
app.get('/api/course/:courseId', async (req, res) => {
    try {
        const { courseId } = req.params;
        const query = `
            SELECT
                c.course_id,
                c.course_code,
                c.course_name,
                c.short_description,
                c.description,
                c.objective,
                c.name_image,
                c.user_id,
                u.first_name,
                u.last_name
            FROM courses c
            JOIN users u ON c.user_id = u.user_id
            WHERE c.course_id = $1;
        `;
        const result = await pool.query(query, [courseId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Course not found' });
        }
        const courseData = result.rows[0];

        const videoLessonsQuery = `
            SELECT lesson_id, video_name, short_description AS video_description, video_path, pdf_path
            FROM video_lessons
            WHERE course_id = $1
            ORDER BY lesson_id ASC;
        `;
        const videoLessonsResult = await pool.query(videoLessonsQuery, [courseId]);

        const videoLessons = videoLessonsResult.rows.map((lesson, index) => {
            const lessonNumber = index + 1;
            return {
                ...lesson,
                video_lesson_id: lesson.lesson_id.toString(),
                video_url: lesson.video_path ? `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseId}/lessons/lesson_${lessonNumber}/${lesson.video_path}` : null,
                pdf_url: lesson.pdf_path ? `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseId}/lessons/lesson_${lessonNumber}/${lesson.pdf_path}` : null,
            };
        });
        
        const imageUrl = courseData.name_image
            ? `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseId}/image/${courseData.name_image}`
            : 'https://placehold.co/600x400.png';

        res.json({
            course_id: courseData.course_id,
            course_code: courseData.course_code,
            course_name: courseData.course_name,
            short_description: courseData.short_description,
            description: courseData.description || '',
            objective: courseData.objective || '',
            professor_name: `${courseData.first_name} ${courseData.last_name}`,
            image_url: imageUrl,
            lessons: videoLessons,
            user_id: courseData.user_id.toString(),
        });
    } catch (error) {
        console.error('Error fetching course details:', error);
        res.status(500).json({ error: 'Database query failed' });
    }
});


// Endpoint สำหรับดึงข้อมูลวิดีโอแต่ละตอนของคอร์ส
app.get('/api/course/:courseId/videos', async (req, res) => {
    try {
        const { courseId } = req.params;

        const courseQuery = `
            SELECT user_id, course_name
            FROM courses
            WHERE course_id = $1;
        `;
        const courseResult = await pool.query(courseQuery, [courseId]);

        if (courseResult.rows.length === 0) {
            return res.status(404).json({ error: 'Course not found' });
        }
        const courseData = courseResult.rows[0];
        const videoLessonsQuery = `
            SELECT lesson_id, video_name, short_description AS video_description, video_path, pdf_path
            FROM video_lessons
            WHERE course_id = $1
            ORDER BY lesson_id ASC;
        `;
        const videoLessonsResult = await pool.query(videoLessonsQuery, [courseId]);
        const videoLessons = videoLessonsResult.rows.map((lesson, index) => {
            const lessonNumber = index + 1;
            return {
                video_lesson_id: lesson.lesson_id.toString(),
                video_name: lesson.video_name,
                video_description: lesson.video_description,
                video_url: lesson.video_path ? `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseId}/lessons/lesson_${lessonNumber}/${lesson.video_path}` : null,
                pdf_url: lesson.pdf_path ? `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseId}/lessons/lesson_${lessonNumber}/${lesson.pdf_path}` : null,
            };
        });

        res.json({
            course_id: courseId,
            course_name: courseData.course_name,
            lessons: videoLessons,
        });

    } catch (error) {
        console.error('Error fetching course videos:', error);
        res.status(500).json({ error: 'Database query failed' });
    }
});

// **ENDPOINT ที่ 3: บันทึกความคืบหน้าการเรียนวิดีโอ (Video Progress)**
app.post('/api/save_progress', async (req, res) => {
    const { 
        userId, 
        courseId, 
        lessonId, 
        savedSeconds, // เวลาที่ดูค้างไว้ (เป็นวินาที)
        courseStatus // 'เรียนต่อ' หรือ 'เรียนใหม่'
    } = req.body;

    // ตรวจสอบข้อมูลที่จำเป็น
    if (!userId || !courseId || !lessonId || savedSeconds === undefined || !courseStatus) {
        return res.status(400).json({ message: 'Missing required progress data (userId, courseId, lessonId, savedSeconds, courseStatus).' });
    }

    // 💡 การ Log ข้อมูลที่ได้รับจาก Client
    console.log('Received progress data:', req.body);
    
    try {
        const query = `
            INSERT INTO video_progress (user_id, course_id, lesson_id, saved_seconds, course_status, updated_at)
            VALUES ($1, $2, $3, $4, $5, NOW())
            ON CONFLICT (user_id, lesson_id) DO UPDATE
            SET 
                saved_seconds = EXCLUDED.saved_seconds,
                course_status = EXCLUDED.course_status,
                updated_at = NOW()
            RETURNING *;
        `;
        const values = [userId, courseId, lessonId, savedSeconds, courseStatus];
        
        // 💡 การ Log ค่าที่จะส่งเข้า Query
        console.log('Query values:', values);

        const result = await pool.query(query, values);

        console.log(`Progress saved/updated for User ${userId}, Lesson ${lessonId}: ${savedSeconds}s, Status: ${courseStatus}`);

        res.status(200).json({ 
            message: 'Video progress saved successfully.',
            progress: result.rows[0] 
        });

    } catch (error) {
        console.error('🛑 ERROR saving video progress:', error);
        // รหัส 23503: Foreign Key Violation (เช่น courseId/lessonId ไม่ถูกต้อง)
        if (error.code === '23503') {
            return res.status(404).json({ message: 'Course ID, Lesson ID, หรือ User ID ไม่ถูกต้อง (Foreign Key violation).', error: error.message });
        }
        res.status(500).json({ message: 'Internal server error during progress save. (Check console for full error)', error: error.message });
    }
});

// **ENDPOINT ที่ 4: ดึงข้อมูลความคืบหน้าของบทเรียนที่ระบุ (Get Specific Lesson Progress)**
app.get('/api/get_progress', async (req, res) => {
    const { userId, courseId, lessonId } = req.query; // 💡 ดึงจาก query parameter

    if (!userId || !courseId || !lessonId) {
        return res.status(400).json({ message: 'Missing userId, courseId, or lessonId.' });
    }

    try {
        const query = `
            SELECT saved_seconds AS "savedSeconds"
            FROM video_progress
            WHERE user_id = $1 AND course_id = $2 AND lesson_id = $3;
        `;
        const result = await pool.query(query, [userId, courseId, lessonId]);

        if (result.rows.length === 0) {
            // 💡 คืนค่า 0 หากไม่พบข้อมูล เพื่อให้ Flutter เริ่มวิดีโอตั้งแต่ต้น
            return res.status(200).json({ 
                message: 'No progress found for this lesson.',
                savedSeconds: 0 
            });
        }

        console.log(`Progress fetched for User ${userId}, Course ${courseId}, Lesson ${lessonId}.`);
        
        res.status(200).json({ 
            message: 'Progress fetched successfully.',
            savedSeconds: result.rows[0].savedSeconds
        });

    } catch (error) {
        console.error('🛑 ERROR fetching video progress:', error);
        res.status(500).json({ message: 'Internal server error during progress fetch.', error: error.message });
    }
});

// ✅ Reports Endpoints
// Endpoint สำหรับส่งรายงานปัญหา
app.post('/api/reports', async (req, res) => {
    const { userId, category, reportMess } = req.body;
    try {
        if (!userId || !category || !reportMess) {
            return res.status(400).json({ message: 'User ID, category, and message are required.' });
        }
        const insertReportQuery = `
            INSERT INTO reports (user_id, category, report_mess)
            VALUES ($1, $2, $3)
            RETURNING *;
        `;
        const result = await pool.query(insertReportQuery, [userId, category, reportMess]);
        res.status(201).json({ message: 'Report submitted successfully.', report: result.rows[0] });
    } catch (error) {
        console.error('Error submitting report:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
});



// เริ่มต้นเซิร์ฟเวอร์
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});