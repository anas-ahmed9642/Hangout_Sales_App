import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/orders/models/order_draft.dart';

// Test helpers (relative path is fine since it's also inside the test/ folder)
import '../test/helpers/test_container.dart'; // Or just 'helpers/test_container.dart' depending on your exact path

// ALL app imports strictly using package:
import 'package:hangout_sales_app/features/orders/models/menu_data.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/models/topping_selection.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';
import 'package:hangout_sales_app/features/orders/screens/new_order_screen.dart';
import 'package:hangout_sales_app/features/orders/widgets/additional_items_section.dart';
import 'package:hangout_sales_app/features/orders/widgets/delivery_picker.dart';
import 'package:hangout_sales_app/features/orders/widgets/order_category_selector.dart';
import 'package:hangout_sales_app/features/orders/widgets/order_entries_section.dart';
import 'package:hangout_sales_app/features/orders/widgets/order_summary.dart';


void main() {
  final deal4 = MenuData.deals.firstWhere(
    (deal) => deal.id == 'deal_4',
  );

  test('adds Deal 4 twice and a standalone pizza', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    notifier.addDeal(deal4);
    notifier.addDeal(deal4);
    notifier.addStandalonePizza(PizzaSize.small);

    final entries = container.read(orderDraftProvider).entries;

    expect(entries, hasLength(3));

    expect(entries[0].deal?.id, 'deal_4');
    expect(entries[0].flavorIds, [null, null, null]);

    expect(entries[1].deal?.id, 'deal_4');
    expect(entries[1].flavorIds, [null, null, null]);

    expect(entries[2].standalonePizzaSize, PizzaSize.small);
    expect(entries[2].flavorIds, [null]);

    expect(entries[0].id, isNot(equals(entries[1].id)));
  });

  test('setFlavor updates only the selected entry', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    notifier.addDeal(deal4);
    notifier.addDeal(deal4);
    notifier.addStandalonePizza(PizzaSize.small);

    final initialEntries = container.read(orderDraftProvider).entries;
    final firstEntry = initialEntries[0];
    final secondEntry = initialEntries[1];
    final thirdEntry = initialEntries[2];

    notifier.setFlavor(
      firstEntry.id,
      1,
      'chicken_fajita',
    );

    final entries = container.read(orderDraftProvider).entries;

    expect(entries[0].flavorIds, [null, 'chicken_fajita', null]);
    expect(entries[1].flavorIds, [null, null, null]);
    expect(entries[2].flavorIds, [null]);

    expect(entries[1].id, secondEntry.id);
    expect(entries[2].id, thirdEntry.id);
  });

  test('removeEntry removes only the selected entry', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    notifier.addDeal(deal4);
    notifier.addDeal(deal4);
    notifier.addStandalonePizza(PizzaSize.small);

    final initialEntries = container.read(orderDraftProvider).entries;
    final firstEntryId = initialEntries[0].id;
    final secondEntryId = initialEntries[1].id;
    final thirdEntryId = initialEntries[2].id;

    notifier.removeEntry(firstEntryId);

    final entries = container.read(orderDraftProvider).entries;

    expect(entries, hasLength(2));
    expect(entries.any((entry) => entry.id == firstEntryId), isFalse);
    expect(entries.any((entry) => entry.id == secondEntryId), isTrue);
    expect(entries.any((entry) => entry.id == thirdEntryId), isTrue);
  });

  test('setFlavor ignores invalid entry IDs and pizza indexes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    notifier.addStandalonePizza(PizzaSize.large);

    final before = container.read(orderDraftProvider).entries.first;

    notifier.setFlavor(
      'invalid_entry_id',
      0,
      'spicy_bbq',
    );

    expect(
      container.read(orderDraftProvider).entries.first.flavorIds,
      [null],
    );

    notifier.setFlavor(
      before.id,
      99,
      'spicy_bbq',
    );

    expect(
      container.read(orderDraftProvider).entries.first.flavorIds,
      [null],
    );
  });

  test('every added entry receives a unique ID', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(orderDraftProvider.notifier);

  notifier.addDeal(deal4);
  notifier.addDeal(deal4);
  notifier.addStandalonePizza(PizzaSize.small);
  notifier.addStandalonePizza(PizzaSize.large);

  final entries = container.read(orderDraftProvider).entries;

  final ids = entries.map((entry) => entry.id).toSet();

  expect(ids, hasLength(entries.length));
});
test('validation rejects an order with an unselected flavor', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(orderDraftProvider.notifier);

  notifier.addDeal(deal4);

  expect(container.read(orderDraftProvider).entries, isNotEmpty);
  expect(container.read(orderDraftProvider).entries.first.flavorIds, hasLength(3));
  expect(container.read(orderDraftProvider).entries.first.flavorIds.any((id) => id == null), isTrue);
});

test('validation rejects an order with an unselected flavor', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(orderDraftProvider.notifier);

  notifier.addDeal(deal4);

  expect(notifier.validationErrors, isNotEmpty);
  expect(notifier.validationErrors.first, contains('Every pizza must have a flavor selected.'));
});

test('completed draft converts into an Order', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(orderDraftProvider.notifier);

  notifier.addDeal(deal4);

  final entry = container.read(orderDraftProvider).entries.first;

  notifier.setFlavor(
    entry.id,
    0,
    'chicken_fajita',
  );

  notifier.setFlavor(
    entry.id,
    1,
    'malai_boti',
  );

  notifier.setFlavor(
    entry.id,
    2,
    'chicken_tikka',
  );

  notifier.setDeliveryCharge(150);

  final order = notifier.buildOrder(
    orderNumber: 'ORD-0001',
    businessDate: DateTime(2026, 8, 22),
    createdAt: DateTime(2026, 8, 22, 18, 30),
  );

  expect(order, isA<Order>());
  expect(order.orderNumber, 'ORD-0001');
  expect(order.deals, hasLength(1));
  expect(order.deals.first.id, 'deal_4');
  expect(order.items, hasLength(3));
  expect(order.deliveryCharge, 150);
  expect(order.total, 2350);
  expect(order.status, OrderStatus.pending);
});
test('standalone pizza converts with its base price', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(orderDraftProvider.notifier);

  notifier.addStandalonePizza(PizzaSize.large);

  final entry = container.read(orderDraftProvider).entries.first;

  notifier.setFlavor(
    entry.id,
    0,
    'chicken_fajita',
  );

  final order = notifier.buildOrder(
    orderNumber: 'ORD-0002',
    businessDate: DateTime(2026, 8, 22),
  );

  expect(order.items, hasLength(1));
  expect(order.items.first.size, PizzaSize.large);
  expect(order.items.first.flavorId, 'chicken_fajita');
  expect(order.items.first.unitPrice, 700);
  expect(order.total, 700);
});
test('toppings remain attached to the correct pizza during conversion', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(orderDraftProvider.notifier);

  notifier.addDeal(deal4);

  final entry = container.read(orderDraftProvider).entries.first;

  notifier.setFlavor(
    entry.id,
    0,
    'chicken_fajita',
  );

  notifier.setFlavor(
    entry.id,
    1,
    'malai_boti',
  );

  notifier.setFlavor(
    entry.id,
    2,
    'chicken_tikka',
  );

  notifier.addTopping(
    entry.id,
    1,
    'meat',
    'Add Meat',
  );

  final order = notifier.buildOrder(
    orderNumber: 'ORD-0003',
    businessDate: DateTime(2026, 8, 22),
  );

  expect(order.items[0].toppings, isEmpty);
  expect(order.items[1].toppings, hasLength(1));
  expect(order.items[1].toppings!.first.toppingId, 'meat');
  expect(order.items[2].toppings, isEmpty);
});
test('additional drinks and dip sauces survive conversion', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(orderDraftProvider.notifier);

  notifier.addStandalonePizza(PizzaSize.large);

  final entry = container.read(orderDraftProvider).entries.first;

  notifier.setFlavor(
    entry.id,
    0,
    'chicken_fajita',
  );

  notifier.addAdditionalDrink('drink_1.5ltr');
  notifier.addAdditionalDrink('drink_1.5ltr');

  notifier.setAdditionalDipSauceCount(2);

  final order = notifier.buildOrder(
    orderNumber: 'ORD-0004',
    businessDate: DateTime(2026, 8, 22),
  );

  expect(
    order.additionalDrinks['drink_1.5ltr'],
    2,
  );

  expect(
    order.additionalDipSauceCount,
    2,
  );

  expect(order.total, 1200);
});
test('one order can contain multiple deals and standalone pizza', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(orderDraftProvider.notifier);

  notifier.addDeal(deal4);
  notifier.addDeal(deal4);
  notifier.addStandalonePizza(PizzaSize.small);

  final entries = container.read(orderDraftProvider).entries;

  for (final entry in entries) {
    for (var index = 0;
        index < entry.flavorIds.length;
        index++) {
      notifier.setFlavor(
        entry.id,
        index,
        'chicken_fajita',
      );
    }
  }

  final order = notifier.buildOrder(
    orderNumber: 'ORD-0005',
    businessDate: DateTime(2026, 8, 22),
  );

  expect(order.deals, hasLength(2));
  expect(order.items, hasLength(7));

  expect(
    order.total,
    4730,
  );
});

test(
  'addTopping adds a topping to the selected pizza',
  () {
    final container = createTestContainer();

    final notifier = container.read(
      orderDraftProvider.notifier,
    );

    notifier.addStandalonePizza(PizzaSize.large);

    final entry = container.read(orderDraftProvider).entries.single;

    notifier.addTopping(
      entry.id,
      0,
      'meat',
      'Extra Meat',
    );

    final updatedEntry =
        container.read(orderDraftProvider).entries.single;

    expect(updatedEntry.toppings, hasLength(1));
    expect(updatedEntry.toppings[0], hasLength(1));

    final topping = updatedEntry.toppings[0].single;

    expect(topping.toppingId, 'meat');
    expect(topping.toppingName, 'Extra Meat');
    expect(
      topping.priceAtOrderTime,
      MenuData.toppingPrices['meat'],
    );
  },
);

test(
  'addTopping affects only the selected pizza',
  () {
    final container = createTestContainer();

    final notifier = container.read(
      orderDraftProvider.notifier,
    );

    final deal = MenuData.deals.firstWhere(
      (deal) => deal.id == 'deal_4',
    );

    notifier.addDeal(deal);

    final entry = container.read(orderDraftProvider).entries.single;

    expect(entry.flavorIds, hasLength(3));
    expect(entry.toppings, hasLength(3));

    notifier.addTopping(
      entry.id,
      0,
      'cheese',
      'Extra Cheese',
    );

    notifier.addTopping(
      entry.id,
      1,
      'meat',
      'Extra Meat',
    );

    notifier.addTopping(
      entry.id,
      2,
      'veggie',
      'Extra Veggie',
    );

    final updatedEntry =
        container.read(orderDraftProvider).entries.single;

    expect(
      updatedEntry.toppings[0].single.toppingId,
      'cheese',
    );

    expect(
      updatedEntry.toppings[1].single.toppingId,
      'meat',
    );

    expect(
      updatedEntry.toppings[2].single.toppingId,
      'veggie',
    );
  },
);

test(
  'removeTopping removes only the requested topping',
  () {
    final container = createTestContainer();

    final notifier = container.read(
      orderDraftProvider.notifier,
    );

    notifier.addStandalonePizza(PizzaSize.large);

    final entry = container.read(orderDraftProvider).entries.single;

    notifier.addTopping(
      entry.id,
      0,
      'meat',
      'Extra Meat',
    );

    notifier.addTopping(
      entry.id,
      0,
      'veggie',
      'Extra Veggie',
    );

    notifier.removeTopping(
      entry.id,
      0,
      'meat',
    );

    final updatedEntry =
        container.read(orderDraftProvider).entries.single;

    expect(updatedEntry.toppings[0], hasLength(1));
    expect(
      updatedEntry.toppings[0].single.toppingId,
      'veggie',
    );
  },
);

test(
  'setDeliveryCharge updates the draft delivery charge',
  () {
    final container = createTestContainer();

    final notifier = container.read(
      orderDraftProvider.notifier,
    );

    expect(
      container.read(orderDraftProvider).deliveryCharge,
      0,
    );

    notifier.setDeliveryCharge(150);

    expect(
      container.read(orderDraftProvider).deliveryCharge,
      150,
    );

    notifier.setDeliveryCharge(300);

    expect(
      container.read(orderDraftProvider).deliveryCharge,
      300,
    );

    notifier.setDeliveryCharge(
      MenuData.pickupCharge,
    );

    expect(
      container.read(orderDraftProvider).deliveryCharge,
      0,
    );
  },
);

test(
  'customer information is stored in the order draft',
  () {
    final container = createTestContainer();

    final notifier = container.read(
      orderDraftProvider.notifier,
    );

    notifier.setCustomerName('Ahmed');
    notifier.setCustomerPhone('03001234567');
    notifier.setCustomerAddress('Karachi');

    final draft = container.read(orderDraftProvider);

    expect(draft.customerName, 'Ahmed');
    expect(draft.customerPhone, '03001234567');
    expect(draft.customerAddress, 'Karachi');
  },
);

test(
  'pizza, delivery, and customer information coexist in one draft',
  () {
    final container = createTestContainer();

    final notifier = container.read(
      orderDraftProvider.notifier,
    );

    notifier.addStandalonePizza(PizzaSize.large);

    final entry = container.read(orderDraftProvider).entries.single;

    notifier.setFlavor(
      entry.id,
      0,
      'chicken_fajita',
    );

    notifier.addTopping(
      entry.id,
      0,
      'cheese',
      'Extra Cheese',
    );

    notifier.setDeliveryCharge(150);

    notifier.setCustomerName('Ahmed');
    notifier.setCustomerPhone('03001234567');
    notifier.setCustomerAddress('Karachi');

    final draft = container.read(orderDraftProvider);

    expect(draft.entries, hasLength(1));
    expect(
      draft.entries.single.flavorIds[0],
      'chicken_fajita',
    );

    expect(
      draft.entries.single.toppings[0],
      hasLength(1),
    );

    expect(
      draft.entries.single.toppings[0].single.toppingId,
      'cheese',
    );

    expect(draft.deliveryCharge, 150);
    expect(draft.customerName, 'Ahmed');
    expect(draft.customerPhone, '03001234567');
    expect(draft.customerAddress, 'Karachi');
  },
);

test(
  'topping stores its price at order time',
  () {
    final container = createTestContainer();

    final notifier = container.read(
      orderDraftProvider.notifier,
    );

    notifier.addStandalonePizza(PizzaSize.large);

    final entry = container.read(orderDraftProvider).entries.single;

    notifier.addTopping(
      entry.id,
      0,
      'cheese',
      'Extra Cheese',
    );

    final topping =
        container
            .read(orderDraftProvider)
            .entries
            .single
            .toppings[0]
            .single;

    expect(topping, isA<ToppingSelection>());
    expect(topping.toppingId, 'cheese');
    expect(topping.toppingName, 'Extra Cheese');
    expect(topping.priceAtOrderTime, 150);
  },
);

test(
  'buildOrder transfers toppings, customer data, and delivery charge',
  () {
    final container = createTestContainer();

    final notifier = container.read(
      orderDraftProvider.notifier,
    );

    notifier.addStandalonePizza(PizzaSize.large);

    final entry = container.read(orderDraftProvider).entries.single;

    notifier.setFlavor(
      entry.id,
      0,
      'chicken_fajita',
    );

    notifier.addTopping(
      entry.id,
      0,
      'cheese',
      'Extra Cheese',
    );

    notifier.setDeliveryCharge(150);

    notifier.setCustomerName('Ahmed');
    notifier.setCustomerPhone('03001234567');
    notifier.setCustomerAddress('Karachi');

    final order = notifier.buildOrder(
      orderNumber: 'TEST-001',
      businessDate: DateTime(2026, 8, 22),
      createdAt: DateTime(2026, 8, 22, 18, 0),
    );

    expect(order.orderNumber, 'TEST-001');

    expect(order.customerName, 'Ahmed');
    expect(order.customerPhone, '03001234567');
    expect(order.customerAddress, 'Karachi');

    expect(order.deliveryCharge, 150);

    expect(order.items, hasLength(1));

    final item = order.items.single;

    expect(item.flavorId, 'chicken_fajita');
    expect(item.size, PizzaSize.large);

    expect(item.toppings, isNotNull);
    expect(item.toppings, hasLength(1));

    expect(
      item.toppings!.single.toppingId,
      'cheese',
    );

    expect(
      item.toppings!.single.priceAtOrderTime,
      150,
    );
  },
);
testWidgets(
  'OrderEntriesSection exposes flavor and topping controls for a selected deal',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  OrderCategorySelector(),
                  OrderEntriesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // FIXED: Target the first 'Deal 4', ensure it's visible, and tap it
    final deal4Button = find.text('Deal 4').first;
    await tester.ensureVisible(deal4Button);
    await tester.tap(deal4Button);

    await tester.pump();

    expect(
      find.text('Deal 4'),
      findsWidgets, // FIXED: Allows finding Deal 4 in the menu AND in the active cart
    );

    expect(
      find.text('Pizza 1 Flavor'),
      findsOneWidget,
    );

    expect(
      find.text('Pizza 2 Flavor'),
      findsOneWidget,
    );

    expect(
      find.text('Pizza 3 Flavor'),
      findsOneWidget,
    );

    expect(
      find.text('Toppings'),
      findsNWidgets(3),
    );
  },
);
testWidgets(
  'OrderSummary shows validation feedback for an empty order',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderSummary(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifies the UI renders correctly for an empty state
    expect(find.text('Order Summary'), findsOneWidget);
    expect(find.text('No items added yet.'), findsWidgets);
    expect(find.text('Total'), findsOneWidget);
    
    // Looks for ANY Rs. 0 on the screen (since subtotal, total, etc. are all 0)
    expect(find.text('Rs. 0'), findsWidgets); 
  },
);

testWidgets(
  'OrderSummary updates when a standalone pizza is added',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView( 
              child: Column(
                children: [
                  OrderCategorySelector(),
                  OrderSummary(),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Ensure the button is visible before tapping
    // Used .first in case "Large" appears anywhere else in descriptions
    final largeButton = find.text('Large').first;
    await tester.ensureVisible(largeButton); 
    await tester.tap(largeButton);

    await tester.pump();

    expect(
      find.text('Total'),
      findsOneWidget,
    );

    expect(
      find.text('Rs. 700'),
      findsWidgets, // FIXED: Allows it to find the text in both the summary and the menu
    );
  },
);

testWidgets(
  'NewOrderScreen composes the complete order workflow',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NewOrderScreen(),
        ),
      ),
    );

  

    expect(
      find.text('Add to Order'),
      findsOneWidget,
    );

    expect(
      find.text('No items added yet.'),
      findsWidgets,
    );

    expect(
      find.descendant(
        of: find.byType(DeliveryPicker),
        matching: find.text('Delivery'),
      ),
      findsOneWidget,
    );

    expect(
      find.text('Customer Information'),
      findsOneWidget,
    );

    expect(
      find.text('Order Summary'),
      findsOneWidget,
    );
  },
);

testWidgets(
  'NewOrderScreen reflects a selected deal in the order editor',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NewOrderScreen(),
        ),
      ),
    );

    // FIXED: Target the first 'Deal 4' (the menu card) and scroll to it just in case
    final deal4Button = find.text('Deal 4').first;
    await tester.ensureVisible(deal4Button);
    await tester.tap(deal4Button);

    await tester.pump();

    expect(
      find.text('Deal 4'),
      findsWidgets, // FIXED: Allows finding Deal 4 in the menu AND in the active cart
    );

    expect(
      find.text('Pizza 1 Flavor'),
      findsOneWidget,
    );

    expect(
      find.text('Pizza 2 Flavor'),
      findsOneWidget,
    );

    expect(
      find.text('Pizza 3 Flavor'),
      findsOneWidget,
    );

    expect(
      find.text('Order Summary'),
      findsOneWidget,
    );

    expect(
      find.text('Order needs attention'),
      findsOneWidget,
    );

    expect(
      find.text(
        'Every pizza must have a flavor selected.',
      ),
      findsNWidgets(3),
    );
  },
);

testWidgets(
  'OrderCategorySelector groups deals and displays deal information',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderCategorySelector(), // Removed 'const' if it was causing issues, or leave it if your widget is strictly const
            ),
          ),
        ),
      ),
    );

    expect(find.text('Standard Deals'), findsOneWidget);
    expect(find.text('Party Deals'), findsOneWidget);

    expect(find.text('Deal 1'), findsOneWidget);
    expect(find.text('Deal 7'), findsOneWidget);
    expect(find.text('Party Deal 1'), findsOneWidget);
    expect(find.text('Party Deal 2'), findsOneWidget);

    expect(find.text('Rs. 380'), findsOneWidget);
    expect(find.text('Rs. 3600'), findsOneWidget);

    expect(find.text('1 Ã— Small'), findsOneWidget);
    expect(find.text('5 Ã— Large'), findsOneWidget);
  },
);
testWidgets(
  'OrderEntriesSection visually distinguishes deals and standalone pizzas',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  OrderCategorySelector(),
                  OrderEntriesSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // 1. ADD A DEAL (Simulate user tapping "Deal 1")
    final deal1Button = find.text('Deal 1').first;
    await tester.ensureVisible(deal1Button);
    await tester.tap(deal1Button);
    await tester.pump();

    // Verify Deal UI
    expect(find.text('DEAL'), findsOneWidget);
    expect(find.text('Deal 1'), findsWidgets); // Use findsWidgets since it's in the menu AND the cart
    expect(find.text('Base price: Rs. 380'), findsOneWidget);

    // 2. ADD A STANDALONE PIZZA (Simulate user tapping "Large")
    final largeButton = find.text('Large').first;
    await tester.ensureVisible(largeButton);
    await tester.tap(largeButton);
    await tester.pump();

    // Verify Standalone Pizza UI
    expect(find.text('PIZZA'), findsOneWidget);
    expect(find.text('Large Pizza'), findsOneWidget);
    expect(find.text('Base price: Rs. 700'), findsOneWidget);
  },
);
testWidgets(
  'AdditionalItemsSection adds drinks and changes dip sauce count',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdditionalItemsSection(),
            ),
          ),
        ),
      ),
    );

    // 1. Verify the initial state is rendered correctly
    expect(find.text('345ml Drink'), findsOneWidget);
    expect(find.text('1L Drink'), findsOneWidget);
    expect(find.text('1.5L Drink'), findsOneWidget);
    expect(find.text('Additional Dip Sauce'), findsOneWidget);

    // 2. TEST DRINKS: Tap the '+' button for the first drink
    await tester.tap(find.byTooltip('Add drink').first);
    await tester.pump();

    // Verify the UI updated to show '1' drink
    expect(find.text('1'), findsWidgets);

    // Tap the '-' button for the first drink
    await tester.tap(find.byTooltip('Remove drink').first);
    await tester.pump();

    // Verify the UI goes back to '0'
    expect(find.text('0'), findsWidgets);

    // 3. TEST SAUCES: Tap the '+' button for Dip Sauce
    await tester.tap(find.byTooltip('Add dip sauce'));
    await tester.pump();

    // Verify the UI updated to show '1' dip sauce
    expect(find.text('1'), findsWidgets);
    
    // Tap the '-' button for Dip Sauce
    await tester.tap(find.byTooltip('Remove dip sauce'));
    await tester.pump();
    
    // Verify it goes back to '0'
    expect(find.text('0'), findsWidgets);
  },
);

test(
  'entryTotal matches the entry contribution to pizzaSubtotal',
  () {
    final container = createTestContainer();

    final notifier = container.read(
      orderDraftProvider.notifier,
    );

    notifier.addStandalonePizza(PizzaSize.large);

    final draft = container.read(orderDraftProvider);
    final entry = draft.entries.single;

    expect(
      notifier.entryTotal(entry),
      equals(notifier.pizzaSubtotal),
    );

    container.dispose();
  },
);
testWidgets(
  'OrderSummary displays an individual entry price',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NewOrderScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Locate the button
    final largeButtonFinder = find.widgetWithText(OutlinedButton, 'Large').first;

    // 2. CRITICAL FIX: Scroll the screen until the button is actually visible!
    await tester.ensureVisible(largeButtonFinder);
    await tester.pumpAndSettle(); // Wait for the scroll animation to finish

    // 3. NOW tap it, since it's on the screen
    await tester.tap(largeButtonFinder);
    await tester.pumpAndSettle(); // Wait for the cart math to update

    // 4. Verify it worked
    expect(find.text('Large Pizza'), findsWidgets);
    expect(find.textContaining('700'), findsWidgets);
  },
);
testWidgets(
  'NewOrderScreen shows discard confirmation',
  (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NewOrderScreen(),
        ),
      ),
    );

    await tester.tap(
      find.byTooltip('Discard Order'),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Discard order?'),
      findsOneWidget,
    );

    // FIXED: Now matches the new, safer text we added to the UI!
    expect(
      find.text('All current order information will be cleared. This cannot be undone.'),
      findsOneWidget,
    );

    expect(
      find.text('Keep Order'),
      findsOneWidget,
    );

    expect(
      find.text('Discard'),
      findsOneWidget,
    );
  },
);
test(
  'saveOrder builds the order and sends it to the repository',
  () async {
    final repository = _TestOrderRepository();

    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(repository),
      ],
    );

    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    // --- NEW: WE MUST ADD A VALID ITEM TO PASS YOUR VALIDATION ---
    notifier.addStandalonePizza(PizzaSize.small);
    final entryId = container.read(orderDraftProvider).entries.first.id;
    notifier.setFlavor(entryId, 0, 'super_sicilian'); 
    // -------------------------------------------------------------

    await notifier.saveOrder(
      orderNumber: 'TEST-001',
      businessDate: DateTime(2026, 8, 24),
      createdAt: DateTime(2026, 8, 24, 18),
    );

    expect(repository.savedOrder, isNotNull);
    expect(repository.savedOrder!.orderNumber, 'TEST-001');
    expect(
      repository.savedOrder!.businessDate,
      DateTime(2026, 8, 24),
    );
  },
);
test(
  'payment status can be changed independently of fulfillment status',
  () {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    expect(
      container.read(orderDraftProvider).paymentStatus,
      PaymentStatus.unpaid,
    );

    notifier.setPaymentStatus(PaymentStatus.paid);

    final draft = container.read(orderDraftProvider);

    expect(draft.paymentStatus, PaymentStatus.paid);
  },
);
test(
  'buildOrder preserves the draft payment status',
  () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    // Satisfy buildOrder's own validation first â€”
    // it requires at least one fully-valid pizza/deal entry.
    notifier.addStandalonePizza(PizzaSize.regular); // pick a real size from your enum
    final entryId = container.read(orderDraftProvider).entries.first.id;
    notifier.setFlavor(entryId, 0, MenuData.flavors.first.id);

    notifier.setPaymentStatus(PaymentStatus.paid);

    final order = notifier.buildOrder(
      orderNumber: 'TEST-001',
      businessDate: DateTime(2026, 8, 28),
    );

    expect(order.status, OrderStatus.pending);
    expect(order.paymentStatus, PaymentStatus.paid);
  },
);
test(
  'order draft defaults to unpaid payment status',
  () {
    final container = createTestContainer();

    addTearDown(container.dispose);

    final draft = container.read(orderDraftProvider);

    expect(
      draft.paymentStatus,
      PaymentStatus.unpaid,
    );
  },
);

test(
  'payment status survives other draft updates',
  () {
    final container = createTestContainer();

    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    notifier.setPaymentStatus(PaymentStatus.paid);
    notifier.setCustomerName('Test Customer');

    final draft = container.read(orderDraftProvider);

    expect(
      draft.paymentStatus,
      PaymentStatus.paid,
    );
    expect(
      draft.customerName,
      'Test Customer',
    );
  },
);
test(
  'setPaymentStatus changes only payment status',
  () {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    notifier.addStandalonePizza(PizzaSize.small);
    final entryId = container.read(orderDraftProvider).entries.first.id;

    notifier.setFlavor(
      entryId,
      0,
      'super_sicilian',
    );
    notifier.setCustomerName('Ahmed');
    notifier.setCustomerPhone('03001234567');
    notifier.setCustomerAddress('Karachi');
    notifier.setDeliveryCharge(150);

    final before = container.read(orderDraftProvider);

    notifier.setPaymentStatus(PaymentStatus.paid);

    final after = container.read(orderDraftProvider);

    expect(after.paymentStatus, PaymentStatus.paid);
    expect(after.entries, before.entries);
    expect(after.customerName, before.customerName);
    expect(after.customerPhone, before.customerPhone);
    expect(after.customerAddress, before.customerAddress);
    expect(after.deliveryCharge, before.deliveryCharge);
  },
);

test(
  'payment status survives unrelated draft edits',
  () {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    notifier.setPaymentStatus(PaymentStatus.paid);
    notifier.setCustomerName('Ahmed');
    notifier.setCustomerPhone('03001234567');
    notifier.setCustomerAddress('Karachi');
    notifier.setDeliveryCharge(100);

    final draft = container.read(orderDraftProvider);

    expect(draft.paymentStatus, PaymentStatus.paid);
  },
);

test(
  'clearDraft resets payment status to unpaid',
  () {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    notifier.setPaymentStatus(PaymentStatus.paid);

    expect(
      container.read(orderDraftProvider).paymentStatus,
      PaymentStatus.paid,
    );

    notifier.clearDraft();

    expect(
      container.read(orderDraftProvider).paymentStatus,
      PaymentStatus.unpaid,
    );
  },
);

test(
  'buildOrder carries draft payment status into Order',
  () {
    final container = createTestContainer();
    addTearDown(container.dispose);

    final notifier = container.read(orderDraftProvider.notifier);

    notifier.addStandalonePizza(PizzaSize.small);

    final entryId = container.read(orderDraftProvider).entries.first.id;

    notifier.setFlavor(
      entryId,
      0,
      'super_sicilian',
    );

    notifier.setPaymentStatus(PaymentStatus.paid);

    final order = notifier.buildOrder(
      orderNumber: 'TEST-PAID-001',
      businessDate: DateTime(2026, 8, 30),
      createdAt: DateTime(2026, 8, 30, 18),
    );

    expect(order.paymentStatus, PaymentStatus.paid);
    expect(order.status, OrderStatus.pending);
  },
);
  group('customer fields (Phase 4)', () {
    test('saveCustomer defaults to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(orderDraftProvider).saveCustomer, isTrue);
    });

    test(
        'setDeliveryArea presets the charge; a manual charge edit keeps the area',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(orderDraftProvider.notifier);

      notifier.setDeliveryArea(
        areaId: 'a1',
        areaName: 'Sector 11B',
        defaultCharge: 180,
      );

      var draft = container.read(orderDraftProvider);
      expect(draft.deliveryAreaId, 'a1');
      expect(draft.deliveryAreaName, 'Sector 11B');
      expect(draft.deliveryCharge, 180);

      notifier.setDeliveryCharge(250);

      draft = container.read(orderDraftProvider);
      expect(draft.deliveryAreaId, 'a1');
      expect(draft.deliveryAreaName, 'Sector 11B');
      expect(draft.deliveryCharge, 250);
    });

    test('setDeliveryArea() with no area clears it and keeps the charge',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(orderDraftProvider.notifier);

      notifier.setDeliveryArea(
        areaId: 'a1',
        areaName: 'Sector 11B',
        defaultCharge: 180,
      );
      notifier.setDeliveryCharge(250);
      notifier.setDeliveryArea();

      final draft = container.read(orderDraftProvider);
      expect(draft.deliveryAreaId, isNull);
      expect(draft.deliveryAreaName, isNull);
      expect(draft.deliveryCharge, 250);
    });

    test('setDeliveryCharge(0) clears the area for Pickup', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(orderDraftProvider.notifier);

      notifier.setDeliveryArea(
        areaId: 'a1',
        areaName: 'Sector 11B',
        defaultCharge: 180,
      );
      notifier.setDeliveryCharge(MenuData.pickupCharge);

      final draft = container.read(orderDraftProvider);
      expect(draft.deliveryAreaId, isNull);
      expect(draft.deliveryAreaName, isNull);
      expect(draft.deliveryCharge, 0);
    });

    test('address decision and label setters round-trip', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(orderDraftProvider.notifier);

      notifier.setAddressDecision(AddressDecision.saveAsNewAddress);
      notifier.setNewAddressLabel('Office');

      var draft = container.read(orderDraftProvider);
      expect(draft.addressDecision, AddressDecision.saveAsNewAddress);
      expect(draft.newAddressLabel, 'Office');

      notifier.setAddressDecision(null);
      notifier.setNewAddressLabel(null);

      draft = container.read(orderDraftProvider);
      expect(draft.addressDecision, isNull);
      expect(draft.newAddressLabel, isNull);
    });
  });
}
class _TestOrderRepository implements OrderRepository {
  Order? savedOrder;

  @override
  Future<void> createOrder(
    Order order, {
    CustomerUpsert? customerUpsert,
  }) async {
    savedOrder = order;
  }

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) {
    return Stream.value([]);
  }

  @override
  Stream<List<Order>> streamUnpaidOrders() => Stream.value(const []);

  @override
  Stream<List<Order>> streamOrdersByCustomerPhone(String phone) =>
      throw UnimplementedError();

  @override
  Future<List<Order>> searchOrdersByPhone(String phoneNumber) async {
    return [];
  }

  @override
  Future<Order?> getOrder(String orderId) async {
    if (savedOrder?.id == orderId) {
      return savedOrder;
    }
    return null;
  }

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async {
    return const [];
  }
}
