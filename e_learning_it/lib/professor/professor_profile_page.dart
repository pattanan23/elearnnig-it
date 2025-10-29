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
  final String courseId; 
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
      courseId: json['course_id']?.toString() ?? '0', 
      courseName: json['course_name'] as String,
      courseImage: json['image_url'] ?? 'https://placehold.co/300x150/505050/FFFFFF?text=IT+Course',
      courseCode: json['course_code'] as String? ?? 'N/A',
    );
  }
}

// ----------------------------------------------------------------------
// 🎯 FULL Course Model (ใหม่! สำหรับใช้ใน Dialog แก้ไข) 
// ----------------------------------------------------------------------
class FullCourseDetails {
  final String courseId; 
  final String courseCode;
  final String courseName;
  final String shortDescription;
  final String description;
  final String objective;
  final String imageUrl;

  FullCourseDetails({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.shortDescription,
    required this.description,
    required this.objective,
    required this.imageUrl,
  });

  factory FullCourseDetails.fromJson(Map<String, dynamic> json) {
    return FullCourseDetails(
      courseId: json['course_id']?.toString() ?? '0',
      courseCode: json['course_code'] as String? ?? 'N/A',
      courseName: json['course_name'] as String? ?? 'ไม่ระบุชื่อวิชา',
      shortDescription: json['short_description'] as String? ?? '',
      description: json['description'] as String? ?? '',
      objective: json['objective'] as String? ?? '',
      imageUrl: json['image_url'] ?? 'https://placehold.co/300x150/505050/FFFFFF?text=IT+Course',
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
// 🔄 Fetch Data Logic & API Interaction
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
    final url = Uri.parse('$BASE_URL/api/professor/courses/${widget.userId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> courseData = json.decode(response.body);
      setState(() {
        _professorCourses = courseData.map((json) => ProfessorCourse.fromJson(json)).toList();
      });
    } else {
      setState(() {
        _professorCourses = [];
      });
    }
  }
  
  // ⚙️ API NEW: ดึงรายละเอียดหลักสูตรแบบเต็ม (เพื่อนำมากรอกใน Pop-up ก่อนแก้ไข)
  Future<FullCourseDetails> _fetchCourseDetails(String courseId) async {
    final url = Uri.parse('$BASE_URL/api/courses/$courseId'); // สมมติว่ามี API นี้อยู่
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // API อาจจะส่งข้อมูลเป็น Array ถ้าเป็นเช่นนั้นต้องแก้ตรงนี้
      // สำหรับโค้ดนี้ สมมติว่าส่งเป็น Object { ... }
      return FullCourseDetails.fromJson(data);
    } else {
      throw Exception('ไม่สามารถดึงรายละเอียดหลักสูตรได้ (Status: ${response.statusCode})');
    }
  }
  
  // ⚙️ API NEW: อัปเดตข้อมูลหลักสูตรผ่าน API
  Future<void> _updateCourseDetails(FullCourseDetails course) async {
    final url = Uri.parse('$BASE_URL/api/courses/${course.courseId}'); 
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        // ฟิลด์ต้องตรงกับ SQL Update Query: course_code, course_name, short_description, description, objective
        'course_code': course.courseCode,
        'course_name': course.courseName,
        'short_description': course.shortDescription,
        'description': course.description,
        'objective': course.objective,
        // course_id ถูกใช้เป็น $6 ใน WHERE clause ใน SQL Query (ส่งใน URL แล้ว)
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('ไม่สามารถอัปเดตหลักสูตรได้ (Status: ${response.statusCode}, Error: ${response.body})');
    }
    
    // เมื่ออัปเดตสำเร็จ ให้โหลดข้อมูลทั้งหมดใหม่ เพื่อให้รายการหลักสูตรอัปเดตบนหน้าจอ
    await _fetchData(); 
  }


// ----------------------------------------------------------------------
// 📝 Edit Dialog Widget (ใหม่! สำหรับการแก้ไข)
// ----------------------------------------------------------------------
  void _showEditCourseDialog(ProfessorCourse course) async {
    // แสดง CircularProgressIndicator ขณะโหลดรายละเอียดเต็ม
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. ดึงรายละเอียดฉบับเต็มมากรอกในฟอร์ม
      final details = await _fetchCourseDetails(course.courseId);
      
      // ปิด Loading Dialog
      Navigator.of(context).pop(); 

      // สร้าง TextEditingController และกำหนดค่าเริ่มต้น
      final codeController = TextEditingController(text: details.courseCode);
      final nameController = TextEditingController(text: details.courseName);
      final shortDescController = TextEditingController(text: details.shortDescription);
      final descController = TextEditingController(text: details.description);
      final objectiveController = TextEditingController(text: details.objective);
      final formKey = GlobalKey<FormState>();

      // 2. แสดง Dialog แก้ไข
      await showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('แก้ไขหลักสูตร: ${course.courseCode}'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(codeController, 'รหัสวิชา (course_code)', isRequired: true),
                    _buildTextField(nameController, 'ชื่อวิชา (course_name)', isRequired: true),
                    _buildTextField(shortDescController, 'คำอธิบายสั้น ๆ (short_description)', maxLines: 2),
                    _buildTextField(descController, 'รายละเอียดหลักสูตร (description)', maxLines: 3),
                    _buildTextField(objectiveController, 'วัตถุประสงค์ (objective)', maxLines: 3),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('ยกเลิก'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF03A96B)),
                child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    // 3. สร้าง Object สำหรับส่ง API
                    final updatedCourse = FullCourseDetails(
                      courseId: course.courseId,
                      courseCode: codeController.text,
                      courseName: nameController.text,
                      shortDescription: shortDescController.text,
                      description: descController.text,
                      objective: objectiveController.text,
                      imageUrl: details.imageUrl, // ใช้รูปภาพเดิม
                    );

                    // 4. เรียกฟังก์ชันอัปเดต
                    try {
                      Navigator.of(dialogContext).pop(); // ปิด Dialog ก่อนส่งข้อมูล
                      // แสดง Loading indicator อีกครั้ง (Optional)
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );
                      
                      await _updateCourseDetails(updatedCourse);
                      
                      // ปิด Loading indicator
                      Navigator.of(context).pop(); 
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('อัปเดตหลักสูตรสำเร็จ!')),
                      );
                    } catch (e) {
                      // ปิด Loading indicator หากมี
                      if (Navigator.of(context).canPop()) {
                         Navigator.of(context).pop(); 
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('อัปเดตล้มเหลว: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      );

    } catch (e) {
      // กรณีดึงรายละเอียดหลักสูตรล้มเหลว
      // ปิด Loading Dialog ที่เปิดไว้ตอนแรก
      if (Navigator.of(context).canPop()) {
         Navigator.of(context).pop(); 
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถโหลดรายละเอียดหลักสูตร: ${e.toString()}')),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        validator: isRequired ? (v) => v!.isEmpty ? 'กรุณากรอก$label' : null : null,
      ),
    );
  }

// ----------------------------------------------------------------------
// 🎨 UI Build Methods
// ----------------------------------------------------------------------
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

                  Flexible(
                    flex: isWideScreen ? 1 : 0, 
                    child: _buildProfessorCoursesCard(context), // 🎯 Responsive Grid (แก้ Right Overflow ที่นี่แล้ว)
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

  // Card 1: Personal Information (ข้อมูลส่วนตัว)
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


  // Card 2: Professor Courses (หลักสูตรของฉัน) - 💡 Responsive Grid (แก้ Right Overflow แล้ว)
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
                : LayoutBuilder( // 🎯 FIX: ใช้ LayoutBuilder เพื่อให้ GridView Responsive (ป้องกัน Right Overflow)
                    builder: (context, constraints) {
                      // คำนวณจำนวนคอลัมน์: กำหนดความกว้างต่ำสุดของ Card คือ 220px
                      int crossAxisCount = max(1, (constraints.maxWidth / 220).floor()); 
                      
                      // จำกัดจำนวนคอลัมน์สูงสุด
                      if (crossAxisCount > 3) crossAxisCount = 3; 

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: coursesToShow.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount, // 💡 Dynamic Cross Axis Count
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.8, 
                        ),
                        itemBuilder: (context, index) {
                          return _buildCourseCard(coursesToShow[index], context);
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
  
  // 🔨 Course Card Widget (มีการแก้ไข onTap เพื่อเรียก Dialog)
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
        // 🎯 NEW: เรียก Dialog แก้ไข เมื่อแตะที่ Card
        onTap: () {
          _showEditCourseDialog(course); 
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