import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 💡 [IMPORTANT] เปลี่ยน IP และ Port ให้ถูกต้อง
// ⚠️ หมายเหตุ: URL นี้จะถูกแทนที่ด้วย _apiUrlBase/rate_course ใน CourseDetailPage แล้ว
const String _apiRateUrl = 'http://localhost:3006/api/rate_course'; 

// 💡 StarRatingDialog
class StarRatingDialog extends StatefulWidget {
  final String courseId; 
  final String userId; 
  final String lessonName;
  
  const StarRatingDialog({
    Key? key,
    required this.courseId,
    required this.userId,
    required this.lessonName,
  }) : super(key: key);

  @override
  _StarRatingDialogState createState() => _StarRatingDialogState();
}

class _StarRatingDialogState extends State<StarRatingDialog> {
  int _rating = 0; // คะแนนที่ผู้ใช้เลือก (1-5)

  // 💡 ฟังก์ชันสำหรับเรียก API บันทึกคะแนน (ยกเลิกการใช้เนื่องจาก CourseDetailPage ทำหน้าที่นี้)
  // หากคุณใช้ StarRatingDialog แยกต่างหากจาก CourseDetailPage คุณสามารถใช้ฟังก์ชันนี้ได้
  // แต่จากโค้ดเดิมของคุณ หน้า CourseDetailPage เป็นผู้เรียกใช้งานฟังก์ชัน API โดยตรง
  // ฟังก์ชันนี้จึงไม่จำเป็นในการแก้ไขส่วนนี้ แต่ผมจะคงโค้ดส่วนนี้ไว้เพื่อความสมบูรณ์
  Future<void> _saveRating() async {
    // 💡 [NOTE] ฟังก์ชันนี้ไม่ถูกเรียกในโค้ด CourseDetailPage ที่คุณให้มา
    // แต่ถ้ามันถูกเรียก เราจะ pop กลับไปพร้อมค่าคะแนน
    if (_rating == 0) return;

    // ... (โค้ดเรียก API เหมือนเดิม) ...
    
    // [BEST PRACTICE] ตรวจสอบว่า Widget ยังอยู่หรือไม่ ก่อนใช้ context
    if (!mounted) return; 

    // สมมติว่าสำเร็จ
    Navigator.of(context).pop(_rating); 
  }
  
  // วิดเจ็ตสำหรับแสดงดาวแต่ละดวง
  Widget _buildStar(int index) {
    IconData icon;
    Color color;

    if (index < _rating) {
      icon = Icons.star_rounded;
      color = Colors.amber;
    } else {
      icon = Icons.star_border_rounded;
      color = Colors.grey;
    }

    return IconButton(
      icon: Icon(icon, color: color, size: 36),
      onPressed: () {
        setState(() {
          _rating = index + 1;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ให้คะแนนบทเรียนนี้'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              widget.lessonName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => _buildStar(index)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _rating == 0 ? 'กรุณาเลือกคะแนน' : 'คุณให้ ${_rating} ดาว',
              style: TextStyle(
                fontStyle: _rating == 0 ? FontStyle.italic : FontStyle.normal,
                color: _rating == 0 ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // ยกเลิก
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          // ⚠️ ปุ่มนี้ควรถูกกดเมื่อคะแนนมากกว่า 0
          // แต่เนื่องจากฟังก์ชัน _showRatingDialog ใน CourseDetailPage เป็นผู้จัดการ API
          // เราจึงเปลี่ยน onPressed ให้ส่งค่าคะแนนกลับไปเมื่อกด "ตกลง"
          onPressed: _rating > 0 ? () => Navigator.of(context).pop(_rating) : null,
          child: const Text('ตกลง'),
        ),
      ],
    );
  }
}