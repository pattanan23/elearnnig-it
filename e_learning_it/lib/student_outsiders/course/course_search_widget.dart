// course_search_widget.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async'; 
import 'dart:io'; 
import 'dart:typed_data'; // สำหรับ utf8.decode
// 💡 สำคัญ: นำเข้า Course Model 
import 'package:e_learning_it/student_outsiders/course/course_detail_page.dart'; // <<< ตรวจสอบ Path นี้

// กำหนด Base URL เดียวกัน
const String _baseUrl = 'http://localhost:3006/api';

// ------------------------------------------------------------------
// 1. ฟังก์ชันสำหรับเรียก API ค้นหารายวิชา (แก้ไขการเรียงลำดับเป็นตัวเลข)
// ------------------------------------------------------------------
Future<List<Course>> searchCourses(String query) async {
  final encodedQuery = Uri.encodeComponent(query);
  final url = '$_baseUrl/search-courses?query=$encodedQuery'; 
  
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // ใช้ utf8.decode เพื่อจัดการภาษาไทย
      final List<dynamic> courseJson = json.decode(utf8.decode(response.bodyBytes));
      
      if (courseJson.isEmpty) {
        return [];
      }
      
      final List<Course> courses = courseJson.map((json) => Course.fromJson(json)).toList();
      
      // 💡 [FIX] แปลง courseId เป็น int ก่อนเปรียบเทียบ เพื่อเรียงตามค่าตัวเลขจริง (มากไปน้อย)
      courses.sort((a, b) {
          final int courseIdB = int.tryParse(b.courseId) ?? 0;
          final int courseIdA = int.tryParse(a.courseId) ?? 0;
          
          return courseIdB.compareTo(courseIdA); // เรียงจากมากไปน้อย (DESCENDING)
      }); 
      
      return courses;
    } else {
      // แสดง Response Body ใน Error เพื่อ Debug ง่ายขึ้น
      throw Exception('Failed to search courses. Status: ${response.statusCode}, Response: ${utf8.decode(response.bodyBytes)}');
    }
  } on SocketException {
    throw Exception('Connection failed. Please check your network or server URL.');
  } catch (e) {
    throw Exception('An unexpected error occurred during search or JSON parsing: ${e.toString()}');
  }
}

// ------------------------------------------------------------------
// 2. Widget ที่จัดการช่องค้นหาและการแสดงผลลัพธ์
// ------------------------------------------------------------------
class CourseSearchWidget extends StatefulWidget {
  final String userName;
  final String userId;
  final Widget Function(
    BuildContext, {
    required String title,
    required Future<List<Course>> futureCourses,
    required String userName,
    required String userId,
  }) buildCourseSection;
  final Future<List<Course>> initialFutureCourses;

  const CourseSearchWidget({
    Key? key,
    required this.userName,
    required this.userId,
    required this.buildCourseSection,
    required this.initialFutureCourses,
  }) : super(key: key);

  @override
  _CourseSearchWidgetState createState() => _CourseSearchWidgetState();
}

class _CourseSearchWidgetState extends State<CourseSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<Course>>? _futureCourses; 
  String _currentQuery = ''; 

  // ------------------------------------------------------------------
  // 3. Init State (การเตรียมข้อมูลเริ่มต้น)
  // ------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _futureCourses = widget.initialFutureCourses;
    // Listener เพื่อให้ปุ่ม Clear แสดง/หาย ได้
    _searchController.addListener(() {
      setState(() {});
    });
  }

  // ------------------------------------------------------------------
  // 4. ฟังก์ชันค้นหา
  // ------------------------------------------------------------------
  void _performSearch(String query) {
    final trimmedQuery = query.trim();
    
    // 💡 การแก้ไขที่สำคัญ: ต้องเรียก setState เพื่ออัปเดต _futureCourses 
    setState(() {
      _currentQuery = trimmedQuery;
      _futureCourses = trimmedQuery.isEmpty
          ? widget.initialFutureCourses // ถ้าว่าง ให้ใช้ Future เดิมที่ดึงรายวิชาทั้งหมด
          : searchCourses(trimmedQuery); // ถ้ามี Query ให้เรียก API ค้นหา
    });
  }

  // ------------------------------------------------------------------
  // 5. Build Method
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. ช่องค้นหา
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ค้นหารายวิชา (เช่น S001, Python Programming)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Color(0xFF2E7D32)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch(''); // ค้นหาด้วยข้อความว่างเพื่อแสดงผลทั้งหมด
                    },
                  )
                : null,
            ),
            // ใช้ onSubmitted สำหรับการค้นหาเมื่อกด Enter/Done
            onSubmitted: _performSearch, 
            onChanged: (value) {
              // สามารถใช้ onChanged และเรียก setState({}) 
              // หรือใช้ listener ใน initState() เหมือนที่ทำอยู่แล้ว
            },
          ),
        ),
        const SizedBox(height: 24),

        // 2. แสดงผลลัพธ์
        widget.buildCourseSection(
          context,
          title: _currentQuery.isEmpty
              ? 'รายวิชา' 
              : 'ผลการค้นหาสำหรับ: \"${_currentQuery}\"', 
          futureCourses: _futureCourses!, // ใช้ Future ที่ถูกอัปเดตแล้ว
          userName: widget.userName,
          userId: widget.userId,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}