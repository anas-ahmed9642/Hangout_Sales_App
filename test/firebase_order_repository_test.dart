import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';


Order _createTestOrder({
  String id = 'test-order-001',
  OrderStatus status = OrderStatus.pending,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
}) {
  return Order(
    id: 'test-order-001',
    orderNumber: 'ORD-0001',
    createdAt: DateTime(2026, 8, 30, 18),
    businessDate: DateTime(2026, 8, 30),
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 100,
    total: 1100,
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
    customerName: 'Ahmed',
    customerPhone: '03001234567',
    customerAddress: 'Test Address',
  );
}
void main() {
  test(
    'orderRepositoryProvider resolves an OrderRepository',
    () {
      final fakeFirestore = FakeFirebaseFirestore();

      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(
            FirebaseOrderRepository(firestore: fakeFirestore),
          ),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(orderRepositoryProvider);
      expect(repository, isA<OrderRepository>());
    },
  );
  test(
  'getOrder reads a saved order from Firestore',
  () async {
    final firestore = FakeFirebaseFirestore();

    await firestore
        .collection('orders')
        .doc('order-001')
        .set({
      'id': 'order-001',
      'orderNumber': 'ORD-0001',
      'createdAt': Timestamp.fromDate(
        DateTime(2026, 8, 25, 18),
      ),
      'businessDate': Timestamp.fromDate(
        DateTime(2026, 8, 25),
      ),
      'customerName': 'Test Customer',
      'customerPhone': '03001234567',
      'customerAddress': 'Test Address',
      'items': [
        {
          'flavorId': 'super_sicilian',
          'flavorName': 'Super Sicilian',
          'flavorPriceExtra': 0.0,
          'size': 'small',
          'toppings': [],
          'quantity': 1,
          'unitPrice': 300.0,
        },
      ],
      'deals': [],
      'additionalDrinks': {},
      'additionalDipSauceCount': 0,
      'deliveryCharge': 0.0,
      'total': 300.0,
      'status': 'pending',
    });

    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    final order = await repository.getOrder('order-001');

    expect(order, isNotNull);
    expect(order!.id, 'order-001');
    expect(order.orderNumber, 'ORD-0001');
    expect(order.customerPhone, '03001234567');
    expect(order.items, hasLength(1));
    expect(order.items.first.size, PizzaSize.small);
    expect(order.items.first.flavorName, 'Super Sicilian');
    expect(order.total, 300.0);
  },
);
test(
  'getOrder returns null when the order does not exist',
  () async {
    final firestore = FakeFirebaseFirestore();

    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    final order = await repository.getOrder(
      'does-not-exist',
    );

    expect(order, isNull);
  },
);
test(
  'streamOrders returns orders for the requested business date',
  () async {
    final firestore = FakeFirebaseFirestore();

    final requestedDate = DateTime(2026, 8, 25);

    await firestore.collection('orders').doc('order-001').set({
      'id': 'order-001',
      'orderNumber': 'ORD-0001',
      'createdAt': Timestamp.fromDate(
        DateTime(2026, 8, 25, 18),
      ),
      'businessDate': Timestamp.fromDate(requestedDate),
      'customerName': 'Customer One',
      'customerPhone': '03000000001',
      'customerAddress': null,
      'items': [],
      'deals': [],
      'additionalDrinks': {},
      'additionalDipSauceCount': 0,
      'deliveryCharge': 0.0,
      'total': 650.0,
      'status': 'pending',
    });

    await firestore.collection('orders').doc('order-002').set({
      'id': 'order-002',
      'orderNumber': 'ORD-0002',
      'createdAt': Timestamp.fromDate(
        DateTime(2026, 8, 26, 1),
      ),
      'businessDate': Timestamp.fromDate(
        DateTime(2026, 8, 24),
      ),
      'customerName': 'Customer Two',
      'customerPhone': '03000000002',
      'customerAddress': null,
      'items': [],
      'deals': [],
      'additionalDrinks': {},
      'additionalDipSauceCount': 0,
      'deliveryCharge': 0.0,
      'total': 500.0,
      'status': 'pending',
    });

    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    final orders = await repository
        .streamOrders(requestedDate)
        .first;

    expect(orders, hasLength(1));
    expect(orders.first.id, 'order-001');
    expect(orders.first.businessDate, requestedDate);
  },
);
test(
  'searchOrdersByPhone returns matching customer orders',
  () async {
    final firestore = FakeFirebaseFirestore();

    Future<void> seedOrder({
      required String id,
      required String phone,
      required String orderNumber,
    }) {
      return firestore.collection('orders').doc(id).set({
        'id': id,
        'orderNumber': orderNumber,
        'createdAt': Timestamp.fromDate(
          DateTime(2026, 8, 25, 18),
        ),
        'businessDate': Timestamp.fromDate(
          DateTime(2026, 8, 25),
        ),
        'customerName': 'Repeat Customer',
        'customerPhone': phone,
        'customerAddress': null,
        'items': [],
        'deals': [],
        'additionalDrinks': {},
        'additionalDipSauceCount': 0,
        'deliveryCharge': 0.0,
        'total': 650.0,
        'status': 'pending',
      });
    }

    await seedOrder(
      id: 'order-001',
      phone: '03001234567',
      orderNumber: 'ORD-0001',
    );

    await seedOrder(
      id: 'order-002',
      phone: '03001234567',
      orderNumber: 'ORD-0002',
    );

    await seedOrder(
      id: 'order-003',
      phone: '03009999999',
      orderNumber: 'ORD-0003',
    );

    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    final orders = await repository.searchOrdersByPhone(
      '03001234567',
    );

    expect(orders, hasLength(2));

    expect(
      orders.map((order) => order.orderNumber),
      containsAll([
        'ORD-0001',
        'ORD-0002',
      ]),
    );
  },
);
test(
  'getOrder preserves saved historical order values',
  () async {
    final firestore = FakeFirebaseFirestore();

    await firestore.collection('orders').doc('order-history-test').set({
      'id': 'order-history-test',
      'orderNumber': 'ORD-0099',
      'createdAt': Timestamp.fromDate(
        DateTime(2026, 8, 20, 21, 30),
      ),
      'businessDate': Timestamp.fromDate(
        DateTime(2026, 8, 20),
      ),
      'customerName': 'Historical Customer',
      'customerPhone': '03009999999',
      'customerAddress': 'Old Address',
      'items': [
        {
          'flavorId': 'old_flavor',
          'flavorName': 'Historical Flavor Name',
          'flavorPriceExtra': 75,
          'size': 'large',
          'toppings': [
            {
              'toppingId': 'old_topping',
              'toppingName': 'Historical Topping',
              'priceAtOrderTime': 120,
            },
          ],
          'quantity': 1,
          'unitPrice': 845,
        },
      ],
      'deals': [],
      'additionalDrinks': {
        'drink_1': 2,
      },
      'additionalDipSauceCount': 3,
      'deliveryCharge': 130,
      'total': 1995,
      'status': 'pending',
    });

    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    final order = await repository.getOrder(
      'order-history-test',
    );

    expect(order, isNotNull);

    expect(order!.orderNumber, 'ORD-0099');
    expect(order.customerName, 'Historical Customer');
    expect(order.customerPhone, '03009999999');
    expect(order.customerAddress, 'Old Address');

    expect(order.items, hasLength(1));

    expect(
      order.items.first.flavorName,
      'Historical Flavor Name',
    );

    expect(
      order.items.first.flavorPriceExtra,
      75,
    );

    expect(
      order.items.first.unitPrice,
      845,
    );

    expect(
      order.items.first.toppings!.first.toppingName,
      'Historical Topping',
    );

    expect(
      order.items.first.toppings!.first.priceAtOrderTime,
      120,
    );

    expect(
      order.additionalDrinks['drink_1'],
      2,
    );

    expect(
      order.additionalDipSauceCount,
      3,
    );

    expect(order.deliveryCharge, 130);
    expect(order.total, 1995);
    expect(order.status, OrderStatus.pending);
  },
);
test(
  'FirebaseOrderRepository preserves paid payment status on readback',
  () async {
    final fakeFirestore = FakeFirebaseFirestore();

    final repository = FirebaseOrderRepository(
      firestore: fakeFirestore,
    );

    final order = Order(
      id: 'payment-round-trip-001',
      orderNumber: 'ORD-0001',
      createdAt: DateTime(2026, 8, 30, 18),
      businessDate: DateTime(2026, 8, 30),
      customerName: 'Ahmed',
      customerPhone: '03001234567',
      customerAddress: 'Karachi',
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 0,
      total: 0,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.paid,
    );

    await repository.createOrder(order);

    final saved = await repository.getOrder(order.id);

    expect(saved, isNotNull);
    expect(saved!.paymentStatus, PaymentStatus.paid);
  },
);

test(
  'updateOrder updates the order and creates an edit-history entry',
  () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    final order = _createTestOrder();

    await firestore
        .collection('orders')
        .doc(order.id)
        .set({
      'id': order.id,
      'orderNumber': order.orderNumber,
      'createdAt': Timestamp.fromDate(order.createdAt),
      'businessDate': Timestamp.fromDate(order.businessDate),
      'items': [],
      'deals': [],
      'additionalDrinks': {},
      'additionalDipSauceCount': order.additionalDipSauceCount,
      'deliveryCharge': order.deliveryCharge,
      'total': order.total,
      'status': order.status.name,
      'paymentStatus': order.paymentStatus.name,
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'customerAddress': order.customerAddress,
    });

    await repository.updateOrder(
      order.id,
      {
        'paymentStatus': PaymentStatus.paid.name,
      },
      changeReason: 'Marked as paid',
    );

    final orderSnapshot = await firestore
        .collection('orders')
        .doc(order.id)
        .get();

    expect(orderSnapshot.exists, isTrue);

    final orderData = orderSnapshot.data()!;

    expect(
      orderData['paymentStatus'],
      PaymentStatus.paid.name,
    );

    // Unchanged fields must remain untouched.
    expect(orderData['status'], OrderStatus.pending.name);
    expect(orderData['deliveryCharge'], 100);
    expect(orderData['total'], 1100);
    expect(orderData['customerName'], 'Ahmed');

    final historySnapshot = await firestore
        .collection('orders')
        .doc(order.id)
        .collection('history')
        .get();

    expect(historySnapshot.docs, hasLength(1));

    final historyData = historySnapshot.docs.first.data();

    expect(historyData['changeReason'], 'Marked as paid');
    expect(historyData['field'], 'paymentStatus');
    expect(historyData['oldValue'], PaymentStatus.unpaid.name);
    expect(historyData['newValue'], PaymentStatus.paid.name);
    expect(historyData['timestamp'], isA<Timestamp>());
  },
);
test(
  'updateOrder supports multiple independent field changes',
  () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    final order = _createTestOrder();

    await firestore
        .collection('orders')
        .doc(order.id)
        .set({
      'id': order.id,
      'orderNumber': order.orderNumber,
      'createdAt': Timestamp.fromDate(order.createdAt),
      'businessDate': Timestamp.fromDate(order.businessDate),
      'items': [],
      'deals': [],
      'additionalDrinks': {},
      'additionalDipSauceCount': order.additionalDipSauceCount,
      'deliveryCharge': order.deliveryCharge,
      'total': order.total,
      'status': order.status.name,
      'paymentStatus': order.paymentStatus.name,
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'customerAddress': order.customerAddress,
    });

    await repository.updateOrder(
      order.id,
      {
        'customerName': 'Ali',
        'deliveryCharge': 150,
      },
      changeReason: 'Corrected customer and delivery information',
    );

    final snapshot = await firestore
        .collection('orders')
        .doc(order.id)
        .get();

    final data = snapshot.data()!;

    expect(data['customerName'], 'Ali');
    expect(data['deliveryCharge'], 150);

    // Completely unrelated values remain unchanged.
    expect(data['paymentStatus'], PaymentStatus.unpaid.name);
    expect(data['status'], OrderStatus.pending.name);
    expect(data['total'], 1100);

    final historySnapshot = await firestore
        .collection('orders')
        .doc(order.id)
        .collection('history')
        .get();

    expect(historySnapshot.docs, hasLength(2));

    final historyEntries = historySnapshot.docs
        .map((doc) => doc.data())
        .toList();

    expect(
      historyEntries.any(
        (entry) =>
            entry['field'] == 'customerName' &&
            entry['oldValue'] == 'Ahmed' &&
            entry['newValue'] == 'Ali',
      ),
      isTrue,
    );

    expect(
      historyEntries.any(
        (entry) =>
            entry['field'] == 'deliveryCharge' &&
            entry['oldValue'] == 100 &&
            entry['newValue'] == 150,
      ),
      isTrue,
    );
  },
);
test(
  'updateOrder increments editCount from zero',
  () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    const orderId = 'test-order-edit-count';

    await firestore
        .collection('orders')
        .doc(orderId)
        .set({
      'id': orderId,
      'orderNumber': 'ORD-0001',
      'editCount': 0,
      'status': 'pending',
      'paymentStatus': 'unpaid',
    });

    await repository.updateOrder(
      orderId,
      {
        'paymentStatus': 'paid',
      },
      changeReason: 'Marked as paid',
    );

    final snapshot = await firestore
        .collection('orders')
        .doc(orderId)
        .get();

    expect(
      snapshot.data()!['editCount'],
      1,
    );
  },
);
test(
  'updateOrder increments an existing editCount',
  () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    const orderId = 'test-order-edit-count-2';

    await firestore
        .collection('orders')
        .doc(orderId)
        .set({
      'id': orderId,
      'orderNumber': 'ORD-0002',
      'editCount': 2,
      'status': 'pending',
      'paymentStatus': 'unpaid',
    });

    await repository.updateOrder(
      orderId,
      {
        'customerName': 'Ali',
      },
      changeReason: 'Corrected customer name',
    );

    final snapshot = await firestore
        .collection('orders')
        .doc(orderId)
        .get();

    expect(
      snapshot.data()!['editCount'],
      3,
    );
  },
);
test(
  'one update operation increments editCount only once',
  () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirebaseOrderRepository(
      firestore: firestore,
    );

    const orderId = 'test-order-multi-edit';

    await firestore
        .collection('orders')
        .doc(orderId)
        .set({
      'id': orderId,
      'orderNumber': 'ORD-0003',
      'editCount': 0,
      'status': 'pending',
      'paymentStatus': 'unpaid',
      'customerName': 'Ahmed',
      'deliveryCharge': 100,
    });

    await repository.updateOrder(
      orderId,
      {
        'customerName': 'Ali',
        'deliveryCharge': 150,
      },
      changeReason: 'Corrected order information',
    );

    final snapshot = await firestore
        .collection('orders')
        .doc(orderId)
        .get();

    expect(
      snapshot.data()!['editCount'],
      1,
    );

    final history = await firestore
        .collection('orders')
        .doc(orderId)
        .collection('history')
        .get();

    expect(history.docs, hasLength(2));
  },
);
test(
  'updateOrder completes a pending order without changing payment status',
  () async {
    final fakeFirestore = FakeFirebaseFirestore();

    final repository = FirebaseOrderRepository(
      firestore: fakeFirestore,
    );

    final order = _createTestOrder(
      id: 'completion-unpaid',
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
    );

    await fakeFirestore
        .collection('orders')
        .doc(order.id)
        .set({
      'id': order.id,
      'orderNumber': order.orderNumber,
      'createdAt': Timestamp.fromDate(order.createdAt),
      'businessDate': Timestamp.fromDate(order.businessDate),
      'customerName': order.customerName,
      'customerPhone': order.customerPhone,
      'customerAddress': order.customerAddress,
      'items': const [],
      'deals': const [],
      'additionalDrinks': const {},
      'additionalDipSauceCount': 0,
      'deliveryCharge': order.deliveryCharge,
      'total': order.total,
      'status': OrderStatus.pending.name,
      'paymentStatus': PaymentStatus.unpaid.name,
      'editCount': 0,
    });

    await repository.updateOrder(
      order.id,
      {
        'status': OrderStatus.completed.name,
      },
      changeReason: 'Order completed',
    );

    final snapshot = await fakeFirestore
        .collection('orders')
        .doc(order.id)
        .get();

    final data = snapshot.data()!;

    expect(data['status'], OrderStatus.completed.name);
    expect(data['paymentStatus'], PaymentStatus.unpaid.name);
  },
);
test(
  'updateOrder completion preserves an already-paid order',
  () async {
    final fakeFirestore = FakeFirebaseFirestore();

    final repository = FirebaseOrderRepository(
      firestore: fakeFirestore,
    );

    const orderId = 'completion-paid';

    await fakeFirestore.collection('orders').doc(orderId).set({
      'id': orderId,
      'orderNumber': 'ORD-TEST',
      'createdAt': Timestamp.fromDate(
        DateTime(2026, 9, 2, 18),
      ),
      'businessDate': Timestamp.fromDate(
        DateTime(2026, 9, 2),
      ),
      'customerName': 'Paid Customer',
      'customerPhone': null,
      'customerAddress': null,
      'items': const [],
      'deals': const [],
      'additionalDrinks': const {},
      'additionalDipSauceCount': 0,
      'deliveryCharge': 0,
      'total': 650,
      'status': OrderStatus.pending.name,
      'paymentStatus': PaymentStatus.paid.name,
      'editCount': 0,
    });

    await repository.updateOrder(
      orderId,
      {
        'status': OrderStatus.completed.name,
      },
      changeReason: 'Order completed',
    );

    final snapshot = await fakeFirestore
        .collection('orders')
        .doc(orderId)
        .get();

    final data = snapshot.data()!;

    expect(data['status'], OrderStatus.completed.name);
    expect(data['paymentStatus'], PaymentStatus.paid.name);
  },
);
test(
  'completing an order records a status change in order history',
  () async {
    final fakeFirestore = FakeFirebaseFirestore();

    final repository = FirebaseOrderRepository(
      firestore: fakeFirestore,
    );

    const orderId = 'completion-history';

    await fakeFirestore.collection('orders').doc(orderId).set({
      'id': orderId,
      'orderNumber': 'ORD-HISTORY',
      'createdAt': Timestamp.fromDate(
        DateTime(2026, 9, 2, 18),
      ),
      'businessDate': Timestamp.fromDate(
        DateTime(2026, 9, 2),
      ),
      'customerName': 'History Customer',
      'customerPhone': null,
      'customerAddress': null,
      'items': const [],
      'deals': const [],
      'additionalDrinks': const {},
      'additionalDipSauceCount': 0,
      'deliveryCharge': 0,
      'total': 500,
      'status': OrderStatus.pending.name,
      'paymentStatus': PaymentStatus.unpaid.name,
      'editCount': 0,
    });

    await repository.updateOrder(
      orderId,
      {
        'status': OrderStatus.completed.name,
      },
      changeReason: 'Order completed',
    );

    final history = await repository.getOrderHistory(orderId);

    expect(history, hasLength(1));
    expect(history.first['field'], 'status');
    expect(history.first['oldValue'], 'pending');
    expect(history.first['newValue'], 'completed');
    expect(history.first['changeReason'], 'Order completed');
  },
);

test(
  'completed order rejects content edits',
  () async {
    final fakeFirestore =
        FakeFirebaseFirestore();

    final repository =
        FirebaseOrderRepository(
      firestore: fakeFirestore,
    );

    await fakeFirestore
        .collection('orders')
        .doc('order-1')
        .set({
      'id': 'order-1',
      'orderNumber': 'ORD-0001',
      'status': 'completed',
      'paymentStatus': 'unpaid',
      'editCount': 0,
      'customerName': 'Ali',
    });

    await expectLater(
      repository.updateOrder(
        'order-1',
        {
          'customerName': 'Ahmed',
        },
        changeReason: 'Customer correction',
      ),
      throwsA(
        isA<StateError>(),
      ),
    );

    final snapshot =
        await fakeFirestore
            .collection('orders')
            .doc('order-1')
            .get();

    expect(
      snapshot.data()?['customerName'],
      'Ali',
    );
  },
);
test(
  'completed order rejects content edits',
  () async {
    final fakeFirestore =
        FakeFirebaseFirestore();

    final repository =
        FirebaseOrderRepository(
      firestore: fakeFirestore,
    );

    await fakeFirestore
        .collection('orders')
        .doc('order-1')
        .set({
      'id': 'order-1',
      'orderNumber': 'ORD-0001',
      'status': 'completed',
      'paymentStatus': 'unpaid',
      'editCount': 0,
      'customerName': 'Ali',
    });

    await expectLater(
      repository.updateOrder(
        'order-1',
        {
          'customerName': 'Ahmed',
        },
        changeReason: 'Customer correction',
      ),
      throwsA(
        isA<StateError>(),
      ),
    );

    final snapshot =
        await fakeFirestore
            .collection('orders')
            .doc('order-1')
            .get();

    expect(
      snapshot.data()?['customerName'],
      'Ali',
    );
  },
);
test(
  'pending order accepts content edits',
  () async {
    final fakeFirestore =
        FakeFirebaseFirestore();

    final repository =
        FirebaseOrderRepository(
      firestore: fakeFirestore,
    );

    await fakeFirestore
        .collection('orders')
        .doc('order-1')
        .set({
      'id': 'order-1',
      'orderNumber': 'ORD-0001',
      'status': 'pending',
      'paymentStatus': 'unpaid',
      'editCount': 0,
      'customerName': 'Ali',
    });

    await repository.updateOrder(
      'order-1',
      {
        'customerName': 'Ahmed',
      },
      changeReason: 'Customer name correction',
    );

    final snapshot =
        await fakeFirestore
            .collection('orders')
            .doc('order-1')
            .get();

    expect(
      snapshot.data()?['customerName'],
      'Ahmed',
    );

    expect(
      snapshot.data()?['editCount'],
      1,
    );
  },
);
test(
  'content edit creates one history document per changed field',
  () async {
    final fakeFirestore =
        FakeFirebaseFirestore();

    final repository =
        FirebaseOrderRepository(
      firestore: fakeFirestore,
    );

    await fakeFirestore
        .collection('orders')
        .doc('order-1')
        .set({
      'id': 'order-1',
      'orderNumber': 'ORD-0001',
      'status': 'pending',
      'paymentStatus': 'unpaid',
      'editCount': 0,
      'customerName': 'Ali',
      'total': 900,
    });

    await repository.updateOrder(
      'order-1',
      {
        'customerName': 'Ahmed',
        'total': 1000,
      },
      changeReason: 'Customer correction and repricing',
    );

    final history =
        await fakeFirestore
            .collection('orders')
            .doc('order-1')
            .collection('history')
            .get();

    expect(
      history.docs,
      hasLength(2),
    );

    final fields = history.docs
        .map(
          (doc) => doc.data()['field'],
        )
        .toSet();

    expect(
      fields,
      containsAll([
        'customerName',
        'total',
      ]),
    );

    for (final doc in history.docs) {
      expect(
        doc.data()['changeReason'],
        'Customer correction and repricing',
      );
    }
  },
);
test(
  'completed order can still transition from unpaid to paid',
  () async {
    final fakeFirestore =
        FakeFirebaseFirestore();

    final repository =
        FirebaseOrderRepository(
      firestore: fakeFirestore,
    );

    await fakeFirestore
        .collection('orders')
        .doc('order-1')
        .set({
      'id': 'order-1',
      'orderNumber': 'ORD-0001',
      'status': 'completed',
      'paymentStatus': 'unpaid',
      'editCount': 0,
    });

    await repository.updateOrder(
      'order-1',
      {
        'paymentStatus':
            PaymentStatus.paid.name,
      },
      changeReason: 'Payment received',
    );

    final snapshot =
        await fakeFirestore
            .collection('orders')
            .doc('order-1')
            .get();

    expect(
      snapshot.data()?['paymentStatus'],
      'paid',
    );

    expect(
      snapshot.data()?['editCount'],
      1,
    );
  },
);

  test('createOrder persists delivery area and notes', () async {
    final fakeFirestore = FakeFirebaseFirestore();
    final repository = FirebaseOrderRepository(firestore: fakeFirestore);
    final order = _createTestOrder();
    final withFields = Order(
      id: order.id,
      orderNumber: order.orderNumber,
      createdAt: order.createdAt,
      businessDate: order.businessDate,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerAddress: order.customerAddress,
      deliveryAreaId: 'area-1',
      deliveryAreaName: 'Sector 5C/1',
      deliveryNotes: 'Ring twice',
      items: order.items,
      deals: order.deals,
      additionalDrinks: order.additionalDrinks,
      additionalDipSauceCount: order.additionalDipSauceCount,
      deliveryCharge: order.deliveryCharge,
      total: order.total,
      status: order.status,
      paymentStatus: order.paymentStatus,
    );
    await repository.createOrder(withFields);
    final loaded = await repository.getOrder(order.id);
    expect(loaded?.deliveryAreaId, 'area-1');
    expect(loaded?.deliveryAreaName, 'Sector 5C/1');
    expect(loaded?.deliveryNotes, 'Ring twice');
  });
}
