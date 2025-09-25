import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'screen_size.dart';
import '../student_outsiders/main_page.dart';
import '../error_dialog_page.dart';
import '../professor/main_professor_page.dart'; // import ไฟล์ main_professor_page.dart

Future<http.Response> createUser(Map<String, dynamic> userData) async {
  final url = Uri.parse('http://localhost:3006/api/users');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    return response;
  } catch (e) {
    throw Exception('Error during API call: $e');
  }
}

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController studentIDController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? selectedRole;
  final List<String> _roles = ['อาจารย์', 'นิสิต', 'บุคคลภายนอก'];

  final _formKey = GlobalKey<FormState>();

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ErrorDialogPage(message: message);
      },
    );
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
            registrationForm: _buildMemberForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: InputDecoration(
              labelText: 'สถานภาพ',
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            hint: const Text('กรุณาเลือกสถานภาพ'),
            items: _roles.map((role) {
              return DropdownMenuItem<String>(
                value: role,
                child: Text(role),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedRole = newValue;
                studentIDController.clear();
                emailController.clear();
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณาเลือกสถานภาพ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: studentIDController,
            enabled: selectedRole == 'นิสิต',
            decoration: InputDecoration(
              labelText: selectedRole == 'นิสิต' ? 'รหัสนิสิต ' : 'ไม่ต้องกรอก',
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor:
                  selectedRole == 'นิสิต' ? Colors.white : Colors.grey[200],
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (selectedRole == 'นิสิต') {
                if (value == null || value.isEmpty) {
                  return 'กรุณากรอกรหัสนิสิต';
                }
                if (value.length != 10 ||
                    !RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                  return 'รหัสนิสิตต้องเป็นตัวเลข 10 ตัว';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: firstNameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อ',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกชื่อ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: lastNameController,
            decoration: const InputDecoration(
              labelText: 'นามสกุล',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกนามสกุล';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'อีเมล',
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: selectedRole == 'อาจารย์'
                  ? 'เมล ku.th เท่านั้น'
                  : selectedRole == 'บุคคลภายนอก'
                      ? 'เมล gmail.com เท่านั้น'
                      : 'เมล ku.th หรือ gmail.com เท่านั้น',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกอีเมล';
              }
              if (selectedRole == 'อาจารย์' && !value.endsWith('@ku.th')) {
                return 'อีเมลสำหรับอาจารย์ต้องลงท้ายด้วย @ku.th';
              }
              if (selectedRole == 'บุคคลภายนอก' &&
                  !value.endsWith('@gmail.com')) {
                return 'อีเมลสำหรับบุคคลภายนอกต้องลงท้ายด้วย @gmail.com';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'รูปแบบอีเมลไม่ถูกต้อง';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: 'รหัสผ่าน',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณากรอกรหัสผ่าน';
              }
              if (value.length < 6) {
                return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'ยืนยันรหัสผ่าน',
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'กรุณายืนยันรหัสผ่าน';
              }
              if (value != passwordController.text) {
                return 'รหัสผ่านไม่ตรงกัน';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final userData = {
                    'first_name': firstNameController.text,
                    'last_name': lastNameController.text,
                    'email': emailController.text,
                    'password': passwordController.text,
                    'role': selectedRole,
                    'student_id': (selectedRole == 'นิสิต' &&
                            studentIDController.text.isNotEmpty)
                        ? studentIDController.text
                        : null,
                  };

                  try {
                    final response = await createUser(userData);

                    if (response.statusCode == 201) {
                      final responseData = jsonDecode(response.body);
                      final newUser = responseData['user'];
                      final firstName = newUser['first_name'] ?? '';
                      final lastName = newUser['last_name'] ?? '';
                      final userName = '$firstName $lastName'.trim();
                      
                      // 🎯 การแก้ไข: แปลง userId จาก int เป็น String
                      final userId = newUser['user_id'].toString();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
                      );

                      if (selectedRole == 'อาจารย์') {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => MainProfessorPage(
                                userName: userName, userId: userId),
                          ),
                        );
                      } else if (selectedRole == 'นิสิต' ||
                          selectedRole == 'บุคคลภายนอก') {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => MainPage(
                                userName: userName, userId: userId),
                          ),
                        );
                      }
                    } else if (response.statusCode == 409) {
                      final errorBody = jsonDecode(response.body);
                      _showErrorDialog(context, errorBody['error']);
                    } else {
                      _showErrorDialog(context, 'เกิดข้อผิดพลาดในการสมัคร: ${response.statusCode}');
                    }
                  } catch (e) {
                    _showErrorDialog(context, 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
                  }
                } else {
                  _showErrorDialog(context, 'กรุณากรอกข้อมูลให้ครบถ้วนและถูกต้อง');
                }
              },
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
                'สมัครสมาชิก',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    studentIDController.dispose();
    super.dispose();
  }
}