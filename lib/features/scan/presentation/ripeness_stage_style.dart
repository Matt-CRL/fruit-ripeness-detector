import 'package:flutter/material.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

@immutable
final class RipenessStageStyle {
  const RipenessStageStyle({
    required this.accent,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color accent;
  final Color background;
  final Color foreground;
  final IconData icon;
}

RipenessStageStyle ripenessStageStyle(
  RipenessStage stage, {
  Brightness brightness = Brightness.light,
}) {
  final isDark = brightness == Brightness.dark;
  return switch (stage) {
    RipenessStage.unripe => RipenessStageStyle(
      accent: isDark ? const Color(0xFF9FE870) : AppColors.unripeGreen,
      background: isDark
          ? AppColors.darkUnripeSurface
          : AppColors.unripeSurface,
      foreground: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      icon: Icons.eco_outlined,
    ),
    RipenessStage.ripe => RipenessStageStyle(
      accent: isDark ? const Color(0xFFFFD95A) : AppColors.ripeYellow,
      background: isDark ? AppColors.darkRipeSurface : AppColors.ripeSurface,
      foreground: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      icon: Icons.check_circle_outline,
    ),
    RipenessStage.overripe => RipenessStageStyle(
      accent: isDark ? const Color(0xFFFFA15C) : AppColors.overripeOrange,
      background: isDark
          ? AppColors.darkOverripeSurface
          : AppColors.overripeSurface,
      foreground: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      icon: Icons.warning_amber_rounded,
    ),
  };
}
