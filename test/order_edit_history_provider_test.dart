import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/providers/order_edit_history_provider.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';

class _TestOrderRepository implements OrderRepository {
  final List<Map<String, dynamic>> history;

  _TestOrderRepository({
    this.history = const [],
  });

  @override
  Future<void> createOrder(Order order) async {}

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) {
    return const Stream.empty();
  }

  @override
  Stream<List<Order>> streamUnpaidOrders() => Stream.value(const []);

  @override
  Future<List<Order>> searchOrdersByPhone(
    String phoneNumber,
  ) async {
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
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(
    String orderId,
  ) async {
    return history;
  }
}

void main() {
  test(
    'orderEditHistoryProvider exposes repository history',
    () async {
      final repository = _TestOrderRepository(
        history: [
          {
            'id': 'history-1',
            'field': 'paymentStatus',
            'oldValue': 'unpaid',
            'newValue': 'paid',
            'changeReason': 'Marked as paid',
          },
        ],
      );

      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final result = await container.read(
        orderEditHistoryProvider('order-001').future,
      );

      expect(result, hasLength(1));
      expect(result.first['field'], 'paymentStatus');
      expect(result.first['oldValue'], 'unpaid');
      expect(result.first['newValue'], 'paid');
      expect(
        result.first['changeReason'],
        'Marked as paid',
      );
    },
  );

  test(
    'orderEditHistoryProvider returns an empty list when no history exists',
    () async {
      final repository = _TestOrderRepository();

      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final result = await container.read(
        orderEditHistoryProvider('order-without-history').future,
      );

      expect(result, isEmpty);
    },
  );
}