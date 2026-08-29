import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DetailHeader extends StatelessWidget {
  final String title;

  const DetailHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.gold : AppColors.emeraldGreen;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _rule(accentColor, toCenter: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Amiri',
                color: accentColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _rule(accentColor, toCenter: false),
        ],
      ),
    );
  }

  Widget _rule(Color accent, {required bool toCenter}) {
    final colors = [Colors.transparent, accent.withValues(alpha: 0.45)];
    return Expanded(
      child: Container(
        height: 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: toCenter ? colors : colors.reversed.toList(),
          ),
        ),
      ),
    );
  }
}
