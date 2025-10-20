// lib/AdminUserManagementPage.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:e_learning_it/admin/error_dialog_page.dart';
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
  // -----------------------------------------------------
  // STATE MANAGEMENT
  // -----------------------------------------------------
  List<dynamic> _allUsers = []; 
  List<dynamic> _filteredUsers = []; 
  bool _isLoading = true;
  String _selectedRole = 'นิสิต'; 

  // Role Options ที่ใช้ใน UI Tabs
  final Map<String, String> _roleOptions = {
    'นิสิต': 'นิสิต', 
    'อาจารย์': 'อาจารย์', 
    'บุคคลภายนอก': 'บุคคลภายนอก', 
  };
  
  // Role Options ที่ใช้ใน Edit Dialog (อาจมีบทบาทเพิ่มเติม เช่น admin/user)
  final List<String> _dialogRoleOptions = [
    'นิสิต', 
    'บุคคลภายนอก', 
    'อาจารย์', 
    'user', 
    'admin'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }
  
  // -----------------------------------------------------
  // DATA AND FILTERING LOGIC
  // -----------------------------------------------------
  
  // กรองข้อมูลผู้ใช้ตาม Role ที่เลือก
  void _filterUsersByRole(String role) {
    setState(() {
      _selectedRole = role;
      _filteredUsers = _allUsers
          .where((user) => user['role'] == role)
          .toList();
    });
  }

  // API: ดึงข้อมูลผู้ใช้ทั้งหมด
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$API_BASE_URL/users-admin'); 
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> fetchedUsers = json.decode(response.body);
        setState(() {
          _allUsers = fetchedUsers;
          _filterUsersByRole(_selectedRole); 
        });
      } else {
        String errorMessage = 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ใช้: Status Code ${response.statusCode}';
        if (response.body.isNotEmpty) {
            final responseBody = json.decode(response.body);
            errorMessage = responseBody['message'] ?? errorMessage;
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
  // UI: MAIN BUILD METHOD
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavbarAdminPage(
        userName: widget.userName,
        userId: widget.userId,
      ),
      drawer: DrawerAdminPage(
        userName: widget.userName,
        userId: widget.userId,
      ),
      body: Container(
        color: const Color(0xFFF0F2F5), // สีพื้นหลังเทาอ่อน
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัว: จัดการผู้ใช้
            _buildHeader(),
            const SizedBox(height: 20),
            
            // ส่วน Role Tabs
            _buildRoleTabs(),
            const SizedBox(height: 10),

            // ส่วนตารางข้อมูลและ Loading State
            Expanded(
              child: _buildBodyContent(),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // UI COMPONENTS
  // -----------------------------------------------------
  
  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(
          Icons.person, 
          color: Color(0xFF4CAF50), 
          size: 32,
        ),
        SizedBox(width: 10),
        Text(
          'จัดการผู้ใช้',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleTabs() {
    return Row(
      children: _roleOptions.keys.map((roleKey) {
        final isSelected = _selectedRole == roleKey;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ElevatedButton(
            onPressed: () => _filterUsersByRole(roleKey),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? const Color(0xFF4CAF50) : Colors.white,
              foregroundColor: isSelected ? Colors.white : Colors.grey.shade600,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade400,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(roleKey, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
  
  // 💡 แก้ไข: ใช้ LayoutBuilder และ ConstrainedBox เพื่อให้ตารางขยายเต็มความกว้าง
  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Text('ไม่พบข้อมูลผู้ใช้สำหรับบทบาท "$_selectedRole"',
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      // 💡 ใช้ LayoutBuilder เพื่อให้ทราบความกว้างของพื้นที่ที่มี
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            // 💡 ใช้ ConstrainedBox เพื่อบังคับให้ตารางมีความกว้างอย่างน้อยเท่ากับความกว้างสูงสุด
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: _buildDataTable(),
            ),
          );
        },
      ),
    );
  }
  
  // 💡 แก้ไข: ใช้ Expanded ใน DataColumn เพื่อให้คอลัมน์ยืดเต็มพื้นที่
  Widget _buildDataTable() {
    return DataTable(
      // กำหนดความสูงของแถวเพื่อให้ดูสวยงาม
      dataRowMinHeight: 50, 
      dataRowMaxHeight: 60,
      headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
      // กำหนดระยะห่างระหว่างคอลัมน์ให้น้อยลง (เพราะเรากำลังยืดตาราง)
      columnSpacing: 12.0, 
      columns: [
        // คอลัมน์ที่ต้องการให้ยืด
        const DataColumn(label: Expanded(child: Text('ชื่อผู้ใช้', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
        const DataColumn(label: Expanded(child: Text('อีเมล', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
        
        // แสดง 'รหัสนิสิต' เมื่อเลือก 'นิสิต' เท่านั้น และให้ยืดพื้นที่
        if (_selectedRole == 'นิสิต') 
          const DataColumn(label: Expanded(child: Text('รหัสนิสิต', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
        
        // คอลัมน์ 'แก้ไขข้อมูล' ไม่ต้องยืดพื้นที่
        const DataColumn(label: Text('แก้ไขข้อมูล', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
      ],
      rows: _filteredUsers.map<DataRow>((user) {
        final fullName = '${user['first_name']} ${user['last_name']}';
        return DataRow(
          cells: [
            DataCell(Text(fullName)),
            DataCell(Text(user['email'])),
            // แสดงรหัสนิสิตในช่องที่ 3 ถ้าเป็นบทบาท 'นิสิต'
            if (_selectedRole == 'นิสิต') 
              DataCell(Text(user['student_id'] ?? '-')),
            DataCell(
              Center( // จัดให้อยู่ตรงกลางเพราะคอลัมน์นี้ไม่ยืดเต็ม
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.redAccent), 
                  onPressed: () => _showEditDialog(user),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // -----------------------------------------------------
  // FUNCTION: EDIT DIALOG
  // -----------------------------------------------------
  void _showEditDialog(Map<String, dynamic> user) {
    final GlobalKey<FormState> _dialogFormKey = GlobalKey<FormState>();

    final TextEditingController firstNameCtrl = TextEditingController(text: user['first_name']);
    final TextEditingController lastNameCtrl = TextEditingController(text: user['last_name']);
    final TextEditingController emailCtrl = TextEditingController(text: user['email']);
    final TextEditingController studentIdCtrl = TextEditingController(text: user['student_id'] ?? ''); 
    
    String selectedRole = user['role']; 
    
    if (!_dialogRoleOptions.contains(selectedRole)) {
      selectedRole = _dialogRoleOptions.first; 
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('แก้ไขข้อมูลผู้ใช้'),
          content: SingleChildScrollView(
            child: Form( 
              key: _dialogFormKey, 
              child: ListBody(
                children: <Widget>[
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
                            items: _dialogRoleOptions.map((String value) { 
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedRole = newValue;
                                  if (newValue != 'นิสิต') {
                                    studentIdCtrl.clear();
                                  }
                                });
                              }
                            },
                          ),
                          
                          const SizedBox(height: 10),

                          // TextFormField สำหรับ รหัสนิสิต
                          TextFormField(
                            controller: studentIdCtrl, 
                            decoration: InputDecoration(
                              labelText: 'รหัสนิสิต',
                              fillColor: selectedRole == 'นิสิต' ? Colors.transparent : Colors.grey.shade100,
                              filled: selectedRole != 'นิสิต',
                            ),
                            validator: (value) {
                              if (selectedRole == 'นิสิต' && (value == null || value.isEmpty)) {
                                return 'ต้องกรอกรหัสนิสิตสำหรับบทบาท "นิสิต"';
                              }
                              return null;
                            },
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
                if (_dialogFormKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  _updateUser(
                    user['user_id'].toString(), 
                    firstNameCtrl.text,
                    lastNameCtrl.text,
                    emailCtrl.text,
                    studentIdCtrl.text, 
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
  // API: UPDATE USER
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
      final url = Uri.parse('$API_BASE_URL/users-admin/$userId'); 
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          // ส่งค่าว่างเป็น null หาก API รองรับ
          'student_id': studentId.isEmpty ? null : studentId, 
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตข้อมูลผู้ใช้สำเร็จ')),
          );
        }
        _fetchUsers(); // รีเฟรชข้อมูลในตาราง
      } else {
        String errorMessage = 'การอัปเดตล้มเหลว: Status Code ${response.statusCode}';
        try {
          if (response.body.isNotEmpty) {
            final responseBody = json.decode(response.body);
            errorMessage = 'การอัปเดตล้มเหลว: ${responseBody['message'] ?? errorMessage}';
          }
        } catch (e) {
          errorMessage = 'การอัปเดตล้มเหลว: Status Code ${response.statusCode}. ' + 
                          'โปรดตรวจสอบ Console Server: ${response.body.isNotEmpty ? response.body : 'ไม่มีข้อความตอบกลับ'}';
        }
        if (mounted) {
          _showErrorDialog(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'การเชื่อมต่อล้มเหลว: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e',
        );
      }
    }
  }

  // -----------------------------------------------------
  // HELPER FUNCTION
  // -----------------------------------------------------
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialogPage(
        message: message,
      ),
    );
  }
}