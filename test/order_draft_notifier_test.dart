
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/orders/models/menu_data.dart';
import '../lib/features/orders/models/pizza_size.dart';
import '../lib/features/orders/providers/order_draft_provider.dart';
import '../lib/features/orders/models/order.dart';
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

  expect(notifier.canComplete, isFalse);
  expect(notifier.validationErrors, isNotEmpty);
});

test('validation rejects an order with an unselected flavor', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(orderDraftProvider.notifier);

  notifier.addDeal(deal4);

  expect(notifier.canComplete, isFalse);
  expect(notifier.validationErrors, isNotEmpty);
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

}
