import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/router/main_shell.dart';
import 'package:kami/core/layout/kami_responsive.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openScan(BuildContext context) {
    context.push(AppRoutes.scan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chami'),
            Text(
              'Fruit ripeness guide',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: KamiResponsive.pagePadding(
          context,
          top: 8,
          bottom: 36 + mainNavigationContentBottomInset(context),
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WelcomeCard(onScan: () => _openScan(context)),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Supported fruits'),
                  const SizedBox(height: 12),
                  const _SupportedFruitsCard(),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Take a clear photo'),
                  const SizedBox(height: 12),
                  const _PhotoGuidanceCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compact = KamiResponsive.isCompactPhone(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  avatar: Icon(Icons.person_outline, size: 18),
                  label: Text('Guest mode'),
                ),
                Chip(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  avatar: Icon(Icons.offline_bolt_outlined, size: 18),
                  label: Text('Offline ready'),
                ),
              ],
            ),
            SizedBox(height: compact ? 16 : 20),
            _ChamiPrompt(compact: compact),
            SizedBox(height: compact ? 14 : 18),
            const Text(
              'Upload one clear photo or use Live Scan for an offline '
              'on-device assessment. Results can be saved locally. Model '
              'validation is still in progress.',
            ),
            SizedBox(height: compact ? 20 : 24),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Start scan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChamiPrompt extends StatefulWidget {
  const _ChamiPrompt({required this.compact});

  final bool compact;

  @override
  State<_ChamiPrompt> createState() => _ChamiPromptState();
}

class _ChamiPromptState extends State<_ChamiPrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final Animation<double> _bounce = Tween<double>(begin: -3, end: 3)
      .animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
      );

  @override
  void initState() {
    super.initState();
    if (io.Platform.environment['FLUTTER_TEST'] == 'true') {
      _bounceController.forward();
    } else {
      _bounceController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = widget.compact;
    final imageWidth = compact ? 78.0 : 100.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/branding/chami_mascot_mango.png',
          key: const Key('home-chami-mascot'),
          width: imageWidth,
          height: compact ? 102 : 128,
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
          semanticLabel: 'Chami holding a mango',
        ),
        SizedBox(width: compact ? 8 : 10),
        Expanded(
          child: AnimatedBuilder(
            animation: _bounce,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _bounce.value),
              child: child,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: -10,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: CustomPaint(
                    painter: _SpeechBubblePainter(
                      fill: colorScheme.primaryContainer,
                      stroke: colorScheme.primary.withValues(alpha: 0.32),
                    ),
                  ),
                ),
                Container(
                  key: const Key('home-chami-prompt'),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 20,
                    vertical: compact ? 14 : 18,
                  ),
                  child: Text(
                    'Ready to check a fruit?',
                    style:
                        (compact
                                ? theme.textTheme.titleMedium
                                : theme.textTheme.titleLarge)
                            ?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    // Leave room for the tail on the left. Combining the tail and rounded
    // body before stroking removes the doubled outline at their junction.
    const tailWidth = 10.0;
    const tailHeight = 18.0;
    final bubblePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            tailWidth,
            0,
            size.width - tailWidth,
            size.height,
          ),
          const Radius.circular(20),
        ),
      );
    final centerY = size.height / 2;
    final tailPath = Path()
      ..moveTo(tailWidth, centerY - tailHeight / 2)
      ..lineTo(0, centerY)
      ..lineTo(tailWidth, centerY + tailHeight / 2)
      ..close();
    final path = Path.combine(PathOperation.union, bubblePath, tailPath);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_SpeechBubblePainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.stroke != stroke;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _SupportedFruitsCard extends StatelessWidget {
  const _SupportedFruitsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: const Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Keep one supported fruit in each photo.'),
            SizedBox(height: 18),
            _FruitRow(name: 'Carabao mango'),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            _FruitRow(name: 'Lakatan banana'),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            _FruitRow(name: 'Red papaya'),
          ],
        ),
      ),
    );
  }
}

class _FruitRow extends StatelessWidget {
  const _FruitRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.eco_outlined, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(name, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}

class _PhotoGuidanceCard extends StatelessWidget {
  const _PhotoGuidanceCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: const Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          children: [
            _GuidanceRow(
              icon: Icons.center_focus_strong_outlined,
              text: 'Center one fruit in the image.',
            ),
            SizedBox(height: 16),
            _GuidanceRow(
              icon: Icons.light_mode_outlined,
              text: 'Use bright, even lighting.',
            ),
            SizedBox(height: 16),
            _GuidanceRow(
              icon: Icons.motion_photos_off_outlined,
              text: 'Avoid blur and obstruction.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceRow extends StatelessWidget {
  const _GuidanceRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: colorScheme.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
