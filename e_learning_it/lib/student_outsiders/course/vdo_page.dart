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

// คลาส Lesson
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
  // 💡 Note: ในความเป็นจริง ควรดึงข้อมูล _completedVideos จาก API ด้วย
  final Set<int> _completedVideos = {0};
  bool _isFullScreen = false;

  // 💡 ตัวแปรที่ถูกลบ/ปรับปรุง (ไม่ใช้ _initialSeekSeconds แล้ว ใช้ parameter ใน _initializeVideoPlayer แทน)

  // 💡 URL สำหรับเชื่อมต่อ API Node.js ของคุณ (POST)
  // ⚠️ กรุณาเปลี่ยน IP และ Port ให้ถูกต้อง
  final String _apiUrl = 'http://localhost:3006/api/save_progress'; 

  // 💡 [NEW] URL สำหรับดึงความคืบหน้า (GET)
  // ⚠️ กรุณาเปลี่ยน IP และ Port ให้ถูกต้อง
  final String _apiGetUrl = 'http://localhost:3006/api/get_progress'; 

  // 💡 เพิ่มตัวแปรสำหรับ Timer เพื่อบันทึกความคืบหน้าเป็นระยะ
  Timer? _saveProgressTimer;

  @override
  void initState() {
    super.initState();

    _currentVideoIndex = widget.initialLessonIndex;
    
    if (widget.lessons.isNotEmpty) {
      // 💡 [MODIFIED] เริ่มวิดีโอแรกด้วยค่า initialSavedSeconds ที่ส่งมา
      _initializeVideoPlayer(_currentVideoIndex, savedSeconds: widget.initialSavedSeconds);
    }
  }

  // 💡 [NEW FUNCTION] ดึงตำแหน่งที่บันทึกไว้สำหรับบทเรียนนั้นๆ
  Future<int> _fetchSavedProgress(String courseId, String userId, int lessonId) async {
    // ใช้ query parameters เพื่อส่งข้อมูลไปยัง API
    final uri = Uri.parse('$_apiGetUrl?courseId=$courseId&userId=$userId&lessonId=$lessonId');
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // 💡 สมมติว่า API คืนค่าเป็น JSON object ที่มี key "savedSeconds"
        // และใช้ ?? 0 เพื่อให้แน่ใจว่าได้ค่า integer หรือ 0 หากไม่พบข้อมูล
        final int savedSeconds = data['savedSeconds'] as int? ?? 0;
        print('✅ Progress fetched for lesson $lessonId: $savedSeconds seconds.');
        return savedSeconds;
      } else {
        print('❌ Failed to fetch progress. Status: ${response.statusCode}, Body: ${response.body}');
        return 0;
      }
    } catch (e) {
      print('🌐 Error fetching progress from API: $e');
      return 0;
    }
  }


  // 💡 [MODIFIED FUNCTION] รับ savedSeconds เพื่อใช้ในการ seek
  void _initializeVideoPlayer(int index, {int savedSeconds = 0}) async {
    // 💡 หยุด Timer เก่าก่อนเริ่มวิดีโอใหม่
    _saveProgressTimer?.cancel();

    if (_isControllerInitialized) {
      // 💡 บันทึกความคืบหน้าของวิดีโอเดิม ก่อนจะเปลี่ยน
      await _saveVideoProgress();
      await _controller.dispose();
      _isControllerInitialized = false;
    }

    if (widget.lessons.isEmpty || widget.lessons[index].videoUrl == null) {
      setState(() {
        _isControllerInitialized = false;
      });
      return;
    }

    final String videoUrl = widget.lessons[index].videoUrl!;
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isControllerInitialized = true;
        });

        // 💡 [MODIFIED LOGIC] ใช้ savedSeconds ที่ส่งมา (จากการ fetch หรือ initial)
        if (savedSeconds > 0) {
          print('💡 Seeking to: $savedSeconds seconds.');
          _controller.seekTo(Duration(seconds: savedSeconds));
        }

        _controller.play();

        // 💡 เริ่ม Timer เพื่อบันทึกความคืบหน้าทุก 10 วินาที
        _saveProgressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          _saveVideoProgress();
        });

      }).catchError((error) {
        print('Error initializing video: $error');
        setState(() {
          _isControllerInitialized = false;
        });
        // 💡 แสดง SnackBar แจ้งผู้ใช้เมื่อเกิดข้อผิดพลาด
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดวิดีโอ')),
        );
      });

    _controller.addListener(() {
      if (mounted && _controller.value.isInitialized) {
        // 💡 ตรวจสอบและบันทึกวิดีโอที่จบแล้ว
        if (_controller.value.position >= _controller.value.duration &&
            _controller.value.duration > Duration.zero &&
            !_completedVideos.contains(_currentVideoIndex)) {

          setState(() {
            _completedVideos.add(_currentVideoIndex);
            // ปลดล็อกวิดีโอถัดไป
            if (_currentVideoIndex + 1 < widget.lessons.length) {
              _completedVideos.add(_currentVideoIndex + 1);
            }
          });
          _saveVideoProgress(isCompleted: true); // บันทึกสถานะจบวิดีโอ
        }

        setState(() {}); // เพื่ออัปเดต UI เช่น progress bar
      }
    });
  }

  // 💡 ฟังก์ชันที่แก้ไข: บันทึกความคืบหน้าของวิดีโอไปยัง API (ไม่มีการเปลี่ยนแปลงจากก่อนหน้า)
  Future<void> _saveVideoProgress({bool isCompleted = false}) async {
    if (!_isControllerInitialized || !mounted || widget.lessons.isEmpty) return;

    final Lesson currentLesson = widget.lessons[_currentVideoIndex];
    final Duration savedPosition = _controller.value.position;
    final Duration totalDuration = _controller.value.duration;

    String status;
    if (isCompleted || savedPosition >= totalDuration) {
      status = 'เรียนจบ';
    } else if (savedPosition > const Duration(seconds: 5)) {
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
        print('✅ Progress saved successfully to API for lesson ${apiBody['lessonId']}: ${apiBody['savedSeconds']}s, Status: $status');
      } else {
        print('❌ Failed to save progress. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('🌐 Error sending progress to API: $e');
    }
  }


  // 💡 [MODIFIED FUNCTION] ดึงความคืบหน้าก่อนเล่นวิดีโอ
  void _playVideo(int index) async { // 💡 ต้องเป็น async
    final bool isUnlocked = index == 0 || _completedVideos.contains(index - 1);

    if (isUnlocked) {
      if (_currentVideoIndex != index) {

        // 💡 [NEW LOGIC] ดึงข้อมูลความคืบหน้าของบทเรียนใหม่
        final Lesson newLesson = widget.lessons[index];
        final int savedPosition = await _fetchSavedProgress(
          widget.courseId, 
          widget.userId, 
          newLesson.id
        );

        setState(() {
          _currentVideoIndex = index;
        });

        // 💡 ส่ง savedPosition ที่ดึงมาให้ initializer
        _initializeVideoPlayer(index, savedSeconds: savedPosition);
      }
    } else {
      // 💡 แสดง SnackBar แจ้งเตือนเมื่อวิดีโอยังไม่ถูกปลดล็อก
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาดูวิดีโอก่อนหน้าให้จบก่อนจึงจะดูวิดีโอนี้ได้'),
          backgroundColor: Colors.orange,
        ),
      );
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
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
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
          content: const Text('ต้องการบันทึกความคืบหน้าและกลับไปหน้าก่อนหรือไม่?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
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

    await _saveVideoProgress();
    return true;
  }

  @override
  void dispose() {
    // 💡 หยุด Timer ก่อน dispose เพื่อป้องกันการเรียกใช้หลังจาก widget หายไป
    _saveProgressTimer?.cancel();

    // 💡 บันทึกความคืบหน้าครั้งสุดท้ายก่อน dispose
    _saveVideoProgress();
    if (_isControllerInitialized) {
      _controller.dispose();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
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
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            const Center(child: CircularProgressIndicator(color: Colors.white)),

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
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(playedColor: Colors.red, bufferedColor: Colors.white54),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                  onPressed: () {
                    _seek(-10);
                  },
                ),
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                  onPressed: () {
                    _seek(10);
                  },
                ),
                Text(
                  '${_printDuration(_controller.value.position)} / ${_printDuration(_controller.value.duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),

                const Spacer(),

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
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Text(
                          '${_controller.value.playbackSpeed}x',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'วิดีโอการเรียนรู้',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
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

  Widget _buildLessonListItem(BuildContext context, int index) {
    final lesson = widget.lessons[index];
    final bool isCurrent = _currentVideoIndex == index;
    final bool isUnlocked = index == 0 || _completedVideos.contains(index - 1);

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 2,
        color: isCurrent ? Colors.lightGreen.shade50 : Colors.white,
        child: ListTile(
          leading: Icon(
            isUnlocked
              ? (_completedVideos.contains(index) ? Icons.check_circle : Icons.play_circle_fill)
              : Icons.lock,
            color: isCurrent ? const Color(0xFF2E7D32) : (isUnlocked ? Colors.lightGreen : Colors.grey),
          ),
          title: Text(
            'วิดีโอตอนที่ ${index + 1}: ${lesson.videoName}',
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? const Color(0xFF2E7D32) : Colors.black,
            ),
          ),
          subtitle: Text(lesson.videoDescription, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: isUnlocked ? () => _playVideo(index) : null,
        ),
      ),
    );
  }


  Widget _buildVideoInfoAndFiles() {
    if (widget.lessons.isEmpty) {
      return const Center(child: Text('ไม่พบข้อมูลวิดีโอและไฟล์'));
    }

    final currentLesson = widget.lessons[_currentVideoIndex];

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ไฟล์ประกอบการเรียน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (currentLesson.pdfUrl != null)
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
        ],
      ),
    );
  }
}