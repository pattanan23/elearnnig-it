import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:e_learning_it/student_outsiders/course/vdo_page.dart';


class Course {
  final String courseId;
  final String userId;
  final String courseCode;
  final String courseName;
  final String shortDescription;
  final String description;
  final String objective;
  final String professorName;
  final String imageUrl;
  final List<Lesson> lessons;

  Course({
    required this.courseId,
    required this.userId,
    required this.courseCode,
    required this.courseName,
    required this.shortDescription,
    required this.description,
    required this.objective,
    required this.professorName,
    required this.imageUrl,
    required this.lessons,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    var lessonsList = json['lessons'] as List<dynamic>? ?? [];
    List<Lesson> parsedLessons = lessonsList.map((lessonJson) {
      return Lesson(
        id: int.tryParse(lessonJson['lesson_id']?.toString() ?? '0') ?? 0,
        videoName: lessonJson['video_name'] ?? '',
        videoDescription: lessonJson['video_description'] ?? '',
        videoUrl: lessonJson['video_url'],
        pdfUrl: lessonJson['pdf_url'],
      );
    }).toList();

    return Course(
      courseId: json['course_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      courseCode: json['course_code']?.toString() ?? '',
      courseName: json['course_name'] ?? '',
      shortDescription: json['short_description'] ?? '',
      description: json['description'] ?? '',
      objective: json['objective'] ?? '',
      professorName: json['professor_name'] ?? 'ไม่ระบุ',
      imageUrl: json['image_url'] ?? 'https://placehold.co/600x400.png',
      lessons: parsedLessons,
    );
  }
}

// 💡 NEW CLASS: สำหรับรวมผลลัพธ์ของ Future 2 ตัว
class CourseProgressData {
  final Map<String, dynamic> progress;
  final bool hasRated;

  CourseProgressData({
    required this.progress,
    required this.hasRated,
  });
}


class CourseDetailPage extends StatefulWidget {
  final Course course;
  final String userName;
  final String userId;

  const CourseDetailPage({
    Key? key,
    required this.course,
    required this.userName,
    required this.userId,
  }) : super(key: key);

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  // ⚠️ กรุณาเปลี่ยน IP และ Port ให้ถูกต้อง
  // ตรวจสอบว่า IP/Port นี้สามารถเชื่อมต่อกับ Node.js ได้จริง
  final String _apiUrlBase = 'http://localhost:3006/api'; 
  
  late Future<CourseProgressData> _courseStatusFuture;

  @override
  void initState() {
    super.initState();
    _courseStatusFuture = _fetchCombinedCourseStatus();
  }

  // 💡 [CRITICAL FIX] ดึงสถานะการให้คะแนนจาก course_ratings ให้ตรงกับ Node.js API (Endpoint 8)
  Future<bool> _fetchCourseRatingStatus() async {
    try {
      // 🎯 URL ต้องตรงกับ Node.js Endpoint ที่ 8: /api/check_user_rating/:userId/:courseId
      final url = '$_apiUrlBase/check_user_rating/${widget.userId}/${widget.course.courseId}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      // Node.js API ส่ง 200 ถ้าพบ rating และ 404 ถ้าไม่พบ
      if (response.statusCode == 200) {
        // Status 200 = User ได้ให้คะแนนคอร์สนี้แล้ว
        return true; 
      } else if (response.statusCode == 404) {
        // Status 404 = User ยังไม่ได้ให้คะแนนคอร์สนี้
        return false; 
      } 
      
      // สำหรับ Status Code อื่นๆ (เช่น 500)
      return false;

    } catch (e) {
      print('Network error fetching rating status: $e');
      return false;
    }
  }

  // 💡 NEW FUNCTION: ดึงสถานะความคืบหน้า + สถานะการให้คะแนน
  Future<CourseProgressData> _fetchCombinedCourseStatus() async {
    final progress = await _fetchLastProgress();
    final hasRated = await _fetchCourseRatingStatus();
    return CourseProgressData(progress: progress, hasRated: hasRated);
  }

  // 💡 MODIFIED FUNCTION: ดึงความคืบหน้าล่าสุด 
  Future<Map<String, dynamic>> _fetchLastProgress() async {
    Map<String, dynamic> defaultProgress = {
      'lessonId': 0,
      'savedSeconds': 0,
      'courseStatus': 'เรียนใหม่',
    };

    if (widget.course.lessons.isEmpty) return defaultProgress;

    try {
      final url = '$_apiUrlBase/get_progress/${widget.userId}/${widget.course.courseId}';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final progress = data['progress'] ?? defaultProgress;

        final lessonId = progress['lessonId'] as int?;
        if (lessonId != null && widget.course.lessons.any((l) => l.id == lessonId)) {
            return progress;
        }
        return defaultProgress;

      } else if (response.statusCode == 404) {
        return defaultProgress;
      } else {
        print('Error fetching progress: ${response.statusCode}, Body: ${response.body}');
        return defaultProgress;
      }
    } catch (e) {
      print('Network error fetching progress: $e');
      return defaultProgress;
    }
  }

  // 💡 FIXED FUNCTION: ฟังก์ชันส่งคะแนนไปยัง API
  Future<void> _submitRating(int rating) async {
    try {
      // 🎯 URL ตรงกับ Node.js Endpoint ที่ 7: /api/rate_course
      final response = await http.post(
        Uri.parse('$_apiUrlBase/rate_course'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'courseId': widget.course.courseId,
          'userId': widget.userId,
          'rating': rating,
          'review_text': '', 
        }),
      );

      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ บันทึกคะแนนเรียบร้อยแล้ว ปุ่มเปลี่ยนเป็น "ทบทวน"')),
        );
        // ✅ [CRITICAL FIX] เรียก setState เพื่อเรียก FutureBuilder ใหม่ทันที
        setState(() {
          _courseStatusFuture = _fetchCombinedCourseStatus(); // รีเฟรช Future
        }); 
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ไม่สามารถบันทึกคะแนนได้. Status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Network error submitting rating: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🌐 เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    }
  }

  // 💡 FIXED FUNCTION: ฟังก์ชันแสดง Dialog การให้คะแนน
  void _showRatingDialog(BuildContext context) async {
    int _currentRating = 0;

    final int? selectedRating = await showDialog<int>( 
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('ให้คะแนนคอร์ส'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('คุณให้คะแนนคอร์สนี้กี่ดาว?'),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          Icons.star,
                          color: index < _currentRating ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _currentRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null), 
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: _currentRating > 0
                      ? () {
                          Navigator.of(context).pop(_currentRating); 
                        }
                      : null,
                  child: const Text('ส่งคะแนน'),
                ),
              ],
            );
          },
        );
      }
    );
    
    // 2. ตรวจสอบว่ามีคะแนนที่เลือกหรือไม่
    if (selectedRating != null && selectedRating > 0) {
      // 3. เรียกฟังก์ชันส่งคะแนน ซึ่งจะเรียก setState ภายใน
      await _submitRating(selectedRating);
    }
  }

  // 💡 FIXED FUNCTION: นำทางไปหน้าวิดีโอ
  void _navigateToVideoPage(BuildContext context, Map<String, dynamic> progress) async {
    int startLessonIndex = 0; 
    int startSavedSeconds = progress['savedSeconds'] ?? 0;
    String status = progress['courseStatus'] ?? 'เรียนใหม่';

    if (widget.course.lessons.isEmpty) return;

    final lastLessonId = progress['lessonId'] as int?;
    final lastLessonIndex = lastLessonId != null
        ? widget.course.lessons.indexWhere((l) => l.id == lastLessonId)
        : -1;

    // หากเป็นสถานะ 'ทบทวน' หรือ 'เรียนใหม่' ให้เริ่มที่บทเรียนแรก
    if (status == 'เรียนใหม่' || status == 'ทบทวน') {
      startLessonIndex = 0;
      startSavedSeconds = 0;
    } 
    // หากเป็น 'เรียนต่อ' หรือ 'เรียนจบ' (แต่ยังไม่จบบทสุดท้าย)
    else if (lastLessonIndex != -1) {
      if (status == 'เรียนต่อ') {
        startLessonIndex = lastLessonIndex;
      } else if (status == 'เรียนจบ') {
        if (lastLessonIndex + 1 < widget.course.lessons.length) {
          // ไปบทถัดไป
          startLessonIndex = lastLessonIndex + 1;
          startSavedSeconds = 0;
        } else {
          // จบทุกบทเรียนแล้ว
          startLessonIndex = 0;
          startSavedSeconds = 0;
        }
      }
    } 

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VdoPage(
          courseId: widget.course.courseId,
          userId: widget.userId,
          lessons: widget.course.lessons,
          initialLessonIndex: startLessonIndex,
          initialSavedSeconds: startSavedSeconds,
        ),
      ),
    );

    // เมื่อกลับมาจาก VdoPage ให้รีเฟรชหน้า CourseDetailPage
    setState(() {
      _courseStatusFuture = _fetchCombinedCourseStatus(); // รีเฟรช Future
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.courseName),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... (ส่วนหัวหลักสูตรและรูปภาพ) ...
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                    image: DecorationImage(
                      image: NetworkImage(widget.course.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.course.courseName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1.0, 1.0),
                              blurRadius: 3.0,
                              color: Color.fromARGB(150, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // ส่วน Tabs และเนื้อหา
                _buildTabsAndContent(context),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // 💡 ปุ่ม "เริ่ม"
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
              child: FutureBuilder<CourseProgressData>(
                future: _courseStatusFuture, // ใช้ Future ตัวใหม่
                builder: (context, snapshot) {
                  String buttonText = 'เริ่มเรียน';
                  bool isButtonEnabled = true;
                  Map<String, dynamic> progressData = {'courseStatus': 'เรียนใหม่', 'lessonId': 0, 'savedSeconds': 0};
                  bool hasRated = false;

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    buttonText = 'กำลังโหลด...';
                    isButtonEnabled = false;
                  } else if (widget.course.lessons.isEmpty) {
                    buttonText = 'ไม่มีบทเรียน';
                    isButtonEnabled = false;
                  } else if (snapshot.hasError) {
                    // จัดการข้อผิดพลาดในการโหลดข้อมูล (เช่น API Down)
                    print('Error loading course status: ${snapshot.error}');
                    buttonText = 'มีข้อผิดพลาด';
                    isButtonEnabled = false;
                  } else if (snapshot.hasData) {
                    progressData = snapshot.data!.progress;
                    hasRated = snapshot.data!.hasRated; // สถานะการให้คะแนน

                    final status = progressData['courseStatus'];
                    final lastLessonId = progressData['lessonId'] as int?;

                    final isLastLessonInCourse = lastLessonId != null &&
                        widget.course.lessons.isNotEmpty &&
                        lastLessonId == widget.course.lessons.last.id;


                    // 1. ตรวจสอบ "course_ratings": ถ้ามีคะแนนแล้ว ให้เป็น "ทบทวน" ทันที
                    if (hasRated) { 
                      buttonText = 'ทบทวน';
                    }
                    // 2. ตรวจสอบ "video_progress" (สถานะ "เรียนจบ" + บทเรียนสุดท้าย + ยังไม่ได้ให้คะแนน)
                    else if (status == 'เรียนจบ' && isLastLessonInCourse && !hasRated) {
                      buttonText = 'ให้คะแนนคอร์ส';
                    }
                    // 3. ตรวจสอบ "video_progress" (สถานะ "เรียนต่อ" หรือ "เรียนจบ" แต่ยังไม่จบบทสุดท้าย)
                    else if (status == 'เรียนต่อ' || (status == 'เรียนจบ' && !isLastLessonInCourse)) {
                      buttonText = 'เรียนต่อ';
                    } 
                    // 4. สถานะ: เริ่มเรียน (ยังไม่เคยดูเลย)
                    else { 
                      buttonText = 'เริ่มเรียน';
                    }
                  }

                  // กำหนด Action ของปุ่ม
                  final VoidCallback? onPressedAction;
                  if (!isButtonEnabled) {
                    onPressedAction = null;
                  } else if (buttonText == 'ให้คะแนนคอร์ส') {
                    onPressedAction = () => _showRatingDialog(context);
                  } else {
                    onPressedAction = () => _navigateToVideoPage(context, progressData);
                  }

                  final buttonColor = buttonText == 'ให้คะแนนคอร์ส'
                      ? Colors.amber[700]
                      : const Color(0xFF2E7D32);

                  return ElevatedButton(
                    onPressed: onPressedAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: Text(buttonText, style: const TextStyle(fontSize: 18, color: Colors.white)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsAndContent(BuildContext context) {
    return DefaultTabController(
    length: 3,
    child: Column(
      children: [

        const TabBar(
          labelColor: const Color(0xFF2E7D32), // สีเข้ม (สีเดียวกับ AppBar)
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),

          tabs: [
            Tab(text: 'รายละเอียด'),
            Tab(text: 'วุฒิบัตร'),
            Tab(text: 'บทเรียน'),
          ],
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: TabBarView(
            children: [
              _buildDetailTab(),
              _buildCertificateTab(),
              _buildLessonsTab(),
            ],
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildDetailTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วน คำอธิบายหลักสูตร (รายละเอียด)
          Row(
            children: [
              const Icon(Icons.menu_book, color: Color.fromARGB(255, 87, 87, 87)),
              const SizedBox(width: 8),
              Text('คำอธิบายหลักสูตร', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          // ใช้ description
          SelectableText(widget.course.description, style: const TextStyle(fontSize: 16)),

          const Divider(height: 32),

          // ส่วน วัตถุประสงค์การเรียนรู้
          Row(
            children: [
              const Icon(Icons.my_location, color: Color.fromARGB(255, 87, 87, 87)),
              const SizedBox(width: 8),
              Text('วัตถุประสงค์การเรียนรู้', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          // ใช้ objective
          SelectableText(widget.course.objective, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCertificateTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge, size: 48, color: Colors.blueGrey),
            SizedBox(height: 10),
            Text(
              'ข้อมูลวุฒิบัตร/ใบรับรอง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            SizedBox(height: 5),
            Text(
              'คุณจะได้รับวุฒิบัตรเมื่อเรียนจบคอร์สนี้ครบ 100% และผ่านการทดสอบ (ถ้ามี)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey)
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildLessonsTab() {
    return ListView.builder(
      // กำหนด shrinkWrap และ physics เพื่อให้ทำงานใน TabBarView ได้
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.course.lessons.length,
      itemBuilder: (context, index) {
        final lesson = widget.course.lessons[index];
        return ListTile(
          leading: const Icon(Icons.video_library),
          title: Text('ตอนที่ ${index + 1}: ${lesson.videoName}'),
          subtitle: Text(lesson.videoDescription, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            // เมื่อคลิกที่รายการบทเรียน ให้เริ่มดูบทเรียนนั้นตั้งแต่ต้น (ทบทวน)
              _navigateToVideoPage(context, {
                'lessonId': lesson.id,
                'savedSeconds': 0,
                'courseStatus': 'เรียนใหม่',
              });
          },
        );
      },
    );
  }
}