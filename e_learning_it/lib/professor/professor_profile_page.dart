// professor_profile_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

// ----------------------------------------------------------------------
// 🎯 Global Constant: API Base URL
// ----------------------------------------------------------------------
const String BASE_URL = 'http://localhost:3006';

// ----------------------------------------------------------------------
// 🎯 Minimal User and Course Models 
// ----------------------------------------------------------------------
class ProfessorUser {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? studentId; 

  ProfessorUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.studentId,
  });

  factory ProfessorUser.fromJson(Map<String, dynamic> json) {
    final userIdValue = json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0;
    final studentIdValue = json['student_id'];

    return ProfessorUser(
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

class ProfessorCourse {
  final String courseId; // ✅ แก้ไข: เปลี่ยนเป็น String
  final String courseName;
  final String courseImage; 
  final String courseCode;

  ProfessorCourse({
    required this.courseId,
    required this.courseName,
    required this.courseImage,
    required this.courseCode,
  });

  factory ProfessorCourse.fromJson(Map<String, dynamic> json) {
    return ProfessorCourse(
      courseId: json['course_id']?.toString() ?? '0', // ✅ แก้ไข: ดึงค่าเป็น String
      courseName: json['course_name'] as String,
      courseImage: json['image_url'] ?? 'https://placehold.co/300x150/505050/FFFFFF?text=IT+Course',
      courseCode: json['course_code'] as String? ?? 'N/A',
    );
  }
}

class ProfessorProfilePage extends StatefulWidget {
  final String userName; 
  final String userId;

  const ProfessorProfilePage({super.key, required this.userName, required this.userId});

  @override
  State<ProfessorProfilePage> createState() => _ProfessorProfilePageState();
}

class _ProfessorProfilePageState extends State<ProfessorProfilePage> {
  ProfessorUser? _userProfile;
  List<ProfessorCourse> _professorCourses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

// ----------------------------------------------------------------------
// 🔄 Fetch Data Logic (นำกลับมาใช้)
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
      _userProfile = ProfessorUser.fromJson(data);
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
        _professorCourses = courseData.map((json) => ProfessorCourse.fromJson(json)).toList();
      });
    } else {
      // หากเกิดข้อผิดพลาดในการดึงข้อมูลหลักสูตร
      setState(() {
        _professorCourses = [];
        // สามารถเพิ่มการแจ้งเตือน Error ที่นี่ได้ หากต้องการให้แสดง Error เฉพาะส่วน
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 ปรับเป็น Layout แบบมี Sidebar และ Content Area (Desktop/Web)
    return Scaffold(
      appBar: AppBar(
        // สีเขียวตามภาพ Screenshot 2025-10-13 105411.png
        backgroundColor: Colors.green, 
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

  // ----------------------------------------------------------------------
  // 🔨 NAVBAR MOCK (ตามรูป Desktop)
  // ----------------------------------------------------------------------
  Widget _buildMockAppBar() {
    return AppBar(
      automaticallyImplyLeading: false, 
      backgroundColor: Colors.white,
      elevation: 1,
      titleSpacing: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 1. Logo (IT Icon)
          Container(
            width: 200, // กว้างเท่ากับส่วน Sidebar
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                const Icon(Icons.computer, color: Colors.green, size: 28),
                const SizedBox(width: 5),
                const Text('IT', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
          
          // 2. Search Bar
          Expanded(
            child: Container(
              height: 40,
              margin: const EdgeInsets.only(left: 20, right: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey[300]!)
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'ค้นหา',
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 0, bottom: 10),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        // 3. Name (อาจารย์ นนทรี สีเขียว)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            _userProfile != null ? 'อาจารย์ ${_userProfile!.firstName} ${_userProfile!.lastName}' : widget.userName,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
        // 4. Logout Button/Icon
        IconButton(
          icon: const Icon(Icons.power_settings_new, color: Colors.green), 
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logout')),
            );
          },
        ),
        const SizedBox(width: 10),
      ],
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
                    child: _buildPersonalInfoCard(),
                  ),
                  
                  SizedBox(width: isWideScreen ? 20 : 0, height: isWideScreen ? 0 : 20),

                  Flexible(
                    flex: isWideScreen ? 1 : 0, 
                    child: _buildProfessorCoursesCard(context),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Card 1: Personal Information (ข้อมูลส่วนตัว) - ตรงตามรูป
  Widget _buildPersonalInfoCard() {
    final user = _userProfile;
    final displayName = user != null ? '${user.firstName} ${user.lastName}' : widget.userName;
    final displayId = user != null ? user.userId.toString() : widget.userId; 
    final displayEmail = user?.email ?? 'noname@email.com';
    
    final professorNameTitle = 'อาจารย์ ${displayName}'; 

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
                Text(
                  professorNameTitle,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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


  // Card 2: Professor Courses (หลักสูตรของฉัน) - ตรงตามรูป
  Widget _buildProfessorCoursesCard(BuildContext context) {
    // แสดงหลักสูตรสูงสุด 4 รายการ
    final List<ProfessorCourse> coursesToShow = _professorCourses.take(4).toList(); 

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'หลักสูตรของฉัน', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.black54),
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('แก้ไขหลักสูตร')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Course Grid
            coursesToShow.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('อาจารย์ยังไม่ได้สร้างหลักสูตรใด ๆ'),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: coursesToShow.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.8, 
                    ),
                    itemBuilder: (context, index) {
                      return _buildCourseCard(coursesToShow[index], context);
                    },
                  ),
          ],
        ),
      ),
    );
  }
  
  // 🔨 Course Card Widget (ใช้ Card เดียวกับในรูป)
  Widget _buildCourseCard(ProfessorCourse course, BuildContext context) {
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
            // ✅ ส่วนที่แก้ไข: Image area (ใช้รูปภาพจริงจาก Network)
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