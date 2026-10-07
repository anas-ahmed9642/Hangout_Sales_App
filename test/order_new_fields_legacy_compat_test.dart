import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/receipt_data.dart';
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';

/// An order document exactly as written before Phase 5: no deliveryAreaId,
/// deliveryAreaName or deliveryNotes keys.
Map<String, dynamic> _legacyOrderMap() {
  return {
    'id': 'legacy-1',
    'orderNumber': 'ORD-0007',
    'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1, 18)),
    'businessDate': Timestamp.fromDate(DateTime(2026, 9, 1)),
    'customerName': 'Bilal',
    'customerPhone': '03009876543',
    'customerAddress': 'Old address',
    'items': [],
    'deals': [],
    'additionalDrinks': {},
    'additionalDipSauceCount': 0,
    'deliveryCharge': 100.0,
    'total': 900.0,
    'status': 'pending',
    'paymentStatus': 'unpaid',
    'editCount': 0,
  };
}

Order _orderWithNewFields({String? deliveryNotes = 'Ring twice'}) {
  return Order(
    id: 'new-1',
    orderNumber: 'PENDING',
    createdAt: DateTime(2026, 10, 6, 19),
    businessDate: DateTime(2026, 10, 6),
    customerName: 'Cara',
    customerPhone: '03001112222',
    customerAddress: 'Somewhere',
    deliveryAreaId: 'area-1',
    deliveryAreaName: 'Sector 5C/1',
    deliveryNotes: deliveryNotes,
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 150,
    total: 1000,
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
  );
}

void main() {
  test(
    'legacy order documents load with null new fields',
    () async {
      final fake = FakeFirebaseFirestore();
      await fake.collection('orders').doc('legacy-1').set(_legacyOrderMap());

      final repository = FirebaseOrderRepository(firestore: fake);
      final order = await repository.getOrder('legacy-1');

      expect(order, isNotNull);
      expect(order!.deliveryAreaId, isNull);
      expect(order.deliveryAreaName, isNull);
      expect(order.deliveryNotes, isNull);
      // Untouched fields keep working.
      expect(order.customerPhone, '03009876543');
      expect(order.total, 900);
    },
  );

  test(
    'new fields round-trip through createOrder',
    () async {
      final fake = FakeFirebaseFirestore();
      final repository = FirebaseOrderRepository(firestore: fake);

      await repository.createOrder(_orderWithNewFields());
      final loaded = await repository.getOrder('new-1');

      expect(loaded, isNotNull);
      expect(loaded!.deliveryAreaId, 'area-1');
      expect(loaded.deliveryAreaName, 'Sector 5C/1');
      expect(loaded.deliveryNotes, 'Ring twice');
    },
  );

  test(
    'ReceiptData.fromOrder tolerates null delivery notes',
    () {
      final data = ReceiptData.fromOrder(
        _orderWithNewFields(deliveryNotes: null),
      );

      expect(data.deliveryNotes, isNull);
    },
  );

  test(
    'ReceiptData.fromOrder carries delivery notes when present',
    () {
      final data = ReceiptData.fromOrder(_orderWithNewFields());

      expect(data.deliveryNotes, 'Ring twice');
    },
  );
}
