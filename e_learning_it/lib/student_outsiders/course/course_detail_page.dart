// In the CourseDetailPage.dart file

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:e_learning_it/student_outsiders/main_page.dart';
import 'package:e_learning_it/student_outsiders/course/vdo_page.dart';

// The Course class has been moved here.
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
  final List<String> fileNames;
  final List<String> videoNames; // เพิ่ม videoNames

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
    required this.fileNames,
    required this.videoNames, // เพิ่ม videoNames
  });

  factory Course.fromJson(Map<String, dynamic> json) {
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
      fileNames: (json['file_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      videoNames: (json['video_names'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
    print('File Names: ${course.fileNames}');
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
          // Start Button Section positioned at the bottom right
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the video lesson page, passing the video file names
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VdoPage(
                        courseId: course.courseId,
                        userId: course.userId,
                        videoFileNames: course.videoNames,
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
      length: 4,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Color(0xFF2E7D32),
            labelColor: Color(0xFF2E7D32),
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'รายละเอียดหลักสูตร'),
              Tab(text: 'เอกสารประกอบการเรียน'),
              Tab(text: 'วุฒิบัตร'),
              Tab(text: 'ผู้สอน'),
            ],
          ),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                _buildDetailsTab(),
                _buildFileListView(context),
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

  Widget _buildFileListView(BuildContext context) {
    if (course.fileNames.isEmpty) {
      return const Center(child: Text('ไม่พบเอกสารประกอบการเรียน'));
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: course.fileNames.map((fileName) {
            final fileUrl = 'http://localhost:3006/data/${course.userId}/${course.courseId}/file/$fileName';
            return ListTile(
              leading: const Icon(Icons.file_copy, color: Color(0xFF2E7D32)),
              title: Text(fileName),
              onTap: () async {
                final Uri uri = Uri.parse(fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่สามารถเปิดไฟล์ได้')),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}