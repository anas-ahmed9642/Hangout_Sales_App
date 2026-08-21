
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/orders/models/menu_data.dart';
import '../lib/features/orders/models/pizza_size.dart';
import '../lib/features/orders/providers/order_draft_provider.dart';

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
}
