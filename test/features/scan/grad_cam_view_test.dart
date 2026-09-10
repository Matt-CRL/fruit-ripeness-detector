import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/presentation/grad_cam_view.dart';

void main() {
  testWidgets('legend and fallback painter identify green as high attention', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GradCamExplanationCard())),
    );

    expect(find.text('High Attention (Green)'), findsOneWidget);
    expect(find.text('Lowest Attention (Blue)'), findsOneWidget);
    expect(heatmapColor(1), const Color(0xff00c853));
    expect(heatmapColor(0), const Color(0xff1555d1));
  });
}
