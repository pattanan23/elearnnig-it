import 'package:e_learning_it/professor/drawer_processor.dart';
import 'package:e_learning_it/professor/navbar_professor.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:e_learning_it/professor/course_model.dart';
import 'dart:math';

class MainProfessorPage extends StatelessWidget {
  final String userName;
  final String userId;

  const MainProfessorPage({super.key, required this.userName, required this.userId});

  // ฟังก์ชันสำหรับดึงข้อมูลคอร์สจาก API
  Future<List<Course>> fetchRecommendedCourses() async {
    // **เปลี่ยน URL นี้ให้ชี้ไปที่เซิร์ฟเวอร์ Node.js ของคุณ**
    final response = await http.get(Uri.parse('http://localhost:3006/api/show_courses'));

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
      appBar: NavbarProcessorPage(userName: userName, userId: userId),
      drawer: DrawerProcessorPage(userName: userName, userId: userId),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://placehold.co/1200x400/CCCCCC/333333?text=หลักสูตรวิทยาศาสตรบัณฑิต+สาขาวิชาเทคโนโลยีสารสนเทศ',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'หลักสูตรวิทยาศาสตรบัณฑิต สาขาวิชาเทคโนโลยีสารสนเทศ',
                      style: TextStyle(
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
              const SizedBox(height: 16),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.lightGreen[100],
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://placehold.co/1200x300/E8F5E9/000000?text=WELCOME+KU+85+สู่รั้วนนทรี',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'WELCOME KU 85 สู่รั้วนนทรี',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          offset: Offset(1.0, 1.0),
                          blurRadius: 2.0,
                          color: Color.fromARGB(50, 0, 0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'หลักสูตรแนะนำ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                  return FutureBuilder<List<Course>>(
                    future: fetchRecommendedCourses(),
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
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.65, // ปรับค่าเพื่อให้มีพื้นที่น้อยลง
                          ),
                          itemCount: min(snapshot.data!.length, 3), // จำกัดจำนวนคอร์สที่แสดง
                          itemBuilder: (context, index) {
                            final course = snapshot.data![index];
                            return _buildCourseCard(context, course);
                          },
                        );
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Container(
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
          Container(
            height: 150, // เพิ่มความสูงของรูปภาพเพื่อให้พื้นที่ว่างน้อยลง
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(course.imageUrl),
                fit: BoxFit.cover,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseInfoRow('รหัสวิชา:', course.courseCode.toString()),
                _buildCourseInfoRow('ชื่อวิชา:', course.courseName),
                _buildCourseInfoRow('รายละเอียด:', course.shortDescription.toString(), maxLines: 2), // จำกัดจำนวนบรรทัด
                _buildCourseInfoRow('อาจารย์ผู้สอน:', course.professorName),
              ],
            ),
          ),
        ],
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
