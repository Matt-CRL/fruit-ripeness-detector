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
            const Text('Kami'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Text(
              'Ready to check a fruit?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload one clear photo or use Live Scan for an offline '
              'on-device assessment. Results can be saved locally. Model '
              'validation is still in progress.',
            ),
            const SizedBox(height: 24),
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
