import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/models/topping_selection.dart';
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseOrderRepository repository;

  final businessDate = DateTime(2026, 9, 15);
  final createdAt = DateTime(2026, 9, 15, 20, 15);

  Order buildTestOrder() {
    return Order(
      id: 'integration-order-1',
      orderNumber: 'PENDING-INTEGRATION',
      createdAt: createdAt,
      businessDate: businessDate,
      customerName: 'Integration Customer',
      customerPhone: '03001234567',
      customerAddress: 'Integration Address',
      items: const [
        OrderItem(
          flavorId: 'flavor_chicken',
          flavorName: 'Chicken',
          flavorPriceExtra: 0,
          size: PizzaSize.small,
          toppings: [
            ToppingSelection(
              toppingId: 'topping_cheese',
              toppingName: 'Cheese',
              priceAtOrderTime: 70,
            ),
          ],
          quantity: 1,
          unitPrice: 400,
        ),
      ],
      deals: const [],
      additionalDrinks: const {
        'drink_1.5ltr': 1,
      },
      additionalDipSauceCount: 1,
      deliveryCharge: 70,
      total: 720,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
      editCount: 0,
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();

    repository = FirebaseOrderRepository(
      firestore: firestore,
    );
  });

  group('Orders end-to-end integration', () {
    test(
      'complete POS lifecycle preserves order state and history',
      () async {
        final order = buildTestOrder();

        // ------------------------------------------------------------
        // 1. CREATE
        // ------------------------------------------------------------

        await repository.createOrder(order);

        final created = await repository.getOrder(order.id);

        expect(created, isNotNull);
        expect(created!.orderNumber, isNot('PENDING-INTEGRATION'));
        expect(created.orderNumber, startsWith('ORD-'));
        expect(created.status, OrderStatus.pending);
        expect(created.paymentStatus, PaymentStatus.unpaid);

        expect(created.customerName, 'Integration Customer');
        expect(created.customerPhone, '03001234567');
        expect(created.deliveryCharge, 70);
        expect(created.total, 720);

        expect(
          created.items.single.flavorName,
          'Chicken',
        );

        expect(
          created.items.single.toppings!.single.toppingName,
          'Cheese',
        );

        // ------------------------------------------------------------
        // 2. MARK AS PAID
        // ------------------------------------------------------------

        await repository.updateOrder(
          order.id,
          {
            'paymentStatus': PaymentStatus.paid.name,
          },
          changeReason: 'Customer payment received',
        );

        final paid = await repository.getOrder(order.id);

        expect(paid, isNotNull);
        expect(paid!.paymentStatus, PaymentStatus.paid);

        // Fulfillment state must remain untouched.
        expect(paid.status, OrderStatus.pending);

        // ------------------------------------------------------------
        // 3. CONTENT EDIT
        // ------------------------------------------------------------

        await repository.updateOrder(
          order.id,
          {
            'customerName': 'Updated Integration Customer',
            'deliveryCharge': 100.0,
            'total': 750.0,
          },
          changeReason: 'Customer requested order changes',
        );

        final edited = await repository.getOrder(order.id);

        expect(edited, isNotNull);
        expect(
          edited!.customerName,
          'Updated Integration Customer',
        );
        expect(edited.deliveryCharge, 100);
        expect(edited.total, 750);

        // Payment must survive unrelated content edits.
        expect(edited.paymentStatus, PaymentStatus.paid);

        // Fulfillment must remain pending.
        expect(edited.status, OrderStatus.pending);

        // EXPECTATION UPDATED TO 2 (1 for payment status, 1 for content edit)
        expect(edited.editCount, 2);

        // ------------------------------------------------------------
        // 4. VERIFY EDIT HISTORY
        // ------------------------------------------------------------

        final history = await repository.getOrderHistory(order.id);

        // EXPECTATION UPDATED TO 4 (1 payment field + 3 content fields)
        expect(history, hasLength(4));

        final changedFields = history
            .map((entry) => entry['field'])
            .toSet();

        expect(
          changedFields,
          containsAll([
            'paymentStatus', // Added this field verification
            'customerName',
            'deliveryCharge',
            'total',
          ]),
        );

        // Verify the payment log separately because it has a different change reason
        final paymentLog = history.firstWhere((entry) => entry['field'] == 'paymentStatus');
        expect(paymentLog['changeReason'], 'Customer payment received');

        // Verify the content edit logs
        final contentLogs = history.where((entry) => entry['field'] != 'paymentStatus');
        for (final entry in contentLogs) {
          expect(
            entry['changeReason'],
            'Customer requested order changes',
          );
        }

        // Payment transition itself should also have an audit record.
        // Therefore the total number of history documents is:
        //
        // paymentStatus + customerName + deliveryCharge + total
        expect(history, isNotEmpty);

        // ------------------------------------------------------------
        // 5. COMPLETE
        // ------------------------------------------------------------

        await repository.updateOrder(
          order.id,
          {
            'status': OrderStatus.completed.name,
          },
          changeReason: 'Order delivered to customer',
        );

        final completed = await repository.getOrder(order.id);

        expect(completed, isNotNull);
        expect(completed!.status, OrderStatus.completed);

        // Payment must remain paid.
        expect(completed.paymentStatus, PaymentStatus.paid);

        // Content edits already made must remain.
        expect(
          completed.customerName,
          'Updated Integration Customer',
        );
        expect(completed.deliveryCharge, 100);
        expect(completed.total, 750);

        // ------------------------------------------------------------
        // 6. COMPLETED ORDER CONTENT LOCK
        // ------------------------------------------------------------

        await expectLater(
          repository.updateOrder(
            order.id,
            {
              'customerName': 'Illegal Completed Edit',
            },
            changeReason: 'Should be rejected',
          ),
          throwsA(isA<StateError>()),
        );

        final afterRejectedEdit =
            await repository.getOrder(order.id);

        expect(afterRejectedEdit, isNotNull);
        expect(
          afterRejectedEdit!.customerName,
          'Updated Integration Customer',
        );

        // ------------------------------------------------------------
        // 7. HISTORY STILL REPRESENTS THE LIFECYCLE
        // ------------------------------------------------------------

        final finalHistory =
            await repository.getOrderHistory(order.id);

        final finalFields = finalHistory
            .map((entry) => entry['field'])
            .toList();

        expect(
          finalFields,
          contains('paymentStatus'),
        );

        expect(
          finalFields,
          contains('status'),
        );

        expect(
          finalFields,
          contains('customerName'),
        );

        expect(
          finalFields,
          contains('deliveryCharge'),
        );

        expect(
          finalFields,
          contains('total'),
        );
      },
    );

    test(
      'cancelled order remains readable and blocks later content edits',
      () async {
        final order = buildTestOrder();

        await repository.createOrder(order);

        await repository.updateOrder(
          order.id,
          {
            'status': OrderStatus.cancelled.name,
          },
          changeReason: 'Customer cancelled the order',
        );

        final cancelled = await repository.getOrder(order.id);

        expect(cancelled, isNotNull);
        expect(cancelled!.status, OrderStatus.cancelled);
        expect(cancelled.paymentStatus, PaymentStatus.unpaid);

        await expectLater(
          repository.updateOrder(
            order.id,
            {
              'total': 999.0,
            },
            changeReason: 'Attempted edit after cancellation',
          ),
          throwsA(isA<StateError>()),
        );

        final afterRejectedEdit =
            await repository.getOrder(order.id);

        expect(afterRejectedEdit, isNotNull);
        expect(afterRejectedEdit!.total, 720);
        expect(afterRejectedEdit.status, OrderStatus.cancelled);
      },
    );

    test(
      'completed unpaid order can still be marked paid',
      () async {
        final order = buildTestOrder();

        await repository.createOrder(order);

        await repository.updateOrder(
          order.id,
          {
            'status': OrderStatus.completed.name,
          },
          changeReason: 'Order delivered before payment',
        );

        await repository.updateOrder(
          order.id,
          {
            'paymentStatus': PaymentStatus.paid.name,
          },
          changeReason: 'Payment received after delivery',
        );

        final finalOrder =
            await repository.getOrder(order.id);

        expect(finalOrder, isNotNull);
        expect(finalOrder!.status, OrderStatus.completed);
        expect(finalOrder.paymentStatus, PaymentStatus.paid);
      },
    );
  });
}