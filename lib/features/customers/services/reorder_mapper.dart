import 'package:uuid/uuid.dart';

import '../../orders/models/deal.dart';
import '../../orders/models/menu_data.dart';
import '../../orders/models/order.dart';
import '../../orders/models/order_draft_entry.dart';
import '../../orders/models/topping_selection.dart';

/// Result of mapping a saved [Order] back onto a fresh draft's item
/// fields (plan 8.10, F7).
///
/// Only item fields are rebuilt: entries, additionalDrinks,
/// additionalDipSauceCount. Customer fields and the delivery charge are
/// never touched — `applyReorder` replaces exactly these three fields.
class ReorderResult {
  final List<OrderDraftEntry> entries;
  final Map<String, int> additionalDrinks;
  final int additionalDipSauceCount;

  /// How many items from the old order no longer exist on the current
  /// menu and were skipped.
  final int skippedCount;

  const ReorderResult({
    this.entries = const [],
    this.additionalDrinks = const {},
    this.additionalDipSauceCount = 0,
    this.skippedCount = 0,
  });
}

const _uuid = Uuid();

/// Rebuilds draft item fields from [order] against the CURRENT menu.
///
/// Pricing always comes from the current [MenuData] (current prices and
/// flavors) — the old order's stored amounts are ignored. Items that no
/// longer exist on the menu are skipped and counted in
/// [ReorderResult.skippedCount].
///
/// Deal pizzas are matched positionally: [Order.deals] are walked in
/// order, each consuming [Deal.pizzaSizes.length] items from [Order.items] —
/// the exact inverse of `buildOrder` in
/// order_draft_provider.dart, which appends each deal's pizzas right
/// after the deal. Remaining items are standalone pizzas.
ReorderResult mapOrderToDraft(Order order) {
  final entries = <OrderDraftEntry>[];
  var skipped = 0;
  var itemCursor = 0;

  for (var dealIndex = 0; dealIndex < order.deals.length; dealIndex++) {
    final storedDeal = order.deals[dealIndex];
    final slotCount = storedDeal.pizzaSizes.length;

    if (itemCursor + slotCount > order.items.length) {
      // Fewer stored items than the deals claim (hand-edited data): this
      // deal and every remaining one cannot be mapped safely, and the
      // leftover items have no reliable offsets either.
      skipped += order.deals.length - dealIndex;
      itemCursor = order.items.length;
      break;
    }

    final currentDeal = _findDeal(storedDeal.id);
    if (currentDeal == null || !_sameSizes(currentDeal, storedDeal)) {
      // Deal left the menu or changed shape: skip the whole deal, but its
      // items are still consumed positionally so later slots stay aligned.
      skipped++;
      itemCursor += slotCount;
      continue;
    }

    final flavorIds = <String?>[];
    final toppings = <List<ToppingSelection>>[];
    var dealOk = true;
    for (var slot = 0; slot < slotCount; slot++) {
      final item = order.items[itemCursor + slot];
      if (!_flavorExists(item.flavorId)) {
        // A deal with an unorderable pizza is not a valid draft entry —
        // skip the whole deal rather than present a broken one.
        dealOk = false;
        break;
      }
      flavorIds.add(item.flavorId);
      toppings.add(_repriceToppings(item.toppings));
    }
    itemCursor += slotCount;
    if (!dealOk) {
      skipped++;
      continue;
    }

    entries.add(
      OrderDraftEntry(
        id: _uuid.v4(),
        deal: currentDeal,
        flavorIds: flavorIds,
        toppings: toppings,
      ),
    );
  }

  // Remaining items are standalone pizzas.
  for (; itemCursor < order.items.length; itemCursor++) {
    final item = order.items[itemCursor];
    if (!_flavorExists(item.flavorId)) {
      skipped++;
      continue;
    }
    entries.add(
      OrderDraftEntry(
        id: _uuid.v4(),
        standalonePizzaSize: item.size,
        flavorIds: [item.flavorId],
        toppings: [_repriceToppings(item.toppings)],
      ),
    );
  }

  final drinks = <String, int>{};
  for (final drink in order.additionalDrinks.entries) {
    if (MenuData.drinkPrices.containsKey(drink.key)) {
      drinks[drink.key] = drink.value;
    } else {
      skipped++;
    }
  }

  return ReorderResult(
    entries: entries,
    additionalDrinks: drinks,
    additionalDipSauceCount: order.additionalDipSauceCount,
    skippedCount: skipped,
  );
}

Deal? _findDeal(String id) {
  for (final deal in MenuData.deals) {
    if (deal.id == id) {
      return deal;
    }
  }
  return null;
}

bool _sameSizes(Deal current, Deal stored) {
  if (current.pizzaSizes.length != stored.pizzaSizes.length) {
    return false;
  }
  for (var i = 0; i < current.pizzaSizes.length; i++) {
    if (current.pizzaSizes[i] != stored.pizzaSizes[i]) {
      return false;
    }
  }
  return true;
}

bool _flavorExists(String flavorId) {
  return MenuData.flavors.any((flavor) => flavor.id == flavorId);
}

/// Re-prices stored toppings at current menu prices. Toppings that left
/// the menu are dropped — the pizza still reorders without them.
List<ToppingSelection> _repriceToppings(List<ToppingSelection>? stored) {
  if (stored == null) {
    return const [];
  }
  final repriced = <ToppingSelection>[];
  for (final topping in stored) {
    final currentPrice = MenuData.toppingPrices[topping.toppingId];
    if (currentPrice == null) {
      continue;
    }
    repriced.add(
      ToppingSelection(
        toppingId: topping.toppingId,
        toppingName: topping.toppingName,
        priceAtOrderTime: currentPrice,
      ),
    );
  }
  return repriced;
}