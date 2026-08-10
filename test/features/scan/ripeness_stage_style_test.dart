import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/ripeness_stage_style.dart';

void main() {
  test('each ripeness stage has a distinct labeled-color presentation', () {
    final unripe = ripenessStageStyle(RipenessStage.unripe);
    final ripe = ripenessStageStyle(RipenessStage.ripe);
    final overripe = ripenessStageStyle(RipenessStage.overripe);

    expect(unripe.accent, AppColors.unripeGreen);
    expect(unripe.icon, Icons.eco_outlined);
    expect(ripe.accent, AppColors.ripeYellow);
    expect(ripe.icon, Icons.check_circle_outline);
    expect(overripe.accent, AppColors.overripeOrange);
    expect(overripe.icon, Icons.warning_amber_rounded);
    expect({unripe.background, ripe.background, overripe.background}.length, 3);
  });
}
