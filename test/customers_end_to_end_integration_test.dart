import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_actions_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_orders_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_repository_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_stats_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_unpaid_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customers_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/last_order_provider.dart';
import 'package:hangout_sales_app/features/customers/repositories/firebase_customer_repository.dart';
import 'package:hangout_sales_app/features/customers/screens/customer_detail_screen.dart';
import 'package:hangout_sales_app/features/customers/services/contact_launcher.dart';
import 'package:hangout_sales_app/features/customers/services/reorder_mapper.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_area_repository_provider.dart';
import 'package:hangout_sales_app/features/delivery_areas/repositories/firebase_delivery_area_repository.dart';
import 'package:hangout_sales_app/features/orders/models/menu_data.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';

import 'helpers/test_container.dart';

final _t1 = DateTime(2026, 10, 2, 18, 30);
final _t2 = DateTime(2026, 10, 5, 19, 15);
const _phone = '03001234567';

Order _seedOrder(
  String id,
  DateTime createdAt,
  double total,
) {
  final flavor = MenuData.flavors.first;
  return Order(
    id: id,
    orderNumber: 'PENDING',
    createdAt: createdAt,
    businessDate: DateTime(createdAt.year, createdAt.month, createdAt.day),
    customerName: 'Ahmed Raza',
    customerPhone: _phone,
    items: [
      OrderItem(
        flavorId: flavor.id,
        flavorName: flavor.name,
        size: PizzaSize.small,
        quantity: 1,
        unitPrice: total,
      ),
    ],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: total,
    status: OrderStatus.completed,
    paymentStatus: PaymentStatus.unpaid,
  );
}

void main() {
  group('Customers end-to-end workflow (plan Phase 11)', () {
    test(
      'new phone -> customer saved -> second order autofills -> '
      'reorder -> unpaid summary -> stats',
      () async {
        final fake = FakeFirebaseFirestore();
        final container = createTestContainer(overrides: [
          customerRepositoryProvider.overrideWithValue(
            FirebaseCustomerRepository(firestore: fake),
          ),
          orderRepositoryProvider.overrideWithValue(
            FirebaseOrderRepository(firestore: fake),
          ),
          deliveryAreaRepositoryProvider.overrideWithValue(
            FirebaseDeliveryAreaRepository(firestore: fake),
          ),
        ]);
        final notifier = container.read(orderDraftProvider.notifier);
        final flavor = MenuData.flavors.first;
        const charge = 100.0;

        // ---------------------------------------------------------
        // 1. A brand-new phone matches no customer.
        // ---------------------------------------------------------
        notifier.onCustomerPhoneChanged(_phone);
        // 400 ms debounce plus the (instant) repository lookup.
        await Future.delayed(const Duration(milliseconds: 600));

        var draft = container.read(orderDraftProvider);
        expect(draft.matchedCustomerPhone, isNull);

        // ---------------------------------------------------------
        // 2. First order saves the order AND the new customer
        //    (plan 8.5/8.6, switch ON by default).
        // ---------------------------------------------------------
        notifier.setCustomerName('Ahmed Raza');
        notifier.setCustomerAddress('House 14, Street 3');
        notifier.setDeliveryNotes('Ring twice');
        notifier.addStandalonePizza(PizzaSize.small);
        final firstEntryId =
            container.read(orderDraftProvider).entries.single.id;
        notifier.setFlavor(firstEntryId, 0, flavor.id);
        notifier.setDeliveryCharge(charge);
        final firstTotal = notifier.grandTotal;

        await notifier.saveOrder(
          orderNumber: 'PENDING',
          businessDate: DateTime(2026, 10, 2),
          createdAt: _t1,
        );

        final customerRepository =
            FirebaseCustomerRepository(firestore: fake);
        final saved = await customerRepository.getByPhone(_phone);
        expect(saved, isNotNull);
        expect(saved!.name, 'Ahmed Raza');
        expect(saved.addresses, hasLength(1));
        expect(saved.addresses.single.text, 'House 14, Street 3');
        expect(saved.defaultAddressId, saved.addresses.single.id);
        expect(saved.deliveryNotes, 'Ring twice');
        expect(saved.lastOrderAt, _t1);
        final createdAfterFirstOrder = saved.createdAt;

        final firstOrders = await fake.collection('orders').get();
        expect(firstOrders.docs, hasLength(1));
        expect(
          firstOrders.docs.single.data()['orderNumber'],
          'ORD-0001',
        );

        // The lookup provider resolves the saved customer too.
        final viaProvider =
            await container.read(customerByPhoneProvider(_phone).future);
        expect(viaProvider?.phone, _phone);

        // ---------------------------------------------------------
        // 3. Second order: a differently formatted phone autofills
        //    from the saved customer (plan 8.1).
        // ---------------------------------------------------------
        notifier.clearDraft();
        notifier.onCustomerPhoneChanged('0300-1234567');
        await Future.delayed(const Duration(milliseconds: 600));

        draft = container.read(orderDraftProvider);
        expect(draft.matchedCustomerPhone, _phone);
        expect(draft.customerName, 'Ahmed Raza');
        expect(draft.customerAddress, 'House 14, Street 3');
        expect(draft.deliveryNotes, 'Ring twice');
        expect(draft.selectedAddressId, saved.addresses.single.id);

        // ---------------------------------------------------------
        // 4. Second order: the customer is touched, not duplicated,
        //    and its createdAt survives (plan 8.6).
        // ---------------------------------------------------------
        notifier.addStandalonePizza(PizzaSize.small);
        final secondEntryId =
            container.read(orderDraftProvider).entries.single.id;
        notifier.setFlavor(secondEntryId, 0, flavor.id);
        notifier.setDeliveryCharge(charge);
        final secondTotal = notifier.grandTotal;
        expect(secondTotal, firstTotal);

        await notifier.saveOrder(
          orderNumber: 'PENDING',
          businessDate: DateTime(2026, 10, 5),
          createdAt: _t2,
        );

        final allCustomers = await fake.collection('customers').get();
        expect(allCustomers.docs, hasLength(1));

        final touched = await customerRepository.getByPhone(_phone);
        expect(touched, isNotNull);
        expect(touched!.lastOrderAt, _t2);
        expect(touched.createdAt, createdAfterFirstOrder);
        expect(touched.addresses, hasLength(1));

        final orderNumbers = (await fake.collection('orders').get())
            .docs
            .map((doc) => doc.data()['orderNumber'] as String)
            .toList()
          ..sort();
        expect(orderNumbers, ['ORD-0001', 'ORD-0002']);

        // ---------------------------------------------------------
        // 5. Reorder rebuilds the last order at current menu
        //    prices and never touches customer fields (plan 8.10).
        // ---------------------------------------------------------
        final orders =
            await container.read(customerOrdersProvider(_phone).future);
        expect(orders, hasLength(2));
        expect(orders.first.orderNumber, 'ORD-0002');

        final lastOrder = container.read(lastOrderProvider(_phone));
        expect(lastOrder?.orderNumber, 'ORD-0002');

        final reorder = mapOrderToDraft(lastOrder!);
        expect(reorder.skippedCount, 0);
        expect(reorder.entries, hasLength(1));

        notifier.applyReorder(reorder);

        draft = container.read(orderDraftProvider);
        expect(draft.entries.single.flavorIds, [flavor.id]);
        expect(draft.customerName, 'Ahmed Raza');
        expect(draft.customerPhone, '0300-1234567');
        // Re-priced from the current menu; the charge on the draft
        // is untouched by reorder, so the total matches order two.
        expect(notifier.grandTotal, secondTotal);

        // ---------------------------------------------------------
        // 6. Unpaid summary (plan 8.9): both orders are unpaid.
        // ---------------------------------------------------------
        final summary = container.read(customerUnpaidProvider(_phone));
        expect(summary.count, 2);
        expect(summary.amount, firstTotal + secondTotal);
        expect(summary.hasUnpaid, isTrue);

        // ---------------------------------------------------------
        // 7. Detail-screen statistics, derived (plan 5.4/8.8).
        // ---------------------------------------------------------
        final stats = container.read(customerStatsProvider(_phone));
        expect(stats.orderCount, 2);
        expect(stats.totalSpent, firstTotal + secondTotal);
        expect(stats.averageOrderValue, (firstTotal + secondTotal) / 2);
        expect(stats.favoriteFlavor, flavor.name);
        expect(stats.unpaidOrderCount, 2);
        expect(stats.unpaidAmount, firstTotal + secondTotal);
        expect(stats.firstOrderAt, _t1);
        expect(stats.lastOrderAt, _t2);
      },
    );

    testWidgets(
      'customer detail screen shows the stats of both saved orders',
      (tester) async {
        final fake = FakeFirebaseFirestore();
        final orderRepository = FirebaseOrderRepository(firestore: fake);

        // Seed through the real createOrder transaction: the first
        // order creates the customer, the second touches it.
        await orderRepository.createOrder(
          _seedOrder('e2e-order-1', _t1, 430),
          customerUpsert: const CustomerUpsert(
            phone: _phone,
            createIfMissing: true,
            name: 'Ahmed Raza',
          ),
        );
        await orderRepository.createOrder(
          _seedOrder('e2e-order-2', _t2, 430),
          customerUpsert: const CustomerUpsert(
            phone: _phone,
            createIfMissing: true,
          ),
        );

        tester.view.physicalSize = const Size(520, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerRepositoryProvider.overrideWithValue(
                FirebaseCustomerRepository(firestore: fake),
              ),
              orderRepositoryProvider.overrideWithValue(orderRepository),
              deliveryAreaRepositoryProvider.overrideWithValue(
                FirebaseDeliveryAreaRepository(firestore: fake),
              ),
              contactLauncherProvider.overrideWithValue(
                ContactLauncher(
                  canLaunch: (_) async => true,
                  launch: (_) async => true,
                ),
              ),
            ],
            child: const MaterialApp(
              home: CustomerDetailScreen(phone: _phone),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ahmed Raza'), findsWidgets);
        expect(
          find.text('2 orders · Rs. 860 · avg Rs. 430'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Favorite: ${MenuData.flavors.first.name} · '
            'Rs. 860 unpaid (2 orders)',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
