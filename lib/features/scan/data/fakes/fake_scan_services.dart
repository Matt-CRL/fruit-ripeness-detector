import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final class FakeRipenessClassifier implements RipenessClassifier {
  const FakeRipenessClassifier();

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    final requiresRetake = imagePath == 'fake://retake';
    final unrecognized = imagePath == 'fake://unrecognized';

    return ClassificationResult(
      fruit: FruitIdentifier.carabaoMango,
      ripeness: RipenessStage.ripe,
      modelConfidence: requiresRetake
          ? 0.31
          : unrecognized
          ? 0.42
          : 0.87,
      modelVersion: 'fake-foundation-v1',
      origin: ResultOrigin.demo,
      requiresRetake: requiresRetake || unrecognized,
      retakeReason: requiresRetake
          ? 'The demo classifier reported low confidence; no threshold was '
                'evaluated.'
          : unrecognized
          ? 'Fruit not recognized or unclear.'
          : null,
      recognitionStatus: unrecognized
          ? RecognitionStatus.notRecognizedOrUnclear
          : RecognitionStatus.recognized,
      heatmap: unrecognized
          ? const ActivationHeatmap(
              width: 7,
              height: 7,
              values: [
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                1,
                1,
                1,
                0,
                0,
                1,
                2,
                2,
                2,
                1,
                0,
                0,
                1,
                2,
                3,
                2,
                1,
                0,
                0,
                1,
                2,
                2,
                2,
                1,
                0,
                0,
                1,
                1,
                1,
                1,
                1,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
              ],
            )
          : null,
    );
  }
}

final class FakeShelfLifeAdvisor implements ShelfLifeAdvisor {
  const FakeShelfLifeAdvisor();

  @override
  ShelfLifeEstimate estimate(ClassificationResult classification) {
    return const ShelfLifeUnavailable(
      reason: 'Shelf-life evidence and validation have not been supplied.',
      evidenceVersion: 'unavailable-foundation-v1',
    );
  }
}
