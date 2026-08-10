import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/scan_image_provider.dart';
import 'package:kami/features/scan/presentation/scan_screens.dart';

final Uint8List _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

void main() {
  testWidgets('real result uses on-device provenance wording', (tester) async {
    final preview = ScanPreview(
      image: const SelectedScanImage(
        path: '/virtual/model-fruit.png',
        name: 'model-fruit.png',
      ),
      classification: const ClassificationResult(
        fruit: FruitIdentifier.carabaoMango,
        ripeness: RipenessStage.ripe,
        modelConfidence: 0.91,
        modelVersion: 'mobilenetv4-fruit-enhanced-b11167b',
        origin: ResultOrigin.onDeviceModel,
        requiresRetake: false,
      ),
      shelfLife: const ShelfLifeUnavailable(
        reason: 'Shelf-life evidence has not been validated.',
        evidenceVersion: 'unavailable-model-integration-v1',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanImageProviderFactoryProvider.overrideWithValue(
            (_) => MemoryImage(_pixel),
          ),
        ],
        child: MaterialApp(home: ScanResultScreen(preview: preview)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('On-device model result'), findsOneWidget);
    expect(find.text('Model confidence'), findsOneWidget);
    expect(find.text('Model version'), findsOneWidget);
    expect(find.text('mobilenetv4-fruit-enhanced-b11167b'), findsOneWidget);
    expect(find.text('Demo preview only'), findsNothing);
    expect(
      find.textContaining('Save this on-device model result'),
      findsNothing,
    );
  });
}
