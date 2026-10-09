import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseOrderRepository repository;

  Order createOrder({
    OrderStatus status = OrderStatus.pending,
    PaymentStatus paymentStatus = PaymentStatus.unpaid,
    int editCount = 0,
  }) {
    return Order(
      id: 'order-1',
      orderNumber: 'ORD-0001',
      createdAt: DateTime(2026, 9, 15, 18, 30),
      businessDate: DateTime(2026, 9, 15),
      customerName: 'Test Customer',
      customerPhone: '03001234567',
      customerAddress: 'Test Address',
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 0,
      total: 1000,
      status: status,
      paymentStatus: paymentStatus,
      editCount: editCount,
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();

    repository = FirebaseOrderRepository(
      firestore: firestore,
    );
  });

  group('FirebaseOrderRepository lifecycle regression', () {
    test(
      'payment transition changes paymentStatus without changing fulfillment status',
      () async {
        final order = createOrder(
          status: OrderStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        );

        await repository.createOrder(order);

        await repository.updateOrder(
          order.id,
          {
            'paymentStatus': PaymentStatus.paid.name,
          },
          changeReason: 'Marked as paid',
        );

        final saved = await repository.getOrder(order.id);

        expect(saved, isNotNull);
        expect(saved!.paymentStatus, PaymentStatus.paid);
        expect(saved.status, OrderStatus.pending);
      },
    );

    test(
      'completion changes fulfillment status without changing payment status',
      () async {
        final order = createOrder(
          status: OrderStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        );

        await repository.createOrder(order);

        await repository.updateOrder(
          order.id,
          {
            'status': OrderStatus.completed.name,
          },
          changeReason: 'Customer received order',
        );

        final saved = await repository.getOrder(order.id);

        expect(saved, isNotNull);
        expect(saved!.status, OrderStatus.completed);
        expect(saved.paymentStatus, PaymentStatus.unpaid);
      },
    );

    test(
      'completed order can still transition from unpaid to paid',
      () async {
        final order = createOrder(
          status: OrderStatus.completed,
          paymentStatus: PaymentStatus.unpaid,
        );

        await repository.createOrder(order);

        await repository.updateOrder(
          order.id,
          {
            'paymentStatus': PaymentStatus.paid.name,
          },
          changeReason: 'Payment received after completion',
        );

        final saved = await repository.getOrder(order.id);

        expect(saved, isNotNull);
        expect(saved!.status, OrderStatus.completed);
        expect(saved.paymentStatus, PaymentStatus.paid);
      },
    );

    test(
      'completed order rejects content edits',
      () async {
        final order = createOrder(
          status: OrderStatus.completed,
          paymentStatus: PaymentStatus.paid,
        );

        await repository.createOrder(order);

        expect(
          () => repository.updateOrder(
            order.id,
            {
              'customerName': 'Changed Customer',
            },
            changeReason: 'Attempted content edit',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Completed or cancelled orders cannot be edited.',
            ),
          ),
        );
      },
    );

    test(
      'cancelled order rejects content edits',
      () async {
        final order = createOrder(
          status: OrderStatus.cancelled,
          paymentStatus: PaymentStatus.unpaid,
        );

        await repository.createOrder(order);

        expect(
          () => repository.updateOrder(
            order.id,
            {
              'customerName': 'Changed Customer',
            },
            changeReason: 'Attempted content edit',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Completed or cancelled orders cannot be edited.',
            ),
          ),
        );
      },
    );

    test(
      'content edit increments editCount and creates field history',
      () async {
        final order = createOrder(
          status: OrderStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
          editCount: 0,
        );

        await repository.createOrder(order);

        await repository.updateOrder(
          order.id,
          {
            'customerName': 'Updated Customer',
            'deliveryCharge': 70.0,
          },
          changeReason: 'Customer requested changes',
        );

        final saved = await repository.getOrder(order.id);
        final history = await repository.getOrderHistory(order.id);

        expect(saved, isNotNull);
        expect(saved!.editCount, 1);
        expect(saved.customerName, 'Updated Customer');
        expect(saved.deliveryCharge, 70.0);

        expect(history, hasLength(2));

        final fields = history
            .map((entry) => entry['field'])
            .toSet();

        expect(
          fields,
          containsAll([
            'customerName',
            'deliveryCharge',
          ]),
        );

        for (final entry in history) {
          expect(entry['changeReason'], 'Customer requested changes');
          expect(entry['timestamp'], isA<Timestamp>());
        }
      },
    );

    test(
      'unchanged values do not create false history entries',
      () async {
        final order = createOrder(
          status: OrderStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
          editCount: 0,
        );

        await repository.createOrder(order);

        await repository.updateOrder(
          order.id,
          {
            'customerName': 'Test Customer',
          },
          changeReason: 'No actual customer-name change',
        );

        final history = await repository.getOrderHistory(order.id);

        expect(history, isEmpty);

        final saved = await repository.getOrder(order.id);

        expect(saved, isNotNull);
        expect(saved!.editCount, 0);
      },
    );

    test(
      'empty changes are rejected before Firestore update',
      () async {
        final order = createOrder();

        await repository.createOrder(order);

        expect(
          () => repository.updateOrder(
            order.id,
            {},
            changeReason: 'Nothing changed',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'blank change reason is rejected',
      () async {
        final order = createOrder();

        await repository.createOrder(order);

        expect(
          () => repository.updateOrder(
            order.id,
            {
              'customerName': 'New Customer',
            },
            changeReason: '   ',
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'missing order is rejected',
      () async {
        expect(
          () => repository.updateOrder(
            'missing-order',
            {
              'paymentStatus': PaymentStatus.paid.name,
            },
            changeReason: 'Payment received',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Order missing-order does not exist.',
            ),
          ),
        );
      },
    );

    test(
      'area and notes edits create one history entry per field',
      () async {
        final order = createOrder();

        await repository.createOrder(order);

        await repository.updateOrder(
          order.id,
          {
            'deliveryAreaId': 'area-1',
            'deliveryAreaName': 'Sector 5C/1',
            'deliveryNotes': 'Ring twice',
          },
          changeReason: 'Customer moved',
        );

        final saved = await repository.getOrder(order.id);

        expect(saved, isNotNull);
        expect(saved!.deliveryAreaId, 'area-1');
        expect(saved.deliveryAreaName, 'Sector 5C/1');
        expect(saved.deliveryNotes, 'Ring twice');
        expect(saved.editCount, 1);

        final history = await repository.getOrderHistory(order.id);

        expect(history, hasLength(3));
        expect(
          history.map((entry) => entry['field']).toSet(),
          {'deliveryAreaId', 'deliveryAreaName', 'deliveryNotes'},
        );
        for (final entry in history) {
          expect(entry['changeReason'], 'Customer moved');
          expect(entry['oldValue'], isNull);
        }
      },
    );

    test(
      'completed order rejects a delivery area edit',
      () async {
        final order = createOrder(
          status: OrderStatus.completed,
          paymentStatus: PaymentStatus.paid,
        );

        await repository.createOrder(order);

        expect(
          () => repository.updateOrder(
            order.id,
            {
              'deliveryAreaName': 'Sector 9',
            },
            changeReason: 'Attempted area edit',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Completed or cancelled orders cannot be edited.',
            ),
          ),
        );
      },
    );

    test(
      'cancelled order rejects a delivery notes edit',
      () async {
        final order = createOrder(
          status: OrderStatus.cancelled,
          paymentStatus: PaymentStatus.unpaid,
        );

        await repository.createOrder(order);

        expect(
          () => repository.updateOrder(
            order.id,
            {
              'deliveryNotes': 'Ring twice',
            },
            changeReason: 'Attempted notes edit',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Completed or cancelled orders cannot be edited.',
            ),
          ),
        );
      },
    );

    test(
      're-saving identical area and notes creates no history',
      () async {
        final order = createOrder();

        await repository.createOrder(order);

        await repository.updateOrder(
          order.id,
          {
            'deliveryAreaId': 'area-1',
            'deliveryAreaName': 'Sector 5C/1',
            'deliveryNotes': 'Ring twice',
          },
          changeReason: 'Customer moved',
        );

        await repository.updateOrder(
          order.id,
          {
            'deliveryAreaId': 'area-1',
            'deliveryAreaName': 'Sector 5C/1',
            'deliveryNotes': 'Ring twice',
          },
          changeReason: 'Saved again without changes',
        );

        final saved = await repository.getOrder(order.id);

        expect(saved, isNotNull);
        expect(saved!.editCount, 1);

        final history = await repository.getOrderHistory(order.id);
        expect(history, hasLength(3));
      },
    );
  });
}