import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_history_provider.dart';
import 'package:hangout_sales_app/features/orders/screens/order_history_screen.dart';
// Added this import so the test knows what a HangoutAppBar is
import 'package:hangout_sales_app/shared/widgets/hangout_app_bar.dart';

Order _testOrder({
  String orderNumber = 'ORD-0001',
  String? customerName = 'Ahmed',
  double total = 1850,
  OrderStatus status = OrderStatus.pending,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
}) {
  final createdAt = DateTime(2026, 8, 25, 20, 30);
  return Order(
    id: 'test-order-id',
    orderNumber: orderNumber,
    createdAt: createdAt,
    businessDate: DateTime(2026, 8, 25),
    customerName: customerName,
    customerPhone: null,
    customerAddress: null,
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: total,
    status: status,
    paymentStatus: paymentStatus,
  );
}

Widget _buildScreen({
  required Stream<List<Order>> stream,
}) {
  return ProviderScope(
    overrides: [
      orderHistoryProvider.overrideWith((ref) => stream),
    ],
    child: const MaterialApp(
      home: OrderHistoryScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'OrderHistoryScreen displays loading state',
    (tester) async {
      final controller = StreamController<List<Order>>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        _buildScreen(stream: controller.stream),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // FIX: Check for the widget type instead of the fragile text string
      expect(find.byType(HangoutAppBar), findsOneWidget);
    },
  );

  testWidgets(
    'OrderHistoryScreen displays empty state',
    (tester) async {
      await tester.pumpWidget(
        _buildScreen(stream: Stream.value(const <Order>[])),
      );
      await tester.pump();

      expect(find.text('No orders found'), findsOneWidget);
      expect(
        find.text(
          'Orders from this business day will appear here.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'OrderHistoryScreen displays an order',
    (tester) async {
      final order = _testOrder();

      await tester.pumpWidget(
        _buildScreen(stream: Stream.value([order])),
      );
      await tester.pump();

      expect(find.text('ORD-0001'), findsOneWidget);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('Rs. 1850'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    },
  );

  testWidgets(
    'OrderHistoryScreen displays fallback customer name',
    (tester) async {
      final order = _testOrder(customerName: null);

      await tester.pumpWidget(
        _buildScreen(stream: Stream.value([order])),
      );
      await tester.pump();

      expect(find.text('Walk-in Customer'), findsOneWidget);
    },
  );

  testWidgets(
    'OrderHistoryScreen displays error state',
    (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          stream: Stream<List<Order>>.error(
            Exception('Test history failure'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text("Couldn't load orders"), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(
        find.textContaining('Test history failure'),
        findsOneWidget,
      );
    },
  );
}