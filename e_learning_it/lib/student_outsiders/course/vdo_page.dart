import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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

  const VdoPage({
    Key? key,
    required this.courseId,
    required this.userId,
    required this.lessons,
  }) : super(key: key);

  @override
  _VdoPageState createState() => _VdoPageState();
}

class _VdoPageState extends State<VdoPage> {
  late VideoPlayerController _controller;
  int _currentVideoIndex = 0;
  bool _isControllerInitialized = false;
  // bool _showControls = true; // ✅ ไม่ต้องใช้แล้ว
  // Timer? _timer; // ✅ ไม่ต้องใช้แล้ว
  final Set<int> _completedVideos = {}; 
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    if (widget.lessons.isNotEmpty) {
      _initializeVideoPlayer(_currentVideoIndex);
    }
  }

  void _initializeVideoPlayer(int index) async {
    if (_isControllerInitialized) {
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
          // _showControls = true; // ✅ ไม่ต้องกำหนดอีกแล้ว
        });
        _controller.play();
        // _startHideControlsTimer(); // ✅ ลบออก
      }).catchError((error) {
        print('Error initializing video: $error');
        setState(() {
          _isControllerInitialized = false;
        });
      });

    _controller.addListener(() {
      if (mounted && _controller.value.isInitialized) {
        setState(() {}); 
        if (_controller.value.position >= _controller.value.duration && !_completedVideos.contains(_currentVideoIndex)) {
          setState(() {
            _completedVideos.add(_currentVideoIndex);
            // _showControls = true; // ✅ ไม่ต้องกำหนดอีกแล้ว
          });
        }
      }
    });
  }

  // ✅ ลบเมธอดที่เกี่ยวข้องกับการซ่อน/แสดงแถบควบคุม
  /*
  void _startHideControlsTimer() {
    _timer?.cancel();
    if (_isControllerInitialized && _controller.value.isPlaying) {
      _timer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _isControllerInitialized && _controller.value.isPlaying) {
      _startHideControlsTimer();
    } else {
      _timer?.cancel();
    }
  }
  */

  void _playVideo(int index) {
    if (_currentVideoIndex != index) {
      final bool isPreviousVideoCompleted = _completedVideos.contains(index - 1);
      final bool isFirstVideo = index == 0;
      final bool isViewingPreviousVideo = index < _currentVideoIndex;
      
      if (isFirstVideo || isViewingPreviousVideo || isPreviousVideoCompleted) {
        setState(() {
          _currentVideoIndex = index;
        });
        _initializeVideoPlayer(index);
      }
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
      // _startHideControlsTimer(); // ✅ ลบออก
    }
  }

  void _setPlaybackSpeed(double speed) {
    if (_isControllerInitialized && _controller.value.isInitialized) {
      _controller.setPlaybackSpeed(speed);
      // _startHideControlsTimer(); // ✅ ลบออก
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

  @override
  void dispose() {
    // _timer?.cancel(); // ✅ ลบออก
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
    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(
        title: const Text('หน้าเรียนวิดีโอ'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: _isFullScreen
          ? _buildVideoPlayerSection(context)
          : LayoutBuilder(
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
    // ✅ ส่วนที่ถูกแก้ไข
    return Container(
      color: Colors.black,
      width: _isFullScreen ? MediaQuery.of(context).size.width : double.infinity,
      height: _isFullScreen ? MediaQuery.of(context).size.height : 450, // ✅ กำหนดความสูงคงที่
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (_isControllerInitialized && _controller.value.isInitialized)
            VideoPlayer(_controller)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          
          if (_isControllerInitialized && _controller.value.isInitialized)
            // ✅ แถบควบคุมที่แสดงตลอดเวลา
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
                    // _startHideControlsTimer(); // ✅ ลบออก
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
                      // _startHideControlsTimer(); // ✅ ลบออก
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                  onPressed: () {
                    _seek(10);
                    // _startHideControlsTimer(); // ✅ ลบออก
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
            isUnlocked ? (isCurrent ? Icons.play_circle_fill : Icons.check_circle) : Icons.lock,
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