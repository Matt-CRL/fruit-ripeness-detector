import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/router/main_shell.dart';
import 'package:kami/core/widgets/feature_empty_state_card.dart';
import 'package:kami/features/batches/presentation/batch_providers.dart';
import 'package:kami/features/history/application/delete_saved_scan.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/history_selection_policy.dart';
import 'package:kami/features/history/domain/saved_scan_query.dart';
import 'package:kami/features/history/presentation/history_filters.dart';
import 'package:kami/features/history/presentation/saved_scan_image.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/ripeness_stage_style.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const _pageSize = 50;

  HistoryFilters _filters = const HistoryFilters();
  final Set<String> _selectedScanIds = <String>{};
  List<SavedScanRecord> _records = const [];
  PageCursor? _nextCursor;
  int _totalCount = 0;
  Object? _loadError;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSelecting = false;
  bool _isDeleting = false;
  String? _lastRefreshToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  Future<void> _openFilters() async {
    final selected = await showModalBottomSheet<HistoryFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _HistoryFilterSheet(initial: _filters),
    );
    if (selected != null && mounted) {
      setState(() => _filters = selected);
      await _reload();
    }
  }

  void _clearFilters() {
    setState(() => _filters = const HistoryFilters());
    _reload();
  }

  Future<void> _reload({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final page = await ref
          .read(scanRecordRepositoryProvider)
          .fetchPage(query: _filters.toSavedScanQuery(), limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _records = page.records;
        _totalCount = page.totalCount;
        _nextCursor = page.nextCursor;
        _isLoading = false;
        _loadError = null;
        _selectedScanIds.removeWhere(
          (id) => !_records.any((record) => record.id == id),
        );
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_isLoadingMore || cursor == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await ref
          .read(scanRecordRepositoryProvider)
          .fetchPage(
            query: _filters.toSavedScanQuery(),
            cursor: cursor,
            limit: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _records = [..._records, ...page.records];
        _nextCursor = page.nextCursor;
        _totalCount = page.totalCount;
        _isLoadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        _loadError = error;
      });
    }
  }

  void _enterSelection() {
    setState(() {
      _isSelecting = true;
      _selectedScanIds.clear();
    });
  }

  void _exitSelection() {
    if (_isDeleting) {
      return;
    }
    setState(() {
      _isSelecting = false;
      _selectedScanIds.clear();
    });
  }

  void _toggleSelection(String scanId) {
    setState(() {
      if (!_selectedScanIds.add(scanId)) {
        _selectedScanIds.remove(scanId);
      }
    });
  }

  void _selectAll(Iterable<SavedScanRecord> records) {
    setState(() {
      _selectedScanIds
        ..clear()
        ..addAll(records.map((record) => record.id));
    });
  }

  void _clearSelection() {
    setState(() => _selectedScanIds.clear());
  }

  Future<void> _deleteSelected(HistorySelectionPolicy policy) async {
    if (!policy.canDelete || _isDeleting) {
      return;
    }
    final ids = policy.records.map((record) => record.id).toSet();
    final count = ids.length;
    final approved =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete $count saved scans?'),
            content: const Text(
              'This removes the selected scans from History and deletes their '
              'private saved images from this device. This cannot be undone in '
              'the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!approved || !mounted) {
      return;
    }

    setState(() => _isDeleting = true);
    try {
      final deleted = await ref
          .read(deleteSavedScanUseCaseProvider)
          .executeMany(scanIds: ids);
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeleting = false;
        _isSelecting = false;
        _selectedScanIds.clear();
      });
      await _reload(showLoading: false);
      if (!mounted) return;
      final imageMessage = deleted.removedImageCount == deleted.records.length
          ? 'Private images deleted.'
          : 'Some private images could not be cleaned up.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${deleted.records.length} scans deleted. $imageMessage',
          ),
        ),
      );
    } on ScanManagementException catch (error) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _addSelectedToBatch(HistorySelectionPolicy policy) async {
    if (!policy.canAddToBatch || _isDeleting) {
      return;
    }
    final batchId = await context.push<String>(
      AppRoutes.addMultipleScansToBatch,
      extra: policy.records.map((record) => record.id).toList(growable: false),
    );
    if (!mounted || batchId == null) {
      return;
    }
    setState(() {
      _isSelecting = false;
      _selectedScanIds.clear();
    });
    await _reload(showLoading: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${policy.records.length} scans added to batch.')),
    );
  }

  @override
  Widget build(BuildContext context) => _buildPaged(context);

  Widget _buildPaged(BuildContext context) {
    // Detail screens add a one-shot refresh token when they mutate a record
    // and return to this stateful shell branch. This avoids subscribing the
    // paged screen to the full scan collection just to detect changes.
    final refreshToken = GoRouterState.of(context).uri.queryParameters['refresh'];
    if (refreshToken != null && refreshToken != _lastRefreshToken) {
      _lastRefreshToken = refreshToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reload(showLoading: false);
      });
    }
    final batchNames = ref
        .watch(activeBatchListProvider)
        .maybeWhen(
          data: (items) => <String, String>{
            for (final item in items) item.batch.id: item.batch.name,
          },
          orElse: () => const <String, String>{},
        );
    final selectionPolicy = HistorySelectionPolicy.from(
      _records.where((record) => _selectedScanIds.contains(record.id)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: RefreshIndicator(
        onRefresh: () => _reload(showLoading: false),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _historyBounded(
                context,
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Review past results',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Saved scans stay available on this device, even when '
                        'you are offline.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!_isSelecting) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 4,
                            children: [
                              _HistoryFilterButton(
                                activeCount: _filters.activeCount,
                                onPressed: _openFilters,
                              ),
                              TextButton.icon(
                                key: const Key('history-select-button'),
                                onPressed: _enterSelection,
                                icon: const Icon(Icons.check_box_outlined),
                                label: const Text('Select'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(child: _HistoryLoading())
            else if (_loadError != null)
              SliverToBoxAdapter(
                child: _historyBounded(
                  context,
                  _HistoryError(onRetry: _reload),
                ),
              )
            else if (_totalCount == 0 && _filters.activeCount == 0)
              SliverToBoxAdapter(
                child: _historyBounded(
                  context,
                  const FeatureEmptyStateCard(
                    icon: Icons.history_outlined,
                    title: 'No saved scans yet',
                    message:
                        'Save a result after choosing a fruit photo and it '
                        'will appear here.',
                    statusLabel: 'Ready offline',
                  ),
                ),
              )
            else if (_totalCount == 0)
              SliverToBoxAdapter(
                child: _historyBounded(
                  context,
                  Column(
                    children: [
                      _HistoryActiveFilterTags(filters: _filters),
                      const SizedBox(height: 12),
                      FeatureEmptyStateCard(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'No scans match these filters',
                        message:
                            'Try adjusting the filters or clear them to see '
                            'all saved scans.',
                        action: OutlinedButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear filters'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (_filters.activeCount > 0)
                SliverToBoxAdapter(
                  child: _historyBounded(
                    context,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _HistoryActiveFilterTags(filters: _filters),
                    ),
                  ),
                ),
              if (_isSelecting)
                SliverToBoxAdapter(
                  child: _historyBounded(
                    context,
                    _HistorySelectionToolbar(
                      selectedCount: _selectedScanIds.length,
                      totalCount: _records.length,
                      onSelectAll: () => _selectAll(_records),
                      onClearSelection: _clearSelection,
                      onCancel: _exitSelection,
                      onAddToBatch: selectionPolicy.canAddToBatch
                          ? () => _addSelectedToBatch(selectionPolicy)
                          : null,
                      showDisabledAddToBatch:
                          selectionPolicy.allUnassigned &&
                          (selectionPolicy.hasMixedFruit ||
                              selectionPolicy.hasMixedOwner),
                      onDelete: selectionPolicy.canDelete
                          ? () => _deleteSelected(selectionPolicy)
                          : null,
                      isDeleting: _isDeleting,
                    ),
                  ),
                ),
              if (_isSelecting && selectionPolicy.guidance != null)
                SliverToBoxAdapter(
                  child: _historyBounded(
                    context,
                    _HistorySelectionGuidance(
                      message: selectionPolicy.guidance!,
                    ),
                  ),
                ),
              SliverList.builder(
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  final record = _records[index];
                  return _historyBounded(
                    context,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _HistoryScanCard(
                        record: record,
                        batchName: record.batchId == null
                            ? 'Unassigned'
                            : batchNames[record.batchId] ?? 'Unassigned',
                        selectionMode: _isSelecting,
                        selected: _selectedScanIds.contains(record.id),
                        onSelected: () => _toggleSelection(record.id),
                      ),
                    ),
                  );
                },
              ),
              SliverToBoxAdapter(
                child: _historyBounded(
                  context,
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      36 + mainNavigationContentBottomInset(context),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Showing ${_records.length} of $_totalCount scans',
                        ),
                        if (_nextCursor != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _isLoadingMore ? null : _loadMore,
                            icon: _isLoadingMore
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.expand_more),
                            label: Text(
                              _isLoadingMore ? 'Loading...' : 'Load more',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _historyBounded(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: child,
      ),
    );
  }
}

class _HistoryActiveFilterTags extends StatelessWidget {
  const _HistoryActiveFilterTags({required this.filters});

  final HistoryFilters filters;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filters.fruit != null) 'Fruit: ${filters.fruit!.displayName}',
      if (filters.ripeness != null)
        'Ripeness: ${filters.ripeness!.displayName}',
      if (filters.inBatch != null)
        filters.inBatch! ? 'Batch: In a batch' : 'Batch: Unassigned',
      if (filters.dateKind != HistoryDateFilterKind.all)
        'Date: ${_dateFilterLabel(filters)}',
      if (filters.sortOrder == HistorySortOrder.oldestFirst)
        'Sort: Oldest first',
    ];

    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in labels)
            Chip(
              label: Text(label),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
    );
  }
}

String _dateFilterLabel(HistoryFilters filters) {
  switch (filters.dateKind) {
    case HistoryDateFilterKind.all:
      return 'All time';
    case HistoryDateFilterKind.today:
      return 'Today';
    case HistoryDateFilterKind.lastSevenDays:
      return 'Last 7 days';
    case HistoryDateFilterKind.lastThirtyDays:
      return 'Last 30 days';
    case HistoryDateFilterKind.specificDate:
      final date = filters.specificDate;
      return date == null ? 'Specific date' : _formatFilterDate(date);
    case HistoryDateFilterKind.dateRange:
      final start = filters.rangeStart;
      final end = filters.rangeEnd;
      return start == null || end == null
          ? 'Date range'
          : '${_formatFilterDate(start)} - ${_formatFilterDate(end)}';
  }
}

class _HistoryFilterButton extends StatelessWidget {
  const _HistoryFilterButton({
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextButton.icon(
          key: const Key('history-filter-button'),
          onPressed: onPressed,
          icon: const Icon(Icons.filter_alt_outlined),
          label: const Text('Filter'),
        ),
        if (activeCount > 0)
          Positioned(
            top: 0,
            right: -2,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '$activeCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryFilterSheet extends StatefulWidget {
  const _HistoryFilterSheet({required this.initial});

  final HistoryFilters initial;

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late FruitIdentifier? _fruit = widget.initial.fruit;
  late RipenessStage? _ripeness = widget.initial.ripeness;
  late bool? _inBatch = widget.initial.inBatch;
  late HistoryDateFilterKind _dateKind = widget.initial.dateKind;
  late HistorySortOrder _sortOrder = widget.initial.sortOrder;
  late DateTime? _specificDate = widget.initial.specificDate;
  late DateTime? _rangeStart = widget.initial.rangeStart;
  late DateTime? _rangeEnd = widget.initial.rangeEnd;

  HistoryFilters get _draft => HistoryFilters(
    fruit: _fruit,
    ripeness: _ripeness,
    inBatch: _inBatch,
    dateKind: _dateKind,
    sortOrder: _sortOrder,
    specificDate: _specificDate,
    rangeStart: _rangeStart,
    rangeEnd: _rangeEnd,
  );

  void _clearAll() {
    setState(() {
      _fruit = null;
      _ripeness = null;
      _inBatch = null;
      _dateKind = HistoryDateFilterKind.all;
      _sortOrder = HistorySortOrder.newestFirst;
      _specificDate = null;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _selectDateKind(HistoryDateFilterKind kind) {
    setState(() {
      _dateKind = kind;
      if (kind != HistoryDateFilterKind.specificDate) {
        _specificDate = null;
      }
      if (kind != HistoryDateFilterKind.dateRange) {
        _rangeStart = null;
        _rangeEnd = null;
      }
    });
  }

  Future<void> _pickSpecificDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _specificDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select scan date',
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _dateKind = HistoryDateFilterKind.specificDate;
      _specificDate = selected;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = _rangeStart != null && _rangeEnd != null
        ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
        : null;
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: initialRange,
      helpText: 'Select scan date range',
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _dateKind = HistoryDateFilterKind.dateRange;
      _specificDate = null;
      _rangeStart = selected.start;
      _rangeEnd = selected.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter saved scans',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close filters',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FilterSection(
              title: 'Fruit',
              children: [
                _choiceChip(
                  label: 'All',
                  selected: _fruit == null,
                  onSelected: (_) => setState(() => _fruit = null),
                ),
                for (final fruit in FruitIdentifier.values)
                  _choiceChip(
                    label: fruit.displayName,
                    selected: _fruit == fruit,
                    onSelected: (_) => setState(() => _fruit = fruit),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _FilterSection(
              title: 'Ripeness',
              children: [
                _choiceChip(
                  label: 'All',
                  selected: _ripeness == null,
                  onSelected: (_) => setState(() => _ripeness = null),
                ),
                for (final ripeness in RipenessStage.values)
                  _choiceChip(
                    label: ripeness.displayName,
                    selected: _ripeness == ripeness,
                    onSelected: (_) => setState(() => _ripeness = ripeness),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _FilterSection(
              title: 'Batch',
              children: [
                _choiceChip(
                  label: 'All',
                  selected: _inBatch == null,
                  onSelected: (_) => setState(() => _inBatch = null),
                ),
                _choiceChip(
                  label: 'Unassigned',
                  selected: _inBatch == false,
                  onSelected: (_) => setState(() => _inBatch = false),
                ),
                _choiceChip(
                  label: 'In a batch',
                  selected: _inBatch == true,
                  onSelected: (_) => setState(() => _inBatch = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FilterSection(
              title: 'Sort',
              children: [
                _choiceChip(
                  label: 'Newest first',
                  selected: _sortOrder == HistorySortOrder.newestFirst,
                  onSelected: (_) =>
                      setState(() => _sortOrder = HistorySortOrder.newestFirst),
                ),
                _choiceChip(
                  label: 'Oldest first',
                  selected: _sortOrder == HistorySortOrder.oldestFirst,
                  onSelected: (_) =>
                      setState(() => _sortOrder = HistorySortOrder.oldestFirst),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FilterSection(
              title: 'Date',
              children: [
                _choiceChip(
                  label: 'All time',
                  selected: _dateKind == HistoryDateFilterKind.all,
                  onSelected: (_) => _selectDateKind(HistoryDateFilterKind.all),
                ),
                _choiceChip(
                  label: 'Today',
                  selected: _dateKind == HistoryDateFilterKind.today,
                  onSelected: (_) =>
                      _selectDateKind(HistoryDateFilterKind.today),
                ),
                _choiceChip(
                  label: 'Last 7 days',
                  selected: _dateKind == HistoryDateFilterKind.lastSevenDays,
                  onSelected: (_) =>
                      _selectDateKind(HistoryDateFilterKind.lastSevenDays),
                ),
                _choiceChip(
                  label: 'Last 30 days',
                  selected: _dateKind == HistoryDateFilterKind.lastThirtyDays,
                  onSelected: (_) =>
                      _selectDateKind(HistoryDateFilterKind.lastThirtyDays),
                ),
                _choiceChip(
                  label: _specificDate == null
                      ? 'Specific date'
                      : _formatFilterDate(_specificDate!),
                  selected: _dateKind == HistoryDateFilterKind.specificDate,
                  onSelected: (_) => _pickSpecificDate(),
                ),
                _choiceChip(
                  label: _rangeStart == null || _rangeEnd == null
                      ? 'Date range'
                      : '${_formatFilterDate(_rangeStart!)} – '
                            '${_formatFilterDate(_rangeEnd!)}',
                  selected: _dateKind == HistoryDateFilterKind.dateRange,
                  onSelected: (_) => _pickDateRange(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _clearAll,
                    child: const Text('Clear all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_draft),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class _HistorySelectionToolbar extends StatelessWidget {
  const _HistorySelectionToolbar({
    required this.selectedCount,
    required this.totalCount,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onCancel,
    required this.onAddToBatch,
    required this.showDisabledAddToBatch,
    required this.onDelete,
    required this.isDeleting,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onCancel;
  final VoidCallback? onAddToBatch;
  final bool showDisabledAddToBatch;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$selectedCount of $totalCount selected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: selectedCount == totalCount ? null : onSelectAll,
                child: const Text('Select all'),
              ),
              TextButton(
                onPressed: selectedCount == 0 ? null : onClearSelection,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              TextButton.icon(
                key: const Key('history-select-button'),
                onPressed: isDeleting ? null : onCancel,
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              ),
              if (onAddToBatch != null || showDisabledAddToBatch)
                TextButton.icon(
                  key: const Key('history-add-selected-to-batch'),
                  onPressed: onAddToBatch,
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Add to batch'),
                ),
              if (onDelete != null)
                TextButton.icon(
                  key: const Key('history-delete-selected'),
                  onPressed: isDeleting ? null : onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistorySelectionGuidance extends StatelessWidget {
  const _HistorySelectionGuidance({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

String _formatFilterDate(DateTime value) =>
    '${value.month}/${value.day}/${value.year}';

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading saved scans',
          ),
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'History could not be loaded',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Your saved data was not changed. Try loading it again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryScanCard extends StatelessWidget {
  const _HistoryScanCard({
    required this.record,
    required this.batchName,
    this.selectionMode = false,
    this.selected = false,
    this.onSelected,
  });

  final SavedScanRecord record;
  final String batchName;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    final confidence = (record.modelConfidence * 100).round();
    final stageStyle = ripenessStageStyle(
      record.ripeness,
      brightness: Theme.of(context).brightness,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: selectionMode
            ? onSelected
            : () => context.push(AppRoutes.historyDetails(record.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox.square(
                  dimension: 84,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.fruit.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (record.resultOrigin == ResultOrigin.demo)
                          const _DemoChip(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _HistoryRipenessChip(
                          label: record.ripeness.displayName,
                          style: stageStyle,
                        ),
                        const SizedBox(width: 8),
                        Text('$confidence%'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatSavedAt(record.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Batch: $batchName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (selectionMode)
                Checkbox(value: selected, onChanged: (_) => onSelected?.call())
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRipenessChip extends StatelessWidget {
  const _HistoryRipenessChip({required this.label, required this.style});

  final String label;
  final RipenessStageStyle style;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Ripeness: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: style.accent.withValues(alpha: isDark ? 0.22 : 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(color: style.accent, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Demo',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String formatSavedAt(DateTime utcValue) {
  final value = utcValue.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${months[value.month - 1]} ${value.day}, ${value.year} • '
      '$hour:$minute $period';
}
