// all_course_page.dart

import 'package:e_learning_it/student_outsiders/course/course_detail_page.dart';
import 'package:e_learning_it/student_outsiders/drawer_page.dart';
import 'package:e_learning_it/student_outsiders/navbar_normal.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:e_learning_it/student_outsiders/footer_widget.dart';
// 💡 นำเข้า CourseSearchWidget
import 'package:e_learning_it/student_outsiders/course/course_search_widget.dart'; // <<< ตรวจสอบ Path

const String _baseUrl = 'http://localhost:3006/api';

// ------------------------------------------------------------------
// 1. CourseAllPage (StatelessWidget)
// ------------------------------------------------------------------
class CourseAllPage extends StatelessWidget {
  final String userName;
  final String userId;

  const CourseAllPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  // ------------------------------------------------------------------
  // 2. ฟังก์ชันดึงรายวิชาทั้งหมด
  // ------------------------------------------------------------------
  Future<List<Course>> fetchAllCourses() async {
    final response = await http.get(Uri.parse('$_baseUrl/show_courses'));

    if (response.statusCode == 200) {
      final List<dynamic> courseJson = json.decode(utf8.decode(response.bodyBytes));
      if (courseJson.isEmpty) return [];

      final List<Course> courses = courseJson.map((json) => Course.fromJson(json)).toList();
      courses.sort((a, b) => a.courseId.compareTo(b.courseId));
      return courses;
    } else {
      throw Exception('Failed to load all courses. Status: ${response.statusCode}');
    }
  }


  // ------------------------------------------------------------------
  // 3. ฟังก์ชันสำหรับสร้างส่วนแสดงผลลัพธ์ (ใช้ใน CourseSearchWidget)
  // ------------------------------------------------------------------
 Widget _buildCourseSection(
    BuildContext context, {
    required String title,
    required Future<List<Course>> futureCourses, 
    required String userName, 
    required String userId
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, constraints) {
            // กำหนดจำนวนคอลัมน์ตามขนาดหน้าจอ
            final int crossAxisCount = constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 500
                    ? 2
                    : 1;
            final double maxCardWidth = 400;
            final double gridWidth =
                min(constraints.maxWidth, maxCardWidth * crossAxisCount);

            return Center(
              child: SizedBox(
                width: gridWidth,
                child: FutureBuilder<List<Course>>(
                  future: futureCourses,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } 
                    
                    // 💡 [IMPROVEMENT] จัดการ Error
                    else if (snapshot.hasError) {
                      // แสดง Error ชัดเจน
                      return Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${snapshot.error}', textAlign: TextAlign.center));
                    } 
                    
                    // 💡 [IMPROVEMENT] จัดการ No Data/Empty List
                    else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      // แสดงข้อความเมื่อไม่พบข้อมูล
                      return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 50.0),
                            child: Text(
                              title.contains('ผลการค้นหา')
                                  ? 'ไม่พบรายวิชาที่ตรงกับการค้นหา'
                                  : 'ไม่พบข้อมูลรายวิชา',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ));
                    }
                    
                    // ถ้ามีข้อมูล (List ไม่ว่างเปล่า) ให้สร้าง GridView
                    else {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: constraints.maxWidth > 500 ? 0.75 : 1.0,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final course = snapshot.data![index];
                          // 💡 ใช้เมธอด _buildCourseCard
                          return _buildCourseCard(context, course, userName, userId);
                        },
                      ); 
                    }
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // A reusable widget to build a course card.
  Widget _buildCourseCard(BuildContext context, Course course, String userName, String userId) {
    // ... (rest of the _buildCourseCard method remains the same for brevity)
    return GestureDetector(
      onTap: () async {
        if (course.courseId == null || course.courseId.isEmpty || course.courseId == '0') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course ID หายไป ไม่สามารถแสดงรายละเอียดได้ (404)')),
          );
          return; 
        }
        try {
          final response = await http.get( Uri.parse('$_baseUrl/course/${course.courseId}'));
          if (response.statusCode == 200) {
            final courseDetails = Course.fromJson(json.decode(utf8.decode(response.bodyBytes)));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailPage(
                  course: courseDetails, 
                  userName: userName, 
                  userId: userId,
                ),
              ),
            );
          } else if (response.statusCode == 404) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ไม่พบรายละเอียดรายวิชา ID: ${course.courseId}')),
              );
          } else {
            throw Exception('Failed to load course details. Status: ${response.statusCode}');
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรายละเอียด: $e')),
            );
        }
      },
      child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                  child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                      ? Image.network(
                          course.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.book, size: 50, color: Colors.grey),
                          ),
                        ),
                ),
              ),
              // Details Section
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.courseName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รหัส: ${course.courseCode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'โดย ${course.professorName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }

  // ------------------------------------------------------------------
  // 4. Build Method
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavbarPage(userName: userName, userId: userId),
      drawer: DrawerPage(userName: userName, userId: userId),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Title
              Container(
                alignment: Alignment.centerLeft, // จัดให้ชิดซ้าย
                child: const Text(
                  'รายวิชาทั้งหมด',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // All Courses Section (ใช้ Widget ค้นหาใหม่)
              CourseSearchWidget(
                userName: userName,
                userId: userId,
                // ส่งฟังก์ชัน _buildCourseSection เดิมไปให้ Widget ใหม่ใช้
                buildCourseSection: _buildCourseSection,
                initialFutureCourses: fetchAllCourses(), // Future สำหรับรายวิชาทั้งหมด
              ),
                const SizedBox(height: 40),
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}