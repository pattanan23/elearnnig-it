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

ffmpeg.setFfmpegPath('C:/ffmpeg/bin/ffmpeg.exe');
ffmpeg.setFfprobePath('C:/ffmpeg/bin/ffprobe.exe');

const app = express();
const port = process.env.PORT || 3006;
const UPLOAD_DIR = 'C:\\Users\\atSine\\Desktop\\ปัญหาพิเศษ\\Web\\data';

// Middleware
app.use(cors());
app.use(express.json());
app.use('/data', express.static(UPLOAD_DIR)); // ทำให้ไฟล์ใน UPLOAD_DIR เข้าถึงได้
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
                return res.status(409).json({ error: "A user with this email already exists." });
            } else if (error.constraint === 'users_student_id_key') {
                return res.status(409).json({ error: `Student ID '${student_id}' already exists.` });
            }
        }
        return res.status(500).json({ error: "Internal server error" });
    }
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

// ใช้ multer.memoryStorage() สำหรับการเก็บไฟล์ใน RAM ชั่วคราว
const upload = multer({ storage: multer.memoryStorage() });

// Function to save initial course data to database
async function saveCourseToDatabase(courseData) {
    const { course_code, course_name, short_description, description, objective, user_id } = courseData;
    const query = `
        INSERT INTO courses (course_code, course_name, short_description, description, objective, user_id, upload_date)
        VALUES ($1, $2, $3, $4, $5, $6, NOW())
        RETURNING course_id;
    `;
    const values = [course_code, course_name, short_description, description, objective, user_id];
    try {
        const result = await pool.query(query, values);
        return { course_id: result.rows[0].course_id };
    } catch (error) {
        console.error('Error saving initial course data to database:', error);
        throw error;
    }
}

// Function to save video lesson details to a new database table
async function saveVideoLessonsToDatabase(courseId, videoLessons) {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        const lessonQueries = videoLessons.map(lesson => {
            const query = `
                INSERT INTO video_lessons (
                    course_id, video_name, short_description, video_path, pdf_path
                )
                VALUES ($1, $2, $3, $4, $5);
            `;
            const values = [
                courseId,
                lesson.videoName,
                lesson.videoDescription,
                lesson.videoFileName,
                lesson.pdfFileName,
            ];
            return client.query(query, values);
        });
        await Promise.all(lessonQueries);
        await client.query('COMMIT');
    } catch (error) {
        await client.query('ROLLBACK');
        console.error('Error saving video lessons to database:', error);
        throw error;
    } finally {
        client.release();
    }
}

// Endpoint for uploading course
app.post('/api/courses', upload.any(), async (req, res) => {
    const { course_code, course_name, short_description, description, objective, user_id } = req.body;
    if (!user_id || !course_code) {
        return res.status(400).json({ message: 'User ID and Course Code are required.' });
    }

    try {
        // Check if course code exists
        const checkCourseCodeQuery = 'SELECT COUNT(*) FROM subject_master WHERE course_code = $1';
        const courseCodeExists = await pool.query(checkCourseCodeQuery, [course_code]);
        const count = parseInt(courseCodeExists.rows[0].count);

        if (count === 0) {
            return res.status(404).json({ message: 'รหัสวิชาไม่ถูกต้อง หรือไม่มีอยู่ในระบบ' });
        }

        // Save initial course data
        const initialCourseData = { course_code, course_name, short_description, description, objective, user_id };
        const newCourse = await saveCourseToDatabase(initialCourseData);
        const courseId = newCourse.course_id;

        const courseFolderPath = path.join(UPLOAD_DIR, user_id.toString(), courseId.toString());
        const imageFolderPath = path.join(courseFolderPath, 'image');
        const lessonsFolderPath = path.join(courseFolderPath, 'lessons'); 

        fs.mkdirSync(imageFolderPath, { recursive: true });
        fs.mkdirSync(lessonsFolderPath, { recursive: true });

        // Save the main course image
        let imageName = null;
        const imageFile = req.files.find(file => file.fieldname === 'name_image');
        if (imageFile) {
            imageName = `course_image${path.extname(imageFile.originalname)}`;
            const imagePath = path.join(imageFolderPath, imageName);
            fs.writeFileSync(imagePath, imageFile.buffer);
        }

        // Process dynamic video lessons
        const videoLessonsData = [];
        let lessonIndex = 0;
        
        while (req.body[`video_name_${lessonIndex}`]) {
            const lesson = {};
            
            const videoFile = req.files.find(file => file.fieldname === `name_vdo_${lessonIndex}`);
            const pdfFile = req.files.find(file => file.fieldname === `name_file_${lessonIndex}`);

            const videoName = req.body[`video_name_${lessonIndex}`];
            const videoDescription = req.body[`video_description_${lessonIndex}`];

            const lessonFolder = path.join(lessonsFolderPath, `lesson_${lessonIndex + 1}`);
            fs.mkdirSync(lessonFolder, { recursive: true });

            let videoFileName = null;
            if (videoFile) {
                videoFileName = `lesson_${lessonIndex + 1}_vdo${path.extname(videoFile.originalname)}`;
                const videoPath = path.join(lessonFolder, videoFileName);
                fs.writeFileSync(videoPath, videoFile.buffer);
            }

            let pdfFileName = null;
            if (pdfFile) {
                pdfFileName = `lesson_${lessonIndex + 1}_file${path.extname(pdfFile.originalname)}`;
                const pdfPath = path.join(lessonFolder, pdfFileName);
                fs.writeFileSync(pdfPath, pdfFile.buffer);
            }

            videoLessonsData.push({
                videoName,
                videoDescription,
                videoFileName,
                pdfFileName,
            });

            lessonIndex++;
        }

        // Update main course image path in the database
        const updateCourseQuery = `
            UPDATE courses
            SET name_image = $1
            WHERE course_id = $2;
        `;
        await pool.query(updateCourseQuery, [imageName, courseId]);

        // Save video lesson data to a new table
        await saveVideoLessonsToDatabase(courseId, videoLessonsData);

        res.status(201).json({
            message: 'Course and files uploaded successfully!',
            courseId: courseId,
            imageName: imageName,
            videoLessons: videoLessonsData,
        });

    } catch (error) {
        console.error('Error uploading course:', error);
        res.status(500).json({ message: 'Internal server error', error: error.message });
    }
});

// Endpoint ใหม่สำหรับแสดงรายการคอร์สที่ถูกปรับปรุง
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
                course_id: row.course_id,
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

        // Fetch video lessons for this course
        const videoLessonsQuery = `
            SELECT video_name, short_description AS video_description, video_path, pdf_path
            FROM video_lessons
            WHERE course_id = $1
            ORDER BY video_lesson_id ASC;
        `;
        const videoLessonsResult = await pool.query(videoLessonsQuery, [courseId]);

        const videoLessons = videoLessonsResult.rows.map(lesson => ({
            ...lesson,
            video_url: lesson.video_path ? `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseData.course_id}/lessons/lesson_${videoLessonsResult.rows.indexOf(lesson) + 1}/${lesson.video_path}` : null,
            pdf_url: lesson.pdf_path ? `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseData.course_id}/lessons/lesson_${videoLessonsResult.rows.indexOf(lesson) + 1}/${lesson.pdf_path}` : null,
        }));

        // Build image URL
        const imageUrl = courseData.name_image
            ? `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseData.course_id}/image/${courseData.name_image}`
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
            lessons: videoLessons, // Send the lessons array
            user_id: courseData.user_id,
        });

    } catch (error) {
        console.error('Error fetching course details:', error);
        res.status(500).json({ error: 'Database query failed' });
    }
});

// Endpoint ใหม่สำหรับแสดงรายการคอร์สทั้งหมดที่เรียงตาม ID จากน้อยไปมาก
app.get('/api/courses/all_by_id', async (req, res) => {
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
        ORDER BY c.course_id ASC
        `;
        const result = await pool.query(sql);
        
        const courses = result.rows.map(row => {
            const image_url = row.name_image
                ? `http://${req.hostname}:${port}/data/${row.user_id}/${row.course_id}/image/${row.name_image}`
                : null;
        
            return {
                course_id: row.course_id,
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

app.post('/api/reports', async (req, res) => {
    const { userId, category, reportMess } = req.body;

    if (!userId || !category || !reportMess) {
        return res.status(400).json({ error: 'User ID, category, and report message are required.' });
    }

    try {
        // ลบคอลัมน์ report_id ออกจาก INSERT statement
        const result = await pool.query(
            `INSERT INTO reports (user_id, category, report_mess) VALUES ($1, $2, $3) RETURNING report_id`,
            [userId, category, reportMess]
        );

        res.status(201).json({
            message: 'Report submitted successfully.',
            reportId: result.rows[0].report_id,
        });
    } catch (error) {
        console.error('Error submitting report:', error);
        res.status(500).json({ error: 'Failed to submit report. Please try again later.' });
    }
});

// **Endpoint ใหม่สำหรับดึงข้อมูลวิดีโอแต่ละตอนของคอร์ส**
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
            SELECT video_lesson_id, video_name, short_description AS video_description, video_path, pdf_path
            FROM video_lessons
            WHERE course_id = $1
            ORDER BY video_lesson_id ASC;
        `;
        const videoLessonsResult = await pool.query(videoLessonsQuery, [courseId]);

        const videoLessons = videoLessonsResult.rows.map((lesson, index) => {
            const lessonNumber = index + 1;
            return {
                video_lesson_id: lesson.video_lesson_id,
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

// เริ่มต้นเซิร์ฟเวอร์
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});