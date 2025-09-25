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
  final List<String> _issueTypes = ['ปัญหาการเข้าสู่ระบบ', 'ปัญหาเกี่ยวกับระบบ', 'ปัญหาเกี่ยวกับเนื้อหา', 'อื่นๆ'];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    if (_formKey.currentState!.validate()) {
      final category = _selectedIssueType;
      final reportMess = _issueController.text;

      if (category == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเลือกประเภทปัญหา')),
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
  }

  void _clearForm() {
    setState(() {
      _selectedIssueType = null;
      _issueController.clear();
    });
  }
  
  // Helper widgets based on UploadCoursePage's style
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(title),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.green, width: 2.0)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ประเภท', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedIssueType,
          hint: const Text('กรุณาเลือกประเภทของคำถาม'),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Colors.green, width: 2.0)),
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
          validator: (value) => value == null ? 'กรุณาเลือกประเภท' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth > 600 ? 100.0 : 20.0;
    final double verticalPadding = 24.0;

    return Scaffold(
      appBar: NavbarPage(userName: widget.userName, userId: widget.userId),
      drawer: DrawerPage(userName: widget.userName, userId: widget.userId),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: verticalPadding),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.chat, size: 48, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'แจ้งปัญหาหรือถามคำถาม',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'กรอกรายละเอียดปัญหา',
                  children: [
                    _buildDropdownField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _issueController,
                      label: 'ปัญหาที่พบ',
                      maxLines: 5,
                      validator: (value) => value!.isEmpty ? 'กรุณาอธิบายปัญหา' : null,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('ส่งข้อความ'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}