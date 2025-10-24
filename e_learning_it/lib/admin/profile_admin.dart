// professor_profile_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // 💡 ต้อง import dart:math สำหรับ max function

// ----------------------------------------------------------------------
// 🎯 Global Constant: API Base URL
// ----------------------------------------------------------------------
const String BASE_URL = 'http://localhost:3006';

// ----------------------------------------------------------------------
// 🎯 Minimal User and Course Models 
// ----------------------------------------------------------------------
class AdminUser {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? studentId; 

  AdminUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.studentId,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final userIdValue = json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0;
    final studentIdValue = json['student_id'];

    return AdminUser(
      userId: userIdValue,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String, 
      email: json['email'] as String,
      role: json['role'] as String,
      studentId: (studentIdValue == null || studentIdValue == 'null' || studentIdValue == '') 
          ? null 
          : studentIdValue.toString(),
    );
  }
}

class AdminCourse {
  final String courseId; 
  final String courseName;
  final String courseImage; 
  final String courseCode;

  AdminCourse({
    required this.courseId,
    required this.courseName,
    required this.courseImage,
    required this.courseCode,
  });

  factory AdminCourse.fromJson(Map<String, dynamic> json) {
    return AdminCourse(
      courseId: json['course_id']?.toString() ?? '0',
      courseName: json['course_name'] as String,
      courseImage: json['image_url'] ?? 'https://placehold.co/300x150/505050/FFFFFF?text=IT+Course',
      courseCode: json['course_code'] as String? ?? 'N/A',
    );
  }
}

class AdminProfilePage extends StatefulWidget {
  final String userName;
  final String userId;

  const AdminProfilePage({super.key, required this.userName, required this.userId});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  AdminUser? _userProfile;
  List<AdminCourse> _adminCourses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

// ----------------------------------------------------------------------
// 🔄 Fetch Data Logic
// ----------------------------------------------------------------------
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final profileFuture = _fetchProfessorProfile();
      final coursesFuture = _fetchProfessorCourses();
      await Future.wait([profileFuture, coursesFuture]);
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProfessorProfile() async {
    final url = Uri.parse('$BASE_URL/api/user-professor/${widget.userId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _userProfile = AdminUser.fromJson(data);
    } else {
      throw Exception('ไม่สามารถดึงข้อมูลโปรไฟล์ได้ (Status: ${response.statusCode})');
    }
  }

  Future<void> _fetchProfessorCourses() async {
    // เรียก API ที่กรองตาม userId เพื่อดึงเฉพาะหลักสูตรที่ผู้ใช้นี้สร้าง
    final url = Uri.parse('$BASE_URL/api/professor/courses/${widget.userId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> courseData = json.decode(response.body);
      setState(() {
        _adminCourses = courseData.map((json) => AdminCourse.fromJson(json)).toList();
      });
    } else {
      setState(() {
        _adminCourses = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 ปรับเป็น Layout แบบมี Sidebar และ Content Area (Desktop/Web)
    return Scaffold(
      appBar: AppBar(
        // สีเขียวตามภาพ Screenshot 2025-10-13 105411.png
        backgroundColor: const Color(0xFF03A96B),
        // ทำให้ปุ่มย้อนกลับแสดงผล (ถ้าหน้าจอนี้ถูก push มา)
        automaticallyImplyLeading: true, 
        title: const Text(
          'My Profile', 
          style: TextStyle(color: Colors.white),
        ),
        // สีไอคอนเป็นสีขาวตามภาพ
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      // Main Content Area
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _buildProfileContent(context),
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Sub-Header: Icon & Text (ข้อมูลส่วนตัว)
          Row(
            children: [
              const Icon(Icons.person, size: 28, color: Colors.green),
              const SizedBox(width: 10),
              Text(
                'ข้อมูลส่วนตัว', 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700]),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),

          // Two main cards (Profile Info Card and Courses Card) - ใช้ Row สำหรับ Desktop
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth > 800;
              
              return Flex(
                direction: isWideScreen ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: isWideScreen ? 1 : 0, 
                    child: _buildPersonalInfoCard(), // 🎯 แก้ไข Right Overflow ที่นี่
                  ),
                  
                  SizedBox(width: isWideScreen ? 20 : 0, height: isWideScreen ? 0 : 20),
                ],
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Card 1: Personal Information (ข้อมูลส่วนตัว)
  Widget _buildPersonalInfoCard() {
    final user = _userProfile;
    final displayName = user != null ? '${user.firstName} ${user.lastName}' : widget.userName;
    final displayId = user != null ? user.userId.toString() : widget.userId; 
    final displayEmail = user?.email ?? 'noname@email.com';
    
    final professorNameTitle = '${displayName}'; 

    return Card(
      elevation: 0, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[300]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Icon and Name
            Row(
              children: [
                const Icon(Icons.account_circle, size: 80, color: Colors.blueGrey),
                const SizedBox(width: 20),
                // 🎯 FIX: ใช้ Expanded เพื่อป้องกันชื่ออาจารย์ที่ยาวเกินไปทำให้เกิด Right Overflow
                Expanded(
                  child: Text(
                    professorNameTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 1), 
            
            const SizedBox(height: 10),

            // Detailed Information
            _buildProfileDetailRow('รหัสผู้ใช้', displayId),
            _buildProfileDetailRow('อีเมล', displayEmail, isLast: true),
          ],
        ),
      ),
    );
  }
  
  // Helper for Profile Detail Rows
  Widget _buildProfileDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$label : ',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              Expanded( // ใช้ Expanded เพื่อให้ข้อความยาวๆ ไม่เกินขอบ
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!isLast)
            const Divider(height: 10, thickness: 0.5),
        ],
      ),
    );
  }


  // 🔨 Course Card Widget (ใช้ Card เดียวกับในรูป)
  Widget _buildCourseCard(AdminCourse course, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          // 💡 Placeholder: ต้องเปลี่ยนไปหน้า CourseProfessorDetailPage
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('กำลังเปิดดูรายละเอียดหลักสูตร ${course.courseName}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ Image area (ใช้รูปภาพจริงจาก Network)
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  course.courseImage, // ใช้ URL รูปภาพที่ได้จาก API
                  fit: BoxFit.cover,
                  // เพิ่ม Placeholder ขณะโหลด
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[100],
                      child: Center(child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.green,
                      )),
                    );
                  },
                  // เพิ่ม Error widget หากดึงรูปภาพไม่ได้
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.broken_image, color: Colors.grey[600])),
                  ),
                ),
              ),
            ),
            // Text area
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'รหัสวิชา: ${course.courseCode}',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.black54),
                    ),
                    Text(
                      'วิชา: ${course.courseName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Edit Icon
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.edit_note, size: 20, color: Colors.grey[600]),
              ),
            )
          ],
        ),
      ),
    );
  }

}
