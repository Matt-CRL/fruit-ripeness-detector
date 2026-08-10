import 'package:flutter/material.dart';
import 'package:kami/features/scan/data/shelf_life/literature_shelf_life_advisor.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/model_confidence_indicator.dart';
import 'package:kami/features/scan/presentation/ripeness_stage_style.dart';
import 'package:kami/features/scan/presentation/shelf_life_guidance_card.dart';

class ShelfLifePreviewScreen extends StatelessWidget {
  const ShelfLifePreviewScreen({super.key});

  static const _samples = [
    (FruitIdentifier.carabaoMango, RipenessStage.unripe),
    (FruitIdentifier.carabaoMango, RipenessStage.ripe),
    (FruitIdentifier.carabaoMango, RipenessStage.overripe),
    (FruitIdentifier.lakatanBanana, RipenessStage.unripe),
    (FruitIdentifier.lakatanBanana, RipenessStage.ripe),
    (FruitIdentifier.lakatanBanana, RipenessStage.overripe),
    (FruitIdentifier.redPapaya, RipenessStage.unripe),
    (FruitIdentifier.redPapaya, RipenessStage.ripe),
    (FruitIdentifier.redPapaya, RipenessStage.overripe),
  ];

  static const _advisor = LiteratureShelfLifeAdvisor();

  ClassificationResult _classification(
    FruitIdentifier fruit,
    RipenessStage ripeness,
  ) {
    return ClassificationResult(
      fruit: fruit,
      ripeness: ripeness,
      modelConfidence: 0.87,
      modelVersion: 'shelf-life-preview',
      origin: ResultOrigin.demo,
      requiresRetake: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: AppBar(title: const Text('Shelf-life sample previews')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 28 + bottomInset),
        children: [
          Text(
            'Demo-only saved-result samples',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'These nine previews use the same provisional literature-informed '
            'rules as saved scans. They are not stored in History.',
          ),
          const SizedBox(height: 16),
          for (final (fruit, ripeness) in _samples)
            _PreviewSample(
              fruit: fruit,
              ripeness: ripeness,
              estimate: _advisor.estimate(_classification(fruit, ripeness)),
            ),
        ],
      ),
    );
  }
}

class _PreviewSample extends StatelessWidget {
  const _PreviewSample({
    required this.fruit,
    required this.ripeness,
    required this.estimate,
  });

  final FruitIdentifier fruit;
  final RipenessStage ripeness;
  final ShelfLifeEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stageStyle = ripenessStageStyle(
      ripeness,
      brightness: theme.brightness,
    );
    final sampleKey = 'shelf-life-preview-${fruit.name}-${ripeness.name}';

    return Card(
      key: Key(sampleKey),
      color: stageStyle.background,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved demo result', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(stageStyle.icon, color: stageStyle.foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${fruit.displayName} • ${ripeness.displayName}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ModelConfidenceIndicator(
                confidence: 0.87,
                accentColor: stageStyle.accent,
                label: 'Model confidence (demo)',
                semanticsLabel: 'Demo model confidence 87 percent',
              ),
            ),
            const SizedBox(height: 12),
            ShelfLifeGuidanceCard(estimate: estimate, ripeness: ripeness),
          ],
        ),
      ),
    );
  }
}
