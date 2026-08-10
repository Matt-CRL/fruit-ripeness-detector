import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final class FakeRipenessClassifier implements RipenessClassifier {
  const FakeRipenessClassifier();

  @override
  Future<ClassificationResult> classify(String imagePath) async {
    final requiresRetake = imagePath == 'fake://retake';

    return ClassificationResult(
      fruit: FruitIdentifier.carabaoMango,
      ripeness: RipenessStage.ripe,
      modelConfidence: requiresRetake ? 0.31 : 0.87,
      modelVersion: 'fake-foundation-v1',
      origin: ResultOrigin.demo,
      requiresRetake: requiresRetake,
      retakeReason: requiresRetake
          ? 'The demo classifier reported low confidence; no threshold was '
                'evaluated.'
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
