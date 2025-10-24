import 'package:e_learning_it/student_outsiders/drawer_page.dart';
import 'package:e_learning_it/student_outsiders/navbar_normal.dart';
import 'package:e_learning_it/student_outsiders/footer_widget.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth > 600 ? 100.0 : 20.0;
    final double verticalPadding = 24.0;
    
    return Scaffold(
      appBar: NavbarPage(userName: userName, userId: userId),
      drawer: DrawerPage(userName: userName, userId: userId),
      backgroundColor: Colors.grey[200], // Updated to match other pages
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: verticalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title and Icon
              Row(
                children: [
                  Icon(Icons.help_outline, size: 48, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'เกี่ยวกับเรา',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Section Card for contact information
              _buildSectionCard(
                title: 'ช่องทางการติดต่อ',
                children: [
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
              const SizedBox(height: 40),
               const FooterWidget(), 
            ],
          ),
        ),
      ),

    );
  }

  // Helper widget to build a section with a white background, shadow, and rounded corners
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

  // Helper widget for the section title
  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  // Helper widget for each contact item
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