import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseOrderRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseOrderRepository(firestore: firestore);
  });

  Future<void> seedOrder({
    required String id,
    required String orderNumber,
    required OrderStatus status,
    required PaymentStatus paymentStatus,
    int editCount = 0,
  }) async {
    await firestore.collection('orders').doc(id).set({
      'id': id,
      'orderNumber': orderNumber,
      'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1, 18)),
      'businessDate': Timestamp.fromDate(DateTime(2026, 9, 1)),
      'customerName': null,
      'customerPhone': null,
      'customerAddress': null,
      'items': const [],
      'deals': const [],
      'additionalDrinks': const <String, int>{},
      'additionalDipSauceCount': 0,
      'deliveryCharge': 0,
      'total': 500,
      'status': status.name,
      'paymentStatus': paymentStatus.name,
      'editCount': editCount,
    });
  }

  test('global unpaid stream excludes cancelled unpaid orders', () async {
    await seedOrder(
      id: 'pending-unpaid',
      orderNumber: 'ORD-0001',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
    );

    await seedOrder(
      id: 'completed-unpaid',
      orderNumber: 'ORD-0002',
      status: OrderStatus.completed,
      paymentStatus: PaymentStatus.unpaid,
    );

    await seedOrder(
      id: 'paid-pending',
      orderNumber: 'ORD-0003',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.paid,
    );

    await seedOrder(
      id: 'cancelled-unpaid',
      orderNumber: 'ORD-0004',
      status: OrderStatus.cancelled,
      paymentStatus: PaymentStatus.unpaid,
    );

    final orders = await repository.streamUnpaidOrders().first;

    final orderNumbers = orders.map((order) => order.orderNumber).toSet();

    expect(
      orderNumbers,
      containsAll(<String>[
        'ORD-0001',
        'ORD-0002',
      ]),
    );

    expect(orderNumbers, isNot(contains('ORD-0003')));
    expect(orderNumbers, isNot(contains('ORD-0004')));
  });

  test('payment-only update does not increment editCount', () async {
    await seedOrder(
      id: 'payment-order',
      orderNumber: 'ORD-0010',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
    );

    await repository.updateOrder(
      'payment-order',
      {
        'paymentStatus': PaymentStatus.paid.name,
      },
      changeReason: 'Marked as paid',
    );

    final order = await repository.getOrder('payment-order');

    expect(order, isNotNull);
    expect(order!.paymentStatus, PaymentStatus.paid);
    expect(order.editCount, 0);
  });

  test('fulfillment-only update does not increment editCount', () async {
    await seedOrder(
      id: 'completion-order',
      orderNumber: 'ORD-0011',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
    );

    await repository.updateOrder(
      'completion-order',
      {
        'status': OrderStatus.completed.name,
      },
      changeReason: 'Order completed',
    );

    final order = await repository.getOrder('completion-order');

    expect(order, isNotNull);
    expect(order!.status, OrderStatus.completed);
    expect(order.editCount, 0);
  });

  test('content update increments editCount', () async {
    await seedOrder(
      id: 'content-order',
      orderNumber: 'ORD-0012',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
    );

    await repository.updateOrder(
      'content-order',
      {
        'customerName': 'Updated Customer',
      },
      changeReason: 'Customer requested a name change',
    );

    final order = await repository.getOrder('content-order');

    expect(order, isNotNull);
    expect(order!.customerName, 'Updated Customer');
    expect(order.editCount, 1);
  });

  test('payment plus content update increments editCount once', () async {
    await seedOrder(
      id: 'mixed-order',
      orderNumber: 'ORD-0013',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
    );

    await repository.updateOrder(
      'mixed-order',
      {
        'paymentStatus': PaymentStatus.paid.name,
        'customerName': 'Changed Customer',
      },
      changeReason: 'Payment received and customer corrected name',
    );

    final order = await repository.getOrder('mixed-order');

    expect(order, isNotNull);
    expect(order!.paymentStatus, PaymentStatus.paid);
    expect(order.customerName, 'Changed Customer');
    expect(order.editCount, 1);
  });

  test('no-op update does not increment editCount', () async {
    await seedOrder(
      id: 'noop-order',
      orderNumber: 'ORD-0014',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
    );

    await repository.updateOrder(
      'noop-order',
      {
        'paymentStatus': PaymentStatus.unpaid.name,
      },
      changeReason: 'No actual payment change',
    );

    final order = await repository.getOrder('noop-order');

    expect(order, isNotNull);
    expect(order!.editCount, 0);
  });
}