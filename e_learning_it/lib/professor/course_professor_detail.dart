// CourseDetailPage.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// คลาส Lesson สำหรับข้อมูลวิดีโอแต่ละตอน
class Lesson {
  final int id;
  final String videoName;
  final String videoDescription;
  final String? videoUrl;
  final String? pdfUrl;

  Lesson({
    required this.id,
    required this.videoName,
    required this.videoDescription,
    this.videoUrl,
    this.pdfUrl,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // แก้ไข: ตรวจสอบและแปลงค่า id ให้เป็น int อย่างปลอดภัย
    final rawId = json['video_lesson_id'];
    int parsedId;
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ??
          0; // แปลง String เป็น int หรือให้ค่าเริ่มต้นเป็น 0
    } else {
      parsedId = 0; // ถ้าไม่ใช่ทั้ง int และ String ให้ค่าเริ่มต้นเป็น 0
    }

    return Lesson(
      id: parsedId,
      videoName: json['video_name'] ?? 'ไม่ระบุชื่อวิดีโอ',
      videoDescription: json['video_description'] ?? '',
      videoUrl: json['video_url'],
      pdfUrl: json['pdf_url'],
    );
  }
}

// คลาส Course ที่ถูกแก้ไขให้รองรับ lessons
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
    var lessonsFromJson = json['lessons'] as List?;
    List<Lesson> lessonList = lessonsFromJson != null
        ? lessonsFromJson.map((i) => Lesson.fromJson(i)).toList()
        : [];

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
      lessons: lessonList,
    );
  }
}

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
    return Scaffold(
      appBar: AppBar(
         title: const Text('รายละเอียดรายวิชา', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF03A96B),
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัวรายวิชา
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
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
            // Tabs และเนื้อหา
            _buildTabsAndContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsAndContent(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          // แก้ไข: ปรับ Text ใน Tab ให้รองรับข้อความยาวด้วย TextOverflow.ellipsis
          const TabBar(
            indicatorColor: Color(0xFF2E7D32),
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(
                  child: Text('รายละเอียดรายวิชา',
                      overflow: TextOverflow.ellipsis)),
              Tab(child: Text('วิดีโอ', overflow: TextOverflow.ellipsis)),
              Tab(
                  child: Text('เอกสารประกอบการเรียน',
                      overflow: TextOverflow.ellipsis)),
              Tab(child: Text('ผู้สอน', overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(
            height: 600, // สามารถปรับความสูงตามความเหมาะสม
            child: TabBarView(
              children: [
                // Tab 1: รายละเอียดรายวิชา
                _buildDetailsTab(),

                // Tab 2: วิดีโอ (Tab ใหม่)
                _buildVideoLessonsTab(context),

                // Tab 3: เอกสารประกอบการเรียน (ใช้ lessons แทน fileNames)
                _buildFileListView(context),

                // Tab 4: ผู้สอน
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

  Widget _buildVideoLessonsTab(BuildContext context) {
    if (course.lessons.isEmpty) {
      return const Center(
          child: Text('ไม่พบวิดีโอการเรียนการสอนสำหรับรายวิชานี้'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: course.lessons.length,
      itemBuilder: (context, index) {
        final lesson = course.lessons[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.play_circle_filled,
                color: Colors.blue, size: 30),
            title: Text('วิดีโอตอนที่ ${index + 1}: ${lesson.videoName}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(lesson.videoDescription),
            onTap: () async {
              if (lesson.videoUrl != null) {
                final Uri uri = Uri.parse(lesson.videoUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่สามารถเล่นวิดีโอได้')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ไม่พบลิงก์วิดีโอ')),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFileListView(BuildContext context) {
    // กรองเฉพาะ lesson ที่มีไฟล์ PDF
    final filesWithPdf =
        course.lessons.where((lesson) => lesson.pdfUrl != null).toList();

    if (filesWithPdf.isEmpty) {
      return const Center(
          child: Text('ไม่พบเอกสารประกอบการเรียนสำหรับรายวิชานี้'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filesWithPdf.length,
      itemBuilder: (context, index) {
        final lesson = filesWithPdf[index];
        final fileName = lesson.pdfUrl!.split('/').last;
        return ListTile(
          leading: const Icon(Icons.file_copy, color: Color(0xFF2E7D32)),
          title: Text(fileName),
          onTap: () async {
            final Uri uri = Uri.parse(lesson.pdfUrl!);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ไม่สามารถเปิดไฟล์ได้')),
              );
            }
          },
        );
      },
    );
  }
}
