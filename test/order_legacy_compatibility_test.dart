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

    repository = FirebaseOrderRepository(
      firestore: firestore,
    );
  });

  test(
    'legacy order without paymentStatus reads back as unpaid',
    () async {
      final createdAt = DateTime(2026, 9, 15, 18, 30);
      final businessDate = DateTime(2026, 9, 15);

      await firestore.collection('orders').doc('legacy-order').set({
        'id': 'legacy-order',
        'orderNumber': 'ORD-0099',
        'createdAt': Timestamp.fromDate(createdAt),
        'businessDate': Timestamp.fromDate(businessDate),
        'customerName': 'Legacy Customer',
        'customerPhone': '03001234567',
        'customerAddress': null,
        'items': <Map<String, dynamic>>[],
        'deals': <Map<String, dynamic>>[],
        'additionalDrinks': <String, dynamic>{},
        'additionalDipSauceCount': 0,
        'deliveryCharge': 0,
        'total': 500,
        'status': OrderStatus.pending.name,

        // Intentionally omitted:
        // 'paymentStatus'
      });

      final order = await repository.getOrder('legacy-order');

      expect(order, isNotNull);
      expect(order!.orderNumber, 'ORD-0099');
      expect(order.status, OrderStatus.pending);
      expect(order.paymentStatus, PaymentStatus.unpaid);
    },
  );

  test(
    'current order with paymentStatus paid reads back as paid',
    () async {
      final orderDate = DateTime(2026, 9, 15, 19, 0);
      final businessDate = DateTime(2026, 9, 15);

      await firestore.collection('orders').doc('paid-order').set({
        'id': 'paid-order',
        'orderNumber': 'ORD-0100',
        'createdAt': Timestamp.fromDate(orderDate),
        'businessDate': Timestamp.fromDate(businessDate),
        'customerName': 'Paid Customer',
        'customerPhone': '03009876543',
        'customerAddress': null,
        'items': <Map<String, dynamic>>[],
        'deals': <Map<String, dynamic>>[],
        'additionalDrinks': <String, dynamic>{},
        'additionalDipSauceCount': 0,
        'deliveryCharge': 0,
        'total': 1000,
        'status': OrderStatus.pending.name,
        'paymentStatus': PaymentStatus.paid.name,
        'editCount': 0,
      });

      final order = await repository.getOrder('paid-order');

      expect(order, isNotNull);
      expect(order!.paymentStatus, PaymentStatus.paid);
    },
  );

  test(
    'current order with paymentStatus unpaid reads back as unpaid',
    () async {
      final orderDate = DateTime(2026, 9, 15, 20, 0);
      final businessDate = DateTime(2026, 9, 15);

      await firestore.collection('orders').doc('unpaid-order').set({
        'id': 'unpaid-order',
        'orderNumber': 'ORD-0101',
        'createdAt': Timestamp.fromDate(orderDate),
        'businessDate': Timestamp.fromDate(businessDate),
        'customerName': null,
        'customerPhone': null,
        'customerAddress': null,
        'items': <Map<String, dynamic>>[],
        'deals': <Map<String, dynamic>>[],
        'additionalDrinks': <String, dynamic>{},
        'additionalDipSauceCount': 0,
        'deliveryCharge': 70,
        'total': 1070,
        'status': OrderStatus.pending.name,
        'paymentStatus': PaymentStatus.unpaid.name,
        'editCount': 0,
      });

      final order = await repository.getOrder('unpaid-order');

      expect(order, isNotNull);
      expect(order!.paymentStatus, PaymentStatus.unpaid);
    },
  );
}