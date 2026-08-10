import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/router/main_shell.dart';
import 'package:kami/features/batches/application/batch_actions.dart';
import 'package:kami/features/batches/presentation/batch_providers.dart';
import 'package:kami/features/history/application/delete_saved_scan.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/presentation/history_providers.dart';
import 'package:kami/features/history/presentation/history_screen.dart';
import 'package:kami/features/history/presentation/saved_scan_image.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/orders/presentation/order_providers.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/model_confidence_indicator.dart';
import 'package:kami/features/scan/presentation/ripeness_stage_style.dart';
import 'package:kami/features/scan/presentation/shelf_life_guidance_card.dart';

class SavedScanDetailScreen extends ConsumerWidget {
  const SavedScanDetailScreen({
    required this.scanId,
    this.openedFromHistory = false,
    this.openedFromAddScans = false,
    this.openedFromBatchScans = false,
    super.key,
  });

  final String scanId;
  final bool openedFromHistory;
  final bool openedFromAddScans;
  final bool openedFromBatchScans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(savedScanRecordProvider(scanId));

    return Scaffold(
      appBar: AppBar(title: const Text('Saved scan')),
      body: record.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading saved scan details',
          ),
        ),
        error: (error, stackTrace) => _DetailError(
          onRetry: () => ref.invalidate(savedScanRecordProvider(scanId)),
        ),
        data: (value) => value == null
            ? const _MissingRecord()
            : _SavedScanDetails(
                record: value,
                openedFromHistory: openedFromHistory,
                openedFromAddScans: openedFromAddScans,
                openedFromBatchScans: openedFromBatchScans,
              ),
      ),
    );
  }
}

class _SavedScanDetails extends StatelessWidget {
  const _SavedScanDetails({
    required this.record,
    required this.openedFromHistory,
    required this.openedFromAddScans,
    required this.openedFromBatchScans,
  });

  final SavedScanRecord record;
  final bool openedFromHistory;
  final bool openedFromAddScans;
  final bool openedFromBatchScans;

  @override
  Widget build(BuildContext context) {
    final confidence = (record.modelConfidence * 100).round();
    final style = ripenessStageStyle(
      record.ripeness,
      brightness: Theme.of(context).brightness,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        36 + mainNavigationContentBottomInset(context),
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.zero,
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: SavedScanImage(
                      relativePath: record.localImageRelativePath,
                      compact: false,
                    ),
                  ),
                ),
                if (record.resultOrigin == ResultOrigin.demo) ...[
                  const SizedBox(height: 12),
                  const _SavedDemoNotice(),
                ],
                const SizedBox(height: 16),
                Card(
                  color: style.background,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.resultOrigin == ResultOrigin.demo
                              ? 'Saved demo result'
                              : 'Saved assessment',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(style.icon, color: style.foreground),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                record.ripeness.displayName,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          record.fruit.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 18),
                        Container(
                          key: const Key('saved-model-confidence-card'),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: ModelConfidenceIndicator(
                            confidence: record.modelConfidence,
                            accentColor: style.accent,
                            label: record.resultOrigin == ResultOrigin.demo
                                ? 'Model confidence (demo)'
                                : 'Model confidence',
                            semanticsLabel:
                                'Saved model confidence $confidence percent',
                            progressKey: const Key(
                              'saved-model-confidence-progress',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ShelfLifeGuidanceCard(
                  estimate: record.shelfLife,
                  ripeness: record.ripeness,
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Saved',
                          value: formatSavedAt(record.createdAt),
                        ),
                        const Divider(height: 24),
                        _DetailRow(
                          label: 'Model version',
                          value: record.modelVersion,
                        ),
                        const Divider(height: 24),
                        const _DetailRow(
                          label: 'Availability',
                          value: 'Stored on this device',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SavedScanManagementActions(
                  record: record,
                  openedFromHistory: openedFromHistory,
                  hideBatchActions: openedFromAddScans,
                  openedFromBatchScans: openedFromBatchScans,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedScanManagementActions extends ConsumerStatefulWidget {
  const _SavedScanManagementActions({
    required this.record,
    this.openedFromHistory = false,
    this.hideBatchActions = false,
    this.openedFromBatchScans = false,
  });

  final SavedScanRecord record;
  final bool openedFromHistory;
  final bool hideBatchActions;
  final bool openedFromBatchScans;

  @override
  ConsumerState<_SavedScanManagementActions> createState() =>
      _SavedScanManagementActionsState();
}

class _SavedScanManagementActionsState
    extends ConsumerState<_SavedScanManagementActions> {
  bool _working = false;
  String? _errorMessage;

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _removeFromBatch() async {
    final approved = await _confirm(
      title: 'Remove from batch?',
      message:
          'This keeps the saved scan in History and removes it only from its '
          'current batch.',
      confirmLabel: 'Remove',
    );
    if (!approved || !mounted) {
      return;
    }
    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(removeScanFromBatchUseCaseProvider)
          .execute(scanId: widget.record.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan removed from its batch.')),
        );
      }
    } on BatchActionException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _deleteScan() async {
    final approved = await _confirm(
      title: 'Delete saved scan?',
      message:
          'This removes the scan from History and deletes its private saved '
          'image from this device. This cannot be undone in the app.',
      confirmLabel: 'Delete',
    );
    if (!approved || !mounted) {
      return;
    }
    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      final deleted = await ref
          .read(deleteSavedScanUseCaseProvider)
          .execute(scanId: widget.record.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted.imageRemoved
                  ? 'Saved scan and private image deleted.'
                  : 'Saved scan deleted. Its private image could not be '
                        'cleaned up automatically.',
            ),
          ),
        );
        context.go(
          '${AppRoutes.history}?refresh=${DateTime.now().microsecondsSinceEpoch}',
        );
      }
    } on ScanManagementException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    if (widget.hideBatchActions) {
      return const SizedBox.shrink();
    }
    final batchSnapshot = record.batchId == null
        ? null
        : ref.watch(batchSnapshotProvider(record.batchId!));
    final pendingOrder = record.batchId == null
        ? false
        : ref
              .watch(activeBatchOrderProvider(record.batchId!))
              .when(
                data: (order) => order?.status == BatchOrderStatus.pending,
                loading: () => false,
                error: (error, stackTrace) => false,
              );
    final isFinalPendingScan =
        pendingOrder &&
        (batchSnapshot?.when(
              data: (snapshot) => snapshot?.summary.total == 1,
              loading: () => false,
              error: (error, stackTrace) => false,
            ) ??
            false);
    final locked =
        batchSnapshot?.when(
          data: (snapshot) => snapshot?.isLocked ?? false,
          loading: () => false,
          error: (error, stackTrace) => false,
        ) ??
        false;

    if (widget.openedFromBatchScans && record.batchId == null) {
      return const Text('This scan is no longer assigned to this batch.');
    }

    if (widget.openedFromHistory) {
      if (record.batchId != null) {
        return FilledButton.icon(
          onPressed: _working
              ? null
              : () => context.push(AppRoutes.batchDetails(record.batchId!)),
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('View batch'),
        );
      }
      final colorScheme = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _working
                ? null
                : () => context.push(AppRoutes.addToBatch(record.id)),
            icon: const Icon(Icons.playlist_add),
            label: const Text('Add to Batch'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _working ? null : _deleteScan,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete saved scan'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.openedFromBatchScans)
          FilledButton.icon(
            onPressed: _working
                ? null
                : () => context.push(
                    record.batchId == null
                        ? AppRoutes.addToBatch(record.id)
                        : AppRoutes.batchDetails(record.batchId!),
                  ),
            icon: Icon(
              record.batchId == null
                  ? Icons.playlist_add
                  : Icons.inventory_2_outlined,
            ),
            label: Text(record.batchId == null ? 'Add to Batch' : 'View batch'),
          ),
        if (locked) ...[
          const SizedBox(height: 12),
          Text(
            'This scan is in a completed-order batch and cannot be moved, '
            'removed, or deleted.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ] else if (isFinalPendingScan) ...[
          const SizedBox(height: 12),
          Text(
            'This is the final saved scan in a Pending order. Cancel the '
            'order before removing or deleting it.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ] else ...[
          if (record.batchId != null) ...[
            const SizedBox(height: 12),
            if (widget.openedFromBatchScans) ...[
              FilledButton.icon(
                onPressed: _working ? null : _removeFromBatch,
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Remove from batch'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _working
                    ? null
                    : () => context.push(AppRoutes.moveToBatch(record.id)),
                icon: const Icon(Icons.drive_file_move_outline),
                label: const Text('Move to another batch'),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _working
                    ? null
                    : () => context.push(AppRoutes.moveToBatch(record.id)),
                icon: const Icon(Icons.drive_file_move_outline),
                label: const Text('Move to another batch'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _working ? null : _removeFromBatch,
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Remove from batch'),
              ),
            ],
          ],
          if (!widget.openedFromBatchScans) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _working ? null : _deleteScan,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete saved scan'),
            ),
          ],
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedDemoNotice extends StatelessWidget {
  const _SavedDemoNotice();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.science_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Demo record: this image was not evaluated by a real model. '
                'Keep it only for testing the offline save workflow.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(width: 16),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

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
            const Text('The saved scan could not be loaded.'),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _MissingRecord extends StatelessWidget {
  const _MissingRecord();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('This saved scan is no longer available.'),
      ),
    );
  }
}
