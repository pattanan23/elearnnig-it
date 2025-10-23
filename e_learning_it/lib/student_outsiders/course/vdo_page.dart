import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

// 💡 คลาส: สำหรับเก็บข้อมูลความคืบหน้า (Progress Node)
class VideoProgress {
  final String courseId;
  final String userId;
  final int lessonId;
  final Duration savedPosition;
  final String status; // 'เรียนต่อ', 'เรียนใหม่' หรือ 'เรียนจบ'

  VideoProgress({
    required this.courseId,
    required this.userId,
    required this.lessonId,
    required this.savedPosition,
    required this.status,
  });

  // ใช้สำหรับส่งข้อมูลไป API (ปรับ key ให้ตรงกับ Node.js API)
  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'userId': userId,
      'lessonId': lessonId,
      'savedSeconds': savedPosition.inSeconds, // ส่งเป็นวินาที
      'courseStatus': status,
    };
  }
}

// คลาส Lesson (ไม่มีการเปลี่ยนแปลง)
class Lesson {
  final int id;
  final String videoName;
  final String videoDescription;
  final String? videoUrl;
  final String? pdfUrl;

  Lesson({
    required this.id,
    required this.videoName,
    required this.videoDescription,
    this.videoUrl,
    this.pdfUrl,
  });
}

class VdoPage extends StatefulWidget {
  final String courseId;
  final String userId;
  final List<Lesson> lessons;
  final int initialLessonIndex;
  final int initialSavedSeconds;

  const VdoPage({
    Key? key,
    required this.courseId,
    required this.userId,
    required this.lessons,
    this.initialLessonIndex = 0,
    this.initialSavedSeconds = 0,
  }) : super(key: key);

  @override
  _VdoPageState createState() => _VdoPageState();
}

class _VdoPageState extends State<VdoPage> {
  late VideoPlayerController _controller;
  int _currentVideoIndex = 0;
  bool _isControllerInitialized = false;
  // 💡 ใช้ Set นี้เพื่อติดตาม Lesson Index ที่ "ดูจบแล้ว" (มี courseStatus = 'เรียนจบ')
  final Set<int> _completedVideos = {};
  bool _isFullScreen = false;

  // 📢 State ใหม่: ติดตามว่าผู้ใช้ให้คะแนนคอร์สนี้ไปแล้วหรือยัง
  bool _isCourseRated = false;

  // ⚠️ กรุณาเปลี่ยน IP และ Port ให้ถูกต้อง
  final String _apiUrl = 'http://localhost:3006/api/save_progress';

  // 📢 Endpoint ที่ใช้สำหรับดึง progress ของ Lesson เดียว
  final String _apiGetUrl = 'http://localhost:3006/api/get_progress_lesson';

  // 📢 Endpoint ที่ใช้สำหรับดึง progress ทั้งหมดของ Course
  final String _apiGetAllProgressUrl = 'http://localhost:3006/api/get_all_progress';

  // 📢 Endpoint ใหม่: สำหรับบันทึกคะแนนคอร์ส (Rate Course)
  final String _apiRateCourseUrl = 'http://localhost:3006/api/rate_course';

  // 📢 Endpoint ใหม่: สำหรับตรวจสอบสถานะการให้คะแนน
  final String _apiCheckRatingUrl = 'http://localhost:3006/api/check_user_rating';


  @override
  void initState() {
    super.initState();
    _currentVideoIndex = widget.initialLessonIndex;

    // 💡 [ADDED] ตรวจสอบสถานะการให้คะแนนทันทีเมื่อเข้าหน้า
    _checkIfUserHasRated();

    if (widget.lessons.isNotEmpty) {
      _fetchCompletedLessons(); // ดึงสถานะวิดีโอที่ดูจบแล้ว (เพื่อแสดง Checkmark)
      _initializeVideoPlayer(
          _currentVideoIndex, savedSeconds: widget.initialSavedSeconds);
    }
  }

  // 💡 [NEW FUNCTION] ฟังก์ชันสำหรับตรวจสอบสถานะการให้คะแนนของคอร์ส
  Future<void> _checkIfUserHasRated() async {
    // ✅ เรียกใช้ Endpoint /api/check_user_rating/:userId/:courseId
    final uri = Uri.parse(
        '$_apiCheckRatingUrl/${widget.userId}/${widget.courseId}');

    try {
      final response = await http.get(uri);

      if (mounted) {
        if (response.statusCode == 200) {
          // ถ้าได้ 200 OK หมายความว่าผู้ใช้เคยให้คะแนนแล้ว
          setState(() {
            _isCourseRated = true;
          });
        } else if (response.statusCode == 404) {
          // ถ้าได้ 404 Not Found หมายความว่ายังไม่เคยให้คะแนน
          setState(() {
            _isCourseRated = false;
          });
        } else {
          print(
              '❌ Failed to check rating status. Status: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('🌐 Error checking rating status: $e');
    }
  }

  // 💡 [NEW FUNCTION] ฟังก์ชันสำหรับเรียก API ให้คะแนนคอร์ส
  Future<void> _rateCourse(int rating, String? reviewText) async {
    // กำหนด reviewText ให้เป็น null ถ้าเป็นสตริงว่างเปล่า
    final String? finalReviewText =
        (reviewText == null || reviewText.trim().isEmpty) ? null : reviewText;

    try {
      final response = await http.post(
        Uri.parse(_apiRateCourseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'courseId': widget.courseId,
          'userId': widget.userId,
          'rating': rating,
          'review_text': finalReviewText,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _isCourseRated = true; // อัปเดตสถานะเป็นให้คะแนนแล้ว
          });
          ScaffoldMessenger.of(context).showSnackBar(
            // 💡 ปรับข้อความเพื่อรองรับการให้คะแนนครั้งแรกและการทบทวนคะแนน
            const SnackBar(content: Text('✅ บันทึก/อัปเดตคะแนนเรียบร้อยแล้ว!')),
          );
        }
      } else if (response.statusCode == 404) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ ไม่พบ Course ID หรือ User ID')),
          );
      } else {
        print('❌ Failed to rate course. Status: ${response.statusCode}, Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ เกิดข้อผิดพลาดในการบันทึกคะแนน: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('🌐 Error rating course: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🌐 เกิดข้อผิดพลาดในการเชื่อมต่อ')),
      );
    }
  }

  // 💡 [MODIFIED FUNCTION] ดึงสถานะการดูจบแล้ว (เพื่อแสดง Checkmark เท่านั้น)
  Future<void> _fetchCompletedLessons() async {
    final uri = Uri.parse('$_apiGetAllProgressUrl/${widget.userId}/${widget.courseId}');
    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final Set<int> completedIndices = data
            .where((item) => item['courseStatus'] == 'เรียนจบ')
            .map<int>((item) {
              // Map lessonId กลับไปเป็น index ใน List
              return widget.lessons.indexWhere((l) => l.id == item['lessonId']);
            })
            .where((index) => index != -1) // กรอง Lesson ที่หา index ไม่เจอออก
            .toSet();

        if (mounted) {
          setState(() {
            _completedVideos.clear();
            // 💡 [MODIFIED] บันทึกเฉพาะ index ที่ดูจบแล้ว
            _completedVideos.addAll(completedIndices);
          });
        }
      } else {
        print('❌ Failed to fetch all progress. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🌐 Error fetching all progress: $e');
    }
  }


  // 💡 ฟังก์ชันดึงตำแหน่งที่บันทึกไว้ (สำหรับ Lesson เดียว)
  Future<int> _fetchSavedProgress(
      String courseId, String userId, int lessonId) async {
    // ✅ เรียกใช้ Endpoint /api/get_progress_lesson/:userId/:courseId/:lessonId
    final uri =
        Uri.parse('$_apiGetUrl/$userId/$courseId/$lessonId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int savedSeconds = data['progress']['savedSeconds'] as int? ?? 0;
        return savedSeconds;
      } else if (response.statusCode == 404) {
        return 0; // ไม่พบข้อมูล
      } else {
        print('❌ Failed to fetch progress. Status: ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      print('🌐 Error fetching progress from API: $e');
      return 0;
    }
  }

  // 💡 [MODIFIED FUNCTION] จัดการ Controller และยกเลิก Timer
  void _initializeVideoPlayer(int index, {int savedSeconds = 0}) async {
    // 💡 [REMOVED] ยกเลิก Timer

    if (_isControllerInitialized) {
      // 💡 [IMPORTANT] บันทึกความคืบหน้าของวิดีโอเดิม ก่อนจะเปลี่ยน
      await _saveVideoProgress();
      await _controller.dispose();
      _isControllerInitialized = false;
    }

    if (widget.lessons.isEmpty || widget.lessons[index].videoUrl == null) {
      if (mounted) {
        setState(() {
          _isControllerInitialized = false;
        });
      }
      return;
    }

    final String videoUrl = widget.lessons[index].videoUrl!;
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isControllerInitialized = true;
          });
        }

        // ใช้ savedSeconds ที่ส่งมา
        if (savedSeconds > 0) {
          _controller.seekTo(Duration(seconds: savedSeconds));
        }

        _controller.play();

      }).catchError((error) {
        print('Error initializing video: $error');
        if (mounted) {
          setState(() {
            _isControllerInitialized = false;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดวิดีโอ')),
          );
        }
      });

    _controller.addListener(() {
      if (mounted && _controller.value.isInitialized) {
        // 💡 ตรวจสอบและบันทึกวิดีโอที่จบแล้ว (เพื่ออัปเดตสถานะการดูจบ)
        if (_controller.value.position >= _controller.value.duration &&
            _controller.value.duration > Duration.zero &&
            !_completedVideos.contains(_currentVideoIndex)) {

          _saveVideoProgress(isCompleted: true); // บันทึกสถานะจบวิดีโอ

          if (mounted) {
            setState(() {
              _completedVideos.add(_currentVideoIndex);
            });
          }
        }

        if (mounted) {
            setState(() {}); // เพื่ออัปเดต UI เช่น progress bar
        }
      }
    });
  }

  // 💡 ฟังก์ชันบันทึกความคืบหน้า (ใช้ตอนเปลี่ยนวิดีโอและตอนออกเท่านั้น)
  Future<void> _saveVideoProgress({bool isCompleted = false}) async {
    if (!mounted || widget.lessons.isEmpty) return;

    // 💡 หาก Controller ยังไม่ถูก Init หรือถูก Dispose ไปแล้ว ไม่ต้องบันทึก
    if (!_isControllerInitialized) return;

    final Lesson currentLesson = widget.lessons[_currentVideoIndex];
    final Duration savedPosition = _controller.value.position;
    final Duration totalDuration = _controller.value.duration;

    String status;
    if (isCompleted || savedPosition >= totalDuration) {
      status = 'เรียนจบ';
    } else if (savedPosition.inSeconds > 5) { // ดูไปแล้วเกิน 5 วินาที
      status = 'เรียนต่อ';
    } else {
      status = 'เรียนใหม่';
    }

    final VideoProgress progressNode = VideoProgress(
      courseId: widget.courseId,
      userId: widget.userId,
      lessonId: currentLesson.id,
      savedPosition: savedPosition,
      status: status,
    );

    final apiBody = progressNode.toJson();

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(apiBody),
      );

      if (response.statusCode == 200) {
        // print('✅ Progress saved successfully: $status for lesson ${currentLesson.id}');
      } else {
        print('❌ Failed to save progress. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('🌐 Error sending progress to API: $e');
    }
  }

  // 💡 [MODIFIED FUNCTION] นำทางและเริ่มเล่นวิดีโอที่เลือก
  void _playVideo(int index) async {
    // 💡 [REMOVED] ลบการตรวจสอบ isUnlocked

    if (_currentVideoIndex != index) {
      final Lesson newLesson = widget.lessons[index];

      // ถ้าวิดีโอถูกดูจบแล้ว (มี checkmark) ให้เริ่มจาก 0 สำหรับการทบทวน
      final bool isLessonCompleted = _completedVideos.contains(index);
      final int savedPosition = isLessonCompleted
          ? 0
          : await _fetchSavedProgress(
                widget.courseId, widget.userId, newLesson.id);

      if (mounted) {
        setState(() {
          _currentVideoIndex = index;
        });
      }

      // ส่ง savedPosition ที่ดึงมาให้ initializer
      _initializeVideoPlayer(index, savedSeconds: savedPosition);
    }
  }

  void _seek(int seconds) {
    if (_isControllerInitialized && _controller.value.isInitialized) {
      final newPosition = _controller.value.position + Duration(seconds: seconds);
      final Duration duration = _controller.value.duration;
      Duration clampedPosition;

      if (newPosition < Duration.zero) {
        clampedPosition = Duration.zero;
      } else if (newPosition > duration) {
        clampedPosition = duration;
      } else {
        clampedPosition = newPosition;
      }

      _controller.seekTo(clampedPosition);
    }
  }

  void _setPlaybackSpeed(double speed) {
    if (_isControllerInitialized && _controller.value.isInitialized) {
      _controller.setPlaybackSpeed(speed);
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  Future<bool> _onBackPressed() async {
    if (_isFullScreen) {
      _toggleFullScreen();
      return false;
    }

    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการกลับ'),
          content:
              const Text('ต้องการบันทึกความคืบหน้าและกลับไปหน้าก่อนหรือไม่?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            // 💡 บันทึกความคืบหน้าเมื่อกดยืนยันกลับ
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );

    if (shouldPop == false || shouldPop == null) {
      return false;
    }

    await _saveVideoProgress(); // 💡 [KEEP] บันทึกความคืบหน้าครั้งสุดท้ายก่อนกลับ
    return true;
  }

  @override
  void dispose() {
    // 💡 [REMOVED] ยกเลิก Timer
    _saveVideoProgress(); // 💡 [KEEP] บันทึกความคืบหน้าครั้งสุดท้าย เมื่อหน้าถูกทำลาย
    if (_isControllerInitialized) {
      _controller.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return Scaffold(body: _buildVideoPlayerSection(context));
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('หน้าเรียนวิดีโอ'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVideoPlayerSection(context),
                    if (widget.lessons.isNotEmpty) ...[
                      _buildCurrentVideoHeader(),
                      _buildVideoInfoAndFiles(),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: _buildVideoLessonsList(isMobile: true),
                      ),
                    ],
                  ],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVideoPlayerSection(context),
                        if (widget.lessons.isNotEmpty) ...[
                          _buildCurrentVideoHeader(),
                          _buildVideoInfoAndFiles(),

                        ],
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildVideoLessonsList(isMobile: false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- Widgets ---

  // 💡 [MODIFIED WIDGET] เพิ่มปุ่ม Rate Course
  Widget _buildCurrentVideoHeader() {
    final currentLesson = widget.lessons[_currentVideoIndex];

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'วิดีโอตอนที่ ${_currentVideoIndex + 1}: ${currentLesson.videoName}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        
          // 💡 สิ้นสุดส่วนที่เพิ่ม
          const SizedBox(height: 16),
          Text(
            currentLesson.videoDescription,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildVideoPlayerSection(BuildContext context) {
    return Container(
      color: Colors.black,
      width: _isFullScreen ? MediaQuery.of(context).size.width : double.infinity,
      height: _isFullScreen ? MediaQuery.of(context).size.height : 450,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (_isControllerInitialized && _controller.value.isInitialized)
            VideoPlayer(_controller)
          else
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          if (_isControllerInitialized && _controller.value.isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildVideoControls(),
            ),
        ],
      ),
    );
  }

 Widget _buildVideoControls() {
  if (!_isControllerInitialized || !_controller.value.isInitialized) {
    return const SizedBox.shrink();
  }

  return Container(
    color: Colors.black54,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. แถบ Progress Bar (ความคืบหน้า)
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(
              playedColor: Colors.red, bufferedColor: Colors.white54),
        ),
        
        // 2. แถบควบคุมวิดีโอ (ปุ่มต่างๆ)
        Padding(
          // 💡 ปรับ Padding: เพิ่มด้านข้างเป็น 16.0 และเพิ่มด้านแนวตั้งเป็น 4.0
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), 
          child: Row(
            // 💡 เปลี่ยนเป็น MainAxisAlignment.start เพื่อให้ปุ่มควบคุมหลักอยู่ชิดซ้าย
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // ปุ่มย้อนกลับ 10 วิ
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                onPressed: () {
                  _seek(-10);
                },
              ),
              
              // 💡 เพิ่มช่องว่างคงที่ระหว่างปุ่ม
              const SizedBox(width: 15.0), 
              
              // ปุ่มเล่น/หยุด
              IconButton(
                icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    // 💡 ขนาดใหญ่ขึ้นเล็กน้อยเพื่อให้โดดเด่น
                    size: 28), 
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
              
              // 💡 เพิ่มช่องว่างคงที่ระหว่างปุ่ม
              const SizedBox(width: 15.0), 
              
              // ปุ่มกรอไปข้างหน้า 10 วิ
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                onPressed: () {
                  _seek(10);
                },
              ),
              
              // 💡 เพิ่มช่องว่างให้ข้อความบอกเวลาห่างจากปุ่ม
              const SizedBox(width: 12.0), 

              // ข้อความบอกเวลา
              Text(
                '${_printDuration(_controller.value.position)} / ${_printDuration(_controller.value.duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              
              // Spacer ดันส่วนควบคุมความเร็ว/เต็มจอไปขวา
              const Spacer(), 

              // ปุ่มควบคุมความเร็ว/เต็มจอ (อยู่ทางขวา)
              Row(
                children: [
                  PopupMenuButton<double>(
                    initialValue: _controller.value.playbackSpeed,
                    onSelected: _setPlaybackSpeed,
                    itemBuilder: (context) => [
                      for (final speed in [0.5, 1.0, 1.5, 2.0])
                        PopupMenuItem(
                          value: speed,
                          child: Text('${speed}x'),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 8.0),
                      child: Text(
                        '${_controller.value.playbackSpeed}x',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                        _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white),
                    onPressed: _toggleFullScreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Widget _buildVideoLessonsList({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'วิดีโอการเรียนรู้',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // 💡 ใช้ Expanded เฉพาะในโหมด Desktop/Tablet (isMobile: false)
          isMobile
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.lessons.length,
                  itemBuilder: _buildLessonListItem,
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: widget.lessons.length,
                    itemBuilder: _buildLessonListItem,
                  ),
                ),
        ],
      ),
    );
  }

  // 💡 [MODIFIED WIDGET] ยกเลิกการตรวจสอบการปลดล็อค และปรับ UI
  Widget _buildLessonListItem(BuildContext context, int index) {
    final lesson = widget.lessons[index];
    final bool isCurrent = _currentVideoIndex == index;
    // 💡 บทเรียนทั้งหมดเข้าถึงได้
    final bool isFinishedWatching = _completedVideos.contains(index);

    // 💡 [MODIFIED] ใช้ Card และ ListTile เพื่อให้ดูดีขึ้น
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: isCurrent ? 4 : 1,
      color: isCurrent ? Colors.lightGreen.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(
          isFinishedWatching
              ? Icons.check_circle_outline // ดูจบแล้ว (Checkmark)
              : Icons.play_circle_fill_outlined, // ยังไม่จบ (Play Icon)
          color: isCurrent
              ? const Color(0xFF2E7D32)
              : (isFinishedWatching ? Colors.lightGreen.shade700 : Colors.grey.shade600),
        ),
        title: Text(
          'วิดีโอตอนที่ ${index + 1}: ${lesson.videoName}',
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? const Color(0xFF2E7D32) : Colors.black,
          ),
        ),
        subtitle:
            Text(lesson.videoDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
        // 💡 [MODIFIED] สามารถกดได้เสมอ
        onTap: () => _playVideo(index),
      ),
    );
  }

  Widget _buildVideoInfoAndFiles() {
    if (widget.lessons.isEmpty) {
      return const Center(child: Text('ไม่พบข้อมูลวิดีโอและไฟล์'));
    }

    final currentLesson = widget.lessons[_currentVideoIndex];

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 0.0), // ลด bottom padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ไฟล์ประกอบการเรียน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (currentLesson.pdfUrl != null && currentLesson.pdfUrl!.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text(currentLesson.pdfUrl!.split('/').last),
              onTap: () async {
                final Uri uri = Uri.parse(currentLesson.pdfUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ไม่สามารถเปิดไฟล์ PDF ได้')),
                  );
                }
              },
            )
          else
            const Text('ไม่พบไฟล์ประกอบการเรียนสำหรับวิดีโอนี้'),
          const Divider(height: 16), // เพิ่ม Divider คั่นระหว่างไฟล์กับปุ่ม
        ],
      ),
    );
  }
}