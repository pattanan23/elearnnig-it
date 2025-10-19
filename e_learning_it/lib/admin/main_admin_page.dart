import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'error_dialog_page.dart'; // Assume this file exists for error popups
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
  // List to hold the report data
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  // -----------------------------------------------------
  // 1. API: FETCH REPORTS
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
          // กรองรายงานที่มีสถานะเป็น 'รอดำเนินการ' หรือ 'Pending' (ตามค่าเริ่มต้นที่ตั้งไว้)
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
  // 2. API: UPDATE STATUS
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ErrorDialogPage(message: message);
      },
    );
  }

  // -----------------------------------------------------
  // 3. UI: REPORT CARD Widget
  // -----------------------------------------------------
  Widget _buildReportCard(Map<String, dynamic> report, int index) {
    // ใช้ report_id และ user_id จากฐานข้อมูล
    final reportId = report['report_id'];
    final userId = report['user_id'];
    final category = report['category'] ?? 'N/A';
    final message = report['report_mess'] ?? 'ไม่มีข้อความ';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนแสดงรายละเอียด (คล้ายกับรูปแบบของรูปภาพ)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เรื่อง: $category', // ใช้ category เป็นชื่อเรื่อง
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text('User ID ผู้แจ้ง: $userId'),
                  const SizedBox(height: 10),
                  Text('รายละเอียด: $message',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // ปุ่ม "เสร็จสิ้น"
            Align(
              alignment: Alignment.topRight,
              child: ElevatedButton(
                onPressed: () => _updateReportStatus(reportId, index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                child: const Text('เสร็จสิ้น', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // 4. UI: BUILD METHOD
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(
                  child: Text('ไม่มีรายงานที่รอดำเนินการ',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                )
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    return _buildReportCard(_reports[index], index);
                  },
                ),
    );
  }
}
