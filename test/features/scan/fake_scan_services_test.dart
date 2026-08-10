import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/data/fakes/fake_scan_services.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

void main() {
  test('fake classifier returns a deterministic labeled preview', () async {
    const classifier = FakeRipenessClassifier();

    final result = await classifier.classify('fake://classification');

    expect(result.fruit, FruitIdentifier.carabaoMango);
    expect(result.ripeness, RipenessStage.ripe);
    expect(result.requiresRetake, isFalse);
    expect(result.modelVersion, 'fake-foundation-v1');
    expect(result.origin, ResultOrigin.demo);
  });

  test('fake low-confidence outcome does not infer a threshold', () async {
    const classifier = FakeRipenessClassifier();

    final result = await classifier.classify('fake://retake');

    expect(result.requiresRetake, isTrue);
    expect(result.retakeReason, contains('no threshold was evaluated'));
  });

  test('fake shelf-life advisor reports evidence as unavailable', () async {
    const classifier = FakeRipenessClassifier();
    const advisor = FakeShelfLifeAdvisor();
    final result = await classifier.classify('fake://classification');

    final estimate = advisor.estimate(result);

    expect(estimate, isA<ShelfLifeUnavailable>());
  });
}
