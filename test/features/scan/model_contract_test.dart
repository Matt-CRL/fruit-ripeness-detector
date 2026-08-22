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
      File('assets/models/fruit_ripeness_v5.manifest.json').readAsStringSync(),
    );
  });

  test('bundled v5 manifest records the MobileNetV4 + U2-Net contract', () {
    final manifest = ModelBundleManifest.fromJson(manifestJson);

    expect(manifest.modelSha256, hasLength(64));
    expect(manifest.modelVersion, 'mobilenetv4-fruit-enhanced-v5');
    expect(
      manifest.modelSha256,
      'a767f4985df034612ed19e1dd601980a1cbc6af8a35350e4f422caf5b90ea572',
    );
    expect(manifest.auxiliaryModel?.assetPath, 'assets/models/u2net.tflite');
    expect(
      manifest.auxiliaryModel?.sha256,
      '447287302dce2b969ca7dbf7e73e36c5e494c23d93a79f095710181b8ac271c0',
    );
    expect(manifest.input.name, 'serving_default_args_0');
    expect(manifest.input.shape, [1, 3, 224, 224]);
    expect(manifest.input.isNchw, isTrue);
    expect(manifest.input.width, 224);
    expect(manifest.input.height, 224);
    expect(manifest.output.index, 0);
    expect(manifest.output.name, 'serving_default_output_0_output');
    expect(manifest.output.shape, [1, 9]);
    expect(manifest.output.interpretation, 'logits');
  });

  test('manifest rejects incomplete ordered labels', () {
    final output = manifestJson['classificationOutput'] as Map<String, dynamic>;
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

  test('manifest rejects invalid auxiliary sha256', () {
    final aux = manifestJson['auxiliaryModel'] as Map<String, dynamic>;
    aux['sha256'] = 'invalid_hash';

    expect(
      () => ModelBundleManifest.fromJson(manifestJson),
      throwsA(isA<ModelContractException>()),
    );
  });

  test('logits outputs are converted to probabilities using stable Softmax', () {
    final manifest = ModelBundleManifest.fromJson(manifestJson);
    final result = const ModelOutputDecoder().decode(
      logits: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 10.0, 0.0, 0.0],
      manifest: manifest,
    );

    expect(result.fruit, FruitIdentifier.lakatanBanana);
    expect(result.ripeness, RipenessStage.unripe);
    expect(result.modelConfidence, greaterThan(0.99));
    expect(result.requiresRetake, isFalse);
    expect(result.recognitionStatus, RecognitionStatus.recognized);
  });
}
