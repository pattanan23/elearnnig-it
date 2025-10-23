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
  // -----------------------------------------------------
  // STATE MANAGEMENT
  // -----------------------------------------------------
  List<dynamic> _courses = [];
  List<dynamic> _filteredCourses = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // -----------------------------------------------------
  // API: FETCH ALL DATA (Courses)
  // -----------------------------------------------------
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. ดึงข้อมูลคอร์สทั้งหมด
      final coursesUrl = Uri.parse('$API_BASE_URL/courses-admin');
      final coursesResponse = await http.get(coursesUrl);

      if (coursesResponse.statusCode == 200) {
        final List<dynamic> fetchedCourses = json.decode(coursesResponse.body);
        
        // 💡 DEBUG: ตรวจสอบข้อมูลที่ได้รับจาก API เพื่อดูว่ามีคีย์ 'course_name' หรือไม่
        print('Fetched Courses Data: ${json.encode(fetchedCourses)}'); 
        
        setState(() {
          _courses = fetchedCourses;
          _filteredCourses = fetchedCourses; 
        });
      } else {
        throw Exception('Failed to load courses. Status Code: ${coursesResponse.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('การเชื่อมต่อล้มเหลว: ไม่สามารถดึงข้อมูลคอร์สได้: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // -----------------------------------------------------
  // API: UPDATE COURSE (PUT /api/courses-admin/:courseId)
  // -----------------------------------------------------
  Future<void> _updateCourse(
    String courseId,
    String newCourseCode,
  ) async {
    final url = Uri.parse('$API_BASE_URL/courses-admin/$courseId');
    
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตข้อมูลคอร์สสำเร็จ')),
          );
        }
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

        if (mounted) {
          _showErrorDialog(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'การเชื่อมต่อล้มเหลว: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e',
        );
      }
    }
  }

  // -----------------------------------------------------
  // UI: MAIN BUILD METHOD
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavbarAdminPage(
        userName: widget.userName,
        userId: widget.userId,
      ),
      drawer: DrawerAdminPage(
        userName: widget.userName,
        userId: widget.userId,
      ),
      body: Container(
        color: const Color(0xFFF0F2F5), // สีพื้นหลังเทาอ่อน
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัว: คอร์สเรียน
            _buildHeader(),
            const SizedBox(height: 20),
            
            // ส่วนตารางข้อมูลและ Loading State (ขยายเต็มพื้นที่)
            Expanded(
              child: _buildBodyContent(),
            ),
          ],
        ),
      ),
    );
  }
  
  // -----------------------------------------------------
  // UI COMPONENTS
  // -----------------------------------------------------

  Widget _buildHeader() {
    return const Row(
      children: [
        // 💡 Icon คอร์สเรียน
        Icon(
          Icons.book, 
          color: Color(0xFF4CAF50), 
          size: 32,
        ),
        SizedBox(width: 10),
        Text(
          'คอร์สเรียน',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  // 🎯 FIX: เปลี่ยนโครงสร้างเพื่อรองรับ Horizontal Scrolling
  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredCourses.isEmpty) {
      return Center(
        child: Text('ไม่พบข้อมูลคอร์ส',
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    
    // 💡 Container สีขาวพร้อมเงาครอบตาราง
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // 🎯 FIX: ใช้ SingleChildScrollView ในแนวนอนเพื่อรองรับจอเล็ก
      child: SingleChildScrollView( 
        scrollDirection: Axis.horizontal, // 👈 KEY: เลื่อนในแนวนอน
        child: ConstrainedBox(
          // 🎯 FIX: บังคับให้ตารางมีความกว้างอย่างน้อยเท่ากับพื้นที่หน้าจอทั้งหมด (หัก padding)
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40),
          child: SingleChildScrollView( // เลื่อนในแนวตั้งสำหรับรายการในตาราง
            scrollDirection: Axis.vertical,
            child: _buildDataTable(),
          ),
        ),
      ),
    );
  }
  
  // 🎯 การแสดงผล course_name ในตารางมีความถูกต้องแล้ว
  Widget _buildDataTable() {
    return DataTable(
      columnSpacing: 12.0, 
      dataRowMinHeight: 50, 
      dataRowMaxHeight: 60,
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
      columns: [
        // 🎯 กำหนดความกว้างคงที่ (Fixed Width) แทน Expanded
        DataColumn(label: Container(width: 100, alignment: Alignment.centerLeft, child: const Text('รหัสวิชา', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
        DataColumn(label: Container(width: 300, alignment: Alignment.centerLeft, child: const Text('ชื่อวิชา', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
        DataColumn(label: Container(width: 150, alignment: Alignment.centerLeft, child: const Text('ผู้สอน/ผู้สร้าง', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
        // คอลัมน์แก้ไขข้อมูล ไม่ต้องกำหนดความกว้างมาก
        const DataColumn(label: Text('แก้ไขข้อมูล', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
      ],
      rows: _filteredCourses.map<DataRow>((course) {
        final instructorName = course['instructor_name'] ?? '-';
        final courseName = course['course_name'] ?? '-'; // 💡 course_name ถูกเรียกใช้ตรงนี้แล้ว
        
        return DataRow(
          cells: [
            // 🎯 ใช้ SizedBox เพื่อกำหนดความกว้างของ Cell และจัดการ Overflow
            DataCell(SizedBox(width: 100, child: Text(course['course_code'] ?? '-', overflow: TextOverflow.ellipsis))),
            DataCell(SizedBox(width: 300, child: Text(courseName, overflow: TextOverflow.ellipsis))), // 💡 แสดงผล course_name
            DataCell(SizedBox(width: 150, child: Text(instructorName, overflow: TextOverflow.ellipsis))),
            DataCell(
              Center( 
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.redAccent), 
                  onPressed: () => _showEditCourseDialog(course),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
  
  void _showEditCourseDialog(Map<String, dynamic> course) {
    final GlobalKey<FormState> _dialogFormKey = GlobalKey<FormState>();
    final courseCodeController = TextEditingController(text: course['course_code'] ?? '');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('แก้ไขรหัสวิชาของ ID: ${course['course_id']}'),
          content: SingleChildScrollView(
            child: Form( // เพิ่ม Form เพื่อการ Validation
              key: _dialogFormKey,
              child: ListBody(
                children: <Widget>[
                  // ชื่อวิชา (ไม่ให้แก้ไข) - course_name ถูกเรียกใช้ตรงนี้แล้ว
                  Text('ชื่อวิชา: ${course['course_name'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)), 
                  const SizedBox(height: 10),

                  // รหัสวิชา (Course Code)
                  TextFormField(
                    controller: courseCodeController,
                    decoration: const InputDecoration(labelText: 'รหัสวิชา (Course Code)'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสวิชา';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
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
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (_dialogFormKey.currentState!.validate()) {
                  _updateCourse(
                    course['course_id'].toString(),
                    courseCodeController.text, 
                  );
                  Navigator.of(context).pop();
                } 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialogPage(message: message), 
    );
  }
}
