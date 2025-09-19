// In the VdoPage.dart file

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class VdoPage extends StatefulWidget {
  final String courseId;
  final String userId;
  final List<String> videoFileNames;

  const VdoPage({
    Key? key,
    required this.courseId,
    required this.userId,
    required this.videoFileNames,
  }) : super(key: key);

  @override
  _VdoPageState createState() => _VdoPageState();
}

class _VdoPageState extends State<VdoPage> {
  late VideoPlayerController _controller;
  int _currentVideoIndex = 0;
  bool _isControllerInitialized = false;
  bool _showControls = true;
  Timer? _timer;
  final Set<int> _completedVideos = {-1}; // Use a different initial value to lock the first video
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    // Start with the first video unlocked
    _completedVideos.add(-1); 
    if (widget.videoFileNames.isNotEmpty) {
      _initializeVideoPlayer(_currentVideoIndex);
    }
  }

  void _initializeVideoPlayer(int index) async {
    if (_isControllerInitialized) {
      await _controller.dispose();
    }

    if (widget.videoFileNames.isEmpty) {
      setState(() {
        _isControllerInitialized = false;
      });
      return;
    }

    final String fileName = widget.videoFileNames[index];
    final String videoUrl = 'http://localhost:3006/data/${widget.userId}/${widget.courseId}/vdo/$fileName';

    _controller = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isControllerInitialized = true;
          _showControls = true;
        });
        _controller.play();
        _startHideControlsTimer();
      }).catchError((error) {
        print('Error initializing video: $error');
        setState(() {
          _isControllerInitialized = false;
        });
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration && !_completedVideos.contains(_currentVideoIndex)) {
        setState(() {
          _completedVideos.add(_currentVideoIndex);
          _showControls = true;
        });
      }
    });
  }

  void _startHideControlsTimer() {
    _timer?.cancel();
    if (_controller.value.isPlaying) {
      _timer = Timer(const Duration(seconds: 2), () {
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
    if (_showControls && _controller.value.isPlaying) {
      _startHideControlsTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _playVideo(int index) {
    if (_currentVideoIndex != index) {
      // Check if the previous video is in the completed list.
      final bool previousVideoCompleted = _completedVideos.contains(index - 1);
      
      // Allow playing the current or a previous video.
      if (previousVideoCompleted || index < _currentVideoIndex) {
        setState(() {
          _currentVideoIndex = index;
        });
        _initializeVideoPlayer(index);
      }
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
    _timer?.cancel();
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
      ),
      body: Column(
        children: [
          // Video Player Section
          MouseRegion(
            onHover: (event) {
              if (!_showControls) {
                _toggleControlsVisibility();
              }
            },
            onExit: (event) {
              if (_showControls && _controller.value.isPlaying) {
                _startHideControlsTimer();
              }
            },
            child: GestureDetector(
              onTap: _toggleControlsVisibility,
              child: Container(
                color: Colors.black,
                height: _isFullScreen ? MediaQuery.of(context).size.height : 250,
                child: Center(
                  child: _isControllerInitialized
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: _controller.value.size?.width ?? 0,
                                  height: _controller.value.size?.height ?? 0,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: _showControls ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: IconButton(
                                icon: Icon(
                                  _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                  size: 80,
                                  color: Colors.white54,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                    _startHideControlsTimer();
                                  });
                                },
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: IconButton(
                                icon: Icon(
                                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: _toggleFullScreen,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: VideoProgressIndicator(_controller, allowScrubbing: true),
                            ),
                          ],
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            ),
          ),
          if (!_isFullScreen) ...[
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.videoFileNames.length,
                itemBuilder: (context, index) {
                  final bool isCurrent = _currentVideoIndex == index;
                  final bool isUnlocked = index == 0 || _completedVideos.contains(index - 1);

                  return Opacity(
                    opacity: isUnlocked ? 1.0 : 0.5,
                    child: ListTile(
                      leading: Icon(
                        isUnlocked ? Icons.play_circle_fill : Icons.lock,
                        color: isCurrent ? const Color(0xFF2E7D32) : Colors.grey,
                      ),
                      title: Text(
                        'ตอนที่ ${index + 1}',
                        style: TextStyle(
                          color: isCurrent ? const Color(0xFF2E7D32) : Colors.grey,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: isUnlocked ? () => _playVideo(index) : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}