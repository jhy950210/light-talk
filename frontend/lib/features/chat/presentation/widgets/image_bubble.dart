import 'package:flutter/material.dart';
import 'full_screen_image_viewer.dart';

class ImageBubble extends StatelessWidget {
  final String imageUrl;
  final bool isMine;
  final double maxWidth;

  const ImageBubble({
    super.key,
    required this.imageUrl,
    required this.isMine,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(imageUrl: imageUrl),
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: 300,
          ),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 150,
                color: Colors.grey.shade200,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 150,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
