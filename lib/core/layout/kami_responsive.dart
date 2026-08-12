import 'package:flutter/material.dart';

/// Shared portrait-phone layout thresholds and compact spacing values.
///
/// The compact breakpoint models the smallest supported physical-phone
/// viewport without changing system text scaling or interactive control sizes.
abstract final class KamiResponsive {
  static bool isCompactPhone(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide <= 600 &&
        (size.width <= 380 || size.height <= 820);
  }

  static double value(
    BuildContext context, {
    required double regular,
    required double compact,
  }) {
    return isCompactPhone(context) ? compact : regular;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double top = 8,
    double bottom = 36,
  }) {
    final horizontal = value(context, regular: 20, compact: 12);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }
}
