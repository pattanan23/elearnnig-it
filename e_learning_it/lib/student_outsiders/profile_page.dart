import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:e_learning_it/student_outsiders/course/certificate_page.dart';
// import 'user_model.dart'; // Uncomment this line if user_model.dart is needed for other profile data

// ----------------------------------------------------------------------
// 🎯 CLASS: User (นำ User model มาไว้ที่นี่ชั่วคราว หรือ import เข้ามา)
// ----------------------------------------------------------------------
class User {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? studentId;

  User({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.studentId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final studentIdValue = json['student_id'];
    return User(
      userId: json['user_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      studentId: (studentIdValue == null || studentIdValue == 'null' || studentIdValue == '') 
          ? '-' 
          : studentIdValue.toString(),
    );
  }

  String get fullName {
    return '$firstName $lastName';
  }

  String get title {
    return role == 'อาจารย์' ? 'อาจารย์' : role;
  }
}

class UserCertificate {
  final String courseId;
  final String courseCode;
  final String courseName;
  final String subjectName;
  final String issueDate;

  UserCertificate({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.subjectName,
    required this.issueDate,
  });

  factory UserCertificate.fromJson(Map<String, dynamic> json) {
    final String safeCourseId = json['course_id']?.toString() ?? '0';
    
    return UserCertificate(
      courseId: safeCourseId,
      courseCode: json['course_code']?.toString() ?? 'N/A',
      courseName: json['course_name']?.toString() ?? 'ไม่ระบุชื่อหลักสูตร',
      subjectName: json['subject_name']?.toString() ?? 'ไม่ระบุชื่อวิชา',
      issueDate: json['issue_date']?.toString() ?? 'N/A',
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String userName;
  final String userId;

  const ProfilePage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  String _errorMessage = '';
  
  List<UserCertificate> _userCertificates = [];
  User? _userProfile; // 🎯 เพิ่ม State สำหรับเก็บข้อมูลโปรไฟล์
  
  // ---------------------------------------------------
  // 🎯 ฟังก์ชันดึงข้อมูลโปรไฟล์ผู้ใช้ (ใหม่)
  // ---------------------------------------------------
  Future<void> _fetchUserProfile() async {
    const String baseApiUrl = 'http://localhost:3006';
    final url = Uri.parse('$baseApiUrl/api/users/${widget.userId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> userJson = json.decode(response.body);
        setState(() {
          _userProfile = User.fromJson(userJson);
        });
      } else {
        _errorMessage = 'Failed to load profile (Status: ${response.statusCode}).';
      }
    } catch (e) {
      _errorMessage = 'An error occurred (Profile Connection Error): $e';
      debugPrint('Profile Fetch Error: $e');
    }
  }

  // ---------------------------------------------------
  // 🎯 ฟังก์ชันดึงรายการวุฒิบัตรของผู้ใช้
  // ---------------------------------------------------
  Future<void> _fetchUserCertificates() async {
    const String baseApiUrl = 'http://localhost:3006';
    final url = Uri.parse('$baseApiUrl/api/certificates/${widget.userId}');
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> certListJson = json.decode(response.body);
        setState(() {
          _userCertificates = certListJson.map((jsonItem) => UserCertificate.fromJson(jsonItem)).toList();
        });
      } else {
          if (_errorMessage.isNotEmpty) _errorMessage += '\n';
          _errorMessage += 'Failed to load certificates (Status: ${response.statusCode}).';
      }
    } catch (e) {
      if (_errorMessage.isNotEmpty) _errorMessage += '\n';
      _errorMessage += 'An error occurred (Cert Connection Error): $e';
      debugPrint('Certificate Fetch Error: $e');
    }
  }

  // ---------------------------------------------------
  // 🎯 ฟังก์ชันรวมสำหรับโหลดข้อมูลทั้งหมด
  // ---------------------------------------------------
  Future<void> _loadAllData() async {
      setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    await _fetchUserProfile();
    await _fetchUserCertificates();
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadAllData(); // 🎯 เรียกฟังก์ชันโหลดข้อมูลทั้งหมด
  }

  // ---------------------------------------------------
  // 🎯 [MODIFIED WIDGET] Card สำหรับแสดงวุฒิบัตร
  // ---------------------------------------------------
  Widget _buildCertificateCard(UserCertificate certificate, BuildContext context) {
    const Color actionIconColor = Color(0xFF03A96B);
    const Color courseCodeColor = Color(0xFF1976D2);
    const Color darkGraphicColor = Color(0xFF293241);
    
    // 💡 ครอบด้วย SizedBox เพื่อกำหนด Fixed Height
    const double fixedCardHeight = 250.0; // 🎯 กำหนดความสูงที่ต้องการ

    return InkWell(
      onTap: () => _navigateToCertificatePage(context, certificate),
      borderRadius: BorderRadius.circular(8),
      child: SizedBox( // 🎯 1. ใช้ SizedBox เพื่อกำหนด Fixed Height
        height: fixedCardHeight,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 60,
                decoration: const BoxDecoration(
                  color: darkGraphicColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.code, size: 30, color: Colors.blue.shade200),
                    ), 
                  ],
                ),
              ),
              Expanded( // 💡 2. ใช้ Expanded ครอบเนื้อหาส่วนกลางแทน Spacer
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รหัสวิชา : ${certificate.courseCode}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: courseCodeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'วิชา : ${certificate.subjectName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'หลักสูตร: ${certificate.courseName}',
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // 💡 3. นำ const Spacer() ออก
              Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'วันที่ออก:',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                        Text(
                          certificate.issueDate,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: actionIconColor,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // 🎯 ฟังก์ชันนำทางไปหน้า CertificatePage (โค้ดเดิม)
  // ---------------------------------------------------
  void _navigateToCertificatePage(BuildContext context, UserCertificate certificate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificatePage(
          courseId: certificate.courseId,
          userId: widget.userId,
          courseName: certificate.courseName,
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // 💡 [REDESIGNED BUILD]
  // ---------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF03A96B);
    
    if (_isLoading) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }
    
    if (_userProfile == null && _errorMessage.isNotEmpty) {
        return Scaffold(
        appBar: AppBar(title: const Text('My Profile'), backgroundColor: primaryColor, foregroundColor: Colors.white),
        body: Center(child: Text('ไม่สามารถโหลดข้อมูลผู้ใช้ได้: $_errorMessage', style: const TextStyle(color: Colors.red))),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLargeScreen = constraints.maxWidth > 800;
          
          final Widget content = isLargeScreen
            ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, top: 20, right: 10),
                    child: _buildPersonalInfoSection(primaryColor),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, top: 20, right: 20, bottom: 20), // เพิ่ม bottom padding
                    child: _buildCertificatesSection(primaryColor, 2, 20),
                  ),
                ),
              ],
            )
            : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  child: _buildPersonalInfoSection(primaryColor),
                ),
                const SizedBox(height: 20),
                Expanded( // ใช้ Expanded เพื่อให้ GridView ยืดเต็มพื้นที่ที่เหลือใน Column
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SingleChildScrollView( // 🎯 เพิ่ม SingleChildScrollView เพื่อแก้ปัญหา Overflow
                      child: _buildCertificatesSection(primaryColor, 2, 16),
                    ),
                  ),
                ),
              ],
            );

          return SingleChildScrollView(child: content); // 🎯 ปรับให้ SingleChildScrollView อยู่ภายนอกสุดสำหรับจอเล็ก
        },
      ),
    );
  }
  
  // ---------------------------------------------------
  // 🎯 [MODIFIED WIDGET] ส่วนแสดงข้อมูลส่วนตัว (กำหนด Max Width)
  // ---------------------------------------------------
  Widget _buildPersonalInfoSection(Color primaryColor) {
    final User displayUser = _userProfile ?? User(
      userId: int.tryParse(widget.userId) ?? 0, 
      firstName: widget.userName, 
      lastName: '', 
      email: 'N/A', 
      role: 'Outsider', 
      studentId: '-',
    );
    
    final String displayFullName = displayUser.fullName.trim().isEmpty ? widget.userName : displayUser.fullName;

    // 💡 ใช้ ConstrainedBox เพื่อกำหนดความกว้างสูงสุด (Max Width)
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400.0, // 🎯 กำหนดความกว้างสูงสุดของ Card (Fixed Width Limit)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 🎯 Icon และ Title ตรงกับรูป
              Icon(Icons.person_pin, size: 28, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'ข้อมูลส่วนตัว',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // 💡 ความสูงจะยืดตามเนื้อหา (Intrinsically-sized height)
                children: [
                  // ชื่อผู้ใช้และ Avatar
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white, size: 35),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        '${displayUser.title} ${displayFullName}', // 🎯 แสดง Title ตามรูป
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                  const Divider(),
                  
                  // รายละเอียด
                  const SizedBox(height: 10),
                  Text('รหัสผู้ใช้ : ${displayUser.userId}', style: const TextStyle(fontSize: 14)), // 🎯 เปลี่ยนเป็น รหัสผู้ใช้
                  const SizedBox(height: 10),
                  Text('อีเมล : ${displayUser.email}', style: const TextStyle(fontSize: 14)),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------
  // 🎯 [MODIFIED WIDGET] ส่วนแสดงรายการวุฒิบัตร (ปรับ childAspectRatio)
  // ---------------------------------------------------
  Widget _buildCertificatesSection(Color primaryColor, int crossAxisCount, double spacing) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 🎯 เพิ่มเพื่อวาง Edit Icon
          children: [
            Row(
              children: [
                Icon(Icons.laptop_chromebook, size: 28, color: primaryColor), // 🎯 Icon ใกล้เคียงกับรูป
                const SizedBox(width: 8),
                Text(
                  'ใบประกาศของฉัน (${_userCertificates.length})', // 🎯 ยังคงเป็น ใบประกาศ ตามโค้ดเดิม
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            // 🎯 ปุ่มแก้ไข
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.black54),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('แก้ไขวุฒิบัตร (Placeholder)')),
                );
              },
            ),
          ],
        ),
        const Divider(color: Colors.grey),
        
        if (_errorMessage.isNotEmpty && _userProfile != null) 
          Center(child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text('Error Loading Certificates', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            )
          ))
        else if (_userCertificates.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Text('ยังไม่มีวุฒิบัตรที่ได้รับในขณะนี้'),
          ))
        else
          // 🎯 GridView.builder
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            
            itemCount: _userCertificates.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: 1.8, // 🎯 ปรับให้ Card เป็นแนวตั้งเหมือน Card ในรูปภาพอาจารย์
            ),
            itemBuilder: (context, index) {
              final certificate = _userCertificates[index];
              return _buildCertificateCard(certificate, context);
            },
          ),
      ],
    );
  }
}