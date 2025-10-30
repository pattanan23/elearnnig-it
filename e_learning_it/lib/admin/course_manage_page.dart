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
  List<dynamic> _courses = []; // ข้อมูลคอร์สทั้งหมดที่ดึงมาจาก API
  List<dynamic> _filteredCourses = []; // ข้อมูลที่ถูกกรองและแสดงผล
  bool _isLoading = true;
  // 💡 เพิ่ม State สำหรับการค้นหา
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // -----------------------------------------------------
  // FILTERING LOGIC
  // -----------------------------------------------------

  // 💡 เพิ่ม: ฟังก์ชันสำหรับกรองข้อมูลคอร์สตามค่าค้นหา
  void _filterCourses() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredCourses = _courses;
        return;
      }

      final query = _searchQuery.toLowerCase();
      _filteredCourses = _courses.where((course) {
        final courseCode = course['course_code']?.toLowerCase() ?? '';
        final courseName = course['course_name']?.toLowerCase() ?? '';

        // ค้นหาจากรหัสวิชาหรือชื่อวิชา
        return courseCode.contains(query) || courseName.contains(query);
      }).toList();
    });
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
          // เรียกใช้การกรองทันทีหลังดึงข้อมูล (แม้ว่า Query จะว่างเปล่า)
          _filterCourses();
        });
      } else {
        throw Exception(
            'Failed to load courses. Status Code: ${coursesResponse.statusCode}');
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
            // 💡 เพิ่มช่องค้นหา
            _buildSearchBar(),

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

  // 💡 เพิ่ม: ช่องค้นหา (Search Bar)
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'ค้นหาจากรหัสวิชา หรือชื่อวิชา...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
            _filterCourses(); // 🎯 เรียกฟังก์ชันกรอง
          });
        },
      ),
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
          constraints:
              BoxConstraints(minWidth: MediaQuery.of(context).size.width - 40),
          child: SingleChildScrollView(
            // เลื่อนในแนวตั้งสำหรับรายการในตาราง
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
        DataColumn(
            label: Container(
                width: 100,
                alignment: Alignment.centerLeft,
                child: const Text('รหัสวิชา',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)))),
        DataColumn(
            label: Container(
                width: 300,
                alignment: Alignment.centerLeft,
                child: const Text('ชื่อวิชา',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)))),
        DataColumn(
            label: Container(
                width: 150,
                alignment: Alignment.centerLeft,
                child: const Text('ผู้สอน/ผู้สร้าง',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)))),
      ],
      rows: _filteredCourses.map<DataRow>((course) {
        final instructorName = course['instructor_name'] ?? '-';
        final courseName = course['course_name'] ?? '-';

        return DataRow(
          cells: [
            // 1. รหัสวิชา
            DataCell(SizedBox(
                width: 100,
                child: Text(course['course_code'] ?? '-',
                    overflow: TextOverflow.ellipsis))),
            // 2. ชื่อวิชา
            DataCell(SizedBox(
                width: 300,
                child: Text(courseName, overflow: TextOverflow.ellipsis))),
            // 3. ผู้สอน/ผู้สร้าง
            DataCell(SizedBox(
                width: 150,
                child: Text(instructorName, overflow: TextOverflow.ellipsis))),
      
          ],
        );
      }).toList(),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialogPage(message: message),
    );
  }
}