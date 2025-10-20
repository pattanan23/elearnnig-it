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
  List<dynamic> _filteredCourses = []; // ข้อมูลที่ใช้แสดงผล (ไม่ต้องใช้กรองแล้ว)
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

      // (ลบการเรียก API teachers ออกไป)

      if (coursesResponse.statusCode == 200) {
        final List<dynamic> fetchedCourses = json.decode(coursesResponse.body);
        
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
            
            // 💡 ลบ _buildSearchAndAction() ออก

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

  // 💡 ปรับปรุง: ใช้ LayoutBuilder เพื่อให้ตารางขยายเต็มความกว้าง
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
      // 💡 LayoutBuilder เพื่อให้ทราบความกว้างของพื้นที่ที่มี
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: ConstrainedBox(
              // 💡 บังคับให้ตารางมีความกว้างอย่างน้อยเท่ากับความกว้างสูงสุด
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              // 💡 ลบ Column ที่ครอบ DataTable ออก เพราะไม่ต้องมี Pagination แล้ว
              child: _buildDataTable(),
            ),
          );
        },
      ),
    );
  }
  
  // 💡 ปรับปรุง: ใช้ Expanded ใน DataColumn
  Widget _buildDataTable() {
    return DataTable(
      // 💡 ตั้งค่าให้ยืดตาม ConstrainedBox
      columnSpacing: 12.0, 
      dataRowMinHeight: 50, 
      dataRowMaxHeight: 60,
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
      // 💡 ตั้งค่านี้เพื่อบังคับให้ตารางยืดเต็มความกว้าง
      columns: const [
        // 💡 ใช้ Expanded เพื่อให้ยืดพื้นที่
        DataColumn(label: Expanded(child: Text('รหัสวิชา', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
        DataColumn(label: Expanded(child: Text('ชื่อวิชา', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
        DataColumn(label: Expanded(child: Text('ผู้สอน/ผู้สร้าง', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
        // คอลัมน์แก้ไขข้อมูล ไม่ต้องขยายเต็ม
        DataColumn(label: Text('แก้ไขข้อมูล', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
      ],
      rows: _filteredCourses.map<DataRow>((course) {
        final instructorName = course['instructor_name'] ?? '-';
        // ใช้ course['course_name'] เพื่อแสดงชื่อวิชา
        final courseName = course['course_name'] ?? '-';
        
        return DataRow(
          cells: [
            DataCell(Text(course['course_code'] ?? '-')),
            DataCell(Text(courseName)), 
            DataCell(Text(instructorName)),
            DataCell(
              // 💡 เปลี่ยนปุ่ม "แก้ไข" เป็น Icon (ตามรูป image_3094f7.png)
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
  
  // 💡 ลบ _buildPagination() ออก

  // -----------------------------------------------------
  // FUNCTION: EDIT DIALOG & UTILITY
  // -----------------------------------------------------
  void _showEditCourseDialog(Map<String, dynamic> course) {
    final courseCodeController = TextEditingController(text: course['course_code'] ?? '');
    
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
              child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (courseCodeController.text.isNotEmpty) {
                  _updateCourse(
                    course['course_id'].toString(),
                    courseCodeController.text, 
                  );
                  Navigator.of(context).pop();
                } else {
                  _showErrorDialog('กรุณากรอกรหัสวิชา');
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