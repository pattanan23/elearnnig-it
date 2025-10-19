import 'package:flutter/material.dart';
import 'package:e_learning_it/student_outsiders/main_page.dart';
import 'package:e_learning_it/login_page.dart';
import 'package:e_learning_it/professor/upload_page.dart'; 
import 'package:e_learning_it/admin/main_admin_page.dart';
import 'package:e_learning_it/admin/user_manage_page.dart';
import 'package:e_learning_it/admin/course_manage_page.dart';

class DrawerAdminPage extends StatelessWidget {
  final String userName;
  final String userId;

  const DrawerAdminPage(
      {super.key, required this.userName, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2F3337),
      child: Theme(
        data: Theme.of(context).copyWith(
          iconTheme: const IconThemeData(color: Colors.white),
          textTheme: Theme.of(context).textTheme.copyWith(
            bodyLarge: const TextStyle(color: Colors.white),
            bodyMedium: const TextStyle(color: Colors.white),
            titleMedium: const TextStyle(color: Colors.white),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // ส่วน DrawerHeader ที่แก้ไข
            SizedBox(
              height: 100,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF2F3337),
                ),
                child: Stack(
                  children: <Widget>[
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/images/logo2not.png', // เปลี่ยนชื่อไฟล์และ path ให้ถูกต้อง
                        fit: BoxFit.contain,
                        height: 100, // ปรับขนาดรูปภาพตามที่ต้องการ
                      ),
                    ),
                    // ปุ่มปิด Drawer
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop(); // คำสั่งสำหรับปิด Drawer
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // สิ้นสุดส่วนที่แก้ไข
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('หน้าหลัก'),
              iconColor: Colors.white,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AdminMainPage(userName: userName, userId: userId)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('จัดการผู้ใช้งาน'),
              iconColor: Colors.white,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserManagementPage(
                              userName: userName,
                              userId: userId,
                            )));
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('หลักสูตรการเรียน'),
              iconColor: Colors.white,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>CourseManagePage(
                              userName: userName,
                              userId: userId,
                            )));
              },
            ),
          ],
        ),
      ),
    );
  }
}