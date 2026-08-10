import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kami/app/theme/app_colors.dart';
import 'package:kami/features/batches/presentation/batch_providers.dart';
import 'package:kami/features/orders/application/order_actions.dart';
import 'package:kami/features/orders/domain/batch_order.dart';
import 'package:kami/features/orders/presentation/order_providers.dart';

class OrderScreen extends ConsumerWidget {
  const OrderScreen({required this.batchId, super.key});

  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batch = ref.watch(batchSnapshotProvider(batchId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order')),
      body: batch.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _OrderMessage(
          title: 'Batch unavailable',
          message: 'Kami could not load this local batch.',
        ),
        data: (snapshot) {
          if (snapshot == null) {
            return const _OrderMessage(
              title: 'Batch unavailable',
              message: 'This batch is no longer available on this device.',
            );
          }
          final order = ref.watch(activeBatchOrderProvider(batchId));
          return order.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const _OrderMessage(
              title: 'Order unavailable',
              message: 'Kami could not load the local order for this batch.',
            ),
            data: (value) {
              if (value == null && snapshot.summary.total == 0) {
                return const _OrderMessage(
                  title: 'Add a saved scan first',
                  message:
                      'A local order needs a batch with at least one saved '
                      'scan.',
                );
              }
              return _OrderEditor(
                key: ValueKey(value?.id ?? 'new-order'),
                batchId: batchId,
                batchName: snapshot.batch.name,
                order: value,
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderEditor extends ConsumerStatefulWidget {
  const _OrderEditor({
    required this.batchId,
    required this.batchName,
    required this.order,
    super.key,
  });

  final String batchId;
  final String batchName;
  final BatchOrder? order;

  @override
  ConsumerState<_OrderEditor> createState() => _OrderEditorState();
}

class _OrderEditorState extends ConsumerState<_OrderEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late DateTime _deliveryDate;
  bool _submitting = false;
  String? _errorMessage;

  bool get _completed => widget.order?.status == BatchOrderStatus.completed;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _nameController = TextEditingController(text: order?.customerName ?? '');
    _addressController = TextEditingController(
      text: order?.deliveryAddress ?? '',
    );
    _deliveryDate =
        order?.deliveryDate ??
        DateTime.utc(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final current = _deliveryDate.toLocal();
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Delivery date',
    );
    if (selected != null && mounted) {
      setState(
        () => _deliveryDate = DateTime.utc(
          selected.year,
          selected.month,
          selected.day,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_submitting || _completed) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final existing = widget.order;
      if (existing == null) {
        await ref
            .read(createOrderUseCaseProvider)
            .execute(
              batchId: widget.batchId,
              customerName: _nameController.text,
              deliveryAddress: _addressController.text,
              deliveryDate: _deliveryDate,
            );
      } else {
        await ref
            .read(updatePendingOrderUseCaseProvider)
            .execute(
              existing: existing,
              customerName: _nameController.text,
              deliveryAddress: _addressController.text,
              deliveryDate: _deliveryDate,
            );
      }
    } on OrderActionException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _cancel() async {
    final approved =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Pending order?'),
            content: const Text(
              'This removes the Pending order details from this device. The '
              'batch and its saved scans will remain, and you can create a '
              'new order later.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep order'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancel order'),
              ),
            ],
          ),
        ) ??
        false;
    if (!approved || !mounted || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(cancelPendingOrderUseCaseProvider)
          .execute(batchId: widget.order!.batchId);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on OrderActionException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  order == null ? 'Create local order' : 'Local order',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'For ${widget.batchName}. Customer details stay on this '
                  'device while Kami is offline.',
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 20),
                if (_completed) ...[
                  const _CompletedOrderNotice(),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _nameController,
                  enabled: !_completed && !_submitting,
                  maxLength: 160,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Customer name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  enabled: !_completed && !_submitting,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Delivery address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _completed || _submitting ? null : _chooseDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('Delivery date: ${_formatDate(_deliveryDate)}'),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (!_completed) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _save,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _submitting
                          ? 'Saving...'
                          : order == null
                          ? 'Create local order'
                          : 'Save changes',
                    ),
                  ),
                  if (order != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _submitting ? null : _cancel,
                      icon: Icon(
                        Icons.cancel_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      label: Text(
                        'Cancel Pending order',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
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

class _CompletedOrderNotice extends StatelessWidget {
  const _CompletedOrderNotice();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: AppColors.brandGreen),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Completed order. The customer details and batch membership '
                'are now read-only on this device.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderMessage extends StatelessWidget {
  const _OrderMessage({required this.title, required this.message});

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
            const Icon(Icons.receipt_long_outlined, size: 44),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
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
  final local = value.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
