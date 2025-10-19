// lib/AdminCourseManagementPage.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// ตรวจสอบ path ของไฟล์เหล่านี้ให้ถูกต้องตามโครงสร้างโปรเจกต์ของคุณ
import 'package:e_learning_it/admin/error_dialog_page.dart'; 
import 'navbar_admin.dart'; 
import 'drawer_admin.dart'; 

// **NOTE:** แทนที่ด้วย Base URL ที่ถูกต้องของคุณ
const String API_BASE_URL = 'http://localhost:3006/api'; 

class CourseManagePage extends StatefulWidget {
  final String userName;
  final String userId;

  const CourseManagePage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<CourseManagePage> createState() => _CourseManagePageState();
}

class _CourseManagePageState extends State<CourseManagePage> {
  List<dynamic> _courses = [];
  // ลบตัวแปร _teachers ออกได้ แต่เก็บไว้เพื่อความปลอดภัยของ Logic เดิม
  List<dynamic> _teachers = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // -----------------------------------------------------
  // 1. API: FETCH ALL DATA (Courses and Teachers)
  // -----------------------------------------------------
  // ยังคงดึงข้อมูลอาจารย์มาเผื่อไว้แม้จะไม่ได้ใช้ในหน้านี้แล้วก็ตาม
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. ดึงข้อมูลคอร์สทั้งหมด
      final coursesUrl = Uri.parse('$API_BASE_URL/courses-admin');
      final coursesResponse = await http.get(coursesUrl);

      // 2. ดึงข้อมูลอาจารย์ทั้งหมด
      final teachersUrl = Uri.parse('$API_BASE_URL/teachers');
      final teachersResponse = await http.get(teachersUrl);

      if (coursesResponse.statusCode == 200 && teachersResponse.statusCode == 200) {
        final List<dynamic> fetchedCourses = json.decode(coursesResponse.body);
        final List<dynamic> fetchedTeachers = json.decode(teachersResponse.body);

        setState(() {
          _courses = fetchedCourses;
          _teachers = fetchedTeachers;
        });
      } else {
        throw Exception('Failed to load data. Status Codes: Courses=${coursesResponse.statusCode}, Teachers=${teachersResponse.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('การเชื่อมต่อล้มเหลว: ไม่สามารถดึงข้อมูลคอร์สหรืออาจารย์ได้: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // -----------------------------------------------------
  // 2. API: UPDATE COURSE (PUT /api/courses-admin/:courseId)
  // -----------------------------------------------------
  Future<void> _updateCourse(
    String courseId,
    String newCourseCode,
    // ลบ newInstructorId ออกจาก parameter
  ) async {
    final url = Uri.parse('$API_BASE_URL/courses-admin/$courseId');
    
    // ส่งเฉพาะ course_code
    final updateData = {
      'course_code': newCourseCode,
    };

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตข้อมูลคอร์สสำเร็จ')),
        );
        _fetchData(); // รีเฟรชข้อมูลในตาราง
      } else {
        String errorMessage = 'การอัปเดตล้มเหลว: Status Code ${response.statusCode}';
        
        try {
          if (response.body.isNotEmpty) {
            final responseBody = json.decode(response.body);
            errorMessage = 'การอัปเดตล้มเหลว: ${responseBody['message'] ?? errorMessage}';
          }
        } catch (e) {
          errorMessage = 'การอัปเดตล้มเหลว: Status Code ${response.statusCode}. ' + 
                         'โปรดตรวจสอบ Console Server: ${response.body.isNotEmpty ? response.body : 'ไม่มีข้อความตอบกลับ'}';
        }

        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog(
        'การเชื่อมต่อล้มเหลว: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e',
      );
    }
  }

  // -----------------------------------------------------
  // 3. UI: EDIT DIALOG
  // -----------------------------------------------------
  void _showEditCourseDialog(Map<String, dynamic> course) {
    // 1. Controller สำหรับ Course Code
    final courseCodeController = TextEditingController(text: course['course_code'] ?? '');
    
    // ลบ Logic ที่เกี่ยวข้องกับ instructor_id ออกทั้งหมด

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('แก้ไขรหัสวิชาของ ID: ${course['course_id']}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // รหัสวิชา (Course Code)
                TextFormField(
                  controller: courseCodeController,
                  decoration: const InputDecoration(labelText: 'รหัสวิชา (Course Code)'),
                ),
                const SizedBox(height: 20),
                // ลบ Dropdown เลือกอาจารย์ออก
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('บันทึก'),
              onPressed: () {
                // ตรวจสอบความถูกต้องและเรียก API อัปเดต
                if (courseCodeController.text.isNotEmpty) {
                  _updateCourse(
                    course['course_id'].toString(),
                    courseCodeController.text, // ส่งรหัสวิชา
                    // ลบ parameter instructor_id ออก
                  );
                  Navigator.of(context).pop();
                } else {
                  _showErrorDialog('กรุณากรอกรหัสวิชา');
                }
              },
            ),
          ],
        );
      },
    );
  }

  // -----------------------------------------------------
  // 4. UTILITY: ERROR DIALOG (เหมือนเดิม)
  // -----------------------------------------------------
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialogPage(message: message), 
    );
  }

  // -----------------------------------------------------
  // 5. UI: BUILD METHOD (เหมือนเดิม)
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // กำหนด Colums ตาม 3 Fields ที่ต้องการ + ID + จัดการ
    List<DataColumn> columns = const [
      DataColumn(label: Text('ID')),
      DataColumn(label: Text('รหัสวิชา')), 
      DataColumn(label: Text('อีเมลอาจารย์')), 
      DataColumn(label: Text('ชื่ออาจารย์')), 
      DataColumn(label: Text('จัดการ')),
    ];

    return Scaffold(
      appBar: NavbarAdminPage(
        userName: widget.userName,
        userId: widget.userId,
      ),
      drawer: DrawerAdminPage(
        userName: widget.userName,
        userId: widget.userId,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: columns,
                  rows: _courses.map((course) {
                    return DataRow(cells: [
                      DataCell(Text(course['course_id']?.toString() ?? '-')),
                      DataCell(Text(course['course_code'] ?? '-')),
                      DataCell(Text(course['email'] ?? '-')),
                      DataCell(Text(course['instructor_name'] ?? '-')),
                      DataCell(
                        ElevatedButton(
                          onPressed: () => _showEditCourseDialog(course),
                          child: const Text('แก้ไข'),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
    );
  }
}