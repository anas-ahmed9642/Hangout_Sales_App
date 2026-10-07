import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_history_provider.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

class _TestOrderRepository implements OrderRepository {
  final Stream<List<Order>> ordersStream;

  _TestOrderRepository(this.ordersStream);

  @override
  Future<void> createOrder(
    Order order, {
    CustomerUpsert? customerUpsert,
  }) async {}

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) {
    return ordersStream;
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
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async {
    return const [];
  }
}

void main() {
  test(
    'orderHistoryProvider exposes orders from the repository stream',
    () async {
      final orders = <Order>[];

      final repository = _TestOrderRepository(
        Stream.value(orders),
      );

      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      final value = await container.read(
        orderHistoryProvider.future,
      );

      expect(value, isEmpty);
    },
  );

  test(
    'orderHistoryProvider exposes repository errors as provider errors',
    () async {
      final repository = _TestOrderRepository(
        Stream<List<Order>>.error(
          Exception('Test history failure'),
        ),
      );

      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(repository),
        ],
      );

      addTearDown(container.dispose);

      await expectLater(
        container.read(orderHistoryProvider.future),
        throwsA(isA<Exception>()),
      );
    },
  );
}