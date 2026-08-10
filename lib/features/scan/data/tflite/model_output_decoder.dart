import 'dart:math' as math;

import 'package:kami/features/scan/data/tflite/model_bundle_manifest.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final class ModelOutputDecoder {
  const ModelOutputDecoder();

  ClassificationResult decode({
    required List<double> logits,
    required ModelBundleManifest manifest,
  }) {
    final labels = manifest.output.orderedLabels;
    if (logits.length != labels.length || logits.isEmpty) {
      throw const ModelContractException(
        'The model output count does not match its ordered labels.',
      );
    }
    if (logits.any((value) => !value.isFinite)) {
      throw const ModelContractException(
        'The model produced a non-finite output value.',
      );
    }

    final maximum = logits.reduce(math.max);
    final exponentials = logits
        .map((value) => math.exp(value - maximum))
        .toList(growable: false);
    final sum = exponentials.fold<double>(0, (total, value) => total + value);
    if (!sum.isFinite || sum <= 0) {
      throw const ModelContractException(
        'The model output could not be converted to confidence scores.',
      );
    }

    var winningIndex = 0;
    var confidence = exponentials.first / sum;
    for (var index = 1; index < exponentials.length; index++) {
      final candidate = exponentials[index] / sum;
      if (candidate > confidence) {
        winningIndex = index;
        confidence = candidate;
      }
    }

    final modelClass = ModelOutputClass.fromId(labels[winningIndex]);
    final policy = manifest.confidencePolicy;
    final threshold = policy.automaticRetakeEnabled ? policy.threshold : null;
    final requiresRetake = threshold != null && confidence < threshold;

    return ClassificationResult(
      fruit: modelClass.fruit,
      ripeness: modelClass.ripeness,
      modelConfidence: confidence,
      modelVersion: manifest.modelVersion,
      origin: ResultOrigin.onDeviceModel,
      requiresRetake: requiresRetake,
      retakeReason: requiresRetake
          ? 'The on-device model confidence is below its validated threshold.'
          : null,
    );
  }
}

final class ModelOutputClass {
  const ModelOutputClass({required this.fruit, required this.ripeness});

  factory ModelOutputClass.fromId(String id) => switch (id) {
    'unripe-banana' => const ModelOutputClass(
      fruit: FruitIdentifier.lakatanBanana,
      ripeness: RipenessStage.unripe,
    ),
    'ripe-banana' => const ModelOutputClass(
      fruit: FruitIdentifier.lakatanBanana,
      ripeness: RipenessStage.ripe,
    ),
    'overripe-banana' => const ModelOutputClass(
      fruit: FruitIdentifier.lakatanBanana,
      ripeness: RipenessStage.overripe,
    ),
    'unripe-mango' => const ModelOutputClass(
      fruit: FruitIdentifier.carabaoMango,
      ripeness: RipenessStage.unripe,
    ),
    'ripe-mango' => const ModelOutputClass(
      fruit: FruitIdentifier.carabaoMango,
      ripeness: RipenessStage.ripe,
    ),
    'overripe-mango' => const ModelOutputClass(
      fruit: FruitIdentifier.carabaoMango,
      ripeness: RipenessStage.overripe,
    ),
    'unripe-papaya' => const ModelOutputClass(
      fruit: FruitIdentifier.redPapaya,
      ripeness: RipenessStage.unripe,
    ),
    'ripe-papaya' => const ModelOutputClass(
      fruit: FruitIdentifier.redPapaya,
      ripeness: RipenessStage.ripe,
    ),
    'overripe-papaya' => const ModelOutputClass(
      fruit: FruitIdentifier.redPapaya,
      ripeness: RipenessStage.overripe,
    ),
    _ => throw ModelContractException('Unsupported model output label "$id".'),
  };

  final FruitIdentifier fruit;
  final RipenessStage ripeness;
}
