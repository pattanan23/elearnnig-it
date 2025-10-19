import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'error_dialog_page.dart'; 
import 'main_admin_page.dart'; 

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _adminIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _adminIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ฟังก์ชันจัดการการเข้าสู่ระบบ
  Future<void> _handleAdminLogin() async {
    if (_formKey.currentState!.validate()) {
      
      final userData = {
        'identifier': _adminIdController.text, // Email หรือชื่อผู้ใช้
        'password': _passwordController.text,
      };

      try {
        // ใช้ endpoint เดียวกันกับ LoginScreen แต่จะมีการตรวจสอบ role ภายใน
        final url = Uri.parse('http://localhost:3006/api/login-admin'); 
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(userData),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final userRole = responseData['user']['role'];
          final userName = responseData['user']['first_name'] + ' ' + responseData['user']['last_name'];
          
          // **💡 แก้ไขจุดนี้: แปลง user_id ให้เป็น String**
          final userId = responseData['user']['user_id'].toString(); 
          
          // **ตรวจสอบ ROLE ต้องเป็น 'ผู้ดูแล' เท่านั้น**
          if (userRole == 'แอดมิน') {
            // ล็อกอินสำเร็จและบทบาทถูกต้อง
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => AdminMainPage(userName: userName, userId: userId),
              ),
            );
          } else {
            // ล็อกอินสำเร็จ แต่บทบาทไม่ถูกต้อง
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const ErrorDialogPage(
                  message: 'บัญชีนี้ไม่มีสิทธิ์เข้าถึงระบบผู้ดูแล',
                );
              },
            );
          }

        } else {
          // ล็อกอินไม่สำเร็จ (เช่น รหัสผ่านผิด)
          final errorData = jsonDecode(response.body);
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
        // เกิดข้อผิดพลาดในการเชื่อมต่อ
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return const ErrorDialogPage(
              message: 'เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์',
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold สำหรับหน้า Login จะไม่มี Drawer และมักจะไม่มี Navbar ที่ซับซ้อน
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450), // จำกัดขนาดกล่อง Login
            padding: const EdgeInsets.all(30.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'เข้าสู่ระบบ Admin',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green, // ใช้สีเขียวตามโทนของแอป
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _adminIdController,
                    decoration: InputDecoration(
                      labelText: 'Admin ID / ชื่อผู้ใช้',
                      prefixIcon: const Icon(Icons.person, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอก Admin ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.green, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleAdminLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // ใช้สีเขียวเป็นปุ่มหลัก
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'เข้าสู่ระบบ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}