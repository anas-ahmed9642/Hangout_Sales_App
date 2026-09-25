// test/order_cancellation_transition_test.dart
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';

/// Minimal, valid pending order. Deliberately self-contained — this file
/// makes no assumption about fixtures/helpers defined in other test files.
Order _pendingTestOrder({String id = 'cancel-test-order'}) {
  return Order(
    id: id,
    orderNumber: 'PENDING-INTEGRATION',
    createdAt: DateTime(2026, 9, 1, 12),
    businessDate: DateTime(2026, 9, 1),
    customerName: 'Test Customer',
    customerPhone: '03001234567',
    items: const [
      OrderItem(
        flavorId: 'super_sicilian',
        flavorName: 'Super Sicilian',
        size: PizzaSize.regular,
        quantity: 1,
        unitPrice: 550,
      ),
    ],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: 550,
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
  );
}

void main() {
  group('Order cancellation via FirebaseOrderRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseOrderRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirebaseOrderRepository(firestore: firestore);
    });

    test('pending order transitions to cancelled and records history', () async {
      final order = _pendingTestOrder();

      await repository.createOrder(order);

      final created = await repository.getOrder(order.id);
      expect(created, isNotNull);
      expect(created!.status, OrderStatus.pending);

      await repository.updateOrder(
        order.id,
        {'status': OrderStatus.cancelled.name},
        changeReason: 'Customer requested cancellation',
      );

      final cancelled = await repository.getOrder(order.id);
      expect(cancelled, isNotNull);
      expect(cancelled!.status, OrderStatus.cancelled);
      expect(cancelled.editCount, 1);

      final history = await repository.getOrderHistory(order.id);

      final statusEntry = history.singleWhere(
        (entry) => entry['field'] == 'status',
        orElse: () => throw StateError(
          'Expected a status change entry in order history but found none. '
          'History entries: $history',
        ),
      );

      expect(statusEntry['oldValue'], OrderStatus.pending.name);
      expect(statusEntry['newValue'], OrderStatus.cancelled.name);
      expect(statusEntry['changeReason'], 'Customer requested cancellation');
      expect(statusEntry['timestamp'], isA<Timestamp>());
    });

    test('cancelling with an empty change reason throws ArgumentError', () async {
      final order = _pendingTestOrder(id: 'cancel-test-order-2');
      await repository.createOrder(order);

      expect(
        () => repository.updateOrder(
          order.id,
          {'status': OrderStatus.cancelled.name},
          changeReason: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('content edits are blocked after cancellation, but status re-writes are not',
        () async {
      final order = _pendingTestOrder(id: 'cancel-test-order-3');
      await repository.createOrder(order);

      await repository.updateOrder(
        order.id,
        {'status': OrderStatus.cancelled.name},
        changeReason: 'First cancellation',
      );

      // 'customerName' is a content field -> blocked once cancelled.
      expect(
        () => repository.updateOrder(
          order.id,
          {'customerName': 'Changed Name'},
          changeReason: 'Trying to edit after cancel',
        ),
        throwsA(isA<StateError>()),
      );

      // 'status' is not a content field -> still allowed.
      await repository.updateOrder(
        order.id,
        {'status': OrderStatus.cancelled.name},
        changeReason: 'Re-affirm cancellation',
      );

      final result = await repository.getOrder(order.id);
      expect(result!.status, OrderStatus.cancelled);
    });
  });
}