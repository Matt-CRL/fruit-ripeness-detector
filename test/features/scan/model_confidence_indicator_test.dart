import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/presentation/model_confidence_indicator.dart';

void main() {
  testWidgets(
    'shows the stored model confidence as a determinate progress bar',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ModelConfidenceIndicator(
              confidence: 0.87,
              accentColor: Colors.green,
              label: 'Model confidence',
              semanticsLabel: 'Saved model confidence 87 percent',
              progressKey: Key('test-confidence-progress'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Model confidence'), findsOneWidget);
      expect(find.text('87%'), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('test-confidence-progress')),
      );
      expect(progress.value, 0.87);
      expect(progress.minHeight, 10);
      expect(progress.color, Colors.green);
      expect(
        find.bySemanticsLabel('Saved model confidence 87 percent'),
        findsOneWidget,
      );
    },
  );
}
