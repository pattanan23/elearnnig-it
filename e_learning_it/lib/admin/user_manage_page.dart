// lib/AdminUserManagementPage.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:e_learning_it/admin/error_dialog_page.dart'; // ตรวจสอบ path ว่าถูกต้อง
import 'navbar_admin.dart'; 
import 'drawer_admin.dart'; 

// **NOTE:** แทนที่ด้วย Base URL ที่ถูกต้องของคุณ
const String API_BASE_URL = 'http://localhost:3006/api'; 

class UserManagementPage extends StatefulWidget {
  final String userName;
  final String userId;

  const UserManagementPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  // 🚨 ตัวเลือกบทบาททั้งหมดที่มีในระบบ
  final List<String> _roleOptions = [
    'นิสิต', 
    'บุคคลภายนอก', 
    'อาจารย์', 
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // -----------------------------------------------------
  // 1. API: FETCH ALL USERS
  // -----------------------------------------------------
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$API_BASE_URL/users-admin'); // API ที่สร้างใหม่
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> fetchedUsers = json.decode(response.body);
        setState(() {
          _users = fetchedUsers;
        });
      } else {
        // จัดการ Error response
        String errorMessage = 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้: Status Code ${response.statusCode}';
        try {
            if (response.body.isNotEmpty) {
                final responseBody = json.decode(response.body);
                errorMessage = responseBody['message'] ?? errorMessage;
            }
        } catch (_) {
            errorMessage += '. Response body was not readable JSON.';
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog(
        'การเชื่อมต่อล้มเหลว: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // -----------------------------------------------------
  // 2. UI: BUILD METHOD (แสดงตาราง)
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ใช้ Navbar/Drawer เดียวกันกับ AdminMainPage
      appBar: NavbarAdminPage(
        userName: widget.userName,
        userId: widget.userId,
      ),
      drawer: DrawerAdminPage(
        userName: widget.userName,
        userId: widget.userId,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Text('ไม่พบข้อมูลผู้ใช้',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildDataTable(),
                  ),
                ),
    );
  }

  // สร้าง DataTable สำหรับแสดงข้อมูลผู้ใช้
  Widget _buildDataTable() {
    return DataTable(
      columnSpacing: 20.0,
      columns: const [
        DataColumn(label: Text('ชื่อ-นามสกุล', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('รหัสนิสิต', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('อีเมล', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('บทบาท', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('ดำเนินการ', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: _users.map<DataRow>((user) {
        final fullName = '${user['first_name']} ${user['last_name']}';
        return DataRow(
          cells: [
            DataCell(Text(fullName)),
            DataCell(Text(user['student_id'] ?? '-')),
            DataCell(Text(user['email'])),
            DataCell(Text(user['role'])),
            DataCell(
              ElevatedButton(
                onPressed: () => _showEditDialog(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, // ปุ่มสีส้มสำหรับแก้ไข
                  foregroundColor: Colors.white,
                ),
                child: const Text('แก้ไข'),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // -----------------------------------------------------
  // 3. FUNCTION: SHOW EDIT DIALOG
  // -----------------------------------------------------
void _showEditDialog(Map<String, dynamic> user) {
  // Key สำหรับ Form Validation ภายใน Dialog
  final GlobalKey<FormState> _dialogFormKey = GlobalKey<FormState>();

  final TextEditingController firstNameCtrl = TextEditingController(text: user['first_name']);
  final TextEditingController lastNameCtrl = TextEditingController(text: user['last_name']);
  final TextEditingController emailCtrl = TextEditingController(text: user['email']);
  final TextEditingController studentIdCtrl = TextEditingController(text: user['student_id'] ?? ''); 
  
  String selectedRole = user['role']; 

  final List<String> roleOptions = [
    'นิสิต', 
    'บุคคลภายนอก', 
    'อาจารย์', 
    'user', 
    'admin'
  ];
  
  // กำหนดค่าเริ่มต้นถ้าค่าที่โหลดมาไม่ตรงกับตัวเลือก
  if (!roleOptions.contains(selectedRole)) {
    selectedRole = roleOptions.first; 
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('แก้ไขข้อมูลผู้ใช้'),
        content: SingleChildScrollView(
          child: Form( // 🚨 เพิ่ม Form
            key: _dialogFormKey, // 🚨 กำหนด Key
            child: ListBody(
              children: <Widget>[
                // ... Fields for first_name, last_name, email ...
                TextFormField(
                  controller: firstNameCtrl, 
                  decoration: const InputDecoration(labelText: 'ชื่อ'),
                  validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอกชื่อ' : null,
                ),
                TextFormField(
                  controller: lastNameCtrl, 
                  decoration: const InputDecoration(labelText: 'นามสกุล'),
                  validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอกนามสกุล' : null,
                ),
                TextFormField(
                  controller: emailCtrl, 
                  decoration: const InputDecoration(labelText: 'อีเมล'),
                  validator: (value) => (value == null || value.isEmpty) ? 'กรุณากรอกอีเมล' : null,
                ),
                
                const SizedBox(height: 10),
                
                // Dropdown สำหรับ Role
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(labelText: 'บทบาท'),
                          items: roleOptions.map((String value) { 
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedRole = newValue;
                                // 💡 เมื่อเปลี่ยนบทบาท ให้บังคับล้างค่ารหัสนิสิต
                                // ถ้าบทบาทใหม่ไม่ใช่ 'นิสิต' เพื่อให้ Server รับ NULL
                                if (newValue != 'นิสิต') {
                                  studentIdCtrl.clear();
                                }
                              });
                            }
                          },
                        ),
                        
                        const SizedBox(height: 10),

                        // 🚨 TextFormField สำหรับ รหัสนิสิต
                        TextFormField(
                          controller: studentIdCtrl, 
                          decoration: InputDecoration(
                            labelText: 'รหัสนิสิต',
                            // 💡 เปลี่ยนสีพื้นหลังถ้าบทบาทไม่ใช่ 'นิสิต'
                            fillColor: selectedRole == 'นิสิต' ? Colors.transparent : Colors.grey.shade100,
                            filled: selectedRole != 'นิสิต',
                          ),
                          // 🚨 Validation Logic: บังคับกรอกถ้ารับบทบาท 'นิสิต'
                          validator: (value) {
                            if (selectedRole == 'นิสิต' && (value == null || value.isEmpty)) {
                              return 'ต้องกรอกรหัสนิสิตสำหรับบทบาท "นิสิต"';
                            }
                            return null;
                          },
                          // 🚨 ป้องกันการแก้ไขถ้ารับบทบาทอื่น
                          enabled: selectedRole == 'นิสิต', 
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('ยกเลิก'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
            onPressed: () {
              // 🚨 ตรวจสอบ Validation ก่อนบันทึก
              if (_dialogFormKey.currentState!.validate()) {
                Navigator.of(context).pop();
                _updateUser(
                  user['user_id'].toString(), 
                  firstNameCtrl.text,
                  lastNameCtrl.text,
                  emailCtrl.text,
                  studentIdCtrl.text, // จะเป็นค่าว่าง ('') ถ้าถูกล้างค่า
                  selectedRole,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      );
    },
  );
}

  // -----------------------------------------------------
  // 4. API: UPDATE USER
  // -----------------------------------------------------
  Future<void> _updateUser(
    String userId,
    String firstName,
    String lastName,
    String email,
    String studentId,
    String role,
  ) async {
    try {
      final url = Uri.parse('$API_BASE_URL/users-admin/$userId'); // API ที่สร้างใหม่
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'student_id': studentId,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        // สำเร็จ: ดึงข้อมูลใหม่มาแสดง
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตข้อมูลผู้ใช้สำเร็จ')),
        );
        _fetchUsers(); // รีเฟรชข้อมูลในตาราง
      } else {
        // จัดการ Error response
        String errorMessage = 'การอัปเดตล้มเหลว: Status Code ${response.statusCode}';
        
        try {
          // 🚨 การแก้ไข: ตรวจสอบและถอดรหัส JSON อย่างปลอดภัย
          if (response.body.isNotEmpty) {
            final responseBody = json.decode(response.body);
            // ใช้ message จากเซิร์ฟเวอร์ (ถ้ามี)
            errorMessage = 'การอัปเดตล้มเหลว: ${responseBody['message'] ?? errorMessage}';
          }
        } catch (e) {
          // ถ้า Body ไม่ใช่ JSON (เช่น 'Internal Server Error' ธรรมดา)
          errorMessage = 'การอัปเดตล้มเหลว: Status Code ${response.statusCode}. ' + 
                         'โปรดตรวจสอบ Console Server: ${response.body.isNotEmpty ? response.body : 'ไม่มีข้อความตอบกลับ'}';
        }

        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog(
        'การเชื่อมต่อล้มเหลว: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e',
      );
    }
  }

  // Helper function เพื่อแสดง Error Dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialogPage(
        message: message,
      ),
    );
  }
}