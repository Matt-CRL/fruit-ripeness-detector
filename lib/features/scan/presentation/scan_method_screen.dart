import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/theme/app_colors.dart';

class ScanMethodScreen extends StatelessWidget {
  const ScanMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan fruit')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose a scan method',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Upload a clear photo or assess one fruit continuously '
                    'with the rear camera.',
                  ),
                  const SizedBox(height: 24),
                  _ScanMethodCard(
                    icon: Icons.photo_library_outlined,
                    title: 'Upload image',
                    description:
                        'Choose a clear fruit photo from your Android device.',
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => context.push(AppRoutes.scanUpload),
                  ),
                  const SizedBox(height: 16),
                  _ScanMethodCard(
                    icon: Icons.center_focus_strong_outlined,
                    title: 'Live Scan',
                    description:
                        'Point the camera at one fruit and see the result and '
                        'confidence update while scanning.',
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => context.push(AppRoutes.scanLive),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    child: const ListTile(
                      leading: Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.brandGreen,
                      ),
                      title: Text(
                        'Camera access is requested only when needed',
                      ),
                      subtitle: Text(
                        'Choosing Live Scan asks for camera permission. Frames '
                        'are assessed on this device, and only a result you '
                        'explicitly save is retained in History.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanMethodCard extends StatelessWidget {
  const _ScanMethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: enabled
                  ? AppColors.softBrandGreen
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: enabled
                  ? AppColors.brandGreen
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    trailing,
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: enabled
          ? '$title. $description'
          : '$title unavailable. $description',
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: enabled ? InkWell(onTap: onTap, child: content) : content,
      ),
    );
  }
}
