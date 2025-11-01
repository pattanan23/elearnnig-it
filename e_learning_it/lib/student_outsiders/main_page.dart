import 'package:e_learning_it/student_outsiders/drawer_page.dart';
import 'package:e_learning_it/student_outsiders/navbar_normal.dart';
import 'package:e_learning_it/student_outsiders/course/course_detail_page.dart'; // import ไฟล์ course_detail_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:e_learning_it/student_outsiders/footer_widget.dart';

// ลบคลาส Course ออกจากไฟล์นี้

class MainPage extends StatelessWidget {
  final String userName;
  final String userId;

  const MainPage({super.key, required this.userName, required this.userId});

  // ฟังก์ชันสำหรับดึงข้อมูลคอร์สจาก API
  Future<List<Course>> fetchRecommendedCourses() async {
    final response =
        await http.get(Uri.parse('http://localhost:3006/api/show_courses'));

    if (response.statusCode == 200) {
      final List<dynamic> courseData = json.decode(response.body);
      return courseData.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recommended courses');
    }
  }

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
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/post.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/post2.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'รายวิชาแนะนำ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
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
                        future: fetchRecommendedCourses(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                                child: Text('ไม่พบข้อมูลรายวิชา'));
                          } else {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final course = snapshot.data![index];
                                return _buildCourseCard(context, course);
                              },
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
               const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return GestureDetector(
      onTap: () async {
        try {
          // ใช้ courseId โดยตรงแทนการแปลง
          final response = await http.get(
              Uri.parse('http://localhost:3006/api/course/${course.courseId}'));

          if (response.statusCode == 200) {
            final courseDetails = Course.fromJson(json.decode(response.body));

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
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('ไม่สามารถดึงข้อมูลรายละเอียดรายวิชาได้')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}')),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(course.imageUrl),
                    fit: BoxFit.cover,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🎯 การแก้ไข: ใช้ Null-aware operator ?? '' เพื่อป้องกันค่า null
                  _buildCourseInfoRow(
                      'รหัสวิชา:', course.courseCode?.toString() ?? 'ไม่ระบุ'),
                  _buildCourseInfoRow('ชื่อวิชา:', course.courseName),
                  _buildCourseInfoRow('รายละเอียด:',
                      course.shortDescription?.toString() ?? 'ไม่มีข้อมูล',
                      maxLines: 2),
                  _buildCourseInfoRow('อาจารย์ผู้สอน:', course.professorName),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfoRow(String label, String value, {int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
            ),
          ],
        ),
      ),
    );
  }
}
