import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'online_indicator.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool showOnlineIndicator;
  final bool isOnline;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 24,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatar = imageUrl != null && imageUrl!.isNotEmpty
        ? CircleAvatar(
            radius: radius,
            backgroundImage: NetworkImage(imageUrl!),
            backgroundColor: AppTheme.surfaceLight,
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: AppTheme.primaryLight.withOpacity(0.3),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryDark,
              ),
            ),
          );

    if (!showOnlineIndicator) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: OnlineIndicator(
            isOnline: isOnline,
            size: radius * 0.5,
          ),
        ),
      ],
    );
  }
}
