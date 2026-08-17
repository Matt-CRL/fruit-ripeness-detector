import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kami/app/router/app_routes.dart';
import 'package:kami/app/router/main_shell.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/core/layout/kami_responsive.dart';
import 'package:kami/core/widgets/feature_empty_state_card.dart';
import 'package:kami/features/batches/application/batch_actions.dart';
import 'package:kami/features/batches/domain/fruit_batch.dart';
import 'package:kami/features/batches/presentation/batch_providers.dart';
import 'package:kami/features/batches/presentation/batch_shelf_life_guidance.dart';
import 'package:kami/features/history/domain/saved_scan_record.dart';
import 'package:kami/features/history/domain/saved_scan_query.dart';
import 'package:kami/features/history/data/drift_scan_record_repository.dart';
import 'package:kami/features/history/presentation/history_filters.dart';
import 'package:kami/features/history/presentation/history_providers.dart';
import 'package:kami/features/history/presentation/history_screen.dart';
import 'package:kami/features/history/presentation/saved_scan_image.dart';
import 'package:kami/features/orders/application/order_actions.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/orders/presentation/order_providers.dart';
import 'package:kami/features/scan/domain/scan_models.dart';
import 'package:kami/features/scan/presentation/ripeness_stage_style.dart';

const _batchScanPreviewLimit = 3;

class BatchesScreen extends ConsumerStatefulWidget {
  const BatchesScreen({super.key});

  @override
  ConsumerState<BatchesScreen> createState() => _BatchesScreenState();
}

class _BatchesScreenState extends ConsumerState<BatchesScreen> {
  final _searchController = TextEditingController();
  _BatchFilterStatus _selectedStatus = _BatchFilterStatus.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPaged(context);

  Widget _buildPaged(BuildContext context) {
    Future<void> createBatch() async {
      final batchId = await context.push<String>(AppRoutes.batchCreate);
      if (context.mounted && batchId != null) {
        await context.push(AppRoutes.batchDetails(batchId));
      }
    }

    final contentSlivers = ref
        .watch(activeBatchListProvider)
        .when<List<Widget>>(
          loading: () => [
            SliverToBoxAdapter(
              child: _batchBounded(
                context,
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: KamiResponsive.value(
                      context,
                      regular: 20,
                      compact: 12,
                    ),
                  ),
                  child: _BatchLoading(),
                ),
              ),
            ),
          ],
          error: (error, stackTrace) => [
            SliverToBoxAdapter(
              child: _batchBounded(
                context,
                _BatchError(
                  onRetry: () => ref.invalidate(activeBatchListProvider),
                ),
              ),
            ),
          ],
          data: (items) {
            // Orders are secondary metadata for a batch card. Render the
            // lightweight batch summaries immediately while the order stream
            // catches up, then rebuild cards when it emits.
            final activeOrders = ref
                .watch(activeOrdersProvider)
                .maybeWhen(data: (orders) => orders, orElse: () => const []);
                  if (items.isEmpty) {
                    return [
                      SliverToBoxAdapter(
                        child: _batchBounded(
                          context,
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: KamiResponsive.value(
                                context,
                                regular: 20,
                                compact: 12,
                              ),
                            ),
                            child: FeatureEmptyStateCard(
                              icon: Icons.inventory_2_outlined,
                              title: 'No batches yet',
                              message:
                                  'Create an empty batch here, or save a scan and '
                                  'choose Save & Add to Batch.',
                              statusLabel: 'Ready offline',
                            ),
                          ),
                        ),
                      ),
                    ];
                  }

                  final ordersByBatch = {
                    for (final order in activeOrders) order.batchId: order,
                  };
                  final normalizedQuery = _searchQuery.trim().toLowerCase();
                  final filtered = items
                      .where((item) {
                        final nameMatches =
                            normalizedQuery.isEmpty ||
                            item.batch.name.toLowerCase().contains(
                              normalizedQuery,
                            );
                        final status = _batchFilterStatus(
                          item,
                          ordersByBatch[item.batch.id],
                        );
                        final statusMatches =
                            _selectedStatus == _BatchFilterStatus.all ||
                            status == _selectedStatus;
                        return nameMatches && statusMatches;
                      })
                      .toList(growable: false);

                  if (filtered.isEmpty) {
                    return [
                      SliverToBoxAdapter(
                        child: _batchBounded(
                          context,
                          SizedBox(
                            width: double.infinity,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: KamiResponsive.value(
                                  context,
                                  regular: 20,
                                  compact: 12,
                                ),
                              ),
                              child: _BatchFilterEmpty(
                                query: _searchQuery.trim(),
                                status: _selectedStatus,
                                onClearSearch: _searchQuery.trim().isEmpty
                                    ? null
                                    : () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                onClearStatus:
                                    _selectedStatus == _BatchFilterStatus.all
                                    ? null
                                    : () => setState(
                                        () => _selectedStatus =
                                            _BatchFilterStatus.all,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ];
                  }

            return [
                    SliverToBoxAdapter(
                      child: _batchBounded(
                        context,
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            KamiResponsive.value(
                              context,
                              regular: 20,
                              compact: 12,
                            ),
                            0,
                            KamiResponsive.value(
                              context,
                              regular: 20,
                              compact: 12,
                            ),
                            12,
                          ),
                          child: Text(
                            '${filtered.length} ${filtered.length == 1 ? 'batch' : 'batches'}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _batchBounded(
                          context,
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              KamiResponsive.value(
                                context,
                                regular: 20,
                                compact: 12,
                              ),
                              0,
                              KamiResponsive.value(
                                context,
                                regular: 20,
                                compact: 12,
                              ),
                              12,
                            ),
                            child: _BatchCard(
                              snapshot: item,
                              order: ordersByBatch[item.batch.id],
                            ),
                          ),
                        );
                      },
                    ),
            ];
          },
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeBatchListProvider);
          ref.invalidate(activeOrdersProvider);
          await ref.read(activeBatchListProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _batchBounded(
                context,
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    KamiResponsive.value(context, regular: 20, compact: 12),
                    8,
                    KamiResponsive.value(context, regular: 20, compact: 12),
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Organize fruit by batch',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Group saved scans of one fruit type and review their '
                        'ripeness summary offline.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 16),
                      const _RipenessLegend(),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: createBatch,
                        icon: const Icon(Icons.add),
                        label: const Text('Create batch'),
                      ),
                      const SizedBox(height: 20),
                      _BatchSearchField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      const SizedBox(height: 14),
                      _BatchStatusFilter(
                        selected: _selectedStatus,
                        onSelected: (status) =>
                            setState(() => _selectedStatus = status),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ...contentSlivers,
            SliverToBoxAdapter(
              child: SizedBox(
                height: 36 + mainNavigationContentBottomInset(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batchBounded(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: child,
      ),
    );
  }
}

enum _BatchFilterStatus { all, noOrder, pending, completed }

class _BatchSearchField extends StatelessWidget {
  const _BatchSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: 'Search batches',
        hintText: 'Search by batch name',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
              ),
      ),
    );
  }
}

class _BatchStatusFilter extends StatelessWidget {
  const _BatchStatusFilter({required this.selected, required this.onSelected});

  final _BatchFilterStatus selected;
  final ValueChanged<_BatchFilterStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by order status',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final status in _BatchFilterStatus.values)
              ChoiceChip(
                label: Text(_batchFilterStatusLabel(status)),
                selected: selected == status,
                onSelected: (_) => onSelected(status),
              ),
          ],
        ),
      ],
    );
  }
}

class _BatchFilterEmpty extends StatelessWidget {
  const _BatchFilterEmpty({
    required this.query,
    required this.status,
    required this.onClearSearch,
    required this.onClearStatus,
  });

  final String query;
  final _BatchFilterStatus status;
  final VoidCallback? onClearSearch;
  final VoidCallback? onClearStatus;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.isNotEmpty;
    final hasStatus = status != _BatchFilterStatus.all;
    final title = hasQuery && hasStatus
        ? 'No matching batches'
        : hasQuery
        ? 'No batches found'
        : 'No batches with this status';
    final message = hasQuery && hasStatus
        ? 'Try a different name or order-status filter.'
        : hasQuery
        ? 'Try a different batch name.'
        : 'Try another order-status filter.';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 42),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onClearSearch != null)
                  OutlinedButton(
                    onPressed: onClearSearch,
                    child: const Text('Clear search'),
                  ),
                if (onClearStatus != null)
                  OutlinedButton(
                    onPressed: onClearStatus,
                    child: Text(
                      hasQuery ? 'Clear status filter' : 'Clear filter',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BatchCreateScreen extends ConsumerStatefulWidget {
  const BatchCreateScreen({this.scanId, this.scanIds = const [], super.key});

  final String? scanId;
  final List<String> scanIds;

  @override
  ConsumerState<BatchCreateScreen> createState() => _BatchCreateScreenState();
}

class _BatchCreateScreenState extends ConsumerState<BatchCreateScreen> {
  final _nameController = TextEditingController();
  FruitIdentifier _fruit = FruitIdentifier.carabaoMango;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit(FruitIdentifier fruit) async {
    if (_submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final batch = await ref
          .read(createBatchUseCaseProvider)
          .execute(
            name: _nameController.text,
            fruit: fruit,
            scanId: widget.scanId,
            scanIds: widget.scanIds,
          );
      if (!mounted) {
        return;
      }
      if (context.canPop()) {
        context.pop(batch.id);
      } else {
        context.go(AppRoutes.batchDetails(batch.id));
      }
    } on BatchActionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorMessage = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanId = widget.scanId;
    if (scanId == null && widget.scanIds.isEmpty) {
      return _buildScaffold();
    }

    if (widget.scanIds.isNotEmpty) {
      final scans = ref.watch(activeScanRecordsProvider);
      return Scaffold(
        appBar: AppBar(title: const Text('Create batch')),
        body: scans.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading selected scans',
            ),
          ),
          error: (error, stackTrace) => _FullPageError(
            message: 'The selected scans could not be loaded.',
            onRetry: () => ref.invalidate(activeScanRecordsProvider),
          ),
          data: (records) {
            final selected = records
                .where((record) => widget.scanIds.contains(record.id))
                .toList(growable: false);
            final fruit = selected.isEmpty ? null : selected.first.fruit;
            final ownerId = selected.isEmpty ? null : selected.first.ownerId;
            final valid =
                selected.length == widget.scanIds.length &&
                fruit != null &&
                selected.every(
                  (record) =>
                      record.batchId == null &&
                      record.fruit == fruit &&
                      record.ownerId == ownerId,
                );
            return valid
                ? _buildBody(
                    lockedFruit: fruit,
                    selectedScanCount: selected.length,
                  )
                : const _FullPageMessage(
                    icon: Icons.image_not_supported_outlined,
                    title: 'Selected scans unavailable',
                    message:
                        'Only active, unassigned scans of one fruit type can '
                        'be added to a new batch.',
                  );
          },
        ),
      );
    }

    final singleScanId = scanId;
    if (singleScanId == null) {
      return _buildScaffold();
    }
    final scan = ref.watch(savedScanRecordProvider(singleScanId));
    return Scaffold(
      appBar: AppBar(title: const Text('Create batch')),
      body: scan.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading saved scan',
          ),
        ),
        error: (error, stackTrace) => _FullPageError(
          message: 'The saved scan could not be loaded.',
          onRetry: () => ref.invalidate(savedScanRecordProvider(singleScanId)),
        ),
        data: (record) => record == null
            ? const _FullPageMessage(
                icon: Icons.image_not_supported_outlined,
                title: 'Saved scan unavailable',
                message: 'This scan can no longer be added to a new batch.',
              )
            : _buildBody(lockedFruit: record.fruit),
      ),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(title: const Text('Create batch')),
      body: _buildBody(),
    );
  }

  Widget _buildBody({FruitIdentifier? lockedFruit, int? selectedScanCount}) {
    final fruit = lockedFruit ?? _fruit;
    return ListView(
      padding: KamiResponsive.pagePadding(context, top: 8, bottom: 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  selectedScanCount != null
                      ? 'Create a batch for $selectedScanCount scans'
                      : lockedFruit == null
                      ? 'Start a new batch'
                      : 'Create a batch for this scan',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedScanCount != null
                      ? 'The fruit type is fixed to ${fruit.displayName}; all '
                            'selected scans will be assigned together.'
                      : lockedFruit == null
                      ? 'Choose one fruit type. Only matching saved scans can '
                            'be added later.'
                      : 'The fruit type is fixed to ${fruit.displayName} so '
                            'the saved scan stays compatible.',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  enabled: !_submitting,
                  maxLength: 120,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(fruit),
                  decoration: const InputDecoration(
                    labelText: 'Batch name',
                    hintText: 'Example: Friday market mangoes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (lockedFruit == null)
                  DropdownMenu<FruitIdentifier>(
                    initialSelection: _fruit,
                    selectOnly: true,
                    enableSearch: false,
                    expandedInsets: EdgeInsets.zero,
                    menuHeight: 280,
                    trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                    selectedTrailingIcon: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                    ),
                    label: const Text('Fruit type'),
                    textStyle: Theme.of(context).textTheme.bodyLarge,
                    menuStyle: MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.surface,
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    dropdownMenuEntries: [
                      for (final value in FruitIdentifier.values)
                        DropdownMenuEntry(
                          value: value,
                          label: value.displayName,
                        ),
                    ],
                    onSelected: _submitting
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _fruit = value);
                            }
                          },
                  )
                else
                  _LockedFruitField(fruit: fruit),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _InlineError(message: _errorMessage!),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submitting ? null : () => _submit(fruit),
                  icon: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Creating batch',
                          ),
                        )
                      : const Icon(Icons.inventory_2_outlined),
                  label: Text(_submitting ? 'Creating...' : 'Create batch'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BatchDetailsScreen extends ConsumerWidget {
  const BatchDetailsScreen({required this.batchId, super.key});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(batchSnapshotProvider(batchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Batch details')),
      body: snapshot.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading batch details',
          ),
        ),
        error: (error, stackTrace) => _FullPageError(
          message: 'This batch could not be loaded.',
          onRetry: () => ref.invalidate(batchSnapshotProvider(batchId)),
        ),
        data: (value) => value == null
            ? const _FullPageMessage(
                icon: Icons.inventory_2_outlined,
                title: 'Batch unavailable',
                message: 'This batch no longer exists on this device.',
              )
            : _BatchDetails(snapshot: value),
      ),
    );
  }
}

class _BatchDetails extends StatelessWidget {
  const _BatchDetails({required this.snapshot});

  final BatchSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final batch = snapshot.batch;
    final previewScans = snapshot.scans.take(_batchScanPreviewLimit).toList();
    final hasMoreScans = snapshot.scans.length > _batchScanPreviewLimit;
    return ListView(
      padding: KamiResponsive.pagePadding(context, top: 8, bottom: 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: batch.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      TextSpan(
                        text: ' · Created ${_formatBatchDate(batch.createdAt)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${batch.fruit.displayName} • Stored on this device',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                if (snapshot.containsDemo) ...[
                  const SizedBox(height: 14),
                  const _DemoBatchNotice(),
                ],
                if (snapshot.isLocked) ...[
                  const SizedBox(height: 14),
                  const _LockedBatchNotice(),
                ],
                const SizedBox(height: 16),
                BatchSummaryCard(
                  summary: snapshot.summary,
                  scans: snapshot.scans,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Saved scans',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (!snapshot.isLocked)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final addedCount = await context.push<int>(
                            AppRoutes.batchAddScans(batch.id),
                          );
                          if (!context.mounted ||
                              addedCount == null ||
                              addedCount <= 0) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$addedCount ${addedCount == 1 ? 'scan' : 'scans'} '
                                'added successfully.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('Add scans'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (snapshot.scans.isEmpty)
                  const FeatureEmptyStateCard(
                    icon: Icons.photo_library_outlined,
                    title: 'No scans in this batch',
                    message:
                        'Use Add scans to choose an unassigned saved scan '
                        'of the same fruit.',
                    statusLabel: 'Empty batch',
                  )
                else
                  for (final scan in previewScans) ...[
                    _BatchScanCard(record: scan, openedFromBatchScans: true),
                    const SizedBox(height: 12),
                  ],
                if (hasMoreScans) ...[
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.batchScans(batch.id)),
                    icon: const Icon(Icons.list_alt_outlined),
                    label: Text('View all scans (${snapshot.scans.length})'),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                _BatchOrderCard(snapshot: snapshot),
                const SizedBox(height: 16),
                _BatchManagementCard(snapshot: snapshot),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BatchScansScreen extends ConsumerWidget {
  const BatchScansScreen({required this.batchId, super.key});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(batchSnapshotProvider(batchId));
    return Scaffold(
      appBar: AppBar(title: const Text('All saved scans')),
      body: snapshot.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Loading saved scans',
          ),
        ),
        error: (error, stackTrace) => _FullPageError(
          message: 'The saved scans could not be loaded.',
          onRetry: () => ref.invalidate(batchSnapshotProvider(batchId)),
        ),
        data: (value) => value == null
            ? const _FullPageMessage(
                icon: Icons.inventory_2_outlined,
                title: 'Batch unavailable',
                message: 'This batch no longer exists on this device.',
              )
            : _AllBatchScans(snapshot: value),
      ),
    );
  }
}

class _AllBatchScans extends ConsumerStatefulWidget {
  const _AllBatchScans({required this.snapshot});

  final BatchSnapshot snapshot;

  @override
  ConsumerState<_AllBatchScans> createState() => _AllBatchScansState();
}

class _AllBatchScansState extends ConsumerState<_AllBatchScans> {
  static const _pageSize = 50;

  final _selectedScanIds = <String>{};
  List<SavedScanRecord> _records = const [];
  PageCursor? _nextCursor;
  int _totalCount = 0;
  bool _loading = true;
  bool _loadingMore = false;
  HistoryFilters _filters = const HistoryFilters();
  bool _selectionMode = false;
  bool _working = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  SavedScanQuery _query() {
    final base = _filters.toSavedScanQuery();
    return SavedScanQuery(
      fruit: base.fruit,
      ripeness: base.ripeness,
      batchId: widget.snapshot.batch.id,
      createdFromUtc: base.createdFromUtc,
      createdUntilUtc: base.createdUntilUtc,
      sortOrder: base.sortOrder,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final page = await ref
          .read(scanRecordRepositoryProvider)
          .fetchPage(query: _query(), limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _records = page.records;
        _totalCount = page.totalCount;
        _nextCursor = page.nextCursor;
        _loading = false;
        _selectedScanIds.removeWhere(
          (id) => !_records.any((record) => record.id == id),
        );
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (_loadingMore || cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(scanRecordRepositoryProvider)
          .fetchPage(query: _query(), cursor: cursor, limit: _pageSize);
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

  Future<void> _openFilters() async {
    if (_working || _selectionMode) {
      return;
    }
    final selected = await showBatchScansFilterSheet(context, _filters);
    if (selected != null && mounted) {
      setState(() {
        _filters = selected;
        _errorMessage = null;
      });
      await _reload();
    }
  }

  void _toggle(String scanId) {
    if (_working) {
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
    if (_working) {
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

  Future<void> _removeSelected(Set<String> selectedIds) async {
    if (selectedIds.isEmpty || _working) {
      return;
    }
    final count = selectedIds.length;
    final approved =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Remove $count scans from batch?'),
            content: const Text(
              'The selected scans will remain in History but no longer count '
              'toward this batch.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove scans'),
              ),
            ],
          ),
        ) ??
        false;
    if (!approved || !mounted) {
      return;
    }
    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(removeScansFromBatchUseCaseProvider)
          .execute(scanIds: selectedIds);
      if (!mounted) {
        return;
      }
      setState(() {
        _working = false;
        _selectionMode = false;
        _selectedScanIds.clear();
      });
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$count ${count == 1 ? 'scan' : 'scans'} removed from batch.',
          ),
        ),
      );
    } on BatchActionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _working = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _moveSelected(Set<String> selectedIds) async {
    if (selectedIds.isEmpty || _working) return;
    final movedTo = await context.push<String>(
      AppRoutes.moveMultipleScansToBatch,
      extra: selectedIds.toList(growable: false),
    );
    if (!mounted || movedTo == null) return;
    final count = selectedIds.length;
    setState(() {
      _selectionMode = false;
      _selectedScanIds.clear();
    });
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$count ${count == 1 ? 'scan' : 'scans'} moved to another batch.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final filteredScans = _records;
    final selectedIds = _selectedScanIds.intersection(
      filteredScans.map((scan) => scan.id).toSet(),
    );
    return ListView(
      padding: KamiResponsive.pagePadding(context, top: 8, bottom: 36),
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
                        snapshot.batch.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    BatchScansFilterButton(
                      activeCount: _filters.activeCount,
                      onPressed: _selectionMode ? null : _openFilters,
                    ),
                    if (!snapshot.isLocked && _totalCount > 0)
                      TextButton.icon(
                        onPressed: _working ? null : _toggleSelectionMode,
                        icon: Icon(
                          _selectionMode
                              ? Icons.close
                              : Icons.check_box_outlined,
                        ),
                        label: Text(_selectionMode ? 'Cancel' : 'Select'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _filters.activeCount == 0
                      ? '$_totalCount saved scans'
                      : '${filteredScans.length} of $_totalCount '
                            'saved scans',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                if (_selectionMode) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: selectedIds.isEmpty || _working
                              ? null
                              : () => _moveSelected(selectedIds),
                          icon: const Icon(Icons.drive_file_move_outline),
                          label: const Text('Move to another batch'),
                        ),
                        FilledButton.icon(
                          onPressed: selectedIds.isEmpty || _working
                              ? null
                              : () => _removeSelected(selectedIds),
                          icon: _working
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.remove_circle_outline),
                          label: Text(
                            _working
                                ? 'Removing scans...'
                                : selectedIds.isEmpty
                                ? 'Remove'
                                : 'Remove (${selectedIds.length})',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Loading saved scans...')),
                  )
                else if (_totalCount == 0 && _filters.activeCount == 0)
                  const FeatureEmptyStateCard(
                    icon: Icons.photo_library_outlined,
                    title: 'No scans in this batch',
                    message: 'Saved scans assigned to this batch appear here.',
                    statusLabel: 'Empty batch',
                  )
                else if (filteredScans.isEmpty) ...[
                  BatchScansActiveFilterTags(filters: _filters),
                  const SizedBox(height: 12),
                  FeatureEmptyStateCard(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No scans match these filters',
                    message:
                        'Try adjusting the filters or clear them to see '
                        'all scans in this batch.',
                    statusLabel: 'Filtered view',
                    action: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _filters = const HistoryFilters()),
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Clear filters'),
                    ),
                  ),
                ] else ...[
                  if (_filters.activeCount > 0) ...[
                    BatchScansActiveFilterTags(filters: _filters),
                    const SizedBox(height: 12),
                  ],
                  for (final scan in filteredScans) ...[
                    _BatchScanCard(
                      record: scan,
                      openedFromBatchScans: true,
                      selectionEnabled: _selectionMode,
                      selected: selectedIds.contains(scan.id),
                      onSelected: _selectionMode
                          ? (_) => _toggle(scan.id)
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_nextCursor != null) ...[
                    OutlinedButton.icon(
                      onPressed: _loadingMore ? null : _loadMore,
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
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BatchScansActiveFilterTags extends StatelessWidget {
  const BatchScansActiveFilterTags({required this.filters, super.key});

  final HistoryFilters filters;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      if (filters.ripeness != null)
        'Ripeness: ${filters.ripeness!.displayName}',
      if (filters.dateKind != HistoryDateFilterKind.all)
        'Date: ${_batchScansDateFilterLabel(filters)}',
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

class BatchScansFilterButton extends StatelessWidget {
  const BatchScansFilterButton({
    required this.activeCount,
    required this.onPressed,
    super.key,
  });

  final int activeCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TextButton.icon(
          key: const Key('batch-scans-filter-button'),
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

class _BatchScansFilterSheet extends StatefulWidget {
  const _BatchScansFilterSheet({required this.initial});

  final HistoryFilters initial;

  @override
  State<_BatchScansFilterSheet> createState() => _BatchScansFilterSheetState();
}

Future<HistoryFilters?> showBatchScansFilterSheet(
  BuildContext context,
  HistoryFilters initial,
) {
  return showModalBottomSheet<HistoryFilters>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _BatchScansFilterSheet(initial: initial),
  );
}

class _BatchScansFilterSheetState extends State<_BatchScansFilterSheet> {
  late RipenessStage? _ripeness = widget.initial.ripeness;
  late HistoryDateFilterKind _dateKind = widget.initial.dateKind;
  late HistorySortOrder _sortOrder = widget.initial.sortOrder;
  late DateTime? _specificDate = widget.initial.specificDate;
  late DateTime? _rangeStart = widget.initial.rangeStart;
  late DateTime? _rangeEnd = widget.initial.rangeEnd;

  HistoryFilters get _draft => HistoryFilters(
    ripeness: _ripeness,
    dateKind: _dateKind,
    sortOrder: _sortOrder,
    specificDate: _specificDate,
    rangeStart: _rangeStart,
    rangeEnd: _rangeEnd,
  );

  void _clearAll() {
    setState(() {
      _ripeness = null;
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SafeArea(
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
              _BatchScansFilterSection(
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
              _BatchScansFilterSection(
                title: 'Sort',
                children: [
                  _choiceChip(
                    label: 'Newest first',
                    selected: _sortOrder == HistorySortOrder.newestFirst,
                    onSelected: (_) => setState(
                      () => _sortOrder = HistorySortOrder.newestFirst,
                    ),
                  ),
                  _choiceChip(
                    label: 'Oldest first',
                    selected: _sortOrder == HistorySortOrder.oldestFirst,
                    onSelected: (_) => setState(
                      () => _sortOrder = HistorySortOrder.oldestFirst,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _BatchScansFilterSection(
                title: 'Date',
                children: [
                  _choiceChip(
                    label: 'All time',
                    selected: _dateKind == HistoryDateFilterKind.all,
                    onSelected: (_) =>
                        _selectDateKind(HistoryDateFilterKind.all),
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
                        : _formatBatchScansDate(_specificDate!),
                    selected: _dateKind == HistoryDateFilterKind.specificDate,
                    onSelected: (_) => _pickSpecificDate(),
                  ),
                  _choiceChip(
                    label: _rangeStart == null || _rangeEnd == null
                        ? 'Date range'
                        : '${_formatBatchScansDate(_rangeStart!)} – '
                              '${_formatBatchScansDate(_rangeEnd!)}',
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

class _BatchScansFilterSection extends StatelessWidget {
  const _BatchScansFilterSection({required this.title, required this.children});

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

String _batchScansDateFilterLabel(HistoryFilters filters) {
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
      return date == null ? 'Specific date' : _formatBatchScansDate(date);
    case HistoryDateFilterKind.dateRange:
      final start = filters.rangeStart;
      final end = filters.rangeEnd;
      return start == null || end == null
          ? 'Date range'
          : '${_formatBatchScansDate(start)} - ${_formatBatchScansDate(end)}';
  }
}

String _formatBatchScansDate(DateTime value) =>
    '${value.month}/${value.day}/${value.year}';

String _formatBatchDate(DateTime value) {
  final local = value.toLocal();
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
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

class _BatchMetadataRow extends StatelessWidget {
  const _BatchMetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _BatchOrderCard extends ConsumerWidget {
  const _BatchOrderCard({required this.snapshot});

  final BatchSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(activeBatchOrderProvider(snapshot.batch.id));
    final activeOrder = order.when(
      data: (value) => value,
      loading: () => null,
      error: (error, stackTrace) => null,
    );
    final hasActiveOrder = activeOrder != null;
    final isPending = activeOrder?.status == BatchOrderStatus.pending;
    final isCompleted =
        snapshot.isLocked || activeOrder?.status == BatchOrderStatus.completed;
    final canManage =
        (snapshot.summary.total > 0 || hasActiveOrder) && !snapshot.isLocked;
    Future<void> completeOrder() async {
      final approved =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Mark order completed?'),
              content: const Text(
                'Completed orders cannot be reopened in this app. The batch '
                'will become read-only.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Complete order'),
                ),
              ],
            ),
          ) ??
          false;
      if (!approved || !context.mounted) {
        return;
      }
      try {
        await ref
            .read(completeOrderUseCaseProvider)
            .execute(batchId: activeOrder!.batchId);
      } on OrderActionException catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.brandGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCompleted
                            ? 'Completed order. This batch is read-only.'
                            : isPending
                            ? 'Pending order. You can still edit its details '
                                  'or correct scans.'
                            : canManage
                            ? 'Create order details for this batch.'
                            : 'Add at least one saved scan before creating '
                                  'an order.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (activeOrder != null) ...[
              const SizedBox(height: 14),
              _OrderDetailRow(
                label: 'Customer',
                value: activeOrder.customerName,
              ),
              const SizedBox(height: 10),
              _OrderDetailRow(
                label: 'Address',
                value: activeOrder.deliveryAddress,
              ),
              const SizedBox(height: 10),
              _OrderDetailRow(
                label: 'Delivery date',
                value: _formatOrderDate(activeOrder.deliveryDate),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: completeOrder,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark order completed'),
              ),
            ],
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: canManage || snapshot.isLocked
                  ? () => context.push(AppRoutes.batchOrder(snapshot.batch.id))
                  : null,
              icon: const Icon(Icons.receipt_long_outlined),
              label: Text(isCompleted ? 'View order' : 'Manage local order'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailRow extends StatelessWidget {
  const _OrderDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value),
      ],
    );
  }
}

class _BatchManagementCard extends ConsumerStatefulWidget {
  const _BatchManagementCard({required this.snapshot});

  final BatchSnapshot snapshot;

  @override
  ConsumerState<_BatchManagementCard> createState() =>
      _BatchManagementCardState();
}

class _BatchManagementCardState extends ConsumerState<_BatchManagementCard> {
  bool _working = false;
  String? _errorMessage;

  Future<void> _rename() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          _RenameBatchDialog(initialName: widget.snapshot.batch.name),
    );
    if (name == null || !mounted) {
      return;
    }

    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(renameBatchUseCaseProvider)
          .execute(batchId: widget.snapshot.batch.id, name: name);
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

  Future<void> _changeFruitType() async {
    final fruit = await showDialog<FruitIdentifier>(
      context: context,
      builder: (_) => _ChangeBatchFruitTypeDialog(
        currentFruit: widget.snapshot.batch.fruit,
      ),
    );
    if (fruit == null || !mounted || fruit == widget.snapshot.batch.fruit) {
      return;
    }

    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(changeBatchFruitTypeUseCaseProvider)
          .execute(batchId: widget.snapshot.batch.id, fruit: fruit);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fruit type changed to ${fruit.displayName}.'),
          ),
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

  Future<void> _delete({required bool deleteCompletedWithScans}) async {
    final approved =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              deleteCompletedWithScans
                  ? 'Delete completed batch?'
                  : 'Delete empty batch?',
            ),
            content: Text(
              deleteCompletedWithScans
                  ? 'Deleting this batch will also delete its ${widget.snapshot.summary.total} '
                        'saved scans and completed order from this device. '
                        'This cannot be undone in the app.'
                  : 'This batch has no saved scans. Deleting it removes the '
                        'batch from this device and cannot be undone in the app.',
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

    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(deleteBatchUseCaseProvider)
          .execute(
            batchId: widget.snapshot.batch.id,
            deleteCompletedWithScans: deleteCompletedWithScans,
          );
      if (mounted) {
        context.go(AppRoutes.batches);
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

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final locked = snapshot.isLocked;
    final activeOrder = ref.watch(activeBatchOrderProvider(snapshot.batch.id));
    final hasActiveOrder = activeOrder.when(
      data: (value) => value != null,
      loading: () => true,
      error: (error, stackTrace) => true,
    );
    final isPendingOrder = activeOrder.when(
      data: (value) => value?.status == BatchOrderStatus.pending,
      loading: () => false,
      error: (error, stackTrace) => false,
    );
    final deletable =
        locked || (!hasActiveOrder && snapshot.summary.total == 0);
    final canChangeFruitType =
        !locked && !hasActiveOrder && snapshot.summary.total == 0;
    final fruitTypeDisabledReason = locked
        ? 'Completed orders cannot change fruit type.'
        : hasActiveOrder
        ? 'Cancel the active order before changing fruit type.'
        : snapshot.summary.total > 0
        ? 'Empty the batch first to change fruit type.'
        : null;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manage batch',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              locked
                  ? 'Completed orders are read-only, but you can delete this '
                        'batch and its saved scans.'
                  : isPendingOrder && snapshot.summary.total <= 1
                  ? 'Pending orders must keep at least one saved scan. '
                        'Cancel the order before removing the final scan.'
                  : isPendingOrder
                  ? 'Pending orders remain editable, but this batch must '
                        'keep at least one saved scan.'
                  : hasActiveOrder
                  ? 'Cancel the Pending order before deleting this batch.'
                  : deletable
                  ? 'This empty batch can be renamed or deleted.'
                  : 'Move or remove every saved scan before deleting this batch.',
              style: const TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 14),
            Text(
              'Batch information',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _BatchMetadataRow(
              label: 'Created',
              value: _formatBatchMetadata(snapshot.batch.createdAt),
            ),
            const SizedBox(height: 6),
            _BatchMetadataRow(
              label: 'Last updated',
              value: _formatBatchMetadata(snapshot.batch.updatedAt),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: locked || _working ? null : _rename,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Rename batch'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: canChangeFruitType && !_working
                  ? _changeFruitType
                  : null,
              icon: const Icon(Icons.swap_horiz_outlined),
              label: const Text('Change fruit type'),
            ),
            if (fruitTypeDisabledReason != null) ...[
              const SizedBox(height: 6),
              Text(
                fruitTypeDisabledReason,
                style: const TextStyle(color: AppColors.secondaryText),
              ),
            ],
            const SizedBox(height: 10),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: deletable && !_working
                  ? () => _delete(deleteCompletedWithScans: locked)
                  : null,
              icon: const Icon(Icons.delete_outline),
              label: Text(
                locked ? 'Delete batch and scans' : 'Delete empty batch',
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChangeBatchFruitTypeDialog extends StatefulWidget {
  const _ChangeBatchFruitTypeDialog({required this.currentFruit});

  final FruitIdentifier currentFruit;

  @override
  State<_ChangeBatchFruitTypeDialog> createState() =>
      _ChangeBatchFruitTypeDialogState();
}

class _ChangeBatchFruitTypeDialogState
    extends State<_ChangeBatchFruitTypeDialog> {
  late FruitIdentifier _fruit = widget.currentFruit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change fruit type'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'This option is available because the batch has no saved scans.',
          ),
          const SizedBox(height: 16),
          for (final value in FruitIdentifier.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(value.displayName),
              selected: value == _fruit,
              leading: Icon(
                value == _fruit
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              onTap: () => setState(() => _fruit = value),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_fruit),
          child: const Text('Change fruit type'),
        ),
      ],
    );
  }
}

class _RenameBatchDialog extends StatefulWidget {
  const _RenameBatchDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameBatchDialog> createState() => _RenameBatchDialogState();
}

class _RenameBatchDialogState extends State<_RenameBatchDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename batch'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 120,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value),
        decoration: const InputDecoration(
          labelText: 'Batch name',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

_BatchFilterStatus _batchFilterStatus(
  BatchListItem snapshot,
  BatchOrder? order,
) {
  if (order?.status == BatchOrderStatus.completed) {
    return _BatchFilterStatus.completed;
  }
  if (order?.status == BatchOrderStatus.pending) {
    return _BatchFilterStatus.pending;
  }
  return _BatchFilterStatus.noOrder;
}

String _batchFilterStatusLabel(_BatchFilterStatus status) {
  return switch (status) {
    _BatchFilterStatus.all => 'All',
    _BatchFilterStatus.noOrder => 'No order',
    _BatchFilterStatus.pending => 'Pending',
    _BatchFilterStatus.completed => 'Completed',
  };
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.snapshot, required this.order});

  final BatchListItem snapshot;
  final BatchOrder? order;

  @override
  Widget build(BuildContext context) {
    final batch = snapshot.batch;
    final orderStatus = switch (_batchFilterStatus(snapshot, order)) {
      _BatchFilterStatus.noOrder => _BatchOrderTag.none,
      _BatchFilterStatus.pending => _BatchOrderTag.pending,
      _BatchFilterStatus.completed => _BatchOrderTag.completed,
      _BatchFilterStatus.all => _BatchOrderTag.none,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push(AppRoutes.batchDetails(batch.id)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.softBrandGreen,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.brandGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          batch.fruit.displayName,
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (snapshot.containsDemo) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [const _DemoChip()]),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _CountChip(
                    label: 'Total',
                    count: snapshot.summary.total,
                    color: AppColors.brandGreen,
                  ),
                  _CountChip(
                    label: null,
                    semanticLabel: 'Unripe ${snapshot.summary.unripe}',
                    count: snapshot.summary.unripe,
                    stage: RipenessStage.unripe,
                  ),
                  _CountChip(
                    label: null,
                    semanticLabel: 'Ripe ${snapshot.summary.ripe}',
                    count: snapshot.summary.ripe,
                    stage: RipenessStage.ripe,
                  ),
                  _CountChip(
                    label: null,
                    semanticLabel: 'Overripe ${snapshot.summary.overripe}',
                    count: snapshot.summary.overripe,
                    stage: RipenessStage.overripe,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _BatchOrderTagChip(status: orderStatus),
                  if (order != null)
                    _BatchOrderDateChip(date: order!.deliveryDate),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _BatchOrderTag { none, pending, completed }

class _BatchOrderTagChip extends StatelessWidget {
  const _BatchOrderTagChip({required this.status});

  final _BatchOrderTag status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final label = switch (status) {
      _BatchOrderTag.none => 'No order',
      _BatchOrderTag.pending => 'Pending',
      _BatchOrderTag.completed => 'Completed',
    };
    final foreground = switch (status) {
      _BatchOrderTag.none => theme.colorScheme.onSurfaceVariant,
      _BatchOrderTag.pending => AppColors.ripeYellow,
      _BatchOrderTag.completed =>
        dark ? AppColors.darkBrandGreen : AppColors.brandGreen,
    };
    return Semantics(
      label: 'Order status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: dark ? 0.22 : 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _BatchOrderDateChip extends StatelessWidget {
  const _BatchOrderDateChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final label = 'Delivery: ${_formatOrderDate(date)}';
    return Semantics(
      label: 'Delivery date ${_formatOrderDate(date)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_outlined,
            size: 17,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class BatchSummaryCard extends StatelessWidget {
  const BatchSummaryCard({
    required this.summary,
    required this.scans,
    super.key,
  });

  final BatchSummary summary;
  final List<SavedScanRecord> scans;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ripeness summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryValue(label: 'Total', value: summary.total),
                _SummaryValue(
                  label: 'Unripe',
                  value: summary.unripe,
                  stage: RipenessStage.unripe,
                ),
                _SummaryValue(
                  label: 'Ripe',
                  value: summary.ripe,
                  stage: RipenessStage.ripe,
                ),
                _SummaryValue(
                  label: 'Overripe',
                  value: summary.overripe,
                  stage: RipenessStage.overripe,
                ),
              ],
            ),
            BatchShelfLifeSummaryAction(scans: scans),
          ],
        ),
      ),
    );
  }
}

class _BatchScanCard extends StatelessWidget {
  const _BatchScanCard({
    required this.record,
    this.openedFromBatchScans = false,
    this.selectionEnabled = false,
    this.selected = false,
    this.onSelected,
  });

  final SavedScanRecord record;
  final bool openedFromBatchScans;
  final bool selectionEnabled;
  final bool selected;
  final ValueChanged<bool?>? onSelected;

  @override
  Widget build(BuildContext context) {
    final style = ripenessStageStyle(
      record.ripeness,
      brightness: Theme.of(context).brightness,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: selectionEnabled
            ? () => onSelected?.call(!selected)
            : () => context.push(
                AppRoutes.savedScanDetails(
                  record.id,
                  fromBatchScans: openedFromBatchScans,
                ),
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
                    Row(
                      children: [
                        BatchRipenessChip(
                          label: record.ripeness.displayName,
                          style: style,
                        ),
                        const Spacer(),
                        if (record.resultOrigin == ResultOrigin.demo)
                          const _DemoChip(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatSavedAt(record.createdAt),
                      style: const TextStyle(color: AppColors.secondaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (selectionEnabled)
                Checkbox(value: selected, onChanged: onSelected)
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class BatchRipenessChip extends StatelessWidget {
  const BatchRipenessChip({
    required this.label,
    required this.style,
    super.key,
  });

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 17, color: style.accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: style.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedFruitField extends StatelessWidget {
  const _LockedFruitField({required this.fruit});

  final FruitIdentifier fruit;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Fruit type',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.lock_outline),
      ),
      child: Text(fruit.displayName),
    );
  }
}

class _BatchLoading extends StatelessWidget {
  const _BatchLoading();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading batches'),
        ),
      ),
    );
  }
}

class _BatchError extends StatelessWidget {
  const _BatchError({required this.onRetry});

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
            const Icon(Icons.error_outline, color: AppColors.overripeOrange),
            const SizedBox(height: 12),
            Text(
              'Batches could not be loaded',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Your local data was not changed. Try loading it again.',
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

class _FullPageError extends StatelessWidget {
  const _FullPageError({required this.message, required this.onRetry});

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

class _FullPageMessage extends StatelessWidget {
  const _FullPageMessage({
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
            Icon(icon, size: 42),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

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

class _DemoBatchNotice extends StatelessWidget {
  const _DemoBatchNotice();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.science_outlined, color: AppColors.brandGreen),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Demo batch: one or more scans were not evaluated by a real '
                'model. Use this batch only to test the local workflow.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedBatchNotice extends StatelessWidget {
  const _LockedBatchNotice();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.secondaryText),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This batch is read-only because its order is completed.',
              ),
            ),
          ],
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
        color: AppColors.softBrandGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Demo',
        style: TextStyle(
          color: AppColors.brandGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    this.semanticLabel,
    required this.count,
    this.color,
    this.stage,
  }) : assert(color != null || stage != null),
       assert(color == null || stage == null);

  final String? label;
  final String? semanticLabel;
  final int count;
  final Color? color;
  final RipenessStage? stage;

  @override
  Widget build(BuildContext context) {
    final text = label == null ? '$count' : '$label $count';
    final style = stage == null
        ? null
        : ripenessStageStyle(stage!, brightness: Theme.of(context).brightness);
    final foreground = style?.accent ?? color!;
    final background = style?.background ?? foreground.withValues(alpha: 0.14);
    return Semantics(
      label: semanticLabel ?? text,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _RipenessLegend extends StatelessWidget {
  const _RipenessLegend();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ripeness colors', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _RipenessLegendChip(label: 'Unripe', color: AppColors.unripeGreen),
            _RipenessLegendChip(label: 'Ripe', color: AppColors.ripeYellow),
            _RipenessLegendChip(
              label: 'Overripe',
              color: AppColors.overripeOrange,
            ),
          ],
        ),
      ],
    );
  }
}

class _RipenessLegendChip extends StatelessWidget {
  const _RipenessLegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value, this.stage});

  final String label;
  final int value;
  final RipenessStage? stage;

  @override
  Widget build(BuildContext context) {
    final style = stage == null
        ? null
        : ripenessStageStyle(stage!, brightness: Theme.of(context).brightness);
    final valueWidget = style == null
        ? Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkBrandGreen
                  : AppColors.brandGreen,
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: style.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
    return SizedBox(
      width: 116,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          valueWidget,
          if (style != null) const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}

String _formatOrderDate(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _formatBatchMetadata(DateTime value) {
  final local = value.toLocal();
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
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
      ? local.hour - 12
      : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} at '
      '$hour:$minute $period';
}
