import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kami/features/scan/domain/heatmap_color_scale.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

class GradCamExplanationCard extends StatelessWidget {
  const GradCamExplanationCard({this.isLegacyActivationPreview = false, super.key});

  final bool isLegacyActivationPreview;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: isLegacyActivationPreview
          ? 'Activation preview. This generic map is not class-specific '
              'Grad-CAM or proof of correctness.'
          : 'Heatmap explanation. Colored regions show what influenced the model, '
              'not fruit boundaries or proof of correctness.',
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isLegacyActivationPreview
                          ? 'How the Activation Preview Works'
                          : 'How the Grad-CAM Heatmap Works',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                isLegacyActivationPreview
                    ? 'This temporary preview visualizes the bundled model\'s '
                        'generic activation map. It is not class-specific '
                        'Grad-CAM and does NOT prove correctness.'
                    : 'The colored overlay reveals which areas of the fruit the MobileNetV4 model '
                        'focused on when classifying ripeness. It does NOT define boundaries or prove correctness.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              const ColorLegendRow(
                color: Color(0xff00c853),
                label: 'High Attention (Green)',
                subtitle:
                    'Highest relative activation for this prediction. Check '
                    'whether it aligns with visible ripeness cues.',
              ),
              const SizedBox(height: 8),
              const ColorLegendRow(
                color: Color(0xffffdf00),
                label: 'Moderate Attention (Yellow)',
                subtitle: 'Mid-range relative activation in this heatmap.',
              ),
              const SizedBox(height: 8),
              const ColorLegendRow(
                color: Color(0xffe53935),
                label: 'Low Attention (Red/Orange)',
                subtitle: 'Lower relative activation in this heatmap.',
              ),
              const SizedBox(height: 8),
              const ColorLegendRow(
                color: Color(0xff1555d1),
                label: 'Lowest Attention (Blue)',
                subtitle: 'Lowest relative activation in this heatmap.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColorLegendRow extends StatelessWidget {
  const ColorLegendRow({
    required this.color,
    required this.label,
    this.subtitle,
    super.key,
  });

  final Color color;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class ActivationHeatmapPainter extends CustomPainter {
  const ActivationHeatmapPainter(this.heatmap);

  static const _samplesPerActivationCell = 16;

  final ActivationHeatmap heatmap;

  @override
  void paint(Canvas canvas, Size size) {
    final values = heatmap.values;
    if (values.isEmpty || heatmap.width <= 0 || heatmap.height <= 0) {
      return;
    }
    final minimum = values.reduce(math.min);
    final maximum = values.reduce(math.max);
    final range = maximum - minimum;
    final renderWidth = heatmap.width * _samplesPerActivationCell;
    final renderHeight = heatmap.height * _samplesPerActivationCell;
    final cellWidth = size.width / renderWidth;
    final cellHeight = size.height / renderHeight;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < renderHeight; y++) {
      for (var x = 0; x < renderWidth; x++) {
        final value = _sampleHeatmap(x, y, renderWidth, renderHeight);
        final normalized = range <= 0
            ? 0.5
            : ((value - minimum) / range).clamp(0.0, 1.0);
        paint.color = heatmapColor(
          normalized,
        ).withValues(alpha: heatmapOverlayOpacity);
        canvas.drawRect(
          Rect.fromLTRB(
            x * cellWidth,
            y * cellHeight,
            (x + 1) * cellWidth,
            (y + 1) * cellHeight,
          ),
          paint,
        );
      }
    }
  }

  double _sampleHeatmap(
    int outputX,
    int outputY,
    int renderWidth,
    int renderHeight,
  ) {
    // Use cell-centered coordinates to match the model export and encoded
    // overlay path, which follow bilinear interpolation with
    // align_corners=False.
    final sourceX = ((outputX + 0.5) * heatmap.width / renderWidth - 0.5).clamp(
      0.0,
      heatmap.width - 1.0,
    );
    final sourceY = ((outputY + 0.5) * heatmap.height / renderHeight - 0.5)
        .clamp(0.0, heatmap.height - 1.0);
    final x0 = sourceX.floor();
    final y0 = sourceY.floor();
    final x1 = math.min(x0 + 1, heatmap.width - 1);
    final y1 = math.min(y0 + 1, heatmap.height - 1);
    final xWeight = sourceX - x0;
    final yWeight = sourceY - y0;

    final top = _lerp(
      heatmap.valueAt(x0, y0),
      heatmap.valueAt(x1, y0),
      xWeight,
    );
    final bottom = _lerp(
      heatmap.valueAt(x0, y1),
      heatmap.valueAt(x1, y1),
      xWeight,
    );
    return _lerp(top, bottom, yWeight);
  }

  double _lerp(double start, double end, double amount) =>
      start + (end - start) * amount;

  @override
  bool shouldRepaint(covariant ActivationHeatmapPainter oldDelegate) =>
      oldDelegate.heatmap != heatmap;
}

Color heatmapColor(double value) {
  final rgb = heatmapRgb(value);
  return Color.fromARGB(255, rgb.red, rgb.green, rgb.blue);
}

class LiveGradCamSheet extends StatelessWidget {
  const LiveGradCamSheet({
    required this.heatmap,
    required this.fruitName,
    required this.ripenessName,
    required this.confidence,
    this.gradCamImageBytes,
    this.isLegacyActivationPreview = false,
    super.key,
  });

  final ActivationHeatmap heatmap;
  final String fruitName;
  final String ripenessName;
  final int confidence;
  final Uint8List? gradCamImageBytes;
  final bool isLegacyActivationPreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
              Row(
            children: [
              Icon(Icons.visibility_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
                Expanded(
                  child: Text(
                  isLegacyActivationPreview
                      ? 'Live AI Activation Preview'
                      : 'Live AI Attention Heatmap (Grad-CAM)',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target fruit: $ripenessName $fruitName ($confidence% confidence)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (gradCamImageBytes != null)
                    Image.memory(gradCamImageBytes!, fit: BoxFit.cover)
                  else
                    Container(
                      color: Colors.black87,
                      child: CustomPaint(
                        painter: ActivationHeatmapPainter(heatmap),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GradCamExplanationCard(
            isLegacyActivationPreview: isLegacyActivationPreview,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
