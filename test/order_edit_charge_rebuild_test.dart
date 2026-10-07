import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_edit_provider.dart';
import 'package:hangout_sales_app/features/orders/screens/edit_order_screen.dart';

/// Phase 5: the Edit Order charge dropdown must reflect programmatic changes
/// (area selection presets the charge via setDeliveryArea). Without a
/// key: ValueKey(charge) the DropdownButtonFormField keeps showing the first
/// build's initialValue — the exact Phase 4 stale-dropdown bug, repeated.
void main() {
  Order testOrder() {
    return Order(
      id: 'order-test-1',
      orderNumber: 'ORD-0024',
      createdAt: DateTime(2026, 10, 6, 18, 30),
      businessDate: DateTime(2026, 10, 6),
      customerName: 'Ahmed',
      customerPhone: '03001234567',
      customerAddress: 'House 1, Street 2',
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 100,
      total: 1850,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.paid,
    );
  }

  Finder chargeText(String fragment) {
    return find.descendant(
      of: find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<double>,
      ),
      matching: find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data ?? '').contains(fragment),
      ),
      skipOffstage: false,
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ProviderContainer container,
    Order order,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: EditOrderScreen(order: order)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('charge dropdown reflects programmatic area selection',
      (tester) async {
    final order = testOrder();
    final container = createTestContainer();

    await pumpScreen(tester, container, order);
    expect(chargeText('Rs. 100'), findsOneWidget);

    container.read(orderEditProvider(order).notifier).setDeliveryArea(
          areaId: 'area-1',
          areaName: 'Gulberg',
          defaultCharge: 180,
        );
    await tester.pump();

    expect(chargeText('Rs. 180'), findsOneWidget);
    expect(chargeText('Rs. 100'), findsNothing);
  });

  testWidgets('charge dropdown still works for manual changes', (tester) async {
    final order = testOrder();
    final container = createTestContainer();

    await pumpScreen(tester, container, order);

    container.read(orderEditProvider(order).notifier).setDeliveryCharge(250);
    await tester.pump();

    expect(chargeText('Rs. 250'), findsOneWidget);
  });
}
