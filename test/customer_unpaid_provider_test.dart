import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_orders_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_unpaid_provider.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

import 'helpers/test_container.dart';

final _t = DateTime(2026, 10, 7);

Order _order({
  required String id,
  required double total,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  OrderStatus status = OrderStatus.pending,
}) {
  return Order(
    id: id,
    orderNumber: 'ORD-$id',
    createdAt: _t,
    businessDate: _t,
    items: const [],
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

ProviderContainer _container(Map<String, Stream<List<Order>>> streams) {
  return createTestContainer(overrides: [
    orderRepositoryProvider.overrideWithValue(_FakeOrderRepository(streams)),
  ]);
}

void main() {
  test('unpaid, non-cancelled orders are counted and summed', () async {
    final container = _container({
      '03001234567': Stream.value([
        _order(id: 'a', total: 1000),
        _order(id: 'b', total: 850),
        _order(id: 'c', total: 500, paymentStatus: PaymentStatus.paid),
        _order(id: 'd', total: 2000, status: OrderStatus.cancelled),
      ]),
    });

    // Stream.value emits asynchronously; wait for it before reading.
    await container.read(customerOrdersProvider('03001234567').future);

    final summary = container.read(customerUnpaidProvider('03001234567'));

    expect(summary.count, 2);
    expect(summary.amount, 1850);
    expect(summary.hasUnpaid, isTrue);
  });

  test('all paid orders -> empty summary', () async {
    final container = _container({
      '03001234567': Stream.value([
        _order(id: 'a', total: 1000, paymentStatus: PaymentStatus.paid),
      ]),
    });

    // Stream.value emits asynchronously; wait for it before reading.
    await container.read(customerOrdersProvider('03001234567').future);

    final summary = container.read(customerUnpaidProvider('03001234567'));

    expect(summary.count, 0);
    expect(summary.amount, 0);
    expect(summary.hasUnpaid, isFalse);
  });

  test('customer with no orders -> empty summary', () async {
    final container = _container(const {});

    await container.read(customerOrdersProvider('03009998888').future);

    final summary = container.read(customerUnpaidProvider('03009998888'));

    expect(summary.count, 0);
    expect(summary.amount, 0);
    expect(summary.hasUnpaid, isFalse);
  });

  test('loading stream -> empty summary (banner hides, never blocks)', () {
    // A controller that never emits keeps the provider in loading.
    final controller = StreamController<List<Order>>();
    addTearDown(controller.close);
    final container = _container({
      '03001234567': controller.stream,
    });

    final summary = container.read(customerUnpaidProvider('03001234567'));

    expect(summary.count, 0);
    expect(summary.hasUnpaid, isFalse);
  });

  test('error stream -> empty summary (banner hides, never blocks)', () async {
    final container = _container({
      '03001234567': Stream<List<Order>>.error(StateError('firestore down')),
    });

    // The error must actually be delivered; the future rethrows it.
    await expectLater(
      container.read(customerOrdersProvider('03001234567').future),
      throwsStateError,
    );

    final summary = container.read(customerUnpaidProvider('03001234567'));

    expect(summary.count, 0);
    expect(summary.hasUnpaid, isFalse);
  });
}