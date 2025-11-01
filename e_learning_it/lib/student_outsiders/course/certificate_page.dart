import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; 


// ----------------------------------------------------------------------
// 💡 คลาส: สำหรับเก็บข้อมูลวุฒิบัตร (Mapping Data)
// ----------------------------------------------------------------------
class CertificateData {
  final String userName;
  final String subjectName; // ชื่อรายวิชาย่อย
  final String courseName; // ชื่อรายวิชาหลัก
  final String issueDate; // วันที่ออกวุฒิบัตร (ยังคงเก็บไว้สำหรับ PDF)

  CertificateData({
    required this.userName,
    required this.subjectName,
    required this.courseName,
    required this.issueDate,
  });

  // Factory method เพื่อสร้าง Object จาก JSON
  factory CertificateData.fromJson(Map<String, dynamic> json) {
    // สมมติว่า API ส่ง firstName และ lastName มา
    final String fullName = '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();
    return CertificateData(
      userName: fullName,
      subjectName: json['subjectName'] ?? 'ไม่ระบุรายวิชาย่อย',
      courseName: json['courseName'] ?? 'ไม่ระบุรายวิชาหลัก',
      issueDate: json['issueDate'] ?? '',
    );
  }
}

// ----------------------------------------------------------------------
// 🏆 CERTIFICATE WIDGET
// ----------------------------------------------------------------------
class CertificatePage extends StatefulWidget {
  final String courseName;
  final String courseId; 
  final String userId; 

  const CertificatePage({
    super.key,
    required this.courseName,
    required this.courseId, 
    required this.userId, 
  });

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> {
  // 💡 ตัวแปรสำหรับจัดการสถานะการโหลดข้อมูล
  CertificateData? _certData;
  bool _isLoading = true;
  String? _error;
  
  // สีหลัก
  final Color primaryColor = const Color(0xFF03A96B); 
  // ⚠️ กรุณาเปลี่ยน URL นี้ตามสภาพแวดล้อมจริง
  final String _apiUrlBase = 'http://localhost:3006/api'; 


  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'th'; 
    _fetchCertificateData(); 
  }

  // ----------------------------------------------------------------------
  // 📐 FUNCTION: คำนวณขนาดตัวอักษรแบบ Responsive
  // จะลดขนาด font ลงเมื่อหน้าจอเล็กกว่า 600px โดยมี minScale เป็นการจำกัดขนาดต่ำสุด
  // ----------------------------------------------------------------------
  double _responsiveFontSize(double baseSize, {double minScale = 0.7}) {
    final screenWidth = MediaQuery.of(context).size.width;
    // กำหนด 600.0 เป็นจุดอ้างอิงความกว้างหน้าจอที่ใช้ baseSize เต็มที่
    const double referenceWidth = 600.0; 
    
    // คำนวณ scale factor และจำกัดไม่ให้ scale เล็กกว่า minScale
    double scale = (screenWidth / referenceWidth).clamp(minScale, 1.0);
    
    return baseSize * scale;
  }


  // ----------------------------------------------------------------------
  // 📥 FUNCTION: ดาวน์โหลดวุฒิบัตรเป็น PDF
  // ----------------------------------------------------------------------
  Future<void> _downloadCertificatePdf() async {
    final downloadUrl = '$_apiUrlBase/certificates/pdf/${widget.userId}/${widget.courseId}';
    final Uri uri = Uri.parse(downloadUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ ไม่สามารถเปิดลิงก์ดาวน์โหลดได้ กรุณาลองใหม่อีกครั้ง')),
        );
      }
    }
  }


  // ----------------------------------------------------------------------
  // 💾 API: บันทึกวันที่ออกวุฒิบัตร (ยังคงไว้สำหรับ PDF)
  // ----------------------------------------------------------------------
  Future<void> _saveIssueDateIfNeeded(String currentIssueDate) async {
    // ตรวจสอบทั้งค่าว่างเปล่าและค่า 'null' ที่เป็นสตริง
    if (currentIssueDate.isEmpty || currentIssueDate.toLowerCase() == 'null') {
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String url = '$_apiUrlBase/certificates/save'; 

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'userId': widget.userId,
            'courseId': widget.courseId,
            'issueDate': today,
          }),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            // อัปเดตข้อมูลใน State ด้วยวันที่ที่บันทึกใหม่
            if (_certData != null) {
              setState(() {
                _certData = CertificateData(
                  userName: _certData!.userName,
                  subjectName: _certData!.subjectName,
                  courseName: _certData!.courseName,
                  issueDate: today, // ใช้ today ที่ถูกบันทึก
                );
              });
              // ignore: use_build_context_synchronously
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ บันทึกวันที่ออกวุฒิบัตรแล้ว (สำหรับการสร้าง PDF)')),
              );
            }
          }
        } else {
          // ใช้ print แทน logging เพื่อความเรียบง่าย
          print('Failed to save issue date: ${response.body}');
        }
      } catch (e) {
        print('Error saving issue date: $e');
      }
    }
  }

  // ----------------------------------------------------------------------
  // 🚀 API: ดึงข้อมูลวุฒิบัตร (รวมถึง issueDate)
  // ----------------------------------------------------------------------
  Future<void> _fetchCertificateData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final url = '$_apiUrlBase/certificates/${widget.userId}/${widget.courseId}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final certData = CertificateData.fromJson(data); 
        
        setState(() {
          _certData = certData; // เก็บข้อมูลที่ได้ลงใน State
        });

        // 💡 เรียกฟังก์ชันบันทึกวันที่ หากยังไม่มีการออกวุฒิบัตร (เพื่อเตรียมพร้อมสำหรับการสร้าง PDF)
        await _saveIssueDateIfNeeded(certData.issueDate); 

      } else if (response.statusCode == 404) {
          setState(() {
            _error = 'ไม่พบข้อมูลวุฒิบัตรในระบบ กรุณาติดต่อผู้ดูแล';
          });
      } else {
        setState(() {
          _error = 'Failed to load certificate data (Status: ${response.statusCode})';
        });
      }
    } catch (e) {
      // ⚠️ ข้อผิดพลาด Network 
      setState(() {
        _error = 'Network error: ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ----------------------------------------------------------------------
  // 🎨 UI/BUILD METHOD (ใช้ Responsive Font Sizes ที่นี่)
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    
    // 1. จัดการ Loading และ Error 
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('วุฒิบัตร', style: TextStyle(color: Colors.white)), backgroundColor: primaryColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _certData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('วุฒิบัตร', style: TextStyle(color: Colors.white)), backgroundColor: primaryColor),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              _error ?? 'ไม่พบข้อมูลวุฒิบัตร',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }
    
    // 2. 💡 กำหนดขนาด Responsive สำหรับ Text และ Container (FIX: เรียกใช้ฟังก์ชัน Responsive)
    final double bodyTextSize = _responsiveFontSize(20, minScale: 0.85);
    final double nameTextSize = _responsiveFontSize(34, minScale: 0.7);
    final double courseNameSize = _responsiveFontSize(26, minScale: 0.75);
    final double subjectNameSize = _responsiveFontSize(18, minScale: 0.85);
    final double buttonTextSize = _responsiveFontSize(18, minScale: 0.9);
    
    // 💡 กำหนดความกว้างของกรอบวุฒิบัตรให้ Responsive (อย่างน้อย 300, ไม่เกิน 700)
    final double certContainerWidth = MediaQuery.of(context).size.width.clamp(300.0, 700.0);
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('วุฒิบัตร', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 1. กรอบวุฒิบัตร (Container หลัก)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                  width: certContainerWidth, // 🎯 ใช้ความกว้างที่คำนวณแบบ Responsive
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryColor, width: 5),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                    ],
                    color: Colors.white,
                  ),
                  child: Column(
                    children: <Widget>[
                      // ส่วนหัว: โลโก้
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          // 🎯 ปรับขนาดโลโก้ตามหน้าจอด้วย
                          Image.asset(
                            'assets/images/logo4.png', // ⚠️ **ต้องเปลี่ยน Path นี้ให้ตรงกับไฟล์ของคุณ**
                            height: 80 * (MediaQuery.of(context).size.width / 600).clamp(0.7, 1.0),
                          ), 
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      // ข้อความรับรอง
                      Text(
                        'ประกาศนียบัตรนี้ให้ไว้เพื่อรับรองว่า',
                        style: TextStyle(fontSize: bodyTextSize, color: Colors.black54), // 🎯 ใช้ bodyTextSize
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      // ชื่อผู้ได้รับวุฒิบัตร
                      Text(
                        _certData!.userName,
                        style: TextStyle(
                            fontSize: nameTextSize, // 🎯 ใช้ nameTextSize
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontStyle: FontStyle.italic,
                            decorationColor: primaryColor,
                            decorationThickness: 2),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      // ข้อความจบรายวิชา
                      Text(
                        'ได้ผ่านการอบรมรายวิชา',
                        style: TextStyle(fontSize: bodyTextSize, color: Colors.black54), // 🎯 ใช้ bodyTextSize
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      // ชื่อรายวิชา
                      Text(
                        _certData!.courseName,
                        style: TextStyle(
                            fontSize: courseNameSize, // 🎯 ใช้ courseNameSize
                            fontWeight: FontWeight.bold,
                            color: primaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),

                      // ชื่อรายวิชาย่อย
                      Text(
                        '(${_certData!.subjectName})',
                        style: TextStyle(fontSize: subjectNameSize, color: primaryColor), // 🎯 ใช้ subjectNameSize
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 70), // เว้นช่องว่าง
                      
                      // 📝 (ส่วนลายเซ็น/ผู้บริหาร - สามารถเพิ่มได้ที่นี่)

                    ],
                  ),
                ), // สิ้นสุด Container กรอบวุฒิบัตร
                
                const SizedBox(height: 30), // เว้นช่องว่างระหว่างวุฒิบัตรกับปุ่ม

                // 2. 📥 ปุ่มดาวน์โหลด PDF (อยู่นอก Container)
                ElevatedButton.icon(
                  onPressed: _certData != null ? _downloadCertificatePdf : null,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: Text('ดาวน์โหลดวุฒิบัตร PDF', style: TextStyle(fontSize: buttonTextSize, color: Colors.white)), // 🎯 ใช้ buttonTextSize
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800], 
                    padding: EdgeInsets.symmetric(
                      horizontal: _responsiveFontSize(30, minScale: 0.9), // 🎯 ใช้ Responsive Padding
                      vertical: _responsiveFontSize(15, minScale: 0.9) // 🎯 ใช้ Responsive Padding
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
