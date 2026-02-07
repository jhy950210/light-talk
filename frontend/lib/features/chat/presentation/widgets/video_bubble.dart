import 'package:flutter/material.dart';
import 'video_player_screen.dart';

class VideoBubble extends StatelessWidget {
  final String videoUrl;
  final bool isMine;
  final double maxWidth;

  const VideoBubble({
    super.key,
    required this.videoUrl,
    required this.isMine,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoPlayerScreen(videoUrl: videoUrl),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        child: Container(
          width: 200,
          height: 150,
          color: Colors.black87,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 8),
                Text(
                  '동영상',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
