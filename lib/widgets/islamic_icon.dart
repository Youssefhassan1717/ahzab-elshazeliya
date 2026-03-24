import 'package:flutter/material.dart';

class IslamicIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool withBackground;
  final bool isDark;

  const IslamicIcon({
    super.key,
    required this.size,
    required this.color,
    this.withBackground = false,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.mosque,
      color: color,
      size: size * 0.6,
    );

    if (withBackground) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Center(child: icon),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: icon),
    );
  }
}
