import 'package:flutter/material.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/ripeness_stage_style.dart';

const _batchGuidanceStageOrder = <RipenessStage>[
  RipenessStage.overripe,
  RipenessStage.ripe,
  RipenessStage.unripe,
];

class BatchShelfLifeSummaryAction extends StatelessWidget {
  const BatchShelfLifeSummaryAction({required this.scans, super.key});

  final List<SavedScanRecord> scans;

  @override
  Widget build(BuildContext context) {
    final groups = buildBatchShelfLifeGuidance(scans);
    if (groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.priority_high_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _priorityMessage(groups.first),
                key: const Key('batch-shelf-life-priority'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const Key('batch-shelf-life-open'),
            onPressed: () =>
                showBatchShelfLifeGuidanceSheet(context, scans: scans),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('View shelf-life & storage'),
          ),
        ),
      ],
    );
  }
}

final class BatchShelfLifeStageGuidance {
  const BatchShelfLifeStageGuidance({
    required this.stage,
    required this.count,
    required this.estimate,
  });

  final RipenessStage stage;
  final int count;
  final ShelfLifeEstimate estimate;
}

List<BatchShelfLifeStageGuidance> buildBatchShelfLifeGuidance(
  Iterable<SavedScanRecord> scans,
) {
  final recordsByStage = <RipenessStage, List<SavedScanRecord>>{};
  for (final scan in scans) {
    recordsByStage.putIfAbsent(scan.ripeness, () => []).add(scan);
  }

  return List.unmodifiable(
    _batchGuidanceStageOrder.map((stage) {
      final stageRecords = recordsByStage[stage];
      if (stageRecords == null || stageRecords.isEmpty) {
        return null;
      }

      final firstEstimate = stageRecords.first.shelfLife;
      final isConsistent = stageRecords
          .skip(1)
          .every((record) => _sameEstimate(firstEstimate, record.shelfLife));
      return BatchShelfLifeStageGuidance(
        stage: stage,
        count: stageRecords.length,
        estimate: isConsistent
            ? firstEstimate
            : const ShelfLifeUnavailable(
                reason:
                    'Saved recommendations for this stage are inconsistent.',
                evidenceVersion: 'batch-inconsistent-persisted-guidance',
              ),
      );
    }).whereType<BatchShelfLifeStageGuidance>(),
  );
}

Future<void> showBatchShelfLifeGuidanceSheet(
  BuildContext context, {
  required List<SavedScanRecord> scans,
}) {
  final groups = buildBatchShelfLifeGuidance(scans);
  if (groups.isEmpty) {
    return Future.value();
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _BatchShelfLifeGuidanceSheet(fruit: scans.first.fruit, groups: groups),
  );
}

class _BatchShelfLifeGuidanceSheet extends StatelessWidget {
  const _BatchShelfLifeGuidanceSheet({
    required this.fruit,
    required this.groups,
  });

  final FruitIdentifier fruit;
  final List<BatchShelfLifeStageGuidance> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = theme.colorScheme.onSurfaceVariant;
    return ConstrainedBox(
      key: const Key('batch-shelf-life-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Shelf-life & storage',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close guidance',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                fruit.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Provisional literature estimate',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (groups.length > 1) ...[
                const SizedBox(height: 10),
                Text(
                  'This batch has mixed ripeness. Follow the guidance for '
                  'each stage separately.',
                  key: const Key('batch-shelf-life-mixed-note'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              for (var index = 0; index < groups.length; index++) ...[
                _BatchShelfLifeStageSection(group: groups[index]),
                if (index != groups.length - 1) const Divider(height: 32),
              ],
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    key: const Key('batch-shelf-life-disclaimer-icon'),
                    size: 18,
                    color: secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shelfLifeVariabilityDisclaimer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchShelfLifeStageSection extends StatelessWidget {
  const _BatchShelfLifeStageSection({required this.group});

  final BatchShelfLifeStageGuidance group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stageStyle = ripenessStageStyle(
      group.stage,
      brightness: theme.brightness,
    );
    return Column(
      key: Key('batch-shelf-life-stage-${group.stage.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(stageStyle.icon, size: 19, color: stageStyle.accent),
            const SizedBox(width: 7),
            Text(
              group.stage.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                color: stageStyle.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(_fruitCount(group.count), style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 12),
        switch (group.estimate) {
          ShelfLifeRange(
            :final minimum,
            :final maximum,
            :final unit,
            :final storageGuidance,
          ) =>
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GuidanceLine(
                  icon: Icons.schedule_outlined,
                  iconKey: Key('batch-shelf-life-time-${group.stage.name}'),
                  label: switch (group.stage) {
                    RipenessStage.unripe => 'Estimated time to ripen',
                    RipenessStage.ripe ||
                    RipenessStage.overripe => 'Estimated quality window',
                  },
                  detail: 'approximately $minimum–$maximum $unit',
                ),
                const SizedBox(height: 12),
                _GuidanceLine(
                  icon: Icons.inventory_2_outlined,
                  iconKey: Key('batch-shelf-life-storage-${group.stage.name}'),
                  label: 'Storage guidance',
                  detail: storageGuidance,
                ),
              ],
            ),
          ShelfLifeConsumeImmediately(:final storageGuidance) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GuidanceLine(
                icon: Icons.schedule_outlined,
                iconKey: Key('batch-shelf-life-time-${group.stage.name}'),
                label: 'Consume immediately',
                emphasizeLabel: true,
              ),
              const SizedBox(height: 12),
              _GuidanceLine(
                icon: Icons.inventory_2_outlined,
                iconKey: Key('batch-shelf-life-storage-${group.stage.name}'),
                label: 'Storage guidance',
                detail: storageGuidance,
              ),
            ],
          ),
          ShelfLifeUnavailable(:final reason) => _GuidanceLine(
            icon: Icons.help_outline_rounded,
            iconKey: Key('batch-shelf-life-unavailable-${group.stage.name}'),
            label: 'Guidance unavailable',
            detail: '$reason Review the individual saved scans for details.',
            emphasizeLabel: true,
          ),
        },
      ],
    );
  }
}

class _GuidanceLine extends StatelessWidget {
  const _GuidanceLine({
    required this.icon,
    required this.iconKey,
    required this.label,
    this.detail,
    this.emphasizeLabel = false,
  });

  final IconData icon;
  final Key iconKey;
  final String label;
  final String? detail;
  final bool emphasizeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            key: iconKey,
            size: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: emphasizeLabel
                    ? theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      )
                    : theme.textTheme.labelLarge,
              ),
              if (detail case final value?) ...[
                const SizedBox(height: 4),
                Text(value),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _priorityMessage(BatchShelfLifeStageGuidance priority) {
  final count = priority.count;
  return switch (priority.stage) {
    RipenessStage.overripe =>
      count == 1
          ? '1 overripe fruit needs immediate attention.'
          : '$count overripe fruits need immediate attention.',
    RipenessStage.ripe =>
      count == 1
          ? '1 ripe fruit should be used soon.'
          : '$count ripe fruits should be used soon.',
    RipenessStage.unripe =>
      count == 1
          ? '1 unripe fruit is still ripening.'
          : '$count unripe fruits are still ripening.',
  };
}

String _fruitCount(int count) => '$count ${count == 1 ? 'fruit' : 'fruits'}';

bool _sameEstimate(ShelfLifeEstimate left, ShelfLifeEstimate right) {
  return switch ((left, right)) {
    (
      ShelfLifeRange(
        minimum: final leftMinimum,
        maximum: final leftMaximum,
        unit: final leftUnit,
        storageGuidance: final leftStorage,
      ),
      ShelfLifeRange(
        minimum: final rightMinimum,
        maximum: final rightMaximum,
        unit: final rightUnit,
        storageGuidance: final rightStorage,
      ),
    ) =>
      leftMinimum == rightMinimum &&
          leftMaximum == rightMaximum &&
          leftUnit == rightUnit &&
          leftStorage == rightStorage,
    (
      ShelfLifeConsumeImmediately(storageGuidance: final leftStorage),
      ShelfLifeConsumeImmediately(storageGuidance: final rightStorage),
    ) =>
      leftStorage == rightStorage,
    (
      ShelfLifeUnavailable(reason: final leftReason),
      ShelfLifeUnavailable(reason: final rightReason),
    ) =>
      leftReason == rightReason,
    _ => false,
  };
}
