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

async function updateCoursePathsInDatabase(courseId, imageNames, videoNames, pdfNames) {
    const query = `
        UPDATE courses
        SET name_image = $1, name_vdo = $2, name_file = $3
        WHERE course_id = $4;
    `;
    // ใช้ JSON.stringify สำหรับ Array เพื่อเก็บใน PostgreSQL
    const values = [
        imageNames.length > 0 ? JSON.stringify(imageNames) : null,
        videoNames.length > 0 ? JSON.stringify(videoNames) : null,
        pdfNames.length > 0 ? JSON.stringify(pdfNames) : null,
        courseId
    ];
    try {
        const result = await pool.query(query, values);
        return result;
    } catch (error) {
        console.error('Error updating course paths in database:', error);
        throw error;
    }
}

// Function to split the video file using FFmpeg, now with a buffer
function splitVideoFromBuffer(videoBuffer, outputPath, startTime, duration, outputFileName) {
    return new Promise((resolve, reject) => {
        ffmpeg()
            .input(videoBuffer)
            .setStartTime(startTime)
            .setDuration(duration)
            .output(outputPath)
            .on('end', () => {
                console.log(`Video segment created: ${outputFileName}`);
                resolve();
            })
            .on('error', (err) => {
                console.error(`Error during video splitting for ${outputFileName}:`, err);
                reject(err);
            })
            .run();
    });
}

// Endpoint for uploading course
app.post('/api/courses', upload.fields([
    { name: 'name_image', maxCount: 1 },
    { name: 'name_vdo', maxCount: 1 },
    { name: 'name_file', maxCount: 10 }
]), async (req, res) => {
    const { course_code, course_name, short_description, description, objective, user_id } = req.body;
    if (!user_id || !course_code) {
        return res.status(400).json({ message: 'User ID and Course Code are required.' });
    }

    try {
        // ส่วนที่เพิ่มเข้ามาสำหรับการตรวจสอบรหัสวิชา
        const checkCourseCodeQuery = 'SELECT COUNT(*) FROM subject_master WHERE course_code = $1';
        const courseCodeExists = await pool.query(checkCourseCodeQuery, [course_code]);
        const count = parseInt(courseCodeExists.rows[0].count);

        if (count === 0) {
            // ส่ง response เฉพาะเมื่อรหัสวิชาไม่ถูกต้อง
            return res.status(404).json({ message: 'รหัสวิชาไม่ถูกต้อง หรือไม่มีอยู่ในระบบ' });
        }

        // ส่วนที่เหลือของโค้ดการอัปโหลดจะถูกย้ายเข้ามาใน try-block นี้
        const initialCourseData = { course_code, course_name, short_description, description, objective, user_id };
        const newCourse = await saveCourseToDatabase(initialCourseData);
        const courseId = newCourse.course_id;

        const courseFolderPath = path.join(UPLOAD_DIR, user_id.toString(), courseId.toString());
        const imageFolderPath = path.join(courseFolderPath, 'image');
        const pdfFolderPath = path.join(courseFolderPath, 'file');
        const videoFolderPath = path.join(courseFolderPath, 'vdo');

        fs.mkdirSync(imageFolderPath, { recursive: true });
        fs.mkdirSync(pdfFolderPath, { recursive: true });
        fs.mkdirSync(videoFolderPath, { recursive: true });

        const imageNames = [];
        const videoNames = [];
        const pdfNames = [];

        // 1. Save image file(s)
        if (req.files && req.files['name_image'] && req.files['name_image'].length > 0) {
            const imageFile = req.files['name_image'][0];
            const imageName = `image1${path.extname(imageFile.originalname)}`;
            const imagePath = path.join(imageFolderPath, imageName);
            fs.writeFileSync(imagePath, imageFile.buffer);
            imageNames.push(imageName);
        }

        // 2. Save PDF files
        if (req.files && req.files['name_file'] && req.files['name_file'].length > 0) {
            req.files['name_file'].forEach((pdfFile, index) => {
                const pdfName = `file${index + 1}${path.extname(pdfFile.originalname)}`;
                const pdfPath = path.join(pdfFolderPath, pdfName);
                fs.writeFileSync(pdfPath, pdfFile.buffer);
                pdfNames.push(pdfName);
            });
        }
        
        // 3. Split and save video
        if (req.files && req.files['name_vdo'] && req.files['name_vdo'].length > 0) {
            const videoFile = req.files['name_vdo'][0];
            const videoBuffer = videoFile.buffer;

            // สร้างเส้นทางไฟล์ชั่วคราว
            const tempVideoPath = path.join(os.tmpdir(), `temp_video_${Date.now()}${path.extname(videoFile.originalname)}`);
            fs.writeFileSync(tempVideoPath, videoBuffer); 

            try {
                const videoDuration = await new Promise((resolve, reject) => {
                    ffmpeg.ffprobe(tempVideoPath, (err, metadata) => {
                        if (err) return reject(err);
                        resolve(metadata.format.duration);
                    });
                });

                const segmentDuration = videoDuration / 4;
                for (let i = 0; i < 4; i++) {
                    const startTime = i * segmentDuration;
                    const videoName = `vdo${i + 1}${path.extname(videoFile.originalname)}`;
                    const outputPath = path.join(videoFolderPath, videoName);
                    
                    await splitVideoFromBuffer(tempVideoPath, outputPath, startTime, segmentDuration, videoName);
                    videoNames.push(videoName);
                }
            } finally {
                fs.unlinkSync(tempVideoPath);
            }
        }
        
        // 4. Update file names in the database
        await updateCoursePathsInDatabase(
            courseId,
            imageNames,
            videoNames,
            pdfNames
        );

        res.status(201).json({
            message: 'Course and files uploaded successfully!',
            courseId: courseId,
            imageNames: imageNames,
            videoNames: videoNames,
            pdfNames: pdfNames,
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
        const images = row.name_image ? JSON.parse(row.name_image) : [];
        
        return {
          course_id: row.course_id,
          course_code: row.course_code,
          course_name: row.course_name,
          short_description: row.short_description,
          image_url: images.length > 0 ? `http://${req.hostname}:${port}/data/${row.user_id}/${row.course_id}/image/${images[0]}` : null,
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
                c.description,      -- ดึง field description
                c.objective,        -- ดึง field objective
                c.name_image,
                c.name_file,
                c.name_vdo,
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

        // แปลง JSON string เป็น Array และจัดการค่าว่าง
        const imageNames = courseData.name_image ? JSON.parse(courseData.name_image) : [];
        const fileNames = courseData.name_file ? JSON.parse(courseData.name_file) : [];
        const videoNames = courseData.name_vdo ? JSON.parse(courseData.name_vdo) : [];

        // สร้าง URL ของรูปภาพ
        const imageUrl = imageNames.length > 0
            ? `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseData.course_id}/image/${imageNames[0]}`
            : 'https://placehold.co/600x400.png';

        res.json({
            course_id: courseData.course_id,
            course_code: courseData.course_code,
            course_name: courseData.course_name,
            short_description: courseData.short_description,
            description: courseData.description || '', // ส่งค่าว่างถ้าเป็น null
            objective: courseData.objective || '',     // ส่งค่าว่างถ้าเป็น null
            professor_name: `${courseData.first_name} ${courseData.last_name}`,
            image_url: imageUrl,
            file_names: fileNames, // ส่งแค่ชื่อไฟล์
            video_names: videoNames, // ส่งแค่ชื่อไฟล์
            user_id: courseData.user_id, // เพิ่ม user_id
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
        const images = row.name_image ? JSON.parse(row.name_image) : [];
        
        return {
          course_id: row.course_id,
          course_code: row.course_code,
          course_name: row.course_name,
          short_description: row.short_description,
          image_url: images.length > 0 ? `http://${req.hostname}:${port}/data/${row.user_id}/${row.course_id}/image/${images[0]}` : null,
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

// Endpoint สำหรับดึงข้อมูลวิดีโอของคอร์ส
app.get('/api/course/video/:courseId', async (req, res) => {
    try {
        const { courseId } = req.params;
        const query = `
            SELECT 
                c.course_id,
                c.user_id,
                c.name_vdo,
                c.course_name
            FROM courses c
            WHERE c.course_id = $1;
        `;
        const result = await pool.query(query, [courseId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Course not found' });
        }

        const courseData = result.rows[0];

        // แปลง JSON string ใน name_vdo เป็น Array และจัดการค่าว่าง
        const videoNames = courseData.name_vdo ? JSON.parse(courseData.name_vdo) : [];

        // สร้าง URL สำหรับแต่ละวิดีโอ
        const videoUrls = videoNames.map(fileName => {
            return `http://${req.hostname}:${port}/data/${courseData.user_id}/${courseData.course_id}/vdo/${fileName}`;
        });

        res.json({
            course_id: courseData.course_id,
            user_id: courseData.user_id,
            course_name: courseData.course_name,
            video_names: videoNames, // ส่งแค่ชื่อไฟล์
            video_urls: videoUrls, // ส่ง URL ที่สร้างขึ้นมา
        });

    } catch (error) {
        console.error('Error fetching course video data:', error);
        res.status(500).json({ error: 'Database query failed' });
    }
});

// เริ่มต้นเซิร์ฟเวอร์
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});