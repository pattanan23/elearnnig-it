// CourseDetailPage.dart
import 'package:flutter/material.dart';
// ต้องเพิ่ม import สำหรับ HTTP และ JSON
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:e_learning_it/student_outsiders/course/vdo_page.dart';
import 'package:e_learning_it/student_outsiders/drawer_page.dart';
import 'package:e_learning_it/student_outsiders/navbar_normal.dart';

// Class Course และ Lesson (ใช้โครงสร้างเดิม แต่ต้องมั่นใจว่า Lesson ถูก Import หรือ Define)

// สมมติว่า Lesson ถูก Import จาก vdo_page.dart แล้ว
// class Lesson { ... }

class Course {
  final String courseId;
  final String userId;
  final String courseCode;
  final String courseName;
  final String shortDescription;
  final String description;
  final String objective;
  final String professorName;
  final String imageUrl;
  final List<Lesson> lessons;

  Course({
    required this.courseId,
    required this.userId,
    required this.courseCode,
    required this.courseName,
    required this.shortDescription,
    required this.description,
    required this.objective,
    required this.professorName,
    required this.imageUrl,
    required this.lessons,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    var lessonsList = json['lessons'] as List<dynamic>? ?? [];
    List<Lesson> parsedLessons = lessonsList.map((lessonJson) {
      return Lesson(
        id: int.tryParse(lessonJson['video_lesson_id']?.toString() ?? '0') ?? 0, 
        videoName: lessonJson['video_name'] ?? '',
        videoDescription: lessonJson['video_description'] ?? '',
        videoUrl: lessonJson['video_url'],
        pdfUrl: lessonJson['pdf_url'],
      );
    }).toList();

    return Course(
      courseId: json['course_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      courseCode: json['course_code']?.toString() ?? '',
      courseName: json['course_name'] ?? '',
      shortDescription: json['short_description'] ?? '',
      description: json['description'] ?? '',
      objective: json['objective'] ?? '',
      professorName: json['professor_name'] ?? 'ไม่ระบุ',
      imageUrl: json['image_url'] ?? 'https://placehold.co/600x400.png',
      lessons: parsedLessons,
    );
  }
}

// 💡 เปลี่ยนจาก StatelessWidget เป็น StatefulWidget
class CourseDetailPage extends StatefulWidget {
  final Course course;
  final String userName;
  final String userId;

  const CourseDetailPage({
    Key? key,
    required this.course,
    required this.userName,
    required this.userId,
  }) : super(key: key);

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  // 💡 URL สำหรับดึงข้อมูลความคืบหน้า (เปลี่ยน IP/Port ให้ถูกต้อง)
  final String _apiGetProgressUrl = 'http://192.168.x.x:3006/api/get_progress'; 

  // 💡 ฟังก์ชันใหม่: ดึงความคืบหน้าล่าสุด
  Future<Map<String, dynamic>> _fetchLastProgress() async {
    // กำหนดค่าเริ่มต้น
    Map<String, dynamic> defaultProgress = {
      'lessonId': 0, // 0 หมายถึง Lesson ID เริ่มต้น
      'savedSeconds': 0,
      'courseStatus': 'เรียนใหม่',
    };
    
    // หากไม่มีบทเรียนเลย ให้คืนค่าเริ่มต้น
    if (widget.course.lessons.isEmpty) return defaultProgress;

    try {
      final response = await http.get(
        // ส่ง userId และ courseId เพื่อขอข้อมูล progress
        Uri.parse('$_apiGetProgressUrl/${widget.userId}/${widget.course.courseId}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['progress'] ?? defaultProgress;
      } else if (response.statusCode == 404) {
        // ยังไม่เคยดูเลย (API Node.js ส่ง 404 กลับมา)
        return defaultProgress; 
      } else {
        print('Error fetching progress: ${response.statusCode}, Body: ${response.body}');
        return defaultProgress;
      }
    } catch (e) {
      print('Network error fetching progress: $e');
      return defaultProgress;
    }
  }

  // 💡 ฟังก์ชันใหม่: นำทางไปหน้าวิดีโอ
  void _navigateToVideoPage(BuildContext context, Map<String, dynamic> progress) async {
    int startLessonIndex = 0;
    int startSavedSeconds = progress['savedSeconds'] ?? 0;
    String status = progress['courseStatus'] ?? 'เรียนใหม่';
    
    // หากสถานะคือ 'เรียนต่อ' ให้นำทางไปยังบทเรียนที่ค้างไว้
    if (status == 'เรียนต่อ' && progress['lessonId'] != null) {
        final lastLessonId = progress['lessonId'];
        
        // ค้นหา index ของ Lesson ที่บันทึกไว้ใน List
        final index = widget.course.lessons.indexWhere((l) => l.id == lastLessonId);
        if (index != -1) {
            startLessonIndex = index;
        }
    } else {
        // ถ้า status คือ 'เรียนใหม่' หรือหา Lesson ID ไม่เจอ ให้เริ่มจากบทแรก
        startSavedSeconds = 0;
    }

    // นำทางไป VdoPage
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VdoPage(
          courseId: widget.course.courseId,
          userId: widget.userId,
          lessons: widget.course.lessons,
          initialLessonIndex: startLessonIndex, // เริ่มที่วิดีโอที่ควรเรียนต่อ
          initialSavedSeconds: startSavedSeconds, // เริ่มที่เวลาที่บันทึกไว้
        ),
      ),
    );
    
    // เมื่อกลับมาจาก VdoPage ให้รีเฟรชหน้า CourseDetailPage เพื่ออัปเดตปุ่ม "เริ่ม/เรียนต่อ"
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavbarPage(userName: widget.userName, userId: widget.userId),
      drawer: DrawerPage(userName: widget.userName, userId: widget.userId),
      body: Stack(
        children: [
          SingleChildScrollView(
            // ... (โค้ด SingleChildScrollView เดิม)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนหัวหลักสูตร (คงเดิม)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    image: DecorationImage(
                      image: NetworkImage(widget.course.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.course.courseName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Color.fromARGB(150, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildTabsAndContent(context),
              ],
            ),
          ),
          
          // 💡 ปุ่ม "เริ่ม" ที่ถูกห่อด้วย FutureBuilder
          Align(
            alignment: Alignment.bottomRight,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchLastProgress(), // 💡 เรียก API เพื่อดึงความคืบหน้า
              builder: (context, snapshot) {
                String buttonText = 'เริ่มเรียน';
                Map<String, dynamic> progressData = snapshot.data ?? {'courseStatus': 'เรียนใหม่'};
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  buttonText = 'กำลังโหลด...';
                } else if (snapshot.hasData) {
                  if (progressData['courseStatus'] == 'เรียนต่อ') {
                    buttonText = 'เรียนต่อ';
                  } else if (progressData['courseStatus'] == 'เรียนใหม่' && progressData['savedSeconds'] > 0) {
                     // อาจจะมี savedSeconds > 0 แต่สถานะเป็นเรียนใหม่ แสดงว่าดูจบแล้ว
                     buttonText = 'ทบทวน';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ElevatedButton(
                    onPressed: snapshot.connectionState == ConnectionState.done && widget.course.lessons.isNotEmpty
                        ? () => _navigateToVideoPage(context, progressData)
                        : null, // ปิดการใช้งานปุ่มระหว่างโหลด
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ... (โค้ด _buildTabsAndContent, _buildDetailsTab, _buildDetailSection, _buildTabContent, _buildFileListView เดิม)
  
  Widget _buildTabsAndContent(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF2E7D32),
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'รายละเอียด'),
              Tab(text: 'วุฒิบัตร'),
              Tab(text: 'ผู้สอน'),
            ],
          ),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                _buildDetailsTab(),
                _buildTabContent('วุฒิบัตร', 'เนื้อหาเกี่ยวกับวุฒิบัตร'),
                _buildTabContent('ผู้สอน', widget.course.professorName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('รายละเอียด', widget.course.description),
          const SizedBox(height: 24),
          _buildDetailSection('วัตถุประสงค์', widget.course.objective),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildTabContent(String title, String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFileListView(BuildContext context) {
    return Container();
  }
}