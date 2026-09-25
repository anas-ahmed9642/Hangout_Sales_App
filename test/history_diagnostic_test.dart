import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. We add 'as my_model' to completely isolate your model file
import 'package:hangout_sales_app/features/orders/models/order.dart' as my_model;
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';

void main() {
  test('Diagnostic: Firebase Repository Read/Write Check', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirebaseOrderRepository(firestore: firestore);
    
    final testBusinessDate = DateTime(2026, 8, 25);
    
    // 2. We use 'my_model.Order' to explicitly call YOUR class
    final order = my_model.Order(
      id: 'diagnostic_order_123',
      orderNumber: 'ORD-0001',
      createdAt: DateTime.now(),
      businessDate: testBusinessDate,
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 0,
      total: 1000,
      status: my_model.OrderStatus.pending,
      paymentStatus: my_model.PaymentStatus.unpaid,
    );
    
    await repository.createOrder(order);
    
    final snapshot = await firestore.collection('orders').get();
    print('--- RAW DATABASE CHECK ---');
    print('Total documents in orders collection: ${snapshot.docs.length}');
    
    if (snapshot.docs.isNotEmpty) {
       final savedData = snapshot.docs.first.data();
       print('Saved Business Date (Timestamp): ${savedData['businessDate']}');
    }

    final queryTimestamp = Timestamp.fromDate(testBusinessDate);
    print('--- QUERY CHECK ---');
    print('Attempting to stream orders where businessDate == $queryTimestamp');
    
    final stream = repository.streamOrders(testBusinessDate);
    final results = await stream.first;
    
    print('Orders successfully returned by stream: ${results.length}');
    
    expect(
      results.length, 
      1, 
      reason: 'The stream failed to find the order we just created!',
    );
  });
}