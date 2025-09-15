// ในไฟล์ CourseDetailPage.dart

import 'package:e_learning_it/professor/navbar_professor.dart';
import 'package:flutter/material.dart';
import 'package:e_learning_it/professor/course_model.dart';
import 'package:url_launcher/url_launcher.dart';

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
      appBar: NavbarProcessorPage(userName: userName, userId: userId),
      body: Column(
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
          // Tabs และเนื้อหา
          Expanded(
            child: _buildTabsAndContent(context),
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
          TabBar(
            indicatorColor: const Color(0xFF2E7D32),
            labelColor: const Color(0xFF2E7D32),
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(text: 'รายละเอียดหลักสูตร'),
              Tab(text: 'เอกสารประกอบการเรียน'),
              Tab(text: 'วุฒิบัตร'),
              Tab(text: 'ผู้สอน'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Tab 1: รายละเอียดหลักสูตร
                _buildDetailsTab(),

                // Tab 2: เอกสารประกอบการเรียน
                _buildFileListView(context, course.fileNames, course.userId, course.courseId), // แก้ไขตรงนี้

                // Tab 3: วุฒิบัตร
                _buildTabContent(context, 'วุฒิบัตร', 'เนื้อหาเกี่ยวกับวุฒิบัตร'),

                // Tab 4: ผู้สอน
                _buildTabContent(context, 'ผู้สอน', course.professorName),
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
   final displayContent = content.isEmpty ? 'ไม่มีข้อมูล' : content;
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
          displayContent,
        ),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context, String title, String content) {
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

  Widget _buildFileListView(BuildContext context, List<String> fileNames, String userId, String courseId) { // แก้ไขตรงนี้
    if (fileNames.isEmpty) {
      return const Center(child: Text('ไม่พบเอกสารประกอบการเรียน'));
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: fileNames.map((fileName) {
            final fileUrl = 'http://localhost:3006/data/$userId/$courseId/file/$fileName';
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