import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart'; 
// 💡 นำเข้า CertificatePage (ถ้ามี)
import 'package:e_learning_it/student_outsiders/course/certificate_page.dart'; 

// 🎯 [NEW IMPORT] นำเข้า VdoPage ตัวจริง (กรุณาตรวจสอบ Path ให้ถูกต้อง)
// ⚠️ กรุณาตรวจสอบว่าไฟล์ vdo_page.dart อยู่ใน Path นี้จริงหรือไม่
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
  final String? courseCredit; // 🎯 เพิ่ม field นี้

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
    this.courseCredit, // 🎯 เพิ่มใน Constructor
  });
// ...

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

// Class สำหรับรวมผลลัพธ์ของ Future 3 ตัว (รวม CertificateUrl)
class CourseProgressData {
  final Map<String, dynamic> progress;
  final bool hasRated;
  final bool hasCertificate; 

  CourseProgressData({
    required this.progress,
    required this.hasRated,
    required this.hasCertificate, 
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

class _CourseDetailPageState extends State<CourseDetailPage> with SingleTickerProviderStateMixin {
  
  late TabController _tabController; 
  
  // 💡 [FIX] เพิ่มตัวแปร _apiUrlBase ให้เป็นค่าคงที่
  final String _apiUrlBase = 'http://localhost:3006/api'; 
  
  late Future<CourseProgressData> _courseStatusFuture;
  
  bool _isGenerating = false; 
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 🎯 [FIX] เรียก fetch สถานะรวม
    _courseStatusFuture = _fetchCombinedCourseStatus();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  // 🎯 [FIX] ฟังก์ชันนี้ต้องอ่านค่า 'isGenerated' จาก JSON
  Future<bool> _checkCertificateExistence() async {
    try {
      final url = '$_apiUrlBase/get_certificate/${widget.userId}/${widget.course.courseId}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // 🎯 [FIX HERE] Backend returns 200 with JSON { isGenerated: true/false }
        final data = json.decode(response.body);
        final bool isGenerated = data['isGenerated'] ?? false; // Read the boolean status
        return isGenerated; 
      }
      
      // If status code is not 200 (e.g., 500 server error)
      print('Error checking certificate existence: ${response.statusCode}, Body: ${response.body}');
      return false;

    } catch (e) {
      print('Network error checking certificate existence: $e');
      return false;
    }
  }

  Future<void> _generateCertificate() async {
    if (_isGenerating) return; 

    // ใช้ Future.microtask เพื่อ setState ทันที
    await Future.microtask(() {
      if(mounted) { 
        setState(() {
          _isGenerating = true;
        });
      }
    });

    bool success = false;
    try {
      final url = '$_apiUrlBase/certificates/save'; // 💡 Endpoint ที่ใช้บันทึก issueDate 
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'courseId': widget.course.courseId,
          'userId': widget.userId,
          // 💡 ส่งวันที่ปัจจุบันกลับไปให้ Backend บันทึก (Backend จะจัดการ issueDate เอง)
          'issueDate': DateTime.now().toIso8601String().split('T')[0], 
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          success = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 บันทึกวันที่ออกวุฒิบัตรสำเร็จแล้ว! ระบบกำลังแสดงวุฒิบัตร')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ ไม่สามารถบันทึกวันที่ออกวุฒิบัตรได้. Status: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Network error saving issue date: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌐 เกิดข้อผิดพลาดในการเชื่อมต่อเพื่อบันทึกวันที่ออกวุฒิบัตร')),
        );
      }
    } finally {
      // เมื่อเสร็จแล้ว ให้รีเซ็ตสถานะ _isGenerating และโหลดสถานะรวมใหม่
      await Future.microtask(() {
        if(mounted) {
          setState(() {
            _isGenerating = false;
            _courseStatusFuture = _fetchCombinedCourseStatus(); 
          }); 
        }
      });
    }
  }

  Future<CourseProgressData> _fetchCombinedCourseStatus() async {
    final progress = await _fetchLastProgress();
    final hasRated = await _fetchCourseRatingStatus();
    final hasCertificate = await _checkCertificateExistence(); 
    
    return CourseProgressData(
      progress: progress, 
      hasRated: hasRated,
      hasCertificate: hasCertificate, 
    );
  }

  Future<bool> _fetchCourseRatingStatus() async {
    try {
      final url = '$_apiUrlBase/check_user_rating/${widget.userId}/${widget.course.courseId}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true; 
      } else if (response.statusCode == 404) {
        return false; 
      } 
      
      return false;

    } catch (e) {
      print('Network error fetching rating status: $e');
      return false;
    }
  }

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

  Future<void> _submitRating(int rating) async {
    try {
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

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ บันทึกคะแนนเรียบร้อยแล้ว ปุ่มเปลี่ยนเป็น "ทบทวน"')),
          );
          // 💡 [FIX] โหลดสถานะรวมใหม่เพื่อให้ปุ่มเปลี่ยน
          setState(() {
            _courseStatusFuture = _fetchCombinedCourseStatus(); 
          }); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ ไม่สามารถบันทึกคะแนนได้. Status: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Network error submitting rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🌐 เกิดข้อผิดพลาดในการเชื่อมต่อ')),
        );
      }
    }
  }

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
    
    if (selectedRating != null && selectedRating > 0) {
      await _submitRating(selectedRating);
    }
  }

  // 🎯 [FIX] ปรับปรุงการคำนวณ Index ให้ถูกต้อง
  void _navigateToVideoPage(BuildContext context, Map<String, dynamic> progress) async {
    if (widget.course.lessons.isEmpty) return;
    
    // 1. ดึงข้อมูลที่จำเป็นจาก Progress
    final int lastLessonIdFromProgress = progress['lessonId'] as int? ?? 0;
    int initialIndex = 0;
    int initialSeconds = progress['savedSeconds'] ?? 0;
    String currentStatus = progress['courseStatus'] ?? 'เรียนใหม่';

    // 2. หา Index ของบทเรียนล่าสุดที่ดู
    final int lastLessonIndexFromProgress = lastLessonIdFromProgress != 0
        ? widget.course.lessons.indexWhere((l) => l.id == lastLessonIdFromProgress)
        : -1;
    
    // 3. กำหนด Index และ Saved Seconds ที่ควรเริ่ม
    if (currentStatus == 'เรียนต่อ' && lastLessonIndexFromProgress != -1) {
      // 💡 สถานะ 'เรียนต่อ': เริ่มที่บทเรียนเดิม + ตำแหน่งที่บันทึกไว้
      initialIndex = lastLessonIndexFromProgress;
    } else if (currentStatus == 'เรียนจบ' && lastLessonIndexFromProgress != -1) {
      if (lastLessonIndexFromProgress + 1 < widget.course.lessons.length) {
        // 💡 สถานะ 'เรียนจบ' (แต่ยังมีบทต่อไป): ไปบทถัดไป (เริ่มที่ 0 วิ)
        initialIndex = lastLessonIndexFromProgress + 1;
        initialSeconds = 0;
      } else {
        // 💡 สถานะ 'เรียนจบ' (ครบทุกบท): เริ่มจากบทแรก (ทบทวน)
        initialIndex = 0;
        initialSeconds = 0;
      }
    } else { 
      // 💡 สถานะ 'เรียนใหม่' หรือ fallback: เริ่มจากบทแรก (เริ่มที่ 0 วิ)
      initialIndex = 0;
      initialSeconds = 0;
    }

    // 4. เรียก VdoPage ตัวจริง พร้อมส่งพารามิเตอร์ให้ครบ
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VdoPage(
          courseId: widget.course.courseId,
          userId: widget.userId,
          lessons: widget.course.lessons,
          initialLessonIndex: initialIndex, // 🎯 [FIX] ใช้ index ที่คำนวณ
          initialSavedSeconds: initialSeconds, // 🎯 [FIX] ใช้ seconds ที่คำนวณ
        ),
      ),
    );

    // 5. เมื่อกลับมาจาก VdoPage ให้รีเฟรชหน้า CourseDetailPage
    setState(() {
      _courseStatusFuture = _fetchCombinedCourseStatus(); 
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.courseName),
        backgroundColor: const Color(0xFF03A96B),
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
                    print('Error loading course status: ${snapshot.error}');
                    buttonText = 'มีข้อผิดพลาด';
                    isButtonEnabled = false;
                  } else if (snapshot.hasData) {
                    progressData = snapshot.data!.progress;
                    hasRated = snapshot.data!.hasRated; 

                    final status = progressData['courseStatus'];
                    final lastLessonId = progressData['lessonId'] as int?;

                    final isLastLessonInCourse = lastLessonId != null &&
                        widget.course.lessons.isNotEmpty &&
                        lastLessonId == widget.course.lessons.last.id;


                    if (hasRated) { 
                      buttonText = 'ทบทวน';
                    }
                    else if (status == 'เรียนจบ' && isLastLessonInCourse && !hasRated) {
                      buttonText = 'ให้คะแนนคอร์ส';
                    }
                    else if (status == 'เรียนต่อ' || (status == 'เรียนจบ' && !isLastLessonInCourse)) {
                      buttonText = 'เรียนต่อ';
                    } 
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
            labelColor: const Color(0xFF2E7D32), 
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
          SizedBox( 
            // 💡 [FIX] ลดขนาดความสูงลงเล็กน้อยเพื่อปรับให้เข้ากับจอได้ดีขึ้น
            height: MediaQuery.of(context).size.height * 0.65, 
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
          
          Row(
            children: [
              const Icon(Icons.menu_book, color: Color.fromARGB(255, 87, 87, 87)),
              const SizedBox(width: 8),
              Text('คำอธิบายหลักสูตร', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(widget.course.description, style: const TextStyle(fontSize: 16)),

          const Divider(height: 32),

          
          Row(
            children: [
              const Icon(Icons.my_location, color: Color.fromARGB(255, 87, 87, 87)),
              const SizedBox(width: 8),
              Text('วัตถุประสงค์การเรียนรู้', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(widget.course.objective, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

// 🎯 [FIX] แก้ไขฟังก์ชันนี้เพื่อหยุด Loop และแสดงปุ่มแทน
Widget _buildCertificateTab() {
  return FutureBuilder<CourseProgressData>(
    future: _courseStatusFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดสถานะวุฒิบัตร', style: TextStyle(color: Colors.red)));
      }

      final courseStatus = snapshot.data?.progress['courseStatus'];
      final hasRated = snapshot.data?.hasRated;
      final hasCertificate = snapshot.data?.hasCertificate ?? false; 
      
      // 1. ตรวจสอบสถานะสำเร็จ (มีวุฒิบัตรใน DB แล้ว)
      if (hasCertificate) {
        // 🎯 [FIXED] แสดงปุ่มดูวุฒิบัตรแทนการเปลี่ยนหน้าอัตโนมัติ
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 48, color: Color(0xFF2E7D32)),
              const SizedBox(height: 10),
              const Text(
                'คุณได้รับวุฒิบัตรเรียบร้อยแล้ว!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // 🎯 [FIX] นำทางไป CertificatePage เมื่อผู้ใช้กดปุ่ม
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CertificatePage(
                        courseName: widget.course.courseName,
                        courseId: widget.course.courseId,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                label: const Text(
                  'ดูวุฒิบัตร',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      }


      // 2. ยังไม่มีวุฒิบัตร: แสดงข้อความสถานะ
      String statusMessage = 'คุณจะได้รับวุฒิบัตรเมื่อเรียนจบคอร์สนี้ครบ 100% และผ่านการทดสอบ (ถ้ามี)';

      // 💡 NEW LOGIC: เรียนจบ + ให้คะแนนแล้ว (แต่ยังไม่มี record) -> Trigger การสร้างและแสดงสถานะกำลังดำเนินการ
      if (courseStatus == 'เรียนจบ' && hasRated == true) {

        if (!_isGenerating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _generateCertificate(); // 💡 เรียกฟังก์ชันบันทึกวันที่ออกวุฒิบัตร (Backend จะทำการ INSERT/DO NOTHING)
          });
        }

        // แสดงสถานะ "กำลังดำเนินการ" พร้อม CircularProgressIndicator
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF2E7D32)),
                const SizedBox(height: 20),
                const Text(
                  'ระบบกำลังดำเนินการออกวุฒิบัตรให้คุณ กรุณารอสักครู่',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  '(หน้านี้จะรีเฟรชเมื่อระบบสร้างวุฒิบัตรเสร็จสมบูรณ์)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              ],
            ),
          ),
        );

      } else if (courseStatus == 'เรียนจบ' && hasRated == false) {
        statusMessage = 'คุณเรียนจบคอร์สแล้ว! กรุณา "ให้คะแนนคอร์ส" ก่อน เพื่อดำเนินการออกวุฒิบัตร';
      }

      // สถานะอื่น ๆ (ยังเรียนไม่จบ หรือต้องให้คะแนนก่อน)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pending_actions, size: 48, color: Colors.blueGrey),
              const SizedBox(height: 10),
              const Text(
                'สถานะวุฒิบัตร/ใบรับรอง',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 5),
              Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: courseStatus == 'เรียนจบ' ? Colors.orange[800] : Colors.grey)
              ),
              const SizedBox(height: 20),
              if (courseStatus != 'เรียนจบ')
                Text(
                  'สถานะปัจจุบัน: กำลังเรียน (${courseStatus})',
                  style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                )
            ],
          ),
        ),
      );
    }
  );
}
  
  Widget _buildLessonsTab() {
    return ListView.builder(
      // กำหนด shrinkWrap และ physics เพื่อให้ทำงานใน TabBarView ได้
      shrinkWrap: true,
      // 💡 [FIX] เปลี่ยนเป็น AlwaysScrollableScrollPhysics เพื่อให้เลื่อนได้เสมอ
      physics: const AlwaysScrollableScrollPhysics(), 
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
                'savedSeconds': 0, // 🎯 [FIX] เริ่มจาก 0 สำหรับการทบทวน
                'courseStatus': 'เรียนใหม่',
              });
          },
        );
      },
    );
  }
}