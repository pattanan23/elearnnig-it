import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'screen_size.dart';
import '../student_outsiders/main_page.dart';
import '../error_dialog_page.dart';
import '../professor/main_professor_page.dart'; // import ไฟล์ main_professor_page.dart

// 1. เปลี่ยนชื่อฟังก์ชันจาก createUser เป็น requestRegistrationOTP และเปลี่ยน Logic 
//    (ใน Backend เดิมคือสร้างผู้ใช้ แต่ตอนนี้คือขอ OTP และบันทึกข้อมูลชั่วคราว)
Future<http.Response> requestRegistrationOTP(Map<String, dynamic> userData) async {
  // ใช้ endpoint เดิม /api/users ซึ่งตอนนี้ถูกเปลี่ยน Logic ใน backend ให้ส่ง OTP
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

// 2. ฟังก์ชันใหม่สำหรับยืนยัน OTP กับ Backend
Future<http.Response> verifyRegistrationOTP(String email, String otpCode) async {
  // ใช้ endpoint ใหม่สำหรับการยืนยัน OTP
  final url = Uri.parse('http://localhost:3006/api/register/verify_otp');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp_code': otpCode}),
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
  final TextEditingController otpController = TextEditingController(); // <<<< Controller สำหรับ OTP

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

  // 3. ฟังก์ชันแสดงป๊อปอัปสำหรับกรอกรหัส OTP (ปรับปรุงให้สวยงามขึ้น)
  void _showOTPVerificationDialog(String email) {
    otpController.clear();
    showDialog(
      context: context,
      barrierDismissible: false, // ป้องกันการปิด Pop-up โดยการแตะภายนอก
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // ขอบโค้ง
          title: Row(
            children: <Widget>[
              const Icon(Icons.vpn_key_rounded, color: Color(0xFF03A96B), size: 28), // เพิ่มไอคอน
              const SizedBox(width: 10),
              const Text('ยืนยันรหัส OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'กรุณากรอกรหัส 5 หลักที่ถูกส่งไปที่อีเมลของคุณ',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 25),
                TextFormField(
                  controller: otpController,
                  decoration: InputDecoration(
                    labelText: 'OTP',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF03A96B)), // เน้นขอบสีเขียว
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF03A96B)
                      , width: 2), // เน้นเมื่อโฟกัส
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8, // เว้นระยะห่างระหว่างตัวเลข
                      color: Color(0xFF03A96B), // สีตัวเลข
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5), // สมมติว่าเป็น OTP 5 หลัก
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              // ปรับสีปุ่มให้สอดคล้องกับธีม
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03A96B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('ยืนยัน', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                if (otpController.text.length != 5) {
                  _showErrorDialog(context, 'กรุณากรอกรหัส OTP ให้ครบ 5 หลัก');
                  return;
                }

                // ปิดป๊อปอัป OTP ก่อน
                Navigator.of(context).pop();

                try {
                  final response = await verifyRegistrationOTP(email, otpController.text);

                  if (response.statusCode == 201) {
                    final responseBody = jsonDecode(response.body);
                    final user = responseBody['user'];
                    final userName = '${user['first_name']} ${user['last_name']}';
                    final userId = user['user_id'].toString();
                    final role = user['role'];
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
                    );

                    // นำทางไปยังหน้าหลักตามบทบาท
                    if (role == 'อาจารย์') {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => MainProfessorPage(
                              userName: userName, userId: userId),
                        ),
                      );
                    } else { // นิสิต หรือ บุคคลภายนอก
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => MainPage(
                              userName: userName, userId: userId),
                        ),
                      );
                    }
                  } else {
                    final errorBody = jsonDecode(response.body);
                    final errorMessage = errorBody['message'] ?? 'รหัส OTP ไม่ถูกต้องหรือหมดอายุแล้ว';

                    // ใช้ showDialog().then() เพื่อรอให้ Error Dialog ปิดก่อน
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ErrorDialogPage(message: errorMessage);
                      },
                    ).then((_) {
                      // เปิด Pop-up OTP อีกครั้งหลังจากผู้ใช้กด 'ตกลง' ใน Error Dialog
                      _showOTPVerificationDialog(email);
                    });
                  }
                } catch (e) {
                  // ใช้ showDialog().then() เพื่อรอให้ Error Dialog ปิดก่อน
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ErrorDialogPage(message: 'เกิดข้อผิดพลาดในการเชื่อมต่อเพื่อยืนยัน OTP: $e');
                    },
                  ).then((_) {
                    // เปิด Pop-up OTP อีกครั้งหลังจากผู้ใช้กด 'ตกลง' ใน Error Dialog
                    _showOTPVerificationDialog(email);
                  });
                }
              },
            ),
          ],
        );
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
                    // 4. เรียกใช้ requestRegistrationOTP
                    final response = await requestRegistrationOTP(userData);

                    if (response.statusCode == 200) {
                      // สถานะ 200 หมายถึง Backend ส่ง OTP สำเร็จ
                      final responseBody = jsonDecode(response.body);
                      final emailForVerification = responseBody['email'];
                      
                      // **🎯 การแก้ไข**: ลบ _showErrorDialog ที่รบกวน Pop-up OTP ออก
                      // _showErrorDialog(context, responseBody['message']); // ลบออก
                      
                      _showOTPVerificationDialog(emailForVerification); // แสดงป๊อปอัป OTP ทันที
                      
                    } else if (response.statusCode == 409) {
                      final errorBody = jsonDecode(response.body);
                      _showErrorDialog(context, errorBody['error']);
                    } else {
                      final errorBody = jsonDecode(response.body);
                      _showErrorDialog(context, errorBody['error'] ?? 'เกิดข้อผิดพลาดในการสมัคร: ${response.statusCode}');
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
                  side: const BorderSide(color: Colors.green, width: 2),
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
    otpController.dispose(); // <<<< Dispose controller
    super.dispose();
  }
}