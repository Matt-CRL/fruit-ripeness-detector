import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/shelf_life_guidance_card.dart';

void main() {
  testWidgets('uses stage-specific estimated wording and disclaimer', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      ripeness: RipenessStage.unripe,
      estimate: const ShelfLifeRange(
        minimum: 5,
        maximum: 7,
        unit: 'days',
        storageGuidance: 'Keep at room temperature.',
        evidenceVersion: 'test-v1',
      ),
    );

    expect(find.text('Estimated time to ripen'), findsOneWidget);
    expect(find.text('approximately 5–7 days'), findsOneWidget);
    expect(find.text('Keep at room temperature.'), findsOneWidget);
    expect(find.text('Provisional literature estimate'), findsOneWidget);
    expect(
      find.text('Provisional literature-informed recommendation'),
      findsNothing,
    );
    final provisionalStyle = tester
        .widget<Text>(find.text('Provisional literature estimate'))
        .style!;
    expect(provisionalStyle.fontWeight, FontWeight.w700);
    expect(find.text(shelfLifeVariabilityDisclaimer), findsOneWidget);
    expect(find.byKey(const Key('shelf-life-storage-icon')), findsOneWidget);
    expect(find.byKey(const Key('shelf-life-disclaimer-icon')), findsOneWidget);
    expect(find.byKey(const Key('shelf-life-time-icon')), findsOneWidget);
    final timeIconX = tester
        .getTopLeft(find.byKey(const Key('shelf-life-time-icon')))
        .dx;
    expect(
      tester.getTopLeft(find.byKey(const Key('shelf-life-storage-icon'))).dx,
      timeIconX,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('shelf-life-disclaimer-icon'))).dx,
      timeIconX,
    );

    await _pumpCard(
      tester,
      ripeness: RipenessStage.ripe,
      estimate: const ShelfLifeRange(
        minimum: 1,
        maximum: 3,
        unit: 'days',
        storageGuidance: 'Consume soon.',
        evidenceVersion: 'test-v1',
      ),
    );

    expect(find.text('Estimated quality window'), findsOneWidget);
    expect(find.text('approximately 1–3 days'), findsOneWidget);
    expect(find.text('Consume soon.'), findsOneWidget);
    expect(find.text(shelfLifeVariabilityDisclaimer), findsOneWidget);
  });

  testWidgets('consume immediately never displays the 0-0 sentinel', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      ripeness: RipenessStage.overripe,
      estimate: const ShelfLifeConsumeImmediately(
        storageGuidance: 'Consume immediately if still sound.',
        evidenceVersion: 'test-v1',
      ),
    );

    expect(find.text('Consume immediately'), findsOneWidget);
    expect(find.text('Consume immediately if still sound.'), findsOneWidget);
    expect(find.textContaining('0 days'), findsNothing);
    expect(find.textContaining('0–0'), findsNothing);
    expect(find.text(shelfLifeVariabilityDisclaimer), findsOneWidget);
    expect(find.byKey(const Key('shelf-life-time-icon')), findsOneWidget);
  });
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required RipenessStage ripeness,
  required ShelfLifeEstimate estimate,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ShelfLifeGuidanceCard(estimate: estimate, ripeness: ripeness),
      ),
    ),
  );
}
