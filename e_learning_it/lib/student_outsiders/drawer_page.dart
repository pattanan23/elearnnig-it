import 'package:e_learning_it/student_outsiders/report_page.dart';
import 'package:flutter/material.dart';
import 'package:e_learning_it/student_outsiders/main_page.dart';
import 'package:e_learning_it/student_outsiders/course/new_course_page.dart';
import 'package:e_learning_it/student_outsiders/course/all_course_page.dart';
import 'package:e_learning_it/student_outsiders/about_page.dart';

class DrawerPage extends StatelessWidget {
  final String userName;
  final String userId;

  const DrawerPage({super.key, required this.userName, required this.userId});

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
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('หน้าหลัก'),
              iconColor: Colors.white,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          MainPage(userName: userName, userId: userId)),
                );
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.book),
              title: const Text('หลักสูตร'),
              collapsedIconColor: Colors.white,
              iconColor: const Color(0xFF03A96B),
              collapsedTextColor: Colors.white,
              textColor: const Color(0xFF03A96B),
              children: <Widget>[
               ListTile(
                  title: const Text('หลักสูตรทั้งหมด'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                               CourseAllPage(userName: userName, userId: userId)), // Navigate to a new page
                    );
                  },
                ),
                ListTile(
                  title: const Text('หลักสูตรใหม่ล่าสุด'),
                  onTap: () {
                    Navigator.pop(context); // Close the drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                               CourseNewPage(userName: userName, userId: userId)), // Navigate to a new page
                    );
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('คำถาม'),
              iconColor: Colors.white,
                onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ReportPage(userName: userName, userId: userId)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('เกี่ยวกับเรา'),
              iconColor: Colors.white,
               onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          AboutUsPage(userName: userName, userId: userId)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
