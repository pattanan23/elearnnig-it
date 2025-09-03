import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'student_outsiders/main_page.dart'; // Import หน้าหลัก (MainPage) เพื่อใช้ในการนำทาง
import 'login/screen_size.dart'; // Import ResponsiveLayout
import 'error_dialog_page.dart'; // Import หน้า Dialog Box ที่สร้างขึ้นใหม่
import 'login/membership.dart'; // Import หน้า MembershipPage
import 'professor/main_professor_page.dart'; // Import หน้าสำหรับอาจารย์

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final userData = {
        'identifier': identifierController.text, // Email หรือรหัสนิสิต
        'password': passwordController.text,
      };

      try {
        final url = Uri.parse('http://localhost:3006/api/login'); // Endpoint ของ API สำหรับการล็อกอิน
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(userData),
        );

        if (response.statusCode == 200) {
          // ล็อกอินสำเร็จ
          print('Login successful: ${response.body}');
          final responseData = jsonDecode(response.body);
          final userRole = responseData['user']['role']; // ดึง role จากข้อมูลผู้ใช้ที่ได้รับจาก API
          final userName = responseData['user']['first_name'] + ' ' + responseData['user']['last_name']; // ดึงชื่อผู้ใช้
          final userId = responseData['user']['user_id']; // ดึง user_id
          

          // ตรวจสอบ role และนำทางไปยังหน้าตามที่กำหนด
          if (userRole == 'อาจารย์') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) =>  MainProfessorPage(userName: userName, userId: userId),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MainPage(userName: userName, userId: userId),
              ),
            );
          }

        } else {
          final errorData = jsonDecode(response.body);
          // แสดง Dialog Box ข้อผิดพลาดตามที่คุณต้องการ โดยใช้ ErrorDialogPage ที่สร้างขึ้นใหม่
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return ErrorDialogPage(
                message: errorData['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ กรุณาตรวจสอบข้อมูล',
              );
            },
          );
        }
      } catch (e) {
        print('Error during API call: $e');
        // แสดง Dialog Box ข้อผิดพลาดเมื่อเกิด Exception
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return const ErrorDialogPage(
              message: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้งในภายหลัง',
            );
          },
        );
      }
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double mobileBreakpoint = 600;
    final bool isMobile = screenWidth < mobileBreakpoint;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24.0 : (screenWidth * 0.1),
            vertical: 24.0,
          ),
          child: ResponsiveLayout(
            registrationForm: _buildLoginForm(),
          ),
        ),
      ),
    );
  }

  // Widget สำหรับฟอร์มล็อกอิน
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          TextFormField(
            controller: identifierController,
            decoration: const InputDecoration(
              labelText: 'Email / รหัสนิสิต',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอก Email หรือรหัสนิสิต';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // ช่องกรอกรหัสผ่าน
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'รหัสผ่าน',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกรหัสผ่าน';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(5),
                ),
                elevation: 2,
              ),
              child: const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // เพิ่มข้อความและลิงก์สำหรับสมัครสมาชิก
          TextButton(
            onPressed: () {
              // นำทางไปที่หน้า MembershipPage
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MemberScreen(),
                ),
              );
            },
            child: const Text(
              'สมัครสมาชิก', // ข้อความที่คุณขอ
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                decoration: TextDecoration.underline, // เพิ่มขีดเส้นใต้เพื่อให้ดูเหมือนลิงก์
              ),
            ),
          ),
        ],
      ),
    );
  }
}
