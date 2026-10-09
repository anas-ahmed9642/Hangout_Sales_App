import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_orders_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_stats_provider.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

import 'helpers/test_container.dart';

OrderItem _item(String flavorName, int quantity) {
  return OrderItem(
    flavorId: flavorName.toLowerCase(),
    flavorName: flavorName,
    size: PizzaSize.large,
    quantity: quantity,
    unitPrice: 1000,
  );
}

Order _order({
  required String id,
  required DateTime createdAt,
  required double total,
  PaymentStatus paymentStatus = PaymentStatus.paid,
  OrderStatus status = OrderStatus.completed,
  List<OrderItem> items = const [],
}) {
  return Order(
    id: id,
    orderNumber: 'ORD-$id',
    createdAt: createdAt,
    businessDate: createdAt,
    items: items,
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: total,
    status: status,
    paymentStatus: paymentStatus,
  );
}

class _FakeOrderRepository implements OrderRepository {
  final Map<String, Stream<List<Order>>> streams;

  _FakeOrderRepository(this.streams);

  @override
  Stream<List<Order>> streamOrdersByCustomerPhone(String phone) {
    return streams[phone] ?? Stream.value(const []);
  }

  @override
  Future<void> createOrder(Order order, {CustomerUpsert? customerUpsert}) =>
      throw UnimplementedError();

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) =>
      throw UnimplementedError();

  @override
  Future<List<Order>> searchOrdersByPhone(String phoneNumber) =>
      throw UnimplementedError();

  @override
  Future<Order?> getOrder(String orderId) => throw UnimplementedError();

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) =>
      throw UnimplementedError();

  @override
  Stream<List<Order>> streamUnpaidOrders() => throw UnimplementedError();
}

void main() {
  group('computeCustomerStats', () {
    test('no orders -> empty stats', () {
      final stats = computeCustomerStats(const []);

      expect(stats.orderCount, 0);
      expect(stats.totalSpent, 0);
      expect(stats.averageOrderValue, 0);
      expect(stats.favoriteFlavor, isNull);
      expect(stats.unpaidOrderCount, 0);
      expect(stats.unpaidAmount, 0);
      expect(stats.firstOrderAt, isNull);
      expect(stats.lastOrderAt, isNull);
    });

    test('hand count: totals, average, favorite, unpaid, first/last',
        () {
      // Newest first, as customerOrdersProvider streams them.
      final newest = DateTime(2026, 10, 5, 20, 0);
      final oldest = DateTime(2026, 10, 1, 19, 0);
      final stats = computeCustomerStats([
        _order(
          id: 'new',
          createdAt: newest,
          total: 2300,
          items: [_item('Fajita', 2)],
        ),
        _order(
          id: 'old',
          createdAt: oldest,
          total: 1850,
          paymentStatus: PaymentStatus.unpaid,
          status: OrderStatus.pending,
          items: [_item('Fajita', 1), _item('Chicken Tikka', 3)],
        ),
      ]);

      expect(stats.orderCount, 2);
      expect(stats.totalSpent, 4150);
      expect(stats.averageOrderValue, 2075);
      // Fajita 2+1 = 3 ties Chicken Tikka 3; the tie goes to the
      // flavor in the most recent order.
      expect(stats.favoriteFlavor, 'Fajita');
      expect(stats.unpaidOrderCount, 1);
      expect(stats.unpaidAmount, 1850);
      expect(stats.firstOrderAt, oldest);
      expect(stats.lastOrderAt, newest);
    });

    test('favorite flavor counts quantity, not order count', () {
      final stats = computeCustomerStats([
        _order(
          id: 'a',
          createdAt: DateTime(2026, 10, 5),
          total: 1000,
          items: [_item('Fajita', 1)],
        ),
        _order(
          id: 'b',
          createdAt: DateTime(2026, 10, 4),
          total: 1000,
          items: [_item('Fajita', 1)],
        ),
        _order(
          id: 'c',
          createdAt: DateTime(2026, 10, 3),
          total: 1000,
          items: [_item('Chicken Tikka', 5)],
        ),
      ]);

      // Fajita appears in 2 orders but totals 2; Tikka totals 5.
      expect(stats.favoriteFlavor, 'Chicken Tikka');
    });

    test('cancelled orders contribute nothing anywhere', () {
      final stats = computeCustomerStats([
        _order(
          id: 'gone',
          createdAt: DateTime(2026, 10, 6),
          total: 9999,
          paymentStatus: PaymentStatus.unpaid,
          status: OrderStatus.cancelled,
          items: [_item('Cancelled Special', 9)],
        ),
        _order(
          id: 'kept',
          createdAt: DateTime(2026, 10, 2),
          total: 1200,
          items: [_item('Fajita', 1)],
        ),
      ]);

      expect(stats.orderCount, 1);
      expect(stats.totalSpent, 1200);
      expect(stats.averageOrderValue, 1200);
      expect(stats.favoriteFlavor, 'Fajita');
      expect(stats.unpaidOrderCount, 0);
      expect(stats.unpaidAmount, 0);
      expect(stats.firstOrderAt, DateTime(2026, 10, 2));
      expect(stats.lastOrderAt, DateTime(2026, 10, 2));
    });

    test('orders without items have no favorite flavor', () {
      final stats = computeCustomerStats([
        _order(id: 'a', createdAt: DateTime(2026, 10, 5), total: 700),
      ]);

      expect(stats.orderCount, 1);
      expect(stats.favoriteFlavor, isNull);
    });

    test('favorite tie and dates ignore input order', () {
      final orders = [
        _order(
          id: 'a',
          createdAt: DateTime(2026, 10, 1),
          total: 100,
          items: [_item('Fajita', 2)],
        ),
        _order(
          id: 'b',
          createdAt: DateTime(2026, 10, 5),
          total: 100,
          items: [_item('Chicken Tikka', 2)],
        ),
      ];

      // Equal quantities: the flavor from the most recent order
      // wins, whichever way round the list is handed over.
      expect(computeCustomerStats(orders).favoriteFlavor, 'Chicken Tikka');
      final reversedStats = computeCustomerStats(orders.reversed.toList());
      expect(reversedStats.favoriteFlavor, 'Chicken Tikka');
      expect(reversedStats.firstOrderAt, DateTime(2026, 10, 1));
      expect(reversedStats.lastOrderAt, DateTime(2026, 10, 5));
    });

    test('all cancelled -> empty stats', () {
      final stats = computeCustomerStats([
        _order(
          id: 'x',
          createdAt: DateTime(2026, 10, 5),
          total: 500,
          status: OrderStatus.cancelled,
        ),
      ]);

      expect(stats.orderCount, 0);
      expect(stats.totalSpent, 0);
      expect(stats.firstOrderAt, isNull);
      expect(stats.lastOrderAt, isNull);
    });
  });

  group('customerStatsProvider', () {
    test('derives stats from the streamed orders', () async {
      final container = createTestContainer(overrides: [
        orderRepositoryProvider.overrideWithValue(
          _FakeOrderRepository({
            '03001234567': Stream.value([
              _order(
                id: 'new',
                createdAt: DateTime(2026, 10, 5),
                total: 2300,
                items: [_item('Fajita', 2)],
              ),
              _order(
                id: 'old',
                createdAt: DateTime(2026, 10, 1),
                total: 1850,
                paymentStatus: PaymentStatus.unpaid,
                items: [_item('Fajita', 1)],
              ),
            ]),
          }),
        ),
      ]);

      // Stream.value emits asynchronously; wait for the first
      // emission before reading the derived provider, or the read
      // would collapse to the loading state and pass vacuously.
      await container.read(customerOrdersProvider('03001234567').future);

      final stats = container.read(customerStatsProvider('03001234567'));

      expect(stats.orderCount, 2);
      expect(stats.totalSpent, 4150);
      expect(stats.favoriteFlavor, 'Fajita');
      expect(stats.unpaidAmount, 1850);
    });

    test('collapses to empty while the orders stream has not emitted',
        () {
      final neverEmits = StreamController<List<Order>>();
      addTearDown(neverEmits.close);
      final container = createTestContainer(overrides: [
        orderRepositoryProvider.overrideWithValue(
          _FakeOrderRepository({'03001234567': neverEmits.stream}),
        ),
      ]);

      // No await: the stream is still loading, and the provider must
      // show the no-orders state instead of throwing (File 1 doc).
      final stats = container.read(customerStatsProvider('03001234567'));

      expect(stats.orderCount, 0);
      expect(stats.favoriteFlavor, isNull);
    });
  });
}
