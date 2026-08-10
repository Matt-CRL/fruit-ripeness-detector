import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/core/widgets/feature_empty_state_card.dart';
import 'package:kami/features/batches/application/batch_actions.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/batches/presentation/batch_providers.dart';
import 'package:kami/features/batches/presentation/batch_screens.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/saved_scan_query.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/presentation/history_filters.dart';
import 'package:kami/features/history/presentation/history_providers.dart';
import 'package:kami/features/history/presentation/history_screen.dart';
import 'package:kami/features/history/presentation/saved_scan_image.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/ripeness_stage_style.dart';

class AddScansToBatchScreen extends ConsumerStatefulWidget {
  const AddScansToBatchScreen({required this.batchId, super.key});

  final String batchId;

  @override
  ConsumerState<AddScansToBatchScreen> createState() =>
      _AddScansToBatchScreenState();
}

class _AddScansToBatchScreenState extends ConsumerState<AddScansToBatchScreen> {
  static const _pageSize = 50;

  final _selectedScanIds = <String>{};
  List<SavedScanRecord> _records = const [];
  PageCursor? _nextCursor;
  int _totalCount = 0;
  bool _loadingPage = false;
  bool _loadingMore = false;
  String? _loadedBatchId;
  HistoryFilters _filters = const HistoryFilters();
  bool _selectionMode = false;
  bool _assigning = false;
  String? _errorMessage;

  SavedScanQuery _query(BatchSnapshot snapshot) {
    final base = _filters.toSavedScanQuery();
    return SavedScanQuery(
      fruit: snapshot.batch.fruit,
      ripeness: base.ripeness,
      inBatch: false,
      ownerId: snapshot.batch.ownerId,
      onlyNullOwner: snapshot.batch.ownerId == null,
      createdFromUtc: base.createdFromUtc,
      createdUntilUtc: base.createdUntilUtc,
      sortOrder: base.sortOrder,
    );
  }

  void _ensurePage(BatchSnapshot snapshot) {
    if (_loadedBatchId == snapshot.batch.id || _loadingPage) return;
    _loadedBatchId = snapshot.batch.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reloadPage(snapshot);
    });
  }

  Future<void> _reloadPage(BatchSnapshot snapshot) async {
    if (!mounted) return;
    setState(() {
      _loadingPage = true;
      _errorMessage = null;
    });
    try {
      final page = await ref
          .read(scanRecordRepositoryProvider)
          .fetchPage(query: _query(snapshot), limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _records = page.records;
        _totalCount = page.totalCount;
        _nextCursor = page.nextCursor;
        _loadingPage = false;
        _selectedScanIds.removeWhere(
          (id) => !_records.any((record) => record.id == id),
        );
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPage = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadMore(BatchSnapshot snapshot) async {
    final cursor = _nextCursor;
    if (_loadingMore || cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(scanRecordRepositoryProvider)
          .fetchPage(query: _query(snapshot), cursor: cursor, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _records = [..._records, ...page.records];
        _totalCount = page.totalCount;
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _assign(Iterable<String> scanIds) async {
    final ids = scanIds.toSet().toList(growable: false);
    if (ids.isEmpty || _assigning) {
      return;
    }
    setState(() {
      _assigning = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(addScansToBatchUseCaseProvider)
          .execute(scanIds: ids, batchId: widget.batchId);
      if (!mounted) {
        return;
      }
      context.pop(ids.length);
    } on BatchActionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _assigning = false;
        _errorMessage = error.message;
      });
      ref.invalidate(activeScanRecordsProvider);
      ref.invalidate(batchSnapshotProvider(widget.batchId));
    }
  }

  void _toggle(String scanId) {
    if (_assigning) {
      return;
    }
    setState(() {
      if (!_selectedScanIds.remove(scanId)) {
        _selectedScanIds.add(scanId);
      }
      _errorMessage = null;
    });
  }

  void _toggleSelectionMode() {
    if (_assigning) {
      return;
    }
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedScanIds.clear();
      }
      _errorMessage = null;
    });
  }

  Future<void> _openFilters() async {
    if (_assigning || _selectionMode) {
      return;
    }
    final selected = await showBatchScansFilterSheet(context, _filters);
    if (selected != null && mounted) {
      setState(() {
        _filters = selected;
        _errorMessage = null;
      });
      final batch = await ref.read(
        batchSnapshotProvider(widget.batchId).future,
      );
      if (mounted && batch != null) await _reloadPage(batch);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(batchSnapshotProvider(widget.batchId));
    return Scaffold(
      appBar: AppBar(title: const Text('Add scans to batch')),
      body: _buildBody(context, snapshot),
      bottomNavigationBar: _buildActionBar(context, snapshot),
    );
  }

  Widget _buildBody(BuildContext context, AsyncValue<BatchSnapshot?> snapshot) {
    return snapshot.when(
      loading: () => const Center(
        child: CircularProgressIndicator(semanticsLabel: 'Loading batch'),
      ),
      error: (error, stackTrace) => _AddScansError(
        message: 'This batch could not be loaded.',
        onRetry: () => ref.invalidate(batchSnapshotProvider(widget.batchId)),
      ),
      data: (batchSnapshot) {
        if (batchSnapshot == null) {
          return const _AddScansMessage(
            icon: Icons.inventory_2_outlined,
            title: 'Batch unavailable',
            message: 'This batch no longer exists on this device.',
          );
        }
        if (batchSnapshot.isLocked) {
          return const _AddScansMessage(
            icon: Icons.lock_outline,
            title: 'Batch is read-only',
            message: 'Completed-order batches cannot receive additional scans.',
          );
        }
        _ensurePage(batchSnapshot);
        return _buildAvailable(context, batchSnapshot);
      },
    );
  }

  Widget _buildAvailable(BuildContext context, BatchSnapshot snapshot) {
    final eligible = _records;
    final filteredEligible = eligible;
    final selectedIds = _selectedScanIds.intersection(
      filteredEligible.map((record) => record.id).toSet(),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add scans to ${snapshot.batch.name}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Only unassigned ${snapshot.batch.fruit.displayName} scans '
                  'are shown.',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _AddScansErrorMessage(message: _errorMessage!),
                ],
                if (_filters.activeCount > 0) ...[
                  const SizedBox(height: 14),
                  BatchScansActiveFilterTags(filters: _filters),
                ],
                const SizedBox(height: 20),
                if (_totalCount > 0) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BatchScansFilterButton(
                          activeCount: _filters.activeCount,
                          onPressed: _selectionMode ? null : _openFilters,
                        ),
                        if (filteredEligible.isNotEmpty)
                          TextButton.icon(
                            onPressed: _assigning ? null : _toggleSelectionMode,
                            icon: Icon(
                              _selectionMode
                                  ? Icons.close
                                  : Icons.check_box_outlined,
                            ),
                            label: Text(_selectionMode ? 'Cancel' : 'Select'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_loadingPage)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Loading unassigned scans',
                      ),
                    ),
                  )
                else if (_totalCount == 0 && _filters.activeCount == 0)
                  FeatureEmptyStateCard(
                    icon: Icons.photo_library_outlined,
                    title:
                        'No unassigned ${snapshot.batch.fruit.displayName} '
                        'scans',
                    message:
                        'Scans already assigned to another batch are not '
                        'listed here.',
                  )
                else if (filteredEligible.isEmpty) ...[
                  FeatureEmptyStateCard(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No scans match these filters',
                    message:
                        'Try adjusting the filters or clear them to see '
                        'all eligible scans.',
                    statusLabel: 'Filtered view',
                    action: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _filters = const HistoryFilters()),
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear filters'),
                    ),
                  ),
                ] else ...[
                  for (final record in filteredEligible) ...[
                    _AddScansCard(
                      record: record,
                      selectionEnabled: _selectionMode,
                      selected: selectedIds.contains(record.id),
                      disabled: _assigning,
                      onTap: () => _toggle(record.id),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_nextCursor != null) ...[
                    OutlinedButton.icon(
                      onPressed: _loadingMore
                          ? null
                          : () => _loadMore(snapshot),
                      icon: _loadingMore
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more),
                      label: Text(
                        _loadingMore ? 'Loading...' : 'Load more scans',
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildActionBar(
    BuildContext context,
    AsyncValue<BatchSnapshot?> snapshot,
  ) {
    BatchSnapshot? batch;
    snapshot.when(
      loading: () {},
      error: (error, stackTrace) {},
      data: (value) => batch = value,
    );
    final resolvedBatch = batch;
    if (resolvedBatch == null ||
        resolvedBatch.isLocked ||
        _loadingPage ||
        !_selectionMode) {
      return null;
    }
    final eligibleIds = _records.map((record) => record.id).toSet();
    final selectedIds = _selectedScanIds.intersection(eligibleIds);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton.icon(
          onPressed: selectedIds.isEmpty || _assigning
              ? null
              : () => _assign(selectedIds),
          icon: _assigning
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.playlist_add),
          label: Text(
            _assigning
                ? 'Adding scans...'
                : 'Add selected (${selectedIds.length})',
          ),
        ),
      ),
    );
  }
}

class _AddScansCard extends StatelessWidget {
  const _AddScansCard({
    required this.record,
    required this.selectionEnabled,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final SavedScanRecord record;
  final bool selectionEnabled;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = ripenessStageStyle(
      record.ripeness,
      brightness: Theme.of(context).brightness,
    );
    final label =
        '${record.fruit.displayName}, ${record.ripeness.displayName}, '
        '${formatSavedAt(record.createdAt)}';
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: disabled
              ? null
              : selectionEnabled
              ? onTap
              : () => context.push(
                  AppRoutes.savedScanDetails(record.id, fromAddScans: true),
                ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BatchRipenessChip(
                        label: record.ripeness.displayName,
                        style: style,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatSavedAt(record.createdAt),
                        style: const TextStyle(color: AppColors.secondaryText),
                      ),
                      if (record.resultOrigin == ResultOrigin.demo) ...[
                        const SizedBox(height: 5),
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
                if (selectionEnabled)
                  Checkbox(
                    value: selected,
                    onChanged: disabled ? null : (_) => onTap(),
                    semanticLabel: 'Select saved scan',
                  )
                else
                  const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddScansMessage extends StatelessWidget {
  const _AddScansMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Back to batch'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddScansError extends StatelessWidget {
  const _AddScansError({required this.message, required this.onRetry});

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

class _AddScansErrorMessage extends StatelessWidget {
  const _AddScansErrorMessage({required this.message});

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
