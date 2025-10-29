// C:\Users\atSine\Desktop\ปัญหาพิเศษ\Web\elearnnig-it\e_learning_it\lib\backend\server.js

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
const PDFDocument = require('pdfkit');
const nodemailer = require('nodemailer');

// Ensure ffmpeg paths are correct for your system
ffmpeg.setFfmpegPath('C:/ffmpeg/bin/ffmpeg.exe');
ffmpeg.setFfprobePath('C:/ffmpeg/bin/ffprobe.exe');

const app = express();
const port = process.env.PORT || 3006;
const UPLOAD_DIR = 'C:\\Users\\atSine\\Desktop\\Problem\\Web\\data';

// Middleware
app.use(cors());
app.use(express.json());
// 💡 เปลี่ยน hostname เป็น IP Address ของเครื่องคุณ (ถ้ามีปัญหาเรื่องการเข้าถึงจาก Emulator/Device)
// ตัวอย่าง: app.use('/data', express.static('C:/Users/atSine/Desktop/ปัญหาพิเศษ/Web/data'));
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

const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com', // ใช้ Gmail SMTP
    port: 465, // พอร์ตสำหรับ SSL
    secure: true, // ต้องเป็น true สำหรับ port 465
    auth: {
        user: process.env.EMAIL_USER, // อีเมลผู้ส่งจาก .env
        pass: process.env.EMAIL_PASS, // App Password จาก .env
    },
});

function generateOTP() {
    return Math.floor(10000 + Math.random() * 90000).toString();
}
async function sendOTPEmail(toEmail, otpCode) {
    const mailOptions = {
        from: process.env.EMAIL_USER,
        to: toEmail,
        subject: 'รหัส OTP สำหรับการรีเซ็ตรหัสผ่าน E-Learning IT',
        html: `
            <div style="font-family: Arial, sans-serif;">
                <h2 style="color: #4CAF50;">การร้องขอรีเซ็ตรหัสผ่าน</h2>
                <p>รหัส OTP ของคุณคือ:</p>
                <div style="font-size: 24px; font-weight: bold; color: #333; background-color: #f0f0f0; padding: 10px; display: inline-block; margin: 10px 0;">
                    ${otpCode}
                </div>
                <p>รหัสนี้จะหมดอายุภายใน 10 นาที</p>
            </div>
        `,
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`OTP email sent successfully to ${toEmail}`); // 💡 SUCCESS: แสดงว่าส่งจริงสำเร็จ
        return true;
    } catch (error) {
        console.error(`🛑 Error sending OTP email to ${toEmail}:`, error); // 🛑 FAILURE: แสดงข้อผิดพลาดจริงของ SMTP
        return false;
    }
}


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

app.post('/api/login-admin', async (req, res) => {
    const { identifier, password } = req.body;

    // ตรวจสอบว่ามีข้อมูลครบถ้วนหรือไม่
    if (!identifier || !password) {
        return res.status(400).json({ message: 'กรุณากรอก Email/รหัสนิสิต และรหัสผ่าน' });
    }

    try {
        // ค้นหาผู้ใช้จาก email หรือ student_id (สมมติว่า identifier คือ user input)
        const userQuery = `
            SELECT 
                user_id, 
                password_hash, 
                role, 
                first_name, 
                last_name, 
                email,
                student_id
            FROM users 
            WHERE email = $1 OR student_id = $1;
        `;
        const result = await pool.query(userQuery, [identifier]);

        if (result.rows.length === 0) {
            // ไม่พบผู้ใช้
            return res.status(401).json({ message: 'Email หรือรหัสนิสิตไม่ถูกต้อง' });
        }

        const user = result.rows[0];
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);

        if (!isPasswordValid) {
            // รหัสผ่านไม่ถูกต้อง
            return res.status(401).json({ message: 'รหัสผ่านไม่ถูกต้อง' });
        }

        // ล็อกอินสำเร็จ ส่งข้อมูลผู้ใช้กลับไปตามที่ Flutter ต้องการ
        return res.status(200).json({
            message: 'เข้าสู่ระบบสำเร็จ',
            user: {
                user_id: user.user_id,
                email: user.email,
                student_id: user.student_id, // ใส่ student_id ไปด้วย (ถ้ามี)
                first_name: user.first_name,
                last_name: user.last_name,
                role: user.role // 'นิสิต', 'อาจารย์', 'ผู้ดูแล'
            }
        });

    } catch (error) {
        console.error('🛑 ERROR during login API:', error);
        // แสดง Dialog Box ข้อผิดพลาดเมื่อเกิด Exception
        return res.status(500).json({ message: 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์ กรุณาลองใหม่อีกครั้ง' });
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
        courseStatus // 'เรียนต่อ' หรือ 'เรียนใหม่' หรือ 'เรียนจบ'
    } = req.body;

    // ตรวจสอบข้อมูลที่จำเป็น
    if (!userId || !courseId || !lessonId || savedSeconds === undefined || !courseStatus) {
        return res.status(400).json({ message: 'Missing required progress data (userId, courseId, lessonId, savedSeconds, courseStatus).' });
    }

    console.log('Received progress data:', req.body);

    try {
        // ใช้ ON CONFLICT เพื่อทำการ Upsert (Insert หรือ Update)
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

        console.log('Query values:', values);

        const result = await pool.query(query, values);

        console.log(`Progress saved/updated for User ${userId}, Lesson ${lessonId}: ${savedSeconds}s, Status: ${courseStatus}`);

        res.status(200).json({
            message: 'Video progress saved successfully.',
            progress: result.rows[0]
        });

    } catch (error) {
        console.error('🛑 ERROR saving video progress:', error);
        if (error.code === '23503') {
            return res.status(404).json({ message: 'Course ID, Lesson ID, หรือ User ID ไม่ถูกต้อง (Foreign Key violation).', error: error.message });
        }
        res.status(500).json({ message: 'Internal server error during progress save. (Check console for full error)', error: error.message });
    }
});

// **ENDPOINT ที่ 4: ดึงข้อมูลความคืบหน้าของบทเรียนที่ระบุ (Get Specific Lesson Progress)**
// 💡 แก้ไข: ใช้ Path Parameters เพื่อดึง Lesson ID จาก Flutter (ตามที่ App คาดหวัง)
app.get('/api/get_progress', async (req, res) => {
    const { userId, courseId, lessonId } = req.query; // 💡 ดึงจาก query parameter

    if (!userId || !courseId || !lessonId) {
        return res.status(400).json({ message: 'Missing userId, courseId, or lessonId.' });
    }

    try {
        const query = `
            SELECT saved_seconds AS "savedSeconds", course_status AS "courseStatus"
            FROM video_progress
            WHERE user_id = $1 AND course_id = $2 AND lesson_id = $3;
        `;
        const result = await pool.query(query, [userId, courseId, lessonId]);

        if (result.rows.length === 0) {
            // คืนค่า 0 หากไม่พบข้อมูล
            return res.status(404).json({ // 💡 คืน 404 เพื่อให้ Flutter รู้ว่ายังไม่เคยดู
                message: 'No progress found for this lesson.',
                savedSeconds: 0,
                courseStatus: 'เรียนใหม่'
            });
        }

        // 💡 คืนค่าสถานะและเวลาที่บันทึกไว้
        res.status(200).json({
            message: 'Progress fetched successfully.',
            savedSeconds: result.rows[0].savedSeconds,
            courseStatus: result.rows[0].courseStatus
        });

    } catch (error) {
        console.error('🛑 ERROR fetching video progress:', error);
        res.status(500).json({ message: 'Internal server error during progress fetch.', error: error.message });
    }
});

// **ENDPOINT ที่ 5: ดึงข้อมูลความคืบหน้าทั้งหมดของคอร์ส (Get Last Progress for Course Detail Page)**
// Route: GET /api/get_progress/:userId/:courseId
app.get('/api/get_progress/:userId/:courseId', async (req, res) => {
    const { userId, courseId } = req.params;

    if (!userId || !courseId) {
        return res.status(400).json({ message: 'Missing userId or courseId.' });
    }

    try {
        // 💡 ดึงข้อมูลความคืบหน้าล่าสุด (ตาม updated_at) ของคอร์สนั้น
        const query = `
            SELECT 
                lesson_id AS "lessonId", 
                saved_seconds AS "savedSeconds", 
                course_status AS "courseStatus"
            FROM video_progress
            WHERE user_id = $1 AND course_id = $2
            ORDER BY updated_at DESC
            LIMIT 1;
        `;
        const result = await pool.query(query, [userId, courseId]);

        if (result.rows.length === 0) {
            // 💡 คืน 404 เมื่อไม่เคยดูคอร์สนี้เลย
            return res.status(404).json({
                message: 'No overall progress found for this course.'
            });
        }

        res.status(200).json({
            message: 'Last course progress fetched successfully.',
            progress: result.rows[0] // คืนค่า progress node ล่าสุด
        });

    } catch (error) {
        console.error('🛑 ERROR fetching last course progress:', error);
        res.status(500).json({ message: 'Internal server error during progress fetch.', error: error.message });
    }
});

// **ENDPOINT ที่ 6: ดึงสถานะการดูบทเรียนทั้งหมดในคอร์ส**
// Route: GET /api/get_all_progress/:userId/:courseId
app.get('/api/get_all_progress/:userId/:courseId', async (req, res) => {
    const { userId, courseId } = req.params;

    if (!userId || !courseId) {
        return res.status(400).json({ message: 'Missing userId or courseId.' });
    }

    try {
        // 💡 ดึงสถานะทั้งหมดของทุกบทเรียนในคอร์สนี้
        const query = `
            SELECT 
                lesson_id AS "lessonId", 
                course_status AS "courseStatus"
            FROM video_progress
            WHERE user_id = $1 AND course_id = $2;
        `;
        const result = await pool.query(query, [userId, courseId]);

        if (result.rows.length === 0) {
            return res.status(200).json([]); // คืน Array เปล่าถ้าไม่มีข้อมูล
        }

        res.status(200).json(result.rows); // คืน Array ของ { lessonId, courseStatus }

    } catch (error) {
        console.error('🛑 ERROR fetching all progress:', error);
        res.status(500).json({ message: 'Internal server error during progress fetch.', error: error.message });
    }
});

// **ENDPOINT ที่ 7: บันทึก/อัปเดตคะแนนคอร์ส (Rate Course) - [FINAL FIX]**
app.post('/api/rate_course', async (req, res) => {
    const { courseId, userId, rating, review_text } = req.body;

    // ✅ [STEP 1] ตรวจสอบและแปลงค่า (Parsing)
    const courseIdInt = parseInt(courseId);
    const userIdInt = parseInt(userId);
    const ratingValue = parseInt(rating);

    if (isNaN(courseIdInt) || isNaN(userIdInt) || isNaN(ratingValue) || ratingValue < 1 || ratingValue > 5) {
        return res.status(400).json({ message: 'Invalid input data.' });
    }
    const finalReviewText = (review_text === '' || review_text === undefined || review_text === null) ? null : review_text;

    try {
        // 1. บันทึก/อัปเดตคะแนนของผู้ใช้ (Upsert ใน course_ratings)
        const upsertRatingQuery = `
            INSERT INTO course_ratings (course_id, user_id, rating_value, review_text)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (course_id, user_id) DO UPDATE
            SET 
                rating_value = EXCLUDED.rating_value,
                review_text = EXCLUDED.review_text;
        `;
        await pool.query(upsertRatingQuery, [courseIdInt, userIdInt, ratingValue, finalReviewText]);

        // 2. ✅ [CRITICAL FIX] บังคับให้ Progress Record ของ Lesson แรกถูกตั้งค่าเป็น 'ทบทวน'
        //    เราจะค้นหา Lesson ID แรกของคอร์สก่อน
        const firstLessonQuery = `
            SELECT lesson_id 
            FROM video_lessons 
            WHERE course_id = $1 
            ORDER BY lesson_id ASC 
            LIMIT 1;
        `;
        const firstLessonResult = await pool.query(firstLessonQuery, [courseIdInt]);

        if (firstLessonResult.rows.length === 0) {
            // ไม่สามารถดำเนินการต่อได้หากไม่มีบทเรียนเลย
            return res.status(500).json({ message: 'Course has no lessons, cannot set review status.' });
        }

        const firstLessonId = firstLessonResult.rows[0].lesson_id;

        // 3. ใช้ Upsert เพื่อสร้าง/อัปเดต Progress Record สำหรับ Lesson แรก
        const progressUpsertQuery = `
            INSERT INTO video_progress (user_id, course_id, lesson_id, saved_seconds, course_status, updated_at)
            VALUES ($1, $2, $3, 0, 'ทบทวน', NOW())
            ON CONFLICT (user_id, lesson_id) DO UPDATE
            SET 
                course_status = 'ทบทวน',
                saved_seconds = 0, -- รีเซ็ตเวลาเป็น 0 เมื่อเข้าสู่โหมดทบทวน
                updated_at = NOW(); 
        `;
        // 💡 ใช้ firstLessonId เป็น target เพื่อให้ ON CONFLICT ทำงานได้อย่างถูกต้อง
        await pool.query(progressUpsertQuery, [userIdInt, courseIdInt, firstLessonId]);

        console.log(`Rating saved/updated. Progress for Lesson ${firstLessonId} set to 'ทบทวน'.`);

        // 4. ส่งค่ากลับ
        res.status(200).json({
            message: 'Course rating saved/updated and progress set for review successfully.',
        });

    } catch (error) {
        console.error('🛑 ERROR during rate_course transaction:', error);
        res.status(500).json({ message: 'Internal server error during rating process.', error: error.message });
    }
});

// **ENDPOINT ที่ 8: ตรวจสอบสถานะการให้คะแนนของผู้ใช้**
app.get('/api/check_user_rating/:userId/:courseId', async (req, res) => {
    const { userId, courseId } = req.params;
    const userIdInt = parseInt(userId);
    const courseIdInt = parseInt(courseId);

    if (isNaN(userIdInt) || isNaN(courseIdInt)) {
        return res.status(400).json({ message: 'Invalid User ID or Course ID.' });
    }

    try {
        const query = `
            SELECT rating_value
            FROM course_ratings
            WHERE user_id = $1 AND course_id = $2;
        `;
        const result = await pool.query(query, [userIdInt, courseIdInt]);

        if (result.rows.length > 0) {
            // ถ้ามีข้อมูลในตาราง ratings แสดงว่าให้คะแนนแล้ว
            return res.status(200).json({
                message: 'User has rated this course.',
                rating: result.rows[0].rating_value
            });
        } else {
            // ถ้าไม่พบข้อมูลในตาราง ratings แสดงว่ายังไม่ให้คะแนน
            return res.status(404).json({ message: 'User has not rated this course yet.' });
        }
    } catch (error) {
        console.error('Error checking user rating:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
});

// ✅ Certificates Endpoints
// 1. ENDPOINT: ดึงข้อมูลวุฒิบัตร (GET /api/certificates/:userId/:courseId)
app.get('/api/certificates/:userId/:courseId', async (req, res) => {
    const { userId, courseId } = req.params;

    try {
        // 🎯 [แก้ไข SQL Query] ใช้ c.course_detail หรือ c.course_code เป็น subject_name
        const courseQuery = `
            SELECT 
                c.course_name, 
                c.course_code AS subject_name, /* 👈 [สำคัญ] ใช้ course_code หรือ course_detail แล้วตั้ง Alias เป็น subject_name */
                u.first_name, u.last_name,
                cert.issue_date
            FROM courses c
            JOIN users u ON u.user_id = $1  
            LEFT JOIN certificates cert ON cert.user_id = $1 AND cert.course_id = $2
            WHERE c.course_id = $2;
        `;

        const result = await pool.query(courseQuery, [userId, courseId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'Certificate data not found.' });
        }

        const data = result.rows[0];

        // 🎯 [สำคัญ: การแก้ไขวันที่]
        let formattedIssueDate = '';
        const issueDateValue = data.issue_date;

        if (issueDateValue) {
            const dateObj = new Date(issueDateValue);

            // 💡 [FIX] ตรวจสอบว่า Date object ที่สร้างขึ้นมานั้นถูกต้อง (is not NaN)
            if (dateObj instanceof Date && !isNaN(dateObj.getTime())) {
                // แปลงเป็น YYYY-MM-DD format (มาตรฐานที่ Flutter Parse ได้)
                formattedIssueDate = dateObj.toISOString().split('T')[0];
            }
            // ถ้าเป็น Invalid Date จะข้ามไป ทำให้ formattedIssueDate เป็น ''
        }

        // จัดรูปแบบข้อมูลที่ส่งกลับให้ตรงกับ CertificateData.fromJson ใน Frontend
        const responseData = {
            firstName: data.first_name,
            lastName: data.last_name || '',
            subjectName: data.subject_name || data.course_name || 'ไม่ระบุหลักสูตรย่อย',
            courseName: data.course_name,
            issueDate: formattedIssueDate, // ใช้ค่าที่ตรวจสอบแล้ว (YYYY-MM-DD หรือ '')
        };

        res.json(responseData);

    } catch (error) {
        // ให้ Error 500 ตอบกลับข้อความที่ไม่ใช่ Database Syntax Error เพื่อให้ Frontend จัดการง่ายขึ้น
        console.error('🛑 ERROR fetching certificate data:', error);
        res.status(500).json({ message: 'Internal server error while fetching certificate.' });
    }
});

// 2. ENDPOINT: ตรวจสอบสถานะวุฒิบัตร (GET /api/get_certificate/:userId/:courseId)
app.get('/api/get_certificate/:userId/:courseId', async (req, res) => {
    try {
        const { userId, courseId } = req.params;

        // ตรวจสอบเฉพาะตาราง certificates
        const query = `
            SELECT user_id 
            FROM certificates 
            WHERE user_id = $1 AND course_id = $2;
        `;

        const result = await pool.query(query, [userId, courseId]);

        if (result.rows.length > 0) {
            // พบวุฒิบัตร: isGenerated เป็น true
            return res.status(200).json({
                isGenerated: true
            });
        }

        // ไม่พบวุฒิบัตร: isGenerated เป็น false (ใช้ 200 เพื่อให้ Flutter จัดการง่าย)
        return res.status(200).json({
            isGenerated: false
        });

    } catch (error) {
        console.error('🛑 ERROR checking certificate status:', error);
        res.status(500).json({ message: 'Internal server error during certificate status check.' });
    }
});

// 3. ENDPOINT: บันทึกวันที่ออกวุฒิบัตร (POST /api/certificates/save)
app.post('/api/certificates/save', async (req, res) => {
    // issueDate จะถูกส่งมาเป็น String 'YYYY-MM-DD'
    const { userId, courseId, issueDate } = req.body;

    if (!userId || !courseId || !issueDate) {
        return res.status(400).json({ message: 'Missing required data (userId, courseId, issueDate)' });
    }

    try {
        // ใช้ ON CONFLICT DO NOTHING เพื่อให้แน่ใจว่าถ้ามีข้อมูลอยู่แล้ว จะไม่เกิด Error
        // และเป็นการบันทึก issueDate ครั้งแรกเท่านั้น
        const query = `
            INSERT INTO certificates (user_id, course_id, issue_date) 
            VALUES ($1, $2, $3)
            ON CONFLICT (user_id, course_id) DO NOTHING;
        `;

        const result = await pool.query(query, [userId, courseId, issueDate]);

        if (result.rowCount === 0) {
            // ถ้า rowCount เป็น 0 แปลว่ามีการชนกันและไม่ได้ทำการ INSERT ใหม่
            return res.status(200).json({ message: "Issue date already saved." });
        }

        res.status(200).json({ message: "Issue date saved successfully." });

    } catch (error) {
        console.error('🛑 ERROR saving issue date:', error);
        res.status(500).json({ message: 'Internal server error during issue date save.' });
    }
});

// 2. ENDPOINT: สร้างและดาวน์โหลด PDF (GET /api/certificates/pdf/:userId/:courseId)
app.get('/api/certificates/pdf/:userId/:courseId', async (req, res) => {
    const { userId, courseId } = req.params;

    // 💡 Path จึงชี้ไปที่ Subfolder 'font' และ 'assets'
    const FONT_REGULAR_PATH = path.join(__dirname, 'font/Sarabun-Regular.ttf');
    const FONT_BOLD_PATH = path.join(__dirname, 'font/Sarabun-ExtraBold.ttf');

    // 🎯 [NEW] กำหนด Path ของโลโก้ (กรุณาเปลี่ยนชื่อไฟล์และ Path ให้ถูกต้อง)
    const LOGO_PATH = path.join(__dirname, 'font/logo4.png'); // ⚠️ ตรวจสอบ Path นี้!

    // 2. ตรวจสอบสถานะฟอนต์ และกำหนด Fallback
    const FONT_AVAILABLE = fs.existsSync(FONT_REGULAR_PATH) && fs.existsSync(FONT_BOLD_PATH);

    // กำหนดชื่อฟอนต์ที่จะใช้
    const NORMAL_FONT = FONT_AVAILABLE ? FONT_REGULAR_PATH : 'Times-Roman';
    const BOLD_FONT = FONT_AVAILABLE ? FONT_BOLD_PATH : 'Times-Bold';

    if (!FONT_AVAILABLE) {
        console.warn('⚠️ WARN: Thai font files not found. Using standard Times-Roman. Thai text may display incorrectly.');
    }

    try {
        // 1. ดึงข้อมูลวุฒิบัตรจากฐานข้อมูล (ใช้ JOIN เหมือนเดิม)
        const query = `
            SELECT
                u.first_name,
                u.last_name,
                c.course_name,
                c.course_code AS subject_name,
                cert.issue_date
            FROM
                certificates cert
            JOIN
                users u ON cert.user_id = u.user_id
            JOIN
                courses c ON cert.course_id = c.course_id
            WHERE
                cert.user_id = $1 AND cert.course_id = $2;
        `;
        const result = await pool.query(query, [userId, courseId]);

        if (result.rowCount === 0) {
            return res.status(404).json({ message: 'Certificate data not found.' });
        }

        const data = result.rows[0];
        const fullName = `${data.first_name} ${data.last_name}`;

        // แปลง issue_date เป็นรูปแบบภาษาไทยที่อ่านได้ (สำหรับแสดงใน PDF)
        let issueDateFormatted = 'ไม่ระบุวันที่';
        if (data.issue_date) {
            const dateObj = new Date(data.issue_date);
            // 💡 [FIX for Invalid Date] ตรวจสอบก่อนจัดรูปแบบ
            if (dateObj instanceof Date && !isNaN(dateObj.getTime())) {
                // ใช้ Intl.DateTimeFormat จัดรูปแบบภาษาไทย
                const dateFormatter = new Intl.DateTimeFormat('th-TH', {
                    day: 'numeric',
                    month: 'long',
                    year: 'numeric'
                });
                issueDateFormatted = dateFormatter.format(dateObj);
            }
        }

        // 2. ตั้งค่า Response Headers สำหรับ PDF Download
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader('Content-Disposition', `attachment; filename="certificate_${userId}_${courseId}.pdf"`);

        // 3. สร้าง PDF Document
        const doc = new PDFDocument({
            layout: 'landscape', // แนวนอน
            size: 'A4',
            autoFirstPage: false
        });

        // Pipe PDF output ไปที่ Response stream ทันที
        doc.pipe(res);
        doc.addPage();

        const PADDING = 50;
        const DOC_WIDTH = doc.page.width;
        const DOC_HEIGHT = doc.page.height;
        const primaryColor = '#2E7D32';
        const IMAGE_HEIGHT = 80; // กำหนดความสูงของโลโก้

        // --- ส่วนการตกแต่ง (Border) ---
        doc.rect(PADDING / 2, PADDING / 2, DOC_WIDTH - PADDING, DOC_HEIGHT - PADDING)
            .lineWidth(5)
            .stroke(primaryColor);

        // --- ส่วนเนื้อหา ---

        let nextY = 80; // ตำแหน่งเริ่มต้น Y ที่ใช้สำหรับโลโก้

        if (fs.existsSync(LOGO_PATH)) {
            const imageX = (DOC_WIDTH - IMAGE_HEIGHT) / 2;
            doc.image(LOGO_PATH, imageX, nextY, {
                height: IMAGE_HEIGHT
            });

            // 💡 [FIX] กำหนดตำแหน่ง Y สำหรับข้อความถัดไป โดยบวกความสูงของรูปภาพและระยะห่างเพิ่ม
            nextY += IMAGE_HEIGHT + 30; // 80 (เริ่มต้น) + 80 (ความสูงรูป) + 30 (ระยะห่าง) = 190

            // ใช้ doc.moveDown() เพื่อให้ Cursor อยู่ในตำแหน่งที่ถูกต้องสำหรับ doc.text() ถัดไป
            doc.y = nextY;
            doc.moveDown(0.5); // moveDown 0.5 เพื่อให้ cursor พร้อมสำหรับข้อความถัดไป

        } else {
            // กรณีไม่พบโลโก้ (Fallback)
            doc.font(BOLD_FONT)
                .fontSize(48)
                .fillColor(primaryColor)
                .text('วุฒิบัตร', PADDING, nextY, { align: 'center', width: DOC_WIDTH - PADDING * 2 });
            doc.moveDown(0.5);
            nextY = doc.y; // อัปเดต nextY ตามตำแหน่งของ Cursor ปัจจุบัน
        }

        // 2. ข้อความรับรอง (ปกติ)
        doc.font(NORMAL_FONT)
            .fontSize(20)
            .fillColor('#333333')
            .text('ประกาศนียบัตรนี้ให้ไว้เพื่อรับรองว่า', { align: 'center' });

        doc.moveDown(0.5);

        // 3. ชื่อผู้ได้รับวุฒิบัตร (ตัวหนา)
        doc.font(BOLD_FONT)
            .fontSize(36)
            .fillColor(primaryColor)
            .text(fullName, { align: 'center' });

        doc.moveDown(0.5);

        // 4. ข้อความจบหลักสูตร (ปกติ)
        doc.font(NORMAL_FONT)
            .fontSize(20)
            .fillColor('#333333')
            .text('ได้ผ่านการอบรมและประเมินผลหลักสูตร', { align: 'center' });

        doc.moveDown(0.5);

        // 5. ชื่อหลักสูตร (ตัวหนา)
        doc.font(BOLD_FONT)
            .fontSize(28)
            .fillColor(primaryColor)
            .text(data.course_name, { align: 'center' });

        doc.moveDown(0.2);

        // 6. ชื่อหลักสูตรย่อย (ปกติ)
        doc.font(NORMAL_FONT)
            .fontSize(20)
            .fillColor(primaryColor)
            .text(`(${data.subject_name})`, { align: 'center' });

        doc.moveDown(2);

        // 7. วันที่ออกวุฒิบัตร (ปกติ)
        doc.font(NORMAL_FONT)
            .fontSize(20)
            .fillColor('#333333')
            .text(`ให้ไว้ ณ วันที่: ${issueDateFormatted}`, { align: 'center' });

        doc.moveDown(3);

        // สิ้นสุดการเขียน PDF
        doc.end();

    } catch (error) {
        console.error('🛑 ERROR generating certificate PDF:', error);
        res.status(500).json({ message: 'Internal server error during PDF generation.', details: error.message });
    }
});

app.get('/api/certificates/:userId', async (req, res) => {
    const userId = req.params.userId;

    // 💡 LOGGING: ตรวจสอบว่า API ถูกเรียกใช้
    console.log(`[API] Attempting to fetch certificates for User ID: ${userId}`);

    try {
        // 🎯 [SQL Query] (ตรวจสอบชื่อตารางและคอลัมน์ใน DB ของคุณ)
        // ตรวจสอบว่าชื่อตาราง "certificates" และ "courses" สะกดถูกต้อง
        const certificateQuery = `
            SELECT 
                cert.course_id, 
                c.course_code, 
                c.course_name, 
                c.course_code AS subject_name, /* ใช้ course_code เป็น subject_name */
                TO_CHAR(cert.issue_date, 'YYYY-MM-DD') AS issue_date 
            FROM 
                certificates cert  
            JOIN 
                courses c ON cert.course_id = c.course_id 
            WHERE 
                cert.user_id = $1
            ORDER BY 
                cert.issue_date DESC;
        `;

        const result = await pool.query(certificateQuery, [userId]);

        // 💡 LOGGING: ตรวจสอบว่า Query สำเร็จและมีกี่แถว
        console.log(`[API Success] Fetched ${result.rows.length} certificates for user ${userId}`);

        return res.status(200).json(result.rows);

    } catch (error) {
        // 🛑 LOGGING: ดักจับข้อผิดพลาด (ถ้าเกิดขึ้น)
        console.error('🛑 FATAL ERROR fetching user certificates (500 Error Cause):', error.message);
        console.error('SQL State:', error.code); // พิมพ์ SQL Error Code (เช่น 42P01: relation does not exist)

        // ส่งข้อความ 500 กลับไป
        return res.status(500).json({
            message: 'Internal server error while fetching certificates.',
            error: error.message
        });
    }
});

// ✅ ENDPOINT 2: ดึงรายละเอียดวุฒิบัตรเฉพาะใบ (สำหรับ CertificatePage)
app.get('/api/certificates/:userId/:courseId', async (req, res) => {
    const { userId, courseId } = req.params;
    console.log(`[API] Attempting to fetch details for User ID: ${userId}, Course ID: ${courseId}`);

    try {
        const detailQuery = `
            SELECT 
                c.course_name, 
                c.course_code AS subject_name, 
                u.first_name, 
                u.last_name,
                TO_CHAR(cert.issue_date, 'YYYY-MM-DD') AS issue_date
            FROM 
                courses c
            JOIN 
                certificates cert ON cert.course_id = c.course_id 
            JOIN
                users u ON u.user_id = cert.user_id
            WHERE 
                cert.user_id = $1 AND cert.course_id = $2;
        `;

        const result = await pool.query(detailQuery, [userId, courseId]);

        if (result.rows.length === 0) {
            console.warn(`[API Warning] Certificate details not found for user ${userId} and course ${courseId}`);
            return res.status(404).json({ message: 'Certificate data not found.' });
        }

        const data = result.rows[0];
        console.log(`[API Success] Fetched details for ${data.first_name}`);

        const responseData = {
            firstName: data.first_name,
            lastName: data.last_name || '',
            subjectName: data.subject_name || data.course_name || 'ไม่ระบุหลักสูตรย่อย',
            courseName: data.course_name,
            issueDate: data.issue_date,
        };

        res.json(responseData);

    } catch (error) {
        console.error('🛑 FATAL ERROR fetching certificate details:', error.message);
        res.status(500).json({ message: 'Internal server error while fetching certificate details.' });
    }
});


// ENDPOINT: ดึงข้อมูลโปรไฟล์ผู้ใช้ตาม ID (GET /api/users/:userId)
app.get('/api/users/:userId', async (req, res) => {
    const { userId } = req.params;

    // 💡 [Step 1] ตรวจสอบความถูกต้องของ userId
    const userIdInt = parseInt(userId);
    if (isNaN(userIdInt)) {
        return res.status(400).json({ message: 'Invalid User ID format.' });
    }

    try {
        // 💡 [Step 2] Query ข้อมูลที่จำเป็นจากตาราง users
        // ดึงเฉพาะ field ที่จำเป็น ไม่รวม password_hash
        const query = `
            SELECT 
                user_id, 
                first_name, 
                last_name, 
                email, 
                role, 
                student_id
            FROM users
            WHERE user_id = $1
        `;

        const result = await pool.query(query, [userIdInt]);
        const user = result.rows[0];

        if (!user) {
            // 💡 [Step 3] ไม่พบผู้ใช้
            return res.status(404).json({ message: `User with ID ${userId} not found.` });
        }

        // 💡 [Step 4] คืนค่าข้อมูลผู้ใช้ในรูปแบบ JSON
        return res.status(200).json(user);

    } catch (error) {
        console.error('🛑 ERROR fetching user profile:', error);
        return res.status(500).json({ message: 'Internal server error while fetching user profile.', error: error.message });
    }
});

// ✅ Reports Endpoints
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

// ✅ User Profile Endpoint (Existing)
app.get('/api/user-professor/:userId', async (req, res) => {
    const userId = parseInt(req.params.userId); // 💡 [Step 1] ดึง userId
    try {
        // 💡 [Step 2] Query ดึงข้อมูลผู้ใช้จาก users table โดยใช้ user_id
        const userQuery = 'SELECT user_id, first_name, last_name, email, role, student_id FROM users WHERE user_id = $1';
        const result = await pool.query(userQuery, [userId]);
        const user = result.rows[0];

        if (!user) {
            // 💡 [Step 3] ไม่พบผู้ใช้
            return res.status(404).json({ message: `User with ID ${userId} not found.` });
        }

        // 💡 [Step 4] คืนค่าข้อมูลผู้ใช้ในรูปแบบ JSON
        return res.status(200).json(user);

    } catch (error) {
        console.error('🛑 ERROR fetching user profile:', error);
        return res.status(500).json({ message: 'Internal server error while fetching user profile.', error: error.message });
    }
});


// **ENDPOINT ที่ 9: ดึงรายการคอร์สที่อาจารย์ (ผู้ใช้) สร้างขึ้นทั้งหมด (สำหรับหน้า Profile ของอาจารย์)**
app.get('/api/professor/courses/:userId', async (req, res) => {
    const userId = parseInt(req.params.userId);
    // ดึง port จาก environment variable หรือใช้ค่า default
    const port = process.env.PORT || 3006;
    const hostname = req.hostname; // ใช้ hostname จาก request (เช่น localhost)

    try {
        // 💡 แก้ไข: เพิ่ม name_image และ JOIN users เพื่อดึงชื่ออาจารย์ และใช้ WHERE clause กรองด้วย user_id
        const coursesQuery = `
            SELECT 
                c.course_id,
                c.course_name,
                c.course_code,
                c.name_image,
                c.user_id,
                u.first_name,
                u.last_name
            FROM courses c
            JOIN users u ON c.user_id = u.user_id 
            WHERE c.user_id = $1; 
        `;
        const result = await pool.query(coursesQuery, [userId]);

        if (result.rows.length === 0) {
            // หากไม่พบคอร์สใด ๆ จะส่ง Array เปล่ากลับไป
            return res.status(200).json([]);
        }

        // 💡 เพิ่ม: การประมวลผลข้อมูลเพื่อสร้าง image_url และ professor_name
        const courses = result.rows.map(row => {
            const imageUrl = row.name_image
                ? `http://${hostname}:${port}/data/${row.user_id}/${row.course_id}/image/${row.name_image}`
                : 'https://placehold.co/300x150/505050/FFFFFF?text=IT+Course'; // ภาพสำรอง

            return {
                course_id: row.course_id.toString(),
                course_code: row.course_code,
                course_name: row.course_name,
                image_url: imageUrl, // ชื่อ key ต้องตรงกับที่ ProfessorCourse.fromJson คาดหวัง
                professor_name: `${row.first_name} ${row.last_name}`
            };
        });

        // ส่งรายการคอร์สที่พบกลับไป
        return res.status(200).json(courses);
    } catch (error) {
        console.error('🛑 ERROR fetching professor courses:', error);
        return res.status(500).json({
            message: 'Internal server error: Cannot fetch professor courses.',
            error: error.message
        });
    }
});

// 1. GET /api/reports/pending
app.get('/api/reports/pending', async (req, res) => {
    try {
        // *** แก้ไข: ใช้ pool.query แทน db.query ***
        const result = await pool.query(` 
            SELECT 
                report_id, 
                user_id, 
                category, 
                report_mess,
                status
            FROM public.reports
            WHERE status IS NULL OR status = 'รอดำเนินการ' OR status = 'Pending'
            ORDER BY report_id ASC
        `);

        // ส่งข้อมูลรายงานกลับไป
        res.status(200).json(result.rows);
    } catch (err) {
        console.error('Error fetching pending reports:', err);
        // การ Log นี้จะแสดง Error ที่แท้จริงใน Console ของ Server
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

// 2. PUT /api/reports/:reportId/resolve
app.put('/api/reports/:reportId/resolve', async (req, res) => {
    const reportId = req.params.reportId;
    const { status } = req.body; // รับ status ('เสร็จสิ้น') จาก Flutter

    if (status !== 'เสร็จสิ้น') {
        return res.status(400).json({ message: 'Invalid status provided' });
    }

    try {
        // อัปเดตตาราง reports
        const updateReportQuery = `
            UPDATE public.reports
            SET status = $1
            WHERE report_id = $2
            RETURNING *;
        `;

        // *** แก้ไข: ใช้ pool.query แทน db.query ***
        const result = await pool.query(updateReportQuery, [status, reportId]);

        if (result.rowCount === 0) {
            return res.status(404).json({ message: 'Report not found' });
        }

        // ส่งการตอบกลับสำเร็จ
        res.status(200).json({ message: `Report ${reportId} resolved successfully`, report: result.rows[0] });

    } catch (err) {
        console.error('Error resolving report:', err);
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

// 3. GET /api/users - ดึงข้อมูลผู้ใช้ทั้งหมด
app.get('/api/users-admin', async (req, res) => {
    try {
        // เลือกข้อมูลที่ต้องการ: ชื่อ, นามสกุล, อีเมล, รหัสนิสิต, บทบาท
        const query = `
            SELECT 
                user_id, first_name, last_name, email, student_id, role
            FROM 
                public.users
            ORDER BY
                user_id; 
        `;

        const result = await pool.query(query);

        res.status(200).json(result.rows);
    } catch (err) {
        console.error('Error fetching all users:', err);
        res.status(500).json({ message: 'Internal Server Error' });
    }
});

// **ENDPOINT: PUT /api/users-admin/:userId (Update user)**
app.put('/api/users-admin/:userId', async (req, res) => {
    // 1. รับ ID ผู้ใช้จาก URL Parameter และแปลงเป็นตัวเลข
    const userId = parseInt(req.params.userId, 10);

    // 2. รับข้อมูลจาก Body
    const { first_name, last_name, email, student_id, role } = req.body;

    // 3. จัดการ student_id ที่เป็นค่าว่าง (String ว่าง -> NULL)
    const finalStudentId = (student_id === '' || student_id === undefined || student_id === null)
        ? null
        : student_id;

    // 3.5 ตรวจสอบ User ID ที่แปลงแล้ว
    if (isNaN(userId)) {
        return res.status(400).json({ message: 'User ID ไม่ถูกต้อง หรือไม่มีการส่ง ID มา' });
    }

    try {
        // 4. คำสั่ง SQL สำหรับอัปเดตข้อมูล
        const query = `
            UPDATE public.users
            SET 
                first_name = $1,
                last_name = $2,
                email = $3,
                student_id = $4,
                role = $5
            WHERE 
                user_id = $6
            RETURNING user_id;
        `;

        // 5. ส่งคำสั่งไปยังฐานข้อมูล
        const values = [first_name, last_name, email, finalStudentId, role, userId];
        const result = await pool.query(query, values);

        // 6. ตรวจสอบว่ามีแถวข้อมูลถูกอัปเดตหรือไม่
        if (result.rowCount === 0) {
            return res.status(404).json({ message: 'ไม่พบผู้ใช้ที่ต้องการแก้ไข' });
        }

        // 7. ส่งคำตอบสำเร็จ
        res.status(200).json({ message: 'อัปเดตข้อมูลผู้ใช้สำเร็จ' });

    } catch (err) {
        console.error('Error updating user:', err);

        // 🚨 การแก้ไข CRITICAL: จัดการ Unique Constraint Violation (Error Code: 23505)
        if (err.code === '23505') {
            let field = 'ข้อมูล';
            if (err.constraint === 'users_email_key') {
                field = 'อีเมล';
            } else if (err.constraint === 'users_student_id_key') {
                field = 'รหัสนิสิต';
            }
            return res.status(409).json({
                message: `${field} ที่คุณระบุมีผู้ใช้งานอยู่แล้ว กรุณาใช้ ${field} อื่น`
            });
        }

        // ส่ง Error ที่แท้จริงจาก Postgres กลับไป
        const errorMessage = err.message || 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ขณะอัปเดตข้อมูล';
        res.status(500).json({ message: errorMessage });
    }
});

// เส้น API: GET /api/courses-admin
app.get('/api/courses-admin', async (req, res) => {
    try {
        const query = `
            SELECT 
                c.course_id, 
                c.course_code, 
                c.course_name,              
                c.user_id AS instructor_id, 
                u.email, 
                u.first_name || ' ' || u.last_name AS instructor_name 
            FROM courses c
            LEFT JOIN users u ON c.user_id = u.user_id 
            ORDER BY c.course_id DESC;
        `;
        const result = await pool.query(query);
        res.status(200).json(result.rows);
    } catch (err) {
        // ข้อความ Error ที่ถูกบันทึกไว้ใน console.error
        console.error('Error fetching courses:', err);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลคอร์ส' });
    }
});


// 2. PUT: อัปเดตข้อมูลคอร์ส (Update Course)
app.put('/api/courses-admin/:courseId', async (req, res) => {
    const courseId = req.params.courseId;
    // รับเฉพาะ course_code
    const { course_code } = req.body;

    if (!course_code) {
        return res.status(400).json({ message: 'กรุณากรอกรหัสวิชา' });
    }

    try {
        // Query สำหรับอัปเดตแค่ course_code
        const query = `
            UPDATE courses
            SET 
                course_code = $1     
            WHERE course_id = $2
            RETURNING course_id;
        `;

        const values = [course_code, courseId]; // ใช้แค่ course_code และ courseId
        const result = await pool.query(query, values);

        if (result.rowCount === 0) {
            return res.status(404).json({ message: 'ไม่พบข้อมูลคอร์สที่ต้องการแก้ไข' });
        }

        res.status(200).json({ message: 'อัปเดตข้อมูลคอร์สสำเร็จ' });

    } catch (err) {
        console.error('Error updating course:', err);

        // จัดการ Unique Constraint Violation
        if (err.code === '23505') {
            let field = 'ข้อมูล';
            if (err.constraint === 'courses_course_code_key') {
                field = 'รหัสวิชา';
            }
            return res.status(409).json({
                message: `${field} ที่คุณระบุมีอยู่แล้ว กรุณาใช้ ${field} อื่น`
            });
        }

        res.status(500).json({ message: 'เกิดข้อผิดพลาดในการอัปเดตข้อมูลคอร์ส' });
    }
});

// 3. GET: ดึงข้อมูลอาจารย์ทั้งหมดสำหรับ Dropdown (Teacher List)
app.get('/api/teachers', async (req, res) => {
    try {
        const query = `
            SELECT user_id, first_name || ' ' || last_name AS name
            FROM users
            WHERE role = 'อาจารย์'
            ORDER BY name;
        `;
        const result = await pool.query(query);
        res.status(200).json(result.rows);
    } catch (err) {
        console.error('Error fetching teachers:', err);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดในการดึงข้อมูลอาจารย์' });
    }
});

// 1. ENDPOINT: ร้องขอรหัส OTP สำหรับรีเซ็ตรหัสผ่าน
app.post('/api/password/request_reset', async (req, res) => {
    const { identifier } = req.body; // รับ Email หรือรหัสนิสิต

    if (!identifier) {
        return res.status(400).json({ message: 'กรุณากรอก Email หรือรหัสนิสิต' });
    }

    try {
        // 1. ค้นหาผู้ใช้จาก identifier
        const userQuery = `
            SELECT user_id, email, first_name
            FROM users 
            WHERE email = $1 OR student_id = $1;
        `;
        const userResult = await pool.query(userQuery, [identifier]);

        if (userResult.rows.length === 0) {
            // ไม่พบผู้ใช้
            return res.status(404).json({ message: 'ไม่พบผู้ใช้ที่ระบุในระบบ' });
        }

        const user = userResult.rows[0];
        const otpCode = generateOTP();
        // กำหนดเวลาหมดอายุ 10 นาที
        const expirationTime = new Date(Date.now() + 10 * 60 * 1000);

        // 2. ลบ OTP เก่าของ User นี้ (ป้องกันการสแปม)
        await pool.query('DELETE FROM password_resets WHERE user_id = $1', [user.user_id]);

        // 3. บันทึก OTP ใหม่ลงในฐานข้อมูล
        const insertOtpQuery = `
            INSERT INTO password_resets (user_id, otp_code, expires_at)
            VALUES ($1, $2, $3);
        `;
        await pool.query(insertOtpQuery, [user.user_id, otpCode, expirationTime]);

        // 4. *** ส่วนส่งอีเมลจริง ***
        const emailSent = await sendOTPEmail(user.email, otpCode);

        if (!emailSent) {
            // ถ้าส่งไม่สำเร็จ ให้ส่ง 500 กลับไปพร้อมข้อความแจ้งผู้ใช้
            return res.status(500).json({
                message: 'เกิดข้อผิดพลาดในการส่งอีเมล OTP (โปรดตรวจสอบ App Password และการเชื่อมต่อของ Server)'
            });
        }

        // 5. ส่งการตอบกลับ
        res.status(200).json({
            message: 'ส่งรหัส OTP ไปยังอีเมลเรียบร้อยแล้ว กรุณาตรวจสอบอีเมลของคุณ'
        });

    } catch (error) {
        console.error('🛑 ERROR during password reset request:', error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ขณะร้องขอรหัสผ่าน' });
    }
});

// 2. ENDPOINT: ตรวจสอบ OTP และรีเซ็ตรหัสผ่านใหม่
app.post('/api/password/reset', async (req, res) => {
    const { identifier, otp_code, new_password } = req.body;

    if (!identifier || !otp_code || !new_password) {
        return res.status(400).json({ message: 'กรุณากรอกข้อมูลให้ครบถ้วน: Email/รหัสนิสิต, รหัส OTP, และรหัสผ่านใหม่' });
    }

    // ใช้ Transaction เพื่อให้แน่ใจว่าการอัปเดตและลบเกิดขึ้นพร้อมกัน
    const client = await pool.connect();

    try {
        await client.query('BEGIN'); // เริ่ม Transaction

        // 1. ค้นหาผู้ใช้จาก identifier และดึง user_id
        const userQuery = 'SELECT user_id FROM users WHERE email = $1 OR student_id = $1;';
        const userResult = await client.query(userQuery, [identifier]);

        if (userResult.rows.length === 0) {
            await client.query('COMMIT');
            return res.status(404).json({ message: 'ไม่พบผู้ใช้ที่ระบุ' });
        }

        const userId = userResult.rows[0].user_id;

        // 2. ตรวจสอบ OTP: ตรงกันหรือไม่ และยังไม่หมดอายุ (expires_at > NOW())
        const otpCheckQuery = `
            SELECT id
            FROM password_resets
            WHERE user_id = $1
              AND otp_code = $2
              AND expires_at > NOW();
        `;
        const otpResult = await client.query(otpCheckQuery, [userId, otp_code]);

        if (otpResult.rows.length === 0) {
            await client.query('COMMIT');
            return res.status(401).json({ message: 'รหัส OTP ไม่ถูกต้องหรือหมดอายุแล้ว' });
        }

        // 3. เข้ารหัสรหัสผ่านใหม่
        const saltRounds = 10;
        const newPasswordHash = await bcrypt.hash(new_password, saltRounds);

        // 4. อัปเดตรหัสผ่านในตาราง users
        const updatePasswordQuery = `
            UPDATE users
            SET password_hash = $1
            WHERE user_id = $2;
        `;
        await client.query(updatePasswordQuery, [newPasswordHash, userId]);

        // 5. ลบ OTP ที่ใช้ไปแล้วออกจากตาราง password_resets
        const otpId = otpResult.rows[0].id;
        await client.query('DELETE FROM password_resets WHERE id = $1', [otpId]);

        // 6. Commit Transaction: ยืนยันการเปลี่ยนแปลงทั้งหมด
        await client.query('COMMIT');

        res.status(200).json({ message: 'รีเซ็ตรหัสผ่านสำเร็จ' });

    } catch (error) {
        await client.query('ROLLBACK'); // Rollback: ยกเลิกการเปลี่ยนแปลงทั้งหมดหากมี Error
        console.error('🛑 ERROR during password reset process:', error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ขณะรีเซ็ตรหัสผ่าน' });
    } finally {
        client.release(); // คืน Client สู่ Pool
    }
});

app.get('/api/courses/:courseId', async (req, res) => {
    const { courseId } = req.params;

    // ตรวจสอบความถูกต้องของ courseId ที่ส่งมา
    if (!courseId || isNaN(parseInt(courseId))) {
        return res.status(400).json({ message: 'รหัสหลักสูตรไม่ถูกต้อง' });
    }

    const client = await pool.connect();
    try {
        const query = `
    SELECT 
        course_id, 
        course_code, 
        course_name, 
        short_description, 
        description, 
        objective, 
    FROM courses 
    WHERE course_id = $1
`;

        const result = await client.query(query, [courseId]);

        if (result.rows.length === 0) {
            // สำคัญ: คืน 404 เมื่อไม่พบข้อมูล แต่ไม่ควรขึ้น 404 จากการหา Route ไม่เจอ
            return res.status(404).json({ message: 'ไม่พบคอร์สเรียนที่ระบุในฐานข้อมูล' });
        }

        res.status(200).json(result.rows[0]);

    } catch (error) {
        console.error("Error fetching course details:", error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ในการดึงข้อมูลหลักสูตร' });
    } finally {
        client.release();
    }
});


app.put('/api/courses/:courseId', async (req, res) => {
    const { courseId } = req.params;
    const {
        course_code,
        course_name,
        short_description,
        description,
        objective
    } = req.body;

    // 💡 ควรมีการตรวจสอบข้อมูลใน req.body ว่าไม่เป็นค่าว่างก่อนดำเนินการต่อ

    const client = await pool.connect();
    try {
        const updateQuery = `
            UPDATE courses
            SET 
                course_code = $1,
                course_name = $2,
                short_description = $3,
                description = $4,
                objective = $5
            WHERE 
                course_id = $6
            RETURNING *;
        `;

        const values = [
            course_code,
            course_name,
            short_description,
            description,
            objective,
            courseId
        ];

        const result = await client.query(updateQuery, values);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'ไม่พบคอร์สเรียนที่ต้องการแก้ไข' });
        }

        res.status(200).json({
            message: 'อัปเดตข้อมูลคอร์สเรียนสำเร็จ',
            course: result.rows[0]
        });

    } catch (error) {
        console.error("Error updating course details:", error);
        res.status(500).json({ message: 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์ในการอัปเดตข้อมูลหลักสูตร' });
    } finally {
        client.release();
    }
});

// เริ่มต้นเซิร์ฟเวอร์
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
