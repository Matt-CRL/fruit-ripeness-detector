import 'package:flutter_test/flutter_test.dart';
import 'package:kami/core/persistence/entity_id_generator.dart';
import 'package:kami/core/persistence/local_sync_state.dart';
import 'package:kami/features/orders/application/order_actions.dart';
import 'package:kami/features/orders/domain/batch_order.dart';

import '../../helpers/fake_order_repository.dart';

const _orderId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
const _batchId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
final _createdAt = DateTime.utc(2026, 8, 2, 12);
final _updatedAt = DateTime.utc(2026, 8, 2, 13);

void main() {
  test('creates trimmed local Pending orders', () async {
    final repository = FakeOrderRepository();
    addTearDown(repository.dispose);
    final useCase = CreateOrderUseCase(
      repository,
      const _FixedIdGenerator(),
      () => _createdAt,
    );

    final order = await useCase.execute(
      batchId: _batchId,
      customerName: '  Ada Lovelace  ',
      deliveryAddress: '  1 Market Street  ',
      deliveryDate: DateTime.utc(2026, 8, 5),
    );

    expect(order.id, _orderId);
    expect(order.customerName, 'Ada Lovelace');
    expect(order.deliveryAddress, '1 Market Street');
    expect(order.status, BatchOrderStatus.pending);
    expect(order.syncState, LocalSyncState.localOnly);
  });

  test('updates Pending details and then completes the local order', () async {
    final repository = FakeOrderRepository();
    addTearDown(repository.dispose);
    final create = CreateOrderUseCase(
      repository,
      const _FixedIdGenerator(),
      () => _createdAt,
    );
    final order = await create.execute(
      batchId: _batchId,
      customerName: 'Ada',
      deliveryAddress: 'First address',
      deliveryDate: DateTime.utc(2026, 8, 5),
    );

    await UpdatePendingOrderUseCase(repository, () => _updatedAt).execute(
      existing: order,
      customerName: 'Grace',
      deliveryAddress: 'Second address',
      deliveryDate: DateTime.utc(2026, 8, 6),
    );
    final updated = await repository.findActiveForBatch(_batchId);
    expect(updated?.customerName, 'Grace');
    expect(updated?.deliveryAddress, 'Second address');

    final completed = await CompleteOrderUseCase(
      repository,
      () => _updatedAt,
    ).execute(batchId: _batchId);
    expect(completed.status, BatchOrderStatus.completed);
    expect(
      (await repository.findActiveForBatch(_batchId))?.status,
      BatchOrderStatus.completed,
    );
  });

  test('cancels a Pending order without changing its batch data', () async {
    final repository = FakeOrderRepository();
    addTearDown(repository.dispose);
    final order =
        await CreateOrderUseCase(
          repository,
          const _FixedIdGenerator(),
          () => _createdAt,
        ).execute(
          batchId: _batchId,
          customerName: 'Ada',
          deliveryAddress: 'Address',
          deliveryDate: DateTime.utc(2026, 8, 5),
        );

    await CancelPendingOrderUseCase(
      repository,
      () => _updatedAt,
    ).execute(batchId: order.batchId);

    expect(await repository.findActiveForBatch(_batchId), isNull);
  });

  test('rejects a blank customer name before writing', () async {
    final repository = FakeOrderRepository();
    addTearDown(repository.dispose);
    final useCase = CreateOrderUseCase(
      repository,
      const _FixedIdGenerator(),
      () => _createdAt,
    );

    await expectLater(
      useCase.execute(
        batchId: _batchId,
        customerName: ' ',
        deliveryAddress: 'Address',
        deliveryDate: DateTime.utc(2026, 8, 5),
      ),
      throwsA(
        isA<OrderActionException>().having(
          (error) => error.message,
          'message',
          'Enter the customer name.',
        ),
      ),
    );
    expect(await repository.findActiveForBatch(_batchId), isNull);
  });
}

final class _FixedIdGenerator implements EntityIdGenerator {
  const _FixedIdGenerator();

  @override
  String nextId() => _orderId;
}
