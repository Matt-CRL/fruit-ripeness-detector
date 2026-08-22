import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/data/tflite/tflite_ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled v5 heatmap model recognizes the supplied mid-gray fixture',
    () async {
      final classifier = TfliteRipenessClassifier();
      addTearDown(classifier.close);

      final result = await classifier.classify(
        'assets/models/fixtures/fruit_ripeness_v5_midgray.jpg',
      );

      expect(result.fruit, FruitIdentifier.lakatanBanana);
      expect(result.ripeness, RipenessStage.unripe);
      expect(result.modelConfidence, greaterThan(0.75));
      expect(result.modelVersion, 'mobilenetv4-fruit-enhanced-v5');
      expect(result.recognitionStatus, RecognitionStatus.recognized);
    },
    skip: Platform.isWindows
        ? 'tflite_flutter native runtime is not bundled for Windows test execution.'
        : false,
  );
}
