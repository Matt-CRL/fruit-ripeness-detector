import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/features/history/presentation/history_providers.dart';
import 'package:kami/features/scan/presentation/scan_image_provider.dart';

class SavedScanImage extends ConsumerWidget {
  const SavedScanImage({
    required this.relativePath,
    required this.compact,
    super.key,
  });

  final String? relativePath;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final path = relativePath;
    if (path == null) {
      return _UnavailableImage(compact: compact);
    }

    final resolved = ref.watch(retainedImagePathProvider(path));
    return resolved.when(
      loading: () => ColoredBox(
        color: colorScheme.primaryContainer,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: 'Loading saved image',
          ),
        ),
      ),
      error: (error, stackTrace) => _UnavailableImage(compact: compact),
      data: (absolutePath) {
        return Image(
          image: ref.watch(scanImageProviderFactoryProvider)(absolutePath),
          fit: compact ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _UnavailableImage(compact: compact);
          },
        );
      },
    );
  }
}

class _UnavailableImage extends StatelessWidget {
  const _UnavailableImage({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.primaryContainer,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, color: colorScheme.primary),
              if (!compact) ...[
                const SizedBox(height: 8),
                Text(
                  'The saved image is unavailable. The scan details are still '
                  'shown below.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
