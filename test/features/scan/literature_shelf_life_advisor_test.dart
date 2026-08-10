import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/data/shelf_life/literature_shelf_life_advisor.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

void main() {
  const advisor = LiteratureShelfLifeAdvisor();

  test('returns all nine provisional literature-informed rules', () {
    const expectedRanges = {
      (FruitIdentifier.carabaoMango, RipenessStage.unripe): (5, 7),
      (FruitIdentifier.carabaoMango, RipenessStage.ripe): (1, 3),
      (FruitIdentifier.lakatanBanana, RipenessStage.unripe): (8, 13),
      (FruitIdentifier.lakatanBanana, RipenessStage.ripe): (3, 4),
      (FruitIdentifier.redPapaya, RipenessStage.unripe): (3, 6),
      (FruitIdentifier.redPapaya, RipenessStage.ripe): (1, 2),
    };
    const expectedStorageFragments = {
      (FruitIdentifier.carabaoMango, RipenessStage.unripe):
          'dry, ventilated, shaded',
      (FruitIdentifier.carabaoMango, RipenessStage.ripe): 'coolest shaded',
      (FruitIdentifier.carabaoMango, RipenessStage.overripe):
          'otherwise discard',
      (FruitIdentifier.lakatanBanana, RipenessStage.unripe): 'good airflow',
      (FruitIdentifier.lakatanBanana, RipenessStage.ripe):
          'Refrigeration may darken',
      (FruitIdentifier.lakatanBanana, RipenessStage.overripe):
          'eating or cooking',
      (FruitIdentifier.redPapaya, RipenessStage.unripe): 'dry, shaded',
      (FruitIdentifier.redPapaya, RipenessStage.ripe):
          'Brief refrigeration after ripening',
      (FruitIdentifier.redPapaya, RipenessStage.overripe): 'otherwise discard',
    };

    var evaluatedRules = 0;
    for (final fruit in FruitIdentifier.values) {
      for (final ripeness in RipenessStage.values) {
        final estimate = advisor.estimate(
          _classification(fruit: fruit, ripeness: ripeness),
        );
        evaluatedRules++;

        final storageGuidance = switch (estimate) {
          ShelfLifeRange(:final storageGuidance) => storageGuidance,
          ShelfLifeConsumeImmediately(:final storageGuidance) =>
            storageGuidance,
          ShelfLifeUnavailable() => '',
        };
        expect(
          storageGuidance,
          isNotEmpty,
          reason: '$fruit/$ripeness must include storage guidance',
        );
        expect(
          storageGuidance,
          contains(expectedStorageFragments[(fruit, ripeness)]!),
          reason: '$fruit/$ripeness must use its own approved storage rule',
        );
        expect(storageGuidance.toLowerCase(), isNot(contains('fixed')));
        expect(storageGuidance.toLowerCase(), isNot(contains('do not add')));
        expect(storageGuidance.toLowerCase(), isNot(contains('do not claim')));

        if (ripeness == RipenessStage.overripe) {
          expect(
            estimate,
            isA<ShelfLifeConsumeImmediately>(),
            reason: '$fruit overripe must not be a numeric range',
          );
          expect(
            (estimate as ShelfLifeConsumeImmediately).evidenceVersion,
            LiteratureShelfLifeAdvisor.evidenceVersion,
          );
          continue;
        }

        final expected = expectedRanges[(fruit, ripeness)]!;
        expect(estimate, isA<ShelfLifeRange>());
        final range = estimate as ShelfLifeRange;
        expect((range.minimum, range.maximum), expected);
        expect(range.unit, 'days');
        expect(
          range.evidenceVersion,
          LiteratureShelfLifeAdvisor.evidenceVersion,
        );
      }
    }

    expect(evaluatedRules, 9);
  });

  test('confidence never changes an accepted literature rule', () {
    final lowerConfidence =
        advisor.estimate(
              _classification(
                fruit: FruitIdentifier.lakatanBanana,
                ripeness: RipenessStage.ripe,
                confidence: 0.20,
              ),
            )
            as ShelfLifeRange;
    final higherConfidence =
        advisor.estimate(
              _classification(
                fruit: FruitIdentifier.lakatanBanana,
                ripeness: RipenessStage.ripe,
                confidence: 0.99,
              ),
            )
            as ShelfLifeRange;

    expect(lowerConfidence.minimum, higherConfidence.minimum);
    expect(lowerConfidence.maximum, higherConfidence.maximum);
    expect(lowerConfidence.storageGuidance, higherConfidence.storageGuidance);
  });

  test('withholds guidance whenever classification requires a retake', () {
    final estimate = advisor.estimate(
      _classification(
        fruit: FruitIdentifier.redPapaya,
        ripeness: RipenessStage.ripe,
        confidence: 0.99,
        requiresRetake: true,
      ),
    );

    expect(estimate, isA<ShelfLifeUnavailable>());
  });
}

ClassificationResult _classification({
  required FruitIdentifier fruit,
  required RipenessStage ripeness,
  double confidence = 0.87,
  bool requiresRetake = false,
}) {
  return ClassificationResult(
    fruit: fruit,
    ripeness: ripeness,
    modelConfidence: confidence,
    modelVersion: 'test-model-v1',
    origin: ResultOrigin.onDeviceModel,
    requiresRetake: requiresRetake,
    retakeReason: requiresRetake ? 'Test retake.' : null,
  );
}
