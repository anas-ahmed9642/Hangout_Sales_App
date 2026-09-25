import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- Added Riverpod import
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/screens/order_detail_screen.dart';
import 'package:hangout_sales_app/features/orders/screens/order_history_screen.dart';
import 'package:hangout_sales_app/features/orders/screens/new_order_screen.dart';

void main() {
  Order buildOrder({
    OrderStatus status = OrderStatus.pending,
    PaymentStatus paymentStatus = PaymentStatus.unpaid,
  }) {
    return Order(
      id: 'cross-screen-order',
      orderNumber: 'ORD-1001',
      createdAt: DateTime(2026, 9, 15, 20),
      businessDate: DateTime(2026, 9, 15),
      customerName: 'Cross Screen Customer',
      customerPhone: '03001234567',
      customerAddress: 'Cross Screen Address',
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 0,
      total: 500,
      status: status,
      paymentStatus: paymentStatus,
      editCount: 0,
    );
  }

  Widget buildScreen(Widget child) {
    // <-- Wrapped MaterialApp in a ProviderScope
    return ProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Orders cross-screen regression', () {
    testWidgets(
      'NewOrderScreen can render inside the application shell',
      (tester) async {
        await tester.pumpWidget(
          buildScreen(
            const NewOrderScreen(),
          ),
        );

        await tester.pump();

        expect(find.byType(NewOrderScreen), findsOneWidget);
      },
    );

    testWidgets(
      'OrderHistoryScreen can render inside the application shell',
      (tester) async {
        await tester.pumpWidget(
          buildScreen(
            const OrderHistoryScreen(),
          ),
        );

        await tester.pump();

        expect(
          find.byType(OrderHistoryScreen),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'OrderDetailScreen accepts a saved order snapshot',
      (tester) async {
        final order = buildOrder(
          status: OrderStatus.pending,
          paymentStatus: PaymentStatus.paid,
        );

        await tester.pumpWidget(
          buildScreen(
            OrderDetailScreen(order: order),
          ),
        );

        await tester.pump();

        expect(
          find.byType(OrderDetailScreen),
          findsOneWidget,
        );

        expect(
          find.text('ORD-1001'),
          findsOneWidget,
        );

        expect(
          find.text('Cross Screen Customer'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'OrderDetailScreen receives payment and fulfillment independently',
      (tester) async {
        final order = buildOrder(
          status: OrderStatus.completed,
          paymentStatus: PaymentStatus.unpaid,
        );

        await tester.pumpWidget(
          buildScreen(
            OrderDetailScreen(order: order),
          ),
        );

        await tester.pump();

        expect(
          find.byType(OrderDetailScreen),
          findsOneWidget,
        );

        expect(
          find.textContaining('Completed'),
          findsWidgets,
        );

        expect(
          find.textContaining('Unpaid'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'completed order detail remains readable',
      (tester) async {
        final order = buildOrder(
          status: OrderStatus.completed,
          paymentStatus: PaymentStatus.paid,
        );

        await tester.pumpWidget(
          buildScreen(
            OrderDetailScreen(order: order),
          ),
        );

        await tester.pump();

        expect(
          find.text('ORD-1001'),
          findsOneWidget,
        );

        expect(
          find.textContaining('Completed'),
          findsWidgets,
        );

        expect(
          find.textContaining('Paid'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'cancelled order detail remains readable',
      (tester) async {
        final order = buildOrder(
          status: OrderStatus.cancelled,
          paymentStatus: PaymentStatus.unpaid,
        );

        await tester.pumpWidget(
          buildScreen(
            OrderDetailScreen(order: order),
          ),
        );

        await tester.pump();

        expect(
          find.text('ORD-1001'),
          findsOneWidget,
        );

        expect(
          find.textContaining('Cancelled'),
          findsWidgets,
        );
      },
    );
  });
}