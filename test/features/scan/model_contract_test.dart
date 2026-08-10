import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/data/tflite/model_bundle_manifest.dart';
import 'package:kami/features/scan/data/tflite/model_output_decoder.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

void main() {
  late Map<String, dynamic> manifestJson;

  setUp(() {
    manifestJson = jsonDecode(
      File(
        'assets/models/mobilenetv4_fruit_float32.manifest.json',
      ).readAsStringSync(),
    );
  });

  test('bundled manifest records the reviewed FLOAT32 contract', () {
    final manifest = ModelBundleManifest.fromJson(manifestJson);

    expect(manifest.modelSha256, hasLength(64));
    expect(manifest.modelVersion, 'mobilenetv4-fruit-enhanced-b11167b');
    expect(
      manifest.modelSha256,
      '5f131720b8d4b820ec9584e4f8ffab9ac2951e1e8d145363070bf5f2afcca5a2',
    );
    expect(manifest.input.name, 'input');
    expect(manifest.input.shape, [1, 224, 224, 3]);
    expect(manifest.output.name, 'output');
    expect(manifest.output.shape, [1, 9]);
    expect(manifest.output.orderedLabels, [
      'overripe-banana',
      'overripe-mango',
      'overripe-papaya',
      'ripe-banana',
      'ripe-mango',
      'ripe-papaya',
      'unripe-banana',
      'unripe-mango',
      'unripe-papaya',
    ]);
    expect(manifest.confidencePolicy.automaticRetakeEnabled, isFalse);
    expect(manifest.confidencePolicy.threshold, isNull);
  });

  test('manifest rejects incomplete ordered labels', () {
    final output = manifestJson['output'] as Map<String, dynamic>;
    output['orderedLabels'] = <String>[
      ...supportedModelOutputLabels.where(
        (label) => label != 'overripe-papaya',
      ),
      'ripe-dragonfruit',
    ];

    expect(
      () => ModelBundleManifest.fromJson(manifestJson),
      throwsA(isA<ModelContractException>()),
    );
  });

  test('manifest rejects enabled confidence policy without threshold', () {
    final policy = manifestJson['confidencePolicy'] as Map<String, dynamic>;
    policy['automaticRetakeEnabled'] = true;

    expect(
      () => ModelBundleManifest.fromJson(manifestJson),
      throwsA(isA<ModelContractException>()),
    );
  });

  test('stable Softmax maps all nine ordered outputs', () {
    final manifest = ModelBundleManifest.fromJson(manifestJson);
    const decoder = ModelOutputDecoder();
    final expected = <(FruitIdentifier, RipenessStage)>[
      (FruitIdentifier.lakatanBanana, RipenessStage.overripe),
      (FruitIdentifier.carabaoMango, RipenessStage.overripe),
      (FruitIdentifier.redPapaya, RipenessStage.overripe),
      (FruitIdentifier.lakatanBanana, RipenessStage.ripe),
      (FruitIdentifier.carabaoMango, RipenessStage.ripe),
      (FruitIdentifier.redPapaya, RipenessStage.ripe),
      (FruitIdentifier.lakatanBanana, RipenessStage.unripe),
      (FruitIdentifier.carabaoMango, RipenessStage.unripe),
      (FruitIdentifier.redPapaya, RipenessStage.unripe),
    ];

    for (var winningIndex = 0; winningIndex < expected.length; winningIndex++) {
      final logits = List<double>.filled(expected.length, -1000);
      logits[winningIndex] = 1000;
      final result = decoder.decode(logits: logits, manifest: manifest);

      expect(result.fruit, expected[winningIndex].$1);
      expect(result.ripeness, expected[winningIndex].$2);
      expect(result.modelConfidence, closeTo(1, 1e-12));
      expect(result.origin, ResultOrigin.onDeviceModel);
      expect(result.requiresRetake, isFalse);
    }
  });

  test('validated confidence threshold produces a tentative result', () {
    final policy = manifestJson['confidencePolicy'] as Map<String, dynamic>;
    policy['automaticRetakeEnabled'] = true;
    policy['threshold'] = 0.8;
    final manifest = ModelBundleManifest.fromJson(manifestJson);

    final result = const ModelOutputDecoder().decode(
      logits: List<double>.filled(9, 0),
      manifest: manifest,
    );

    expect(result.modelConfidence, closeTo(1 / 9, 1e-12));
    expect(result.requiresRetake, isTrue);
    expect(result.retakeReason, isNotNull);
  });
}
