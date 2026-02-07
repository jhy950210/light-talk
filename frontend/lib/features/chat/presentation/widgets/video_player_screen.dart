import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.play();
      }).catchError((_) {
        setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _hasError
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white54, size: 64),
                  SizedBox(height: 12),
                  Text(
                    '동영상을 재생할 수 없습니다',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              )
            : !_isInitialized
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                      const SizedBox(height: 16),
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white10,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}
