// lib/login/reset_password_verify.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../error_dialog_page.dart'; // ตรวจสอบ path ของไฟล์นี้ให้ถูกต้อง

const String API_BASE_URL = 'http://localhost:3006/api';

class ResetPasswordVerifyScreen extends StatefulWidget {
  final String identifier; // Email หรือ รหัสนิสิต ที่ส่งมาจากหน้าก่อนหน้า

  const ResetPasswordVerifyScreen({super.key, required this.identifier});

  @override
  State<ResetPasswordVerifyScreen> createState() => _ResetPasswordVerifyScreenState();
}

class _ResetPasswordVerifyScreenState extends State<ResetPasswordVerifyScreen> {
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      _showErrorDialog('รหัสผ่านใหม่ไม่ตรงกัน');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('$API_BASE_URL/password/reset');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': widget.identifier,
          'otp_code': otpController.text,
          'new_password': newPasswordController.text,
        }),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          // สำเร็จ: แจ้งเตือนและกลับไปยังหน้า Login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('รีเซ็ตรหัสผ่านสำเร็จ! กรุณาเข้าสู่ระบบด้วยรหัสผ่านใหม่')),
          );
          // ปิดหน้าปัจจุบันและกลับไปยังหน้าก่อนหน้า (ควรเป็นหน้า Login)
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // จัดการ Error
          String errorMessage = 'การรีเซ็ตรหัสผ่านล้มเหลว';
          if (response.body.isNotEmpty) {
            final responseBody = json.decode(response.body);
            errorMessage = responseBody['message'] ?? errorMessage;
          }
          _showErrorDialog(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('การเชื่อมต่อล้มเหลว: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialogPage(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งรหัสผ่านใหม่'),
        backgroundColor: const Color(0xFF03A96B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ตั้งรหัสผ่านใหม่สำหรับ: ${widget.identifier}',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // ช่องกรอก OTP
                  TextFormField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: const InputDecoration(
                      labelText: 'รหัส OTP (5 หลัก)',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                      border: OutlineInputBorder(),
                      counterText: '', // ซ่อนตัวนับจำนวนตัวอักษร
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length != 5) {
                        return 'กรุณากรอกรหัส OTP 5 หลัก';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // ช่องกรอกรหัสผ่านใหม่
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่านใหม่',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // ช่องยืนยันรหัสผ่านใหม่
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !_isPasswordVisible,
                    decoration: const InputDecoration(
                      labelText: 'ยืนยันรหัสผ่านใหม่',
                      prefixIcon: Icon(Icons.lock_reset),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'รหัสผ่านไม่ตรงกัน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'รีเซ็ตรหัสผ่าน',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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