import 'dart:typed_data';

enum FruitIdentifier {
  carabaoMango('Carabao mango'),
  lakatanBanana('Lakatan banana'),
  redPapaya('Red papaya');

  const FruitIdentifier(this.displayName);

  final String displayName;
}

enum RipenessStage {
  unripe('Unripe'),
  ripe('Ripe'),
  overripe('Overripe');

  const RipenessStage(this.displayName);

  final String displayName;
}

enum ResultOrigin { demo, onDeviceModel }

enum RecognitionStatus { recognized, notRecognizedOrUnclear }

final class ActivationHeatmap {
  const ActivationHeatmap({
    required this.width,
    required this.height,
    required this.values,
  });

  final int width;
  final int height;
  final List<double> values;

  double valueAt(int x, int y) => values[y * width + x];
}

final class SelectedScanImage {
  const SelectedScanImage({required this.path, required this.name})
    : assert(path != ''),
      assert(name != '');

  final String path;
  final String name;
}

final class ClassificationResult {
  const ClassificationResult({
    required this.fruit,
    required this.ripeness,
    required this.modelConfidence,
    required this.modelVersion,
    required this.origin,
    required this.requiresRetake,
    this.retakeReason,
    this.recognitionStatus = RecognitionStatus.recognized,
    this.heatmap,
    this.isolatedImageBytes,
    this.gradCamImageBytes,
  }) : assert(modelConfidence >= 0 && modelConfidence <= 1);

  final FruitIdentifier fruit;
  final RipenessStage ripeness;
  final double modelConfidence;
  final String modelVersion;
  final ResultOrigin origin;
  final bool requiresRetake;
  final String? retakeReason;
  final RecognitionStatus recognitionStatus;
  final ActivationHeatmap? heatmap;
  final Uint8List? isolatedImageBytes;
  final Uint8List? gradCamImageBytes;
}

sealed class ShelfLifeEstimate {
  const ShelfLifeEstimate();
}

const shelfLifeVariabilityDisclaimer =
    'Actual fruit quality may vary depending on maturity, temperature, '
    'handling, and storage conditions.';

final class ShelfLifeRange extends ShelfLifeEstimate {
  const ShelfLifeRange({
    required this.minimum,
    required this.maximum,
    required this.unit,
    required this.storageGuidance,
    required this.evidenceVersion,
  });

  final int minimum;
  final int maximum;
  final String unit;
  final String storageGuidance;
  final String evidenceVersion;
}

final class ShelfLifeConsumeImmediately extends ShelfLifeEstimate {
  const ShelfLifeConsumeImmediately({
    required this.storageGuidance,
    required this.evidenceVersion,
  });

  final String storageGuidance;
  final String evidenceVersion;
}

final class ShelfLifeUnavailable extends ShelfLifeEstimate {
  const ShelfLifeUnavailable({
    required this.reason,
    required this.evidenceVersion,
  });

  final String reason;
  final String evidenceVersion;
}

final class ScanPreview {
  const ScanPreview({
    required this.image,
    required this.classification,
    required this.shelfLife,
  });

  final SelectedScanImage image;
  final ClassificationResult classification;
  final ShelfLifeEstimate shelfLife;
}
