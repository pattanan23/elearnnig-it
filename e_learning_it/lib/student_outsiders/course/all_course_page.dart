// course_overview_page.dart

import 'package:e_learning_it/student_outsiders/course/course_detail_page.dart';
import 'package:e_learning_it/student_outsiders/drawer_page.dart';
import 'package:e_learning_it/student_outsiders/navbar_normal.dart';
import 'package:e_learning_it/student_outsiders/main_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class CourseAllPage extends StatelessWidget {
  final String userName;
  final String userId;

  const CourseAllPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  // A reusable widget to build a section with a title and a grid of courses.
  Widget _buildCourseSection(
    BuildContext context, {
    required String title,
    required Future<List<Course>> futureCourses,
    required String userName,
    required String userId,
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
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('ไม่พบข้อมูลหลักสูตร'));
                    } else {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final course = snapshot.data![index];
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
    return GestureDetector(
      onTap: () async {
        try {
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
                  content: Text('ไม่สามารถดึงข้อมูลรายละเอียดหลักสูตรได้')),
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
          border: Border.all(color: const Color(0xFF2E7D32)),
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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseInfoRow('รหัสวิชา:', course.courseCode.toString()),
                  _buildCourseInfoRow('ชื่อวิชา:', course.courseName),
                  _buildCourseInfoRow('รายละเอียด:', course.shortDescription.toString(),
                      maxLines: 2),
                  _buildCourseInfoRow('อาจารย์ผู้สอน:', course.professorName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for course information rows.
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

  // --- API Fetching Logic ---
  Future<List<Course>> fetchRecommendedCourses() async {
    final response = await http.get(Uri.parse('http://localhost:3006/api/show_courses'));
    if (response.statusCode == 200) {
      final List<dynamic> courseData = json.decode(response.body);
      return courseData.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recommended courses');
    }
  }

  Future<List<Course>> fetchAllCourses() async {
    final response = await http.get(Uri.parse('http://localhost:3006/api/courses/all_by_id'));
    if (response.statusCode == 200) {
      final List<dynamic> courseData = json.decode(response.body);
      return courseData.map((json) => Course.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load all courses');
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
              // Use a container for the page title.
              Container(
                child: const Row(
                  children: [
                    Text(
                      'หลักสูตร',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // New Courses Section
              _buildCourseSection(
                context,
                title: 'หลักสูตรทั้งหมด',
                futureCourses: fetchAllCourses(),
                userName: userName,
                userId: userId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}