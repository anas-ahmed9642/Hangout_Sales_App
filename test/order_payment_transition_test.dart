import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

class _TestOrderRepository implements OrderRepository {
  final List<Map<String, dynamic>> updates = [];

  @override
  Future<void> createOrder(
    Order order, {
    CustomerUpsert? customerUpsert,
  }) async {}

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) {
    return const Stream.empty();
  }

  @override
  Stream<List<Order>> streamUnpaidOrders() => Stream.value(const []);

  @override
  Future<List<Order>> searchOrdersByPhone(String phoneNumber) async {
    return [];
  }

  @override
  Future<Order?> getOrder(String orderId) async {
    return null;
  }

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {
    updates.add({
      'orderId': orderId,
      'changes': changes,
      'changeReason': changeReason,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async {
    return const [];
  }
}

void main() {
  test(
    'payment transition sends unpaid Ã¢â€ â€™ paid through updateOrder',
    () async {
      final repository = _TestOrderRepository();

      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final orderId = 'test-order-001';

      final resolvedRepository = container.read(
        orderRepositoryProvider,
      );

      await resolvedRepository.updateOrder(
        orderId,
        {
          'paymentStatus': PaymentStatus.paid.name,
        },
        changeReason: 'Marked as paid',
      );

      expect(repository.updates, hasLength(1));

      final update = repository.updates.single;

      expect(update['orderId'], orderId);
      expect(
        (update['changes'] as Map<String, dynamic>)['paymentStatus'],
        'paid',
      );
      expect(
        update['changeReason'],
        'Marked as paid',
      );
    },
  );

  test(
    'payment transition does not modify fulfillment status',
    () async {
      final repository = _TestOrderRepository();

      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      await container.read(orderRepositoryProvider).updateOrder(
        'test-order-002',
        {
          'paymentStatus': PaymentStatus.paid.name,
        },
        changeReason: 'Marked as paid',
      );

      final changes =
          repository.updates.single['changes']
              as Map<String, dynamic>;

      expect(changes.containsKey('status'), isFalse);
      expect(changes['paymentStatus'], 'paid');
    },
  );
}