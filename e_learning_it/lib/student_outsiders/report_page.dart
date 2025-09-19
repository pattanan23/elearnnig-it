import 'package:e_learning_it/student_outsiders/drawer_page.dart';
import 'package:e_learning_it/student_outsiders/navbar_normal.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportPage extends StatefulWidget {
  final String userName;
  final String userId;

  const ReportPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? _selectedIssueType;
  final _issueController = TextEditingController();
  final List<String> _issueTypes = ['ปัญหาการเข้าสู่ระบบ', 'ปัญหาการระบบ', 'ปัญหาเกี่ยวกับเนื้อหา', 'อื่นๆ'];

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    final category = _selectedIssueType;
    final reportMess = _issueController.text;

    if (category == null || reportMess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกประเภทและกรอกรายละเอียดปัญหา')),
      );
      return;
    }

    final Map<String, dynamic> data = {
      'userId': int.tryParse(widget.userId) ?? 0,
      'category': category,
      'reportMess': reportMess,
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3006/api/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('ส่งคำถามสำเร็จ'),
              content: const Text('เราได้รับคำถามของคุณแล้ว และจะรีบดำเนินการโดยเร็วที่สุด'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearForm();
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      } else {
        final errorBody = jsonDecode(response.body);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('เกิดข้อผิดพลาด'),
              content: Text('ไม่สามารถส่งคำถามได้: ${errorBody['error']}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('เกิดข้อผิดพลาดในการเชื่อมต่อ'),
            content: Text('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('ตกลง'),
              ),
            ],
          );
        },
      );
    }
  }

  void _clearForm() {
    setState(() {
      _selectedIssueType = null;
      _issueController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavbarPage(userName: widget.userName, userId: widget.userId),
      drawer: DrawerPage(userName: widget.userName, userId: widget.userId),
      backgroundColor: Colors.grey[100], // กำหนดสีพื้นหลังให้เป็นสีเทาอ่อน
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30, // กำหนดขนาดของ container
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey[600], // กำหนดสีพื้นหลังไอคอน
                      shape: BoxShape.circle, // ทำให้เป็นวงกลม
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white, // กำหนดสีไอคอนเป็นสีขาว
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ถามคำถาม',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'ประเภท',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedIssueType,
                hint: const Text('กรุณาเลือกประเภทของคำถาม'),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white, // กำหนดสีพื้นหลังช่องเป็นสีขาว
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _issueTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedIssueType = newValue;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'ปัญหาที่พบ',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _issueController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'กรุณาอธิบายปัญหาแบบสั้นๆ',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white, // กำหนดสีพื้นหลังช่องเป็นสีขาว
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _clearForm,
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _sendReport,
                    child: const Text('ส่งข้อความ'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}