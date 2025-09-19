import 'package:e_learning_it/student_outsiders/drawer_page.dart';
import 'package:e_learning_it/student_outsiders/navbar_normal.dart';
import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  final String userName;
  final String userId;

  const AboutUsPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavbarPage(userName: userName, userId: userId),
      drawer: DrawerPage(userName: userName, userId: userId),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.help_outline,
                    color: Colors.black54,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'เกี่ยวกับเรา',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'ช่องทางการติดต่อ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Contact Section
              Center(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactItem(
                        icon: Icons.facebook,
                        text: 'สาขาวิชาเทคโนโลยีสารสนเทศ มหาวิทยาลัยเกษตรศาสตร์',
                        color: Colors.blue[800],
                      ),
                      _buildContactItem(
                        icon: Icons.language,
                        text: 'https://it.flas.kps.ku.ac.th/',
                        color: Colors.blue,
                      ),
                      _buildContactItem(
                        icon: Icons.youtube_searched_for_outlined,
                        text: 'ITKPS Channel',
                        color: Colors.red,
                      ),
                      _buildContactItem(
                        icon: Icons.email,
                        text: 'itkukps@gmail.com',
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({IconData? icon, required String text, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}