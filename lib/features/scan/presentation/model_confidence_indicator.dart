import 'package:flutter/material.dart';

class ModelConfidenceIndicator extends StatelessWidget {
  const ModelConfidenceIndicator({
    required this.confidence,
    required this.accentColor,
    required this.label,
    required this.semanticsLabel,
    this.progressKey,
    super.key,
  });

  final double confidence;
  final Color accentColor;
  final String label;
  final String semanticsLabel;
  final Key? progressKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidencePercent = (confidence * 100).round();

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
            const SizedBox(width: 12),
            Text('$confidencePercent%', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 10),
        Semantics(
          label: semanticsLabel,
          child: LinearProgressIndicator(
            key: progressKey,
            value: confidence,
            minHeight: 10,
            color: accentColor,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}
