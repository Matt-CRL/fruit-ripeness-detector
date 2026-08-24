import 'package:flutter/material.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

class ShelfLifeGuidanceCard extends StatelessWidget {
  const ShelfLifeGuidanceCard({
    required this.estimate,
    required this.ripeness,
    this.isUserAdjusted = false,
    super.key,
  });

  final ShelfLifeEstimate estimate;
  final RipenessStage ripeness;
  final bool isUserAdjusted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final guidanceIcon = switch (estimate) {
      ShelfLifeUnavailable() => Icons.help_outline_rounded,
      ShelfLifeConsumeImmediately() || ShelfLifeRange() => null,
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: switch (estimate) {
          ShelfLifeUnavailable(:final reason) => _UnavailableGuidance(
            icon: guidanceIcon!,
            iconColor: colorScheme.primary,
            reason: reason,
          ),
          ShelfLifeRange(
            :final minimum,
            :final maximum,
            :final unit,
            :final storageGuidance,
          ) =>
            _AvailableGuidance(
              title: switch (ripeness) {
                RipenessStage.unripe => 'Estimated time to ripen',
                RipenessStage.ripe => 'Estimated quality window',
                RipenessStage.overripe => 'Estimated quality window',
              },
              estimateText: 'approximately $minimum–$maximum $unit',
              storageGuidance: storageGuidance,
              isUserAdjusted: isUserAdjusted,
            ),
          ShelfLifeConsumeImmediately(:final storageGuidance) =>
            _AvailableGuidance(
              title: 'Consume immediately',
              estimateText: null,
              storageGuidance: storageGuidance,
              isUserAdjusted: isUserAdjusted,
            ),
        },
      ),
    );
  }
}

class _UnavailableGuidance extends StatelessWidget {
  const _UnavailableGuidance({
    required this.icon,
    required this.iconColor,
    required this.reason,
  });

  final IconData icon;
  final Color iconColor;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              key: const Key('shelf-life-stage-icon'),
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Shelf-life guidance unavailable',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(reason),
      ],
    );
  }
}

class _AvailableGuidance extends StatelessWidget {
  const _AvailableGuidance({
    required this.title,
    required this.estimateText,
    required this.storageGuidance,
    this.isUserAdjusted = false,
  });

  final String title;
  final String? estimateText;
  final String storageGuidance;
  final bool isUserAdjusted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isUserAdjusted
              ? 'Provisional estimate (Adjusted by user)'
              : 'Provisional literature estimate',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (estimateText case final value?) ...[
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                key: const Key('shelf-life-time-icon'),
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: theme.textTheme.labelLarge)),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
        ] else
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                key: const Key('shelf-life-time-icon'),
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              key: const Key('shelf-life-storage-icon'),
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Storage guidance',
                style: theme.textTheme.labelLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(storageGuidance),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              key: const Key('shelf-life-disclaimer-icon'),
              size: 18,
              color: secondaryText,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isUserAdjusted
                    ? 'Recalculated based on user adjustment & literature rules. Actual fruit quality may vary.'
                    : shelfLifeVariabilityDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
