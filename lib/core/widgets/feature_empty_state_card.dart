import 'package:flutter/material.dart';

class FeatureEmptyStateCard extends StatelessWidget {
  const FeatureEmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.statusLabel,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? statusLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 32,
                  color: colorScheme.primary,
                  semanticLabel: title,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (statusLabel != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Chip(
                  backgroundColor: colorScheme.primaryContainer,
                  side: BorderSide.none,
                  avatar: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  label: Text(statusLabel!),
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
