import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/features/batches/application/batch_actions.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/batches/presentation/batch_providers.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/presentation/history_providers.dart';
import 'package:kami/features/history/presentation/saved_scan_image.dart';
import 'package:kami/features/scan/domain/scan_models.dart';

class AddToBatchScreen extends ConsumerStatefulWidget {
  const AddToBatchScreen({required this.scanId, super.key});

  final String scanId;

  @override
  ConsumerState<AddToBatchScreen> createState() => _AddToBatchScreenState();
}

/// Assigns a same-fruit History selection to one compatible batch.
class AddMultipleScansToBatchScreen extends ConsumerStatefulWidget {
  const AddMultipleScansToBatchScreen({required this.scanIds, super.key});

  final List<String> scanIds;

  @override
  ConsumerState<AddMultipleScansToBatchScreen> createState() =>
      _AddMultipleScansToBatchScreenState();
}

class _AddMultipleScansToBatchScreenState
    extends ConsumerState<AddMultipleScansToBatchScreen> {
  String? _assigningBatchId;
  String? _errorMessage;

  Future<void> _assign(String batchId) async {
    if (_assigningBatchId != null) {
      return;
    }
    setState(() {
      _assigningBatchId = batchId;
      _errorMessage = null;
    });
    try {
      await ref
          .read(addScansToBatchUseCaseProvider)
          .execute(scanIds: widget.scanIds, batchId: batchId);
      if (mounted) {
        context.pop(batchId);
      }
    } on BatchActionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _assigningBatchId = null;
        _errorMessage = error.message;
      });
      ref.invalidate(activeBatchSnapshotsProvider);
    }
  }

  Future<void> _createBatch() async {
    if (_assigningBatchId != null) {
      return;
    }
    final batchId = await context.push<String>(
      AppRoutes.batchCreateForScans,
      extra: widget.scanIds,
    );
    if (mounted && batchId != null) {
      context.pop(batchId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scans = ref.watch(activeScanRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Add to batch')),
      body: scans.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading selected scans',
          ),
        ),
        error: (error, stackTrace) => _LoadError(
          message: 'The selected scans could not be loaded.',
          onRetry: () => ref.invalidate(activeScanRecordsProvider),
        ),
        data: (records) {
          final selected = records
              .where((record) => widget.scanIds.contains(record.id))
              .toList(growable: false);
          if (selected.length != widget.scanIds.length ||
              selected.isEmpty ||
              selected.any((record) => record.batchId != null) ||
              selected.any((record) => record.fruit != selected.first.fruit) ||
              selected.any(
                (record) => record.ownerId != selected.first.ownerId,
              )) {
            return const _MissingScan(
              message:
                  'Only active, unassigned scans of one fruit type can be '
                  'added together.',
            );
          }
          return _buildAvailable(selected);
        },
      ),
    );
  }

  Widget _buildAvailable(List<SavedScanRecord> records) {
    final fruit = records.first.fruit;
    final batches = ref.watch(activeBatchSnapshotsProvider);
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
                        Text('All are ${fruit.displayName} scans.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Choose a ${fruit.displayName} batch',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Only compatible, editable batches appear here.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _assigningBatchId == null ? _createBatch : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Create new batch'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _AssignmentError(message: _errorMessage!),
                ],
                const SizedBox(height: 20),
                batches.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading compatible batches',
                      ),
                    ),
                  ),
                  error: (error, stackTrace) => _LoadErrorCard(
                    onRetry: () => ref.invalidate(activeBatchSnapshotsProvider),
                  ),
                  data: (snapshots) {
                    final compatible = snapshots
                        .where(
                          (snapshot) =>
                              snapshot.batch.fruit == fruit &&
                              snapshot.batch.ownerId == records.first.ownerId &&
                              !snapshot.isLocked,
                        )
                        .toList(growable: false);
                    if (compatible.isEmpty) {
                      return const Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No compatible existing batches yet. Create a '
                            'new batch for these saved scans.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Existing batches',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        for (final snapshot in compatible) ...[
                          _CompatibleBatchCard(
                            snapshot: snapshot,
                            assigning: _assigningBatchId == snapshot.batch.id,
                            disabled: _assigningBatchId != null,
                            onTap: () => _assign(snapshot.batch.id),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddToBatchScreenState extends ConsumerState<AddToBatchScreen> {
  String? _assigningBatchId;
  String? _errorMessage;

  Future<void> _assign(String batchId) async {
    if (_assigningBatchId != null) {
      return;
    }
    setState(() {
      _assigningBatchId = batchId;
      _errorMessage = null;
    });
    try {
      await ref
          .read(addScanToBatchUseCaseProvider)
          .execute(scanId: widget.scanId, batchId: batchId);
      if (!mounted) {
        return;
      }
      context.pop(batchId);
    } on BatchActionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _assigningBatchId = null;
        _errorMessage = error.message;
      });
      ref.invalidate(compatibleBatchSnapshotsProvider(widget.scanId));
    }
  }

  Future<void> _createBatch() async {
    if (_assigningBatchId != null) {
      return;
    }
    final batchId = await context.push<String>(
      AppRoutes.batchCreateForScan(widget.scanId),
    );
    if (mounted && batchId != null) {
      context.pop(batchId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(savedScanRecordProvider(widget.scanId));

    return Scaffold(
      appBar: AppBar(title: const Text('Add to batch')),
      body: scan.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading saved scan',
          ),
        ),
        error: (error, stackTrace) => _LoadError(
          message: 'The saved scan could not be loaded.',
          onRetry: () => ref.invalidate(savedScanRecordProvider(widget.scanId)),
        ),
        data: (record) {
          if (record == null) {
            return const _MissingScan();
          }
          if (record.batchId != null) {
            return _AlreadyAssigned(batchId: record.batchId!);
          }
          return _buildAvailable(record);
        },
      ),
    );
  }

  Widget _buildAvailable(SavedScanRecord record) {
    final batches = ref.watch(compatibleBatchSnapshotsProvider(widget.scanId));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScanHeader(record: record),
                const SizedBox(height: 20),
                Text(
                  'Choose a ${record.fruit.displayName} batch',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Only compatible, editable batches appear here.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _assigningBatchId == null ? _createBatch : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Create new batch'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _AssignmentError(message: _errorMessage!),
                ],
                const SizedBox(height: 20),
                batches.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading compatible batches',
                      ),
                    ),
                  ),
                  error: (error, stackTrace) => _LoadErrorCard(
                    onRetry: () => ref.invalidate(
                      compatibleBatchSnapshotsProvider(widget.scanId),
                    ),
                  ),
                  data: (snapshots) => snapshots.isEmpty
                      ? const Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No compatible existing batches yet. Create a '
                              'new batch for this saved scan.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Existing batches',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            for (final snapshot in snapshots) ...[
                              _CompatibleBatchCard(
                                snapshot: snapshot,
                                assigning:
                                    _assigningBatchId == snapshot.batch.id,
                                disabled: _assigningBatchId != null,
                                onTap: () => _assign(snapshot.batch.id),
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

class _ScanHeader extends StatelessWidget {
  const _ScanHeader({required this.record});

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
                dimension: 76,
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
                  if (record.resultOrigin == ResultOrigin.demo) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Demo saved scan',
                      style: TextStyle(
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompatibleBatchCard extends StatelessWidget {
  const _CompatibleBatchCard({
    required this.snapshot,
    required this.assigning,
    required this.disabled,
    required this.onTap,
  });

  final BatchSnapshot snapshot;
  final bool assigning;
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
        trailing: assigning
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  semanticsLabel: 'Adding scan to batch',
                ),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _AlreadyAssigned extends StatelessWidget {
  const _AlreadyAssigned({required this.batchId});

  final String batchId;

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
            Text(
              'Already in a batch',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'This saved scan will not be moved automatically.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () =>
                  context.pushReplacement(AppRoutes.batchDetails(batchId)),
              child: const Text('View batch'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingScan extends StatelessWidget {
  const _MissingScan({
    this.message = 'This saved scan is no longer available.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: EdgeInsets.all(24), child: Text(message)),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _LoadErrorCard extends StatelessWidget {
  const _LoadErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Text('Compatible batches could not be loaded.'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _AssignmentError extends StatelessWidget {
  const _AssignmentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.overripeOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.overripeOrange),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
