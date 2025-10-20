import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'error_dialog_page.dart';
import 'navbar_admin.dart';
import 'drawer_admin.dart';

// **NOTE:** Replace this with your actual base URL
const String API_BASE_URL = 'http://localhost:3006/api';

class AdminMainPage extends StatefulWidget {
  final String userName;
  final String userId;

  const AdminMainPage({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  // -----------------------------------------------------
  // Data Fetching Logic ( unchanged )
  // -----------------------------------------------------
  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$API_BASE_URL/reports/pending');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> fetchedReports = jsonDecode(response.body);
        setState(() {
          // กรองรายงานที่มีสถานะเป็น 'รอดำเนินการ' หรือ 'Pending'
          _reports = fetchedReports
              .where((report) =>
                  report['status'] == null ||
                  report['status'] == 'รอดำเนินการ' ||
                  report['status'] == 'Pending')
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load reports (Status: ${response.statusCode})');
      }
    } catch (e) {
      print('Error fetching reports: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorDialog('เกิดข้อผิดพลาดในการดึงข้อมูลรายงาน');
      }
    }
  }

  // -----------------------------------------------------
  // Status Update Logic ( unchanged )
  // -----------------------------------------------------
  Future<void> _updateReportStatus(int reportId, int index) async {
    try {
      final url = Uri.parse('$API_BASE_URL/reports/$reportId/resolve');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': 'เสร็จสิ้น', // สถานะที่จะบันทึก
          'admin_id':
              widget.userId, // ส่ง Admin ID ไปบันทึกใน Log/History หากมี
        }),
      );

      if (response.statusCode == 200) {
        // อัปเดต UI โดยลบรายงานที่เสร็จสิ้นแล้วออกจาก List
        setState(() {
          _reports.removeAt(index);
        });
        // อาจเพิ่ม SnackBar แจ้งเตือนความสำเร็จ
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('บันทึกสถานะ "เสร็จสิ้น" เรียบร้อยแล้ว')),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      print('Error updating report status: $e');
      if (mounted) {
        _showErrorDialog('ไม่สามารถอัปเดตสถานะได้: $e');
      }
    }
  }

  // -----------------------------------------------------
  // Helper Function ( unchanged )
  // -----------------------------------------------------
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ErrorDialogPage(message: message);
      },
    );
  }

  // -----------------------------------------------------
  // Build Method ( restructured for better readability )
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
        color: const Color(0xFFF0F2F5), // เพิ่มสีพื้นหลังเพื่อให้ดูดีขึ้น
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications,
                    color: Color(0xFF4CAF50),
                    size: 32,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'แจ้งปัญหา',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reports.isEmpty) {
      return const Center(
        child: Text(
          'ไม่มีรายงานที่รอดำเนินการ',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        // ใช้ ReportCard Widget แยกออกมา
        return ReportCard(
          report: _reports[index],
          index: index,
          onResolve: _updateReportStatus,
        );
      },
    );
  }
}

// -----------------------------------------------------
// New Widget: ReportCard (for UI separation)
// -----------------------------------------------------
class ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final int index;
  final Function(int reportId, int index) onResolve;

  const ReportCard({
    super.key,
    required this.report,
    required this.index,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    // ใช้ report_id และ user_id จากฐานข้อมูล
    final reportId = report['report_id'];
    final userId = report['user_id'] ?? 'N/A';
    final category = report['category'] ?? 'N/A';
    final message = report['report_mess'] ?? 'ไม่มีข้อความ';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      elevation: 2, // เพิ่มเงาเล็กน้อย
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เรื่อง: $category', // ใช้ category เป็นชื่อเรื่อง
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // แสดง User ID
                  Text('User ID ผู้แจ้ง: $userId', style: const TextStyle(color: Colors.grey)), 
                  const SizedBox(height: 10),
                  // รายละเอียดปัญหา
                  Text(
                    'รายละเอียด: $message',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // ปุ่ม "เสร็จสิ้น"
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50), // สีเขียวที่ใช้ในรูป
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onResolve(reportId, index), // เรียกใช้ callback
                  borderRadius: BorderRadius.circular(5.0),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Text(
                      'เสร็จสิ้น', 
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}