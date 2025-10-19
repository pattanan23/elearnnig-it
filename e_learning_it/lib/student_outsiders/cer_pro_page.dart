import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 

// ----------------------------------------------------------------------
// 💡 คลาส: สำหรับเก็บข้อมูลวุฒิบัตร (Mapping Data)
// ----------------------------------------------------------------------
class CertificateData {
  final String userName;
  final String subjectName; 
  final String courseName; 
  final String issueDate; 

  CertificateData({
    required this.userName,
    required this.subjectName,
    required this.courseName,
    required this.issueDate,
  });

  factory CertificateData.fromJson(Map<String, dynamic> json) {
    final String fullName = '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim();
    return CertificateData(
      userName: fullName,
      subjectName: json['subjectName'] ?? 'ไม่ระบุหลักสูตรย่อย', 
      courseName: json['courseName'] ?? 'ไม่ระบุหลักสูตรหลัก',
      issueDate: json['issueDate'] ?? '', 
    );
  }
}

// ----------------------------------------------------------------------
// 💡 หน้า: แสดงวุฒิบัตร (รับค่า userId, courseId, courseName)
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
  CertificateData? _certData;
  bool _isLoading = true;
  String? _errorMessage;
  final Color primaryColor = const Color(0xFF03A96B);

  @override
  void initState() {
    super.initState();
    // ⭐️ เริ่มดึงข้อมูลเมื่อเข้าสู่หน้า
    _fetchCertificateData();
  }

  // ----------------------------------------------------------------------
  // ⚙️ ฟังก์ชัน: ดึงข้อมูลวุฒิบัตรจาก API
  // ----------------------------------------------------------------------
  Future<void> _fetchCertificateData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 🎯 URL API ที่ใช้ userId และ courseId ในการเรียกข้อมูล
    final String apiUrl = 'YOUR_API_ENDPOINT/certificates?userId=${widget.userId}&courseId=${widget.courseId}'; 
    
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          _certData = CertificateData.fromJson(data); 
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'ไม่พบข้อมูลวุฒิบัตรสำหรับหลักสูตรนี้. (Status Code: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadCertificatePdf() async {
    if (_certData == null) return;
    final String downloadUrl = 'YOUR_PDF_DOWNLOAD_API/pdf?userId=${widget.userId}&courseId=${widget.courseId}';
    
    if (await canLaunchUrl(Uri.parse(downloadUrl))) {
      await launchUrl(Uri.parse(downloadUrl));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิดลิงก์ดาวน์โหลดได้')),
        );
      }
    }
  }

  // ----------------------------------------------------------------------
  // 🎨 การออกแบบหน้าจอ (Build Method)
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('วุฒิบัตร', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        // 1. 🖼️ กรอบวุฒิบัตร (Container)
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 800, minHeight: 400),
                          padding: const EdgeInsets.all(40.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: primaryColor, width: 8),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'วุฒิบัตรรับรองผล',
                                style: TextStyle(
                                  fontSize: 30, 
                                  fontWeight: FontWeight.bold, 
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 50),

                              const Text(
                                'มอบให้แก่',
                                style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 10),

                              // ชื่อผู้รับวุฒิบัตร
                              Text(
                                _certData!.userName,
                                style: TextStyle(
                                  fontSize: 36, 
                                  fontWeight: FontWeight.w900, 
                                  color: Colors.red[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),

                              // เนื้อหาการรับรอง
                              const Text(
                                'ผ่านการฝึกอบรมหลักสูตร',
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              
                              // ชื่อหลักสูตรหลัก
                              Text(
                                _certData!.courseName,
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold, 
                                  color: primaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),

                              // ชื่อหลักสูตรย่อย
                              Text(
                                '(${_certData!.subjectName})',
                                style: TextStyle(fontSize: 18, color: primaryColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 70),
                            ],
                          ),
                        ), 
                        
                        const SizedBox(height: 30), 

                        // 2. 📥 ปุ่มดาวน์โหลด PDF
                        ElevatedButton.icon(
                          onPressed: _certData != null ? _downloadCertificatePdf : null,
                          icon: const Icon(Icons.download, color: Colors.white),
                          label: const Text('ดาวน์โหลดวุฒิบัตร PDF', style: TextStyle(fontSize: 18, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[800], 
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }
}