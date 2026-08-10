import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/app/theme/app_theme.dart';

void main() {
  test('light theme exposes the approved visual foundation', () {
    final theme = AppTheme.light();

    expect(theme.colorScheme.primary, AppColors.brandGreen);
    expect(theme.colorScheme.primaryContainer, AppColors.softBrandGreen);
    expect(theme.colorScheme.secondary, AppColors.ripeYellow);
    expect(theme.colorScheme.tertiary, AppColors.overripeOrange);
    expect(theme.scaffoldBackgroundColor, AppColors.surface);
    expect(theme.cardTheme.color, AppColors.surface);
    expect(theme.cardTheme.elevation, greaterThan(0));
    expect(theme.cardTheme.shadowColor, AppColors.softShadow);
  });

  test('ripeness colors stay distinct from the brand color', () {
    expect(AppColors.unripeGreen, isNot(AppColors.brandGreen));
    expect(AppColors.ripeYellow, isNot(AppColors.unripeGreen));
    expect(AppColors.overripeOrange, isNot(AppColors.ripeYellow));
  });

  test('light theme keeps readable foregrounds on stage colors', () {
    final theme = AppTheme.light();

    expect(theme.colorScheme.onSecondary, AppColors.primaryText);
    expect(theme.colorScheme.onTertiary, AppColors.primaryText);
    expect(theme.brightness, Brightness.light);
  });

  test('dark theme keeps the green brand with dark application surfaces', () {
    final theme = AppTheme.dark();

    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, AppColors.darkBrandGreen);
    expect(theme.scaffoldBackgroundColor, AppColors.darkPageBackground);
    expect(theme.cardTheme.color, AppColors.darkSurface);
    expect(theme.colorScheme.onSurface, AppColors.darkPrimaryText);
  });
}
