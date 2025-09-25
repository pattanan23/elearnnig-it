// CourseDetailPage.dart
import 'package:flutter/material.dart';
import 'package:e_learning_it/student_outsiders/course/vdo_page.dart';

// The Course class has been updated to use a Lesson class for detailed lesson data.
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
  final List<Lesson> lessons; // Updated to hold a list of Lesson objects.

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
        // แก้ไขตรงนี้เพื่อแปลงค่า 'video_lesson_id' จาก String เป็น int
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
      lessons: parsedLessons, // Now passes the full list of Lesson objects.
    );
  }
}

// Your CourseDetailPage class
class CourseDetailPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    print('Course Description: ${course.description}');
    print('Course Objective: ${course.objective}');
    print('Number of lessons: ${course.lessons.length}');
    
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนหัวหลักสูตร
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(course.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        course.courseName,
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
          // ปุ่ม "เริ่ม" ที่มุมขวาล่าง
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  // Pass the full lessons list to VdoPage.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VdoPage(
                        courseId: course.courseId,
                        userId: course.userId,
                        lessons: course.lessons, // Pass the new lessons list.
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'เริ่ม',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsAndContent(BuildContext context) {
    return DefaultTabController(
      // แก้ไข: ลด length เหลือ 3
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
                _buildTabContent('ผู้สอน', course.professorName),
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
          _buildDetailSection('รายละเอียด', course.description),
          const SizedBox(height: 24),
          _buildDetailSection('วัตถุประสงค์', course.objective),
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

  // Note: This function is not used anymore in the current design.
  Widget _buildFileListView(BuildContext context) {
    return Container();
  }
}