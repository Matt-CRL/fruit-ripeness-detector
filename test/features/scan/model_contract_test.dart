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

  test('bundled v5 manifest records the MobileNetV4 + U2-Net + Heatmap contract', () {
    final manifest = ModelBundleManifest.fromJson(manifestJson);

    expect(manifest.modelSha256, hasLength(64));
    expect(manifest.modelVersion, 'mobilenetv4-fruit-v5-7ea0a20');
    expect(
      manifest.sourceCommit,
      '7ea0a20a1d09645e26d4c3c4116645da4b8b44d0',
    );
    expect(
      manifest.modelSha256,
      'd678cce9a7d3dee3475adfdde14f272f95d21e0ecb6651cd2619ebb25a5912f3',
    );
    expect(manifest.auxiliaryModel?.assetPath, 'assets/models/u2net.tflite');
    expect(
      manifest.auxiliaryModel?.sha256,
      '447287302dce2b969ca7dbf7e73e36c5e494c23d93a79f095710181b8ac271c0',
    );
    expect(manifest.input.name, 'input_tensor');
    expect(manifest.input.shape, [1, 224, 224, 3]);
    expect(manifest.input.isNchw, isFalse);
    expect(manifest.input.width, 224);
    expect(manifest.input.height, 224);
    expect(manifest.output.index, 0);
    expect(manifest.output.name, 'probabilities');
    expect(manifest.output.shape, [1, 9]);
    expect(manifest.output.interpretation, 'probabilities');
    expect(manifest.heatmapOutput?.index, 1);
    expect(manifest.heatmapOutput?.name, 'heatmap_map');
    expect(manifest.heatmapOutput?.shape, [1, 1, 7, 7]);
    expect(manifest.confidencePolicy.automaticRetakeEnabled, isTrue);
    expect(manifest.confidencePolicy.threshold, 0.75);
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

  test('probability outputs map to classification result', () {
    final manifest = ModelBundleManifest.fromJson(manifestJson);
    final result = const ModelOutputDecoder().decode(
      logits: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0],
      manifest: manifest,
    );

    expect(result.fruit, FruitIdentifier.lakatanBanana);
    expect(result.ripeness, RipenessStage.unripe);
    expect(result.modelConfidence, 1.0);
    expect(result.requiresRetake, isFalse);
    expect(result.recognitionStatus, RecognitionStatus.recognized);
  });

  test('decoder triggers low confidence gate when probability is below threshold', () {
    final manifest = ModelBundleManifest.fromJson(manifestJson);
    final result = const ModelOutputDecoder().decode(
      // Top class gets ~0.50 probability
      logits: [0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0],
      manifest: manifest,
    );

    expect(result.modelConfidence, 0.5);
    expect(result.requiresRetake, isTrue);
    expect(result.recognitionStatus, RecognitionStatus.notRecognizedOrUnclear);
  });

  test('decoder keeps heatmaps transient and rejected-only', () {
    final manifest = ModelBundleManifest.fromJson(manifestJson);
    const heatmap = ActivationHeatmap(width: 1, height: 1, values: [1]);

    final accepted = const ModelOutputDecoder().decode(
      logits: [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      manifest: manifest,
      heatmap: heatmap,
    );
    final rejected = const ModelOutputDecoder().decode(
      logits: [0.5, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0],
      manifest: manifest,
      heatmap: heatmap,
    );

    expect(accepted.heatmap, isNull);
    expect(rejected.heatmap, same(heatmap));
  });
}
