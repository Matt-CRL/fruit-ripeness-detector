import 'package:kami/features/scan/domain/ripeness_classifier.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

final class LiteratureShelfLifeAdvisor implements ShelfLifeAdvisor {
  const LiteratureShelfLifeAdvisor();

  static const evidenceVersion = 'provisional-literature-rules-v1.0';

  @override
  ShelfLifeEstimate estimate(ClassificationResult classification) {
    if (classification.requiresRetake) {
      return const ShelfLifeUnavailable(
        reason:
            'Shelf-life guidance is withheld because this classification '
            'requires another image.',
        evidenceVersion: evidenceVersion,
      );
    }

    return switch ((classification.fruit, classification.ripeness)) {
      (FruitIdentifier.carabaoMango, RipenessStage.unripe) =>
        const ShelfLifeRange(
          minimum: 5,
          maximum: 7,
          unit: 'days',
          storageGuidance:
              'Keep whole at room temperature in a dry, ventilated, shaded '
              'area. Do not refrigerate while green.',
          evidenceVersion: evidenceVersion,
        ),
      (FruitIdentifier.carabaoMango, RipenessStage.ripe) =>
        const ShelfLifeRange(
          minimum: 1,
          maximum: 3,
          unit: 'days',
          storageGuidance:
              'Keep in the coolest shaded area available and consume soon. '
              'Brief refrigeration is only a short-term hold.',
          evidenceVersion: evidenceVersion,
        ),
      (FruitIdentifier.carabaoMango, RipenessStage.overripe) =>
        const ShelfLifeConsumeImmediately(
          storageGuidance:
              'Consume immediately if still sound; otherwise discard.',
          evidenceVersion: evidenceVersion,
        ),
      (FruitIdentifier.lakatanBanana, RipenessStage.unripe) =>
        const ShelfLifeRange(
          minimum: 8,
          maximum: 13,
          unit: 'days',
          storageGuidance:
              'Keep at room temperature with good airflow, away from sunlight '
              'and heat. Do not refrigerate while green.',
          evidenceVersion: evidenceVersion,
        ),
      (FruitIdentifier.lakatanBanana, RipenessStage.ripe) =>
        const ShelfLifeRange(
          minimum: 3,
          maximum: 4,
          unit: 'days',
          storageGuidance:
              'Keep in a cool, dry, ventilated place and consume soon. '
              'Refrigeration may darken the peel.',
          evidenceVersion: evidenceVersion,
        ),
      (FruitIdentifier.lakatanBanana, RipenessStage.overripe) =>
        const ShelfLifeConsumeImmediately(
          storageGuidance:
              'Consume immediately for eating or cooking if still sound; '
              'otherwise discard.',
          evidenceVersion: evidenceVersion,
        ),
      (FruitIdentifier.redPapaya, RipenessStage.unripe) => const ShelfLifeRange(
        minimum: 3,
        maximum: 6,
        unit: 'days',
        storageGuidance:
            'Keep at room temperature in a dry, shaded area until ripe. '
            'Avoid household refrigeration while unripe.',
        evidenceVersion: evidenceVersion,
      ),
      (FruitIdentifier.redPapaya, RipenessStage.ripe) => const ShelfLifeRange(
        minimum: 1,
        maximum: 2,
        unit: 'days',
        storageGuidance:
            'Consume promptly. Brief refrigeration after ripening is '
            'reasonable.',
        evidenceVersion: evidenceVersion,
      ),
      (FruitIdentifier.redPapaya, RipenessStage.overripe) =>
        const ShelfLifeConsumeImmediately(
          storageGuidance:
              'Consume immediately only if still sound; otherwise discard.',
          evidenceVersion: evidenceVersion,
        ),
    };
  }
}
