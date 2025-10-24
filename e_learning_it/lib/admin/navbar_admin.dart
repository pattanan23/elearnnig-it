import 'package:flutter/material.dart';
import 'package:e_learning_it/login_page.dart';
// 1. Import the new ProfilePage
import 'package:e_learning_it/admin/profile_admin.dart';

class NavbarAdminPage extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String userId;

  const NavbarAdminPage({super.key, required this.userName, required this.userId});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF03A96B),
      foregroundColor: Colors.white,
      elevation: 1,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 2. Wrap the Text with a GestureDetector
          GestureDetector(
            onTap: () {
              // Navigate to the ProfilePage when the name is tapped
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminProfilePage(
                    userName: userName,
                    userId: userId,
                  ),
                ),
              );
            },
            child: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.white),
            onPressed: () {
              // คำสั่งสำหรับกลับไปหน้า Login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}