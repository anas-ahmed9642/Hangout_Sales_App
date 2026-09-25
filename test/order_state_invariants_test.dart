import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';

void main() {
  final createdAt = DateTime(2026, 9, 15, 18, 30);
  final businessDate = DateTime(2026, 9, 15);

  Order createOrder({
    required OrderStatus status,
    required PaymentStatus paymentStatus,
  }) {
    return Order(
      id: 'test-order-id',
      orderNumber: 'ORD-TEST',
      createdAt: createdAt,
      businessDate: businessDate,
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 0,
      total: 0,
      status: status,
      paymentStatus: paymentStatus,
    );
  }

  group('Order status invariants', () {
    test('pending order can be unpaid', () {
      final order = createOrder(
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.unpaid,
      );

      expect(order.status, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.unpaid);
    });

    test('pending order can be paid', () {
      final order = createOrder(
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.paid,
      );

      expect(order.status, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.paid);
    });

    test('completed order can remain unpaid', () {
      final order = createOrder(
        status: OrderStatus.completed,
        paymentStatus: PaymentStatus.unpaid,
      );

      expect(order.status, OrderStatus.completed);
      expect(order.paymentStatus, PaymentStatus.unpaid);
    });

    test('completed order can be paid', () {
      final order = createOrder(
        status: OrderStatus.completed,
        paymentStatus: PaymentStatus.paid,
      );

      expect(order.status, OrderStatus.completed);
      expect(order.paymentStatus, PaymentStatus.paid);
    });

    test('cancelled order can remain unpaid', () {
      final order = createOrder(
        status: OrderStatus.cancelled,
        paymentStatus: PaymentStatus.unpaid,
      );

      expect(order.status, OrderStatus.cancelled);
      expect(order.paymentStatus, PaymentStatus.unpaid);
    });

    test('payment status is independent from fulfillment status', () {
      final unpaidPending = createOrder(
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.unpaid,
      );

      final paidPending = createOrder(
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.paid,
      );

      final unpaidCompleted = createOrder(
        status: OrderStatus.completed,
        paymentStatus: PaymentStatus.unpaid,
      );

      final paidCompleted = createOrder(
        status: OrderStatus.completed,
        paymentStatus: PaymentStatus.paid,
      );

      expect(unpaidPending.status, OrderStatus.pending);
      expect(paidPending.status, OrderStatus.pending);

      expect(unpaidCompleted.status, OrderStatus.completed);
      expect(paidCompleted.status, OrderStatus.completed);

      expect(unpaidPending.paymentStatus, PaymentStatus.unpaid);
      expect(paidPending.paymentStatus, PaymentStatus.paid);

      expect(unpaidCompleted.paymentStatus, PaymentStatus.unpaid);
      expect(paidCompleted.paymentStatus, PaymentStatus.paid);
    });
  });
}