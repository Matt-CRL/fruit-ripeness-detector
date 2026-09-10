import 'package:flutter/material.dart';

class FruitTagCard extends StatelessWidget {
  const FruitTagCard.uploadSuggestion({required this.fruitTagId, super.key})
    : isDemo = false,
      showSuggestion = true;

  const FruitTagCard.savedDetail({
    required this.fruitTagId,
    required this.isDemo,
    super.key,
  }) : showSuggestion = false;

  final String fruitTagId;
  final bool isDemo;
  final bool showSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!showSuggestion) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isDemo ? 'Demo record ID' : 'Fruit ID',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _FruitIdSticker(fruitTagId: fruitTagId),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Suggested next step',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text('Label this fruit', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Write this ID on a tag and attach it to the fruit.'),
            const SizedBox(height: 14),
            _FruitIdSticker(fruitTagId: fruitTagId),
          ],
        ),
      ),
    );
  }
}

class _FruitIdSticker extends StatelessWidget {
  const _FruitIdSticker({required this.fruitTagId});

  final String fruitTagId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Fruit ID $fruitTagId',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: colorScheme.outline),
                ),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/branding/chami_wordmark_dark.png',
                          height: 23,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          semanticLabel: 'Chami logo',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 13),
                      child: Column(
                        children: [
                          Text(
                            'FRUIT ID',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SelectableText(
                              fruitTagId,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        width: constraints.maxWidth - 32,
                        height: 3,
                        child: CustomPaint(painter: _DashedLinePainter()),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                bottom: 32,
                child: _TagNotch(
                  color: colorScheme.surface,
                  borderColor: colorScheme.outline,
                  showLeftHalf: false,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 32,
                child: _TagNotch(
                  color: colorScheme.surface,
                  borderColor: colorScheme.outline,
                  showLeftHalf: true,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TagNotch extends StatelessWidget {
  const _TagNotch({
    required this.color,
    required this.borderColor,
    required this.showLeftHalf,
  });

  final Color color;
  final Color borderColor;
  final bool showLeftHalf;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 28,
      child: ClipRect(
        child: OverflowBox(
          minWidth: 28,
          maxWidth: 28,
          minHeight: 28,
          maxHeight: 28,
          alignment: showLeftHalf
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: const SizedBox(width: 28, height: 28),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade500
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.square;
    const dashWidth = 13.0;
    const gap = 7.0;
    for (var x = 0.0; x < size.width; x += dashWidth + gap) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset((x + dashWidth).clamp(0, size.width), size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
