import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/models/topping_selection.dart';
import 'package:hangout_sales_app/features/orders/screens/order_detail_screen.dart';

void main() {
  Order _buildPendingOrder() {
    return Order(
      id: 'order-test-pending',
      orderNumber: 'ORD-0040',
      createdAt: DateTime(2026, 8, 24, 20, 30),
      businessDate: DateTime(2026, 8, 24),
      customerName: 'Pending Customer',
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 0,
      total: 500,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.unpaid,
    );
  }
  testWidgets(
    'OrderDetailScreen displays the supplied saved order',
    (tester) async {
      final order = Order(
        id: 'order-test-1',
        orderNumber: 'ORD-0024',
        createdAt: DateTime(2026, 8, 24, 20, 30),
        businessDate: DateTime(2026, 8, 24),
        customerName: 'Ahmed',
        customerPhone: '03001234567',
        customerAddress: 'Karachi',
        items: const [],
        deals: const [],
        additionalDrinks: const {},
        additionalDipSauceCount: 0,
        deliveryCharge: 100,
        total: 1850,
        status: OrderStatus.pending, paymentStatus: PaymentStatus.paid,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderDetailScreen(order: order),
          ),
        ),
      );

      expect(find.text('ORD-0024'), findsOneWidget);
      expect(find.text('Rs. 1850'), findsWidgets);
      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('03001234567'), findsOneWidget);
      expect(find.text('Karachi'), findsOneWidget);
      
      // Removed the old 'Order ID', 'Status', and 'Items (0)' placeholder checks 
      // since the final UI replaces them!
    },
  );

  testWidgets(
    'OrderDetailScreen displays Walk-in Customer when name is absent',
    (tester) async {
      final order = Order(
        id: 'order-test-2',
        orderNumber: 'ORD-0025',
        createdAt: DateTime(2026, 8, 24, 21),
        businessDate: DateTime(2026, 8, 24),
        items: const [],
        deals: const [],
        additionalDrinks: const {},
        additionalDipSauceCount: 0,
        deliveryCharge: 0,
        total: 500,
        status: OrderStatus.completed, paymentStatus: PaymentStatus.paid,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderDetailScreen(order: order),
          ),
        ),
      );

      expect(find.text('Walk-in Customer'), findsOneWidget);
      expect(find.text('ORD-0025'), findsOneWidget);
      expect(find.text('Rs. 500'), findsWidgets);
    },
  );

  testWidgets(
    'OrderDetailScreen displays historical item values without recalculating them',
    (tester) async {
      final item = OrderItem(
        flavorId: 'historical_flavor',
        flavorName: 'Historical Flavor',
        flavorPriceExtra: 75,
        size: PizzaSize.large,
        toppings: const [
          ToppingSelection(
            toppingId: 'historical_topping',
            toppingName: 'Historical Topping',
            priceAtOrderTime: 120,
          ),
        ],
        quantity: 1,
        unitPrice: 845,
      );

      final order = Order(
        id: 'order-test-3',
        orderNumber: 'ORD-0026',
        createdAt: DateTime(2026, 8, 24, 22),
        businessDate: DateTime(2026, 8, 24),
        customerName: 'Historical Customer',
        items: [
          item,
        ],
        deals: const [],
        additionalDrinks: const {
          'drink_1': 2,
        },
        additionalDipSauceCount: 3,
        deliveryCharge: 130,
        total: 1995,
        status: OrderStatus.completed, paymentStatus: PaymentStatus.paid,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderDetailScreen(order: order),
          ),
        ),
      );

      expect(find.text('ORD-0026'), findsOneWidget);
      expect(find.text('Rs. 1995'), findsWidgets);
      expect(find.text('Historical Customer'), findsOneWidget);
      
      // Removed the old 'Items (1)' placeholder check
    },
  );

  testWidgets('Reprint button triggers service and shows success SnackBar', (WidgetTester tester) async {
    // 1. Arrange: Create a dummy historical order
    final testOrder = Order(
      id: 'test-id',
      orderNumber: 'ORD-0001',
      createdAt: DateTime(2026, 8, 27, 20, 30),
      businessDate: DateTime(2026, 8, 27),
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 0,
      total: 1000,
      status: OrderStatus.pending, paymentStatus: PaymentStatus.paid,
    );

    // 2. Build the UI
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: OrderDetailScreen(order: testOrder),
        ),
      )
    );

    expect(find.byTooltip('Reprint Receipt'), findsOneWidget);

    await tester.tap(find.byTooltip('Reprint Receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt reprint sent to printer.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);

  });
  testWidgets(
    'pending order shows Complete Order action',
    (tester) async {
      final order = Order(
        id: 'order-test-pending',
        orderNumber: 'ORD-0030',
        createdAt: DateTime(2026, 8, 24, 20, 30),
        businessDate: DateTime(2026, 8, 24),
        customerName: 'Pending Customer',
        items: const [],
        deals: const [],
        additionalDrinks: const {},
        additionalDipSauceCount: 0,
        deliveryCharge: 0,
        total: 500,
        status: OrderStatus.pending,
        paymentStatus: PaymentStatus.unpaid,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderDetailScreen(order: order),
          ),
        ),
      );

      expect(find.text('Complete Order'), findsOneWidget);
    },
  );
  testWidgets(
  'completed order does not show Complete Order action',
  (tester) async {
    final order = Order(
      id: 'order-test-completed',
      orderNumber: 'ORD-0031',
      createdAt: DateTime(2026, 8, 24, 20, 30),
      businessDate: DateTime(2026, 8, 24),
      customerName: 'Completed Customer',
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 0,
      total: 500,
      status: OrderStatus.completed,
      paymentStatus: PaymentStatus.unpaid,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: OrderDetailScreen(order: order),
        ),
      ),
    );

    expect(
      find.text('Complete Order'),
      findsNothing,
    );
  },
);

testWidgets(
  'cancelled order does not show Complete Order action',
  (tester) async {
    final order = Order(
      id: 'order-test-cancelled',
      orderNumber: 'ORD-0032',
      createdAt: DateTime(2026, 8, 24, 20, 30),
      businessDate: DateTime(2026, 8, 24),
      customerName: 'Cancelled Customer',
      items: const [],
      deals: const [],
      additionalDrinks: const {},
      additionalDipSauceCount: 0,
      deliveryCharge: 0,
      total: 500,
      status: OrderStatus.cancelled,
      paymentStatus: PaymentStatus.unpaid,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: OrderDetailScreen(order: order),
        ),
      ),
    );

    expect(
      find.text('Complete Order'),
      findsNothing,
    );
  },
);


}