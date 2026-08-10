import 'package:flutter/material.dart';
import 'package:kami/app/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final seededScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandGreen,
      brightness: Brightness.light,
      surface: AppColors.surface,
    );
    final colorScheme = seededScheme.copyWith(
      primary: AppColors.brandGreen,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.softBrandGreen,
      onPrimaryContainer: AppColors.primaryText,
      secondary: AppColors.ripeYellow,
      onSecondary: AppColors.primaryText,
      secondaryContainer: AppColors.ripeSurface,
      onSecondaryContainer: AppColors.primaryText,
      tertiary: AppColors.overripeOrange,
      onTertiary: AppColors.primaryText,
      tertiaryContainer: AppColors.overripeSurface,
      onTertiaryContainer: AppColors.primaryText,
      onSurface: AppColors.primaryText,
      onSurfaceVariant: AppColors.navigationInactive,
      outline: AppColors.softOutline,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      pageBackground: AppColors.pageBackground,
      surface: AppColors.surface,
      primaryText: AppColors.primaryText,
      secondaryText: AppColors.secondaryText,
      outline: AppColors.softOutline,
      shadow: AppColors.softShadow,
      primary: AppColors.brandGreen,
      primaryContainer: AppColors.softBrandGreen,
    );
  }

  static ThemeData dark() {
    final seededScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandGreen,
      brightness: Brightness.dark,
      surface: AppColors.darkSurface,
    );
    final colorScheme = seededScheme.copyWith(
      primary: AppColors.darkBrandGreen,
      onPrimary: AppColors.darkPageBackground,
      primaryContainer: AppColors.darkSoftBrandGreen,
      onPrimaryContainer: AppColors.darkPrimaryText,
      secondary: AppColors.ripeYellow,
      onSecondary: AppColors.primaryText,
      secondaryContainer: const Color(0xFF514713),
      onSecondaryContainer: AppColors.darkPrimaryText,
      tertiary: AppColors.overripeOrange,
      onTertiary: AppColors.primaryText,
      tertiaryContainer: const Color(0xFF5A2D0E),
      onTertiaryContainer: AppColors.darkPrimaryText,
      surface: AppColors.darkSurface,
      surfaceContainerHighest: const Color(0xFF29332B),
      onSurface: AppColors.darkPrimaryText,
      onSurfaceVariant: AppColors.darkSecondaryText,
      outline: AppColors.darkSoftOutline,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      pageBackground: AppColors.darkPageBackground,
      surface: AppColors.darkSurface,
      primaryText: AppColors.darkPrimaryText,
      secondaryText: AppColors.darkSecondaryText,
      outline: AppColors.darkSoftOutline,
      shadow: AppColors.darkSoftShadow,
      primary: AppColors.darkBrandGreen,
      primaryContainer: AppColors.darkSoftBrandGreen,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color pageBackground,
    required Color surface,
    required Color primaryText,
    required Color secondaryText,
    required Color outline,
    required Color shadow,
    required Color primary,
    required Color primaryContainer,
  }) {
    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w800,
        height: 1.12,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: primaryText,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        color: primaryText,
        fontSize: 17,
        height: 1.45,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        color: primaryText,
        fontSize: 15,
        height: 1.45,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        color: primaryText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pageBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: pageBackground,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: shadow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: outline, width: 0.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: surface,
        indicatorColor: primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? primary
                : secondaryText,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: BorderSide(color: outline),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: primaryText,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
