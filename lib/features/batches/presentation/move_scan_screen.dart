import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/features/batches/application/batch_actions.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/batches/presentation/batch_providers.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/presentation/history_providers.dart';
import 'package:kami/features/history/presentation/saved_scan_image.dart';

class MoveScanScreen extends ConsumerStatefulWidget {
  const MoveScanScreen({required this.scanId, super.key});

  final String scanId;

  @override
  ConsumerState<MoveScanScreen> createState() => _MoveScanScreenState();
}

class MoveScansToBatchScreen extends ConsumerStatefulWidget {
  const MoveScansToBatchScreen({required this.scanIds, super.key});

  final List<String> scanIds;

  @override
  ConsumerState<MoveScansToBatchScreen> createState() =>
      _MoveScansToBatchScreenState();
}

class _MoveScansToBatchScreenState
    extends ConsumerState<MoveScansToBatchScreen> {
  String? _movingToBatchId;
  String? _errorMessage;

  Future<void> _move(String targetBatchId) async {
    if (_movingToBatchId != null) return;
    setState(() {
      _movingToBatchId = targetBatchId;
      _errorMessage = null;
    });
    try {
      await ref
          .read(moveScansToBatchUseCaseProvider)
          .execute(scanIds: widget.scanIds, targetBatchId: targetBatchId);
      if (mounted) context.pop(targetBatchId);
    } on BatchActionException catch (error) {
      if (!mounted) return;
      setState(() {
        _movingToBatchId = null;
        _errorMessage = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scans = ref.watch(activeScanRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Move saved scans')),
      body: scans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _MoveMessage(
          title: 'Saved scans unavailable',
          message: 'Chami could not load the selected scans.',
        ),
        data: (records) {
          final selected = records
              .where((record) => widget.scanIds.contains(record.id))
              .toList(growable: false);
          final sourceBatchId = selected.isEmpty
              ? null
              : selected.first.batchId;
          final valid =
              selected.length == widget.scanIds.length &&
              selected.isNotEmpty &&
              sourceBatchId != null &&
              selected.every(
                (record) =>
                    record.batchId == sourceBatchId &&
                    record.fruit == selected.first.fruit &&
                    record.ownerId == selected.first.ownerId,
              );
          if (!valid) {
            return const _MoveMessage(
              title: 'These scans cannot be moved together',
              message:
                  'Select active scans from one editable batch and try again.',
            );
          }
          return _MoveMultipleBody(
            records: selected,
            movingToBatchId: _movingToBatchId,
            errorMessage: _errorMessage,
            onMove: _move,
          );
        },
      ),
    );
  }
}

class _MoveScanScreenState extends ConsumerState<MoveScanScreen> {
  String? _movingToBatchId;
  String? _errorMessage;

  Future<void> _move(String batchId) async {
    if (_movingToBatchId != null) {
      return;
    }
    setState(() {
      _movingToBatchId = batchId;
      _errorMessage = null;
    });
    try {
      await ref
          .read(moveScanToBatchUseCaseProvider)
          .execute(scanId: widget.scanId, targetBatchId: batchId);
      if (mounted) {
        context.pop(batchId);
      }
    } on BatchActionException catch (error) {
      if (mounted) {
        setState(() {
          _movingToBatchId = null;
          _errorMessage = error.message;
        });
        ref.invalidate(moveTargetBatchSnapshotsProvider(widget.scanId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(savedScanRecordProvider(widget.scanId));
    return Scaffold(
      appBar: AppBar(title: const Text('Move saved scan')),
      body: scan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _MoveMessage(
          title: 'Saved scan unavailable',
          message: 'Chami could not load this saved scan.',
        ),
        data: (record) {
          if (record == null) {
            return const _MoveMessage(
              title: 'Saved scan unavailable',
              message: 'This scan is no longer available on this device.',
            );
          }
          if (record.batchId == null) {
            return const _MoveMessage(
              title: 'This scan is not in a batch',
              message: 'Add it to a batch from the saved-scan screen instead.',
            );
          }
          return _MoveBody(
            record: record,
            movingToBatchId: _movingToBatchId,
            errorMessage: _errorMessage,
            onMove: _move,
          );
        },
      ),
    );
  }
}

class _MoveBody extends ConsumerWidget {
  const _MoveBody({
    required this.record,
    required this.movingToBatchId,
    required this.errorMessage,
    required this.onMove,
  });

  final SavedScanRecord record;
  final String? movingToBatchId;
  final String? errorMessage;
  final ValueChanged<String> onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targets = ref.watch(moveTargetBatchSnapshotsProvider(record.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MoveScanHeader(record: record),
                const SizedBox(height: 20),
                Text(
                  'Choose a new ${record.fruit.displayName} batch',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Only compatible, unlocked batches are shown. The saved '
                  'scan stays unchanged if you cancel.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                targets.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => _MoveMessage(
                    title: 'Batches could not be loaded',
                    message: 'Your saved scan remains in its current batch.',
                    action: OutlinedButton.icon(
                      onPressed: () => ref.invalidate(
                        moveTargetBatchSnapshotsProvider(record.id),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
                  data: (snapshots) => snapshots.isEmpty
                      ? const _MoveMessage(
                          title: 'No compatible batch available',
                          message:
                              'Remove this scan from its current batch first, '
                              'then create or choose another batch.',
                        )
                      : Column(
                          children: [
                            for (final snapshot in snapshots) ...[
                              _MoveTargetCard(
                                snapshot: snapshot,
                                moving: movingToBatchId == snapshot.batch.id,
                                disabled: movingToBatchId != null,
                                onTap: () => onMove(snapshot.batch.id),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
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

class _MoveMultipleBody extends ConsumerWidget {
  const _MoveMultipleBody({
    required this.records,
    required this.movingToBatchId,
    required this.errorMessage,
    required this.onMove,
  });

  final List<SavedScanRecord> records;
  final String? movingToBatchId;
  final String? errorMessage;
  final ValueChanged<String> onMove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = records.first;
    final targets = ref.watch(moveTargetBatchSnapshotsProvider(first.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${records.length} scans selected',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All are ${first.fruit.displayName} scans from the '
                          'same batch.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose a new ${first.fruit.displayName} batch',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Only compatible, unlocked batches are shown. The selected '
                  'scans stay unchanged if you cancel.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                targets.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => _MoveMessage(
                    title: 'Batches could not be loaded',
                    message:
                        'Your selected scans remain in their current batch.',
                    action: OutlinedButton.icon(
                      onPressed: () => ref.invalidate(
                        moveTargetBatchSnapshotsProvider(first.id),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
                  data: (snapshots) => snapshots.isEmpty
                      ? const _MoveMessage(
                          title: 'No compatible batch available',
                          message:
                              'Create another unlocked batch of the same fruit '
                              'before moving these scans.',
                        )
                      : Column(
                          children: [
                            for (final snapshot in snapshots) ...[
                              _MoveTargetCard(
                                snapshot: snapshot,
                                moving: movingToBatchId == snapshot.batch.id,
                                disabled: movingToBatchId != null,
                                onTap: () => onMove(snapshot.batch.id),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
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

class _MoveScanHeader extends StatelessWidget {
  const _MoveScanHeader({required this.record});

  final SavedScanRecord record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox.square(
                dimension: 72,
                child: SavedScanImage(
                  relativePath: record.localImageRelativePath,
                  compact: true,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.fruit.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(record.ripeness.displayName),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveTargetCard extends StatelessWidget {
  const _MoveTargetCard({
    required this.snapshot,
    required this.moving,
    required this.disabled,
    required this.onTap,
  });

  final BatchSnapshot snapshot;
  final bool moving;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: ListTile(
        enabled: !disabled,
        onTap: disabled ? null : onTap,
        leading: const CircleAvatar(
          backgroundColor: AppColors.softBrandGreen,
          child: Icon(Icons.inventory_2_outlined, color: AppColors.brandGreen),
        ),
        title: Text(snapshot.batch.name),
        subtitle: Text('${snapshot.summary.total} saved scans'),
        trailing: moving
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _MoveMessage extends StatelessWidget {
  const _MoveMessage({required this.title, required this.message, this.action});

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 44),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
