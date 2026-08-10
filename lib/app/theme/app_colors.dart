import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brandGreen = Color(0xFF2F6B3C);
  static const softBrandGreen = Color(0xFFE8F2E7);

  static const unripeGreen = Color(0xFF67A84A);
  static const unripeSurface = Color(0xFFEDF7E8);
  static const ripeYellow = Color(0xFFF2C94C);
  static const ripeSurface = Color(0xFFFFF6CC);
  static const overripeOrange = Color(0xFFE77A22);
  static const overripeSurface = Color(0xFFFFF0E3);

  static const surface = Color(0xFFFFFFFF);
  static const pageBackground = surface;
  static const softShadow = Color(0x1F1F271F);
  static const navigationInactive = Color(0xFFB4BAB5);
  static const primaryText = Color(0xFF1F271F);
  static const secondaryText = Color(0xFF566056);
  static const softOutline = Color(0xFFDCE4DA);

  // Dark-mode surfaces keep the same forest-green identity while giving
  // content enough contrast for comfortable evening use.
  static const darkBrandGreen = Color(0xFFA4E6A9);
  static const darkSoftBrandGreen = Color(0xFF285A34);
  static const darkUnripeSurface = Color(0xFF203A24);
  static const darkRipeSurface = Color(0xFF453D13);
  static const darkOverripeSurface = Color(0xFF4A2810);
  static const darkSurface = Color(0xFF1A211C);
  static const darkPageBackground = Color(0xFF101410);
  static const darkSoftShadow = Color(0x66000000);
  static const darkNavigationInactive = Color(0xFF9AA79D);
  static const darkPrimaryText = Color(0xFFF0F5EF);
  static const darkSecondaryText = Color(0xFFB8C4BA);
  static const darkSoftOutline = Color(0xFF465448);
}
