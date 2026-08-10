import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/presentation/shelf_life_preview_screen.dart';

void main() {
  testWidgets('shows all nine provisional shelf-life samples', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShelfLifePreviewScreen()));

    expect(find.text('Demo-only saved-result samples'), findsOneWidget);
    expect(find.byType(ShelfLifePreviewScreen), findsOneWidget);
    const sampleKeys = [
      'shelf-life-preview-carabaoMango-unripe',
      'shelf-life-preview-carabaoMango-ripe',
      'shelf-life-preview-carabaoMango-overripe',
      'shelf-life-preview-lakatanBanana-unripe',
      'shelf-life-preview-lakatanBanana-ripe',
      'shelf-life-preview-lakatanBanana-overripe',
      'shelf-life-preview-redPapaya-unripe',
      'shelf-life-preview-redPapaya-ripe',
      'shelf-life-preview-redPapaya-overripe',
    ];
    for (final sampleKey in sampleKeys) {
      await tester.scrollUntilVisible(find.byKey(Key(sampleKey)), 500);
      expect(find.byKey(Key(sampleKey)), findsOneWidget);
    }
  });
}
