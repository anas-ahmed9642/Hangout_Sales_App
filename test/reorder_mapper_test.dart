import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/customers/services/reorder_mapper.dart';
import 'package:hangout_sales_app/features/orders/models/deal.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/models/topping_selection.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';

import 'helpers/test_container.dart';

final _t = DateTime(2026, 10, 7);

OrderItem _pizza({
  required String flavorId,
  required PizzaSize size,
  List<ToppingSelection>? toppings,
}) {
  return OrderItem(
    flavorId: flavorId,
    flavorName: flavorId,
    size: size,
    toppings: toppings,
    quantity: 1,
    // Stale on purpose: the mapper must ignore stored amounts and
    // re-price everything from the current menu.
    unitPrice: 9999,
  );
}

Deal _storedDeal({
  required String id,
  required List<PizzaSize> pizzaSizes,
}) {
  return Deal(
    id: id,
    name: id,
    // Stale on purpose: the rebuilt entry must use the current menu deal.
    price: 1,
    pizzaSizes: pizzaSizes,
    dipSauceCount: 0,
    drinkSize: 'drink_345ml',
  );
}

Order _order({
  List<OrderItem> items = const [],
  List<Deal> deals = const [],
  Map<String, int> drinks = const {},
  int dips = 0,
}) {
  return Order(
    id: 'o1',
    orderNumber: 'ORD-0001',
    createdAt: _t,
    businessDate: _t,
    items: items,
    deals: deals,
    additionalDrinks: drinks,
    additionalDipSauceCount: dips,
    deliveryCharge: 0,
    // Stale on purpose: never used by the mapper.
    total: 99999,
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
  );
}

/// The shared "full" order: deal_3 (1 large pizza) written first, then a
/// standalone large pizza, 2x 1L drinks, 3 dips.
Order _fullOrder() {
  return _order(
    items: [
      _pizza(flavorId: 'spicy_bbq', size: PizzaSize.large),
      _pizza(
        flavorId: 'chicken_fajita',
        size: PizzaSize.large,
        toppings: const [
          ToppingSelection(
            toppingId: 'meat',
            toppingName: 'Meat',
            // Stale on purpose: re-priced to the current 100.
            priceAtOrderTime: 1,
          ),
        ],
      ),
    ],
    deals: [_storedDeal(id: 'deal_3', pizzaSizes: [PizzaSize.large])],
    drinks: const {'drink_1ltr': 2},
    dips: 3,
  );
}

void main() {
  group('mapOrderToDraft', () {
    test('rebuilds items, deals, drinks and dips at current menu prices', () {
      final result = mapOrderToDraft(_fullOrder());

      expect(result.skippedCount, 0);
      expect(result.entries.length, 2);

      final dealEntry = result.entries[0];
      expect(dealEntry.deal!.id, 'deal_3');
      // Current menu price (800), not the stored 1.
      expect(dealEntry.deal!.price, 800);
      expect(dealEntry.flavorIds, ['spicy_bbq']);
      expect(dealEntry.toppings.length, 1);
      expect(dealEntry.toppings.first, isEmpty);

      final pizzaEntry = result.entries[1];
      expect(pizzaEntry.deal, isNull);
      expect(pizzaEntry.standalonePizzaSize, PizzaSize.large);
      expect(pizzaEntry.flavorIds, ['chicken_fajita']);
      expect(pizzaEntry.toppings.length, 1);
      expect(pizzaEntry.toppings.first.length, 1);
      expect(pizzaEntry.toppings.first.first.toppingId, 'meat');
      expect(pizzaEntry.toppings.first.first.toppingName, 'Meat');
      // Re-priced to the current 100, not the stored 1.
      expect(pizzaEntry.toppings.first.first.priceAtOrderTime, 100);

      expect(result.additionalDrinks, {'drink_1ltr': 2});
      expect(result.additionalDipSauceCount, 3);

      // Entry ids are fresh and unique.
      expect(result.entries[0].id, isNotEmpty);
      expect(result.entries[0].id, isNot(result.entries[1].id));
    });

    test('standalone pizza with a missing flavor is skipped', () {
      final order = _order(items: [
        _pizza(flavorId: 'ghost_flavor', size: PizzaSize.large),
        _pizza(flavorId: 'chicken_fajita', size: PizzaSize.small),
      ]);

      final result = mapOrderToDraft(order);

      expect(result.entries.length, 1);
      expect(result.entries.first.flavorIds, ['chicken_fajita']);
      expect(result.skippedCount, 1);
    });

    test('deal that left the menu is skipped; its items stay consumed', () {
      final order = _order(
        items: [
          _pizza(flavorId: 'spicy_bbq', size: PizzaSize.large),
          _pizza(flavorId: 'chicken_fajita', size: PizzaSize.small),
        ],
        deals: [_storedDeal(id: 'ghost_deal', pizzaSizes: [PizzaSize.large])],
      );

      final result = mapOrderToDraft(order);

      // Only the standalone pizza survives; the ghost deal's pizza is not
      // misread as a standalone.
      expect(result.entries.length, 1);
      expect(result.entries.first.standalonePizzaSize, PizzaSize.small);
      expect(result.skippedCount, 1);
    });

    test('deal pizza with a missing flavor skips the whole deal', () {
      final order = _order(
        items: [_pizza(flavorId: 'ghost_flavor', size: PizzaSize.small)],
        deals: [_storedDeal(id: 'deal_1', pizzaSizes: [PizzaSize.small])],
      );

      final result = mapOrderToDraft(order);

      expect(result.entries, isEmpty);
      expect(result.skippedCount, 1);
    });

    test('deal whose shape changed on the menu is skipped', () {
      // The stored deal_1 claims 2 small pizzas; the menu's deal_1 has 1.
      final order = _order(
        items: [
          _pizza(flavorId: 'spicy_bbq', size: PizzaSize.small),
          _pizza(flavorId: 'malai_boti', size: PizzaSize.small),
        ],
        deals: [
          _storedDeal(
            id: 'deal_1',
            pizzaSizes: [PizzaSize.small, PizzaSize.small],
          ),
        ],
      );

      final result = mapOrderToDraft(order);

      expect(result.entries, isEmpty);
      expect(result.skippedCount, 1);
    });

    test('missing drink is skipped; missing topping is dropped silently', () {
      final order = _order(
        items: [
          _pizza(
            flavorId: 'chicken_fajita',
            size: PizzaSize.large,
            toppings: const [
              ToppingSelection(
                toppingId: 'ghost_topping',
                toppingName: 'Ghost',
                priceAtOrderTime: 50,
              ),
              ToppingSelection(
                toppingId: 'veggie',
                toppingName: 'Veggie',
                priceAtOrderTime: 1,
              ),
            ],
          ),
        ],
        drinks: const {'ghost_drink': 1, 'drink_345ml': 2},
      );

      final result = mapOrderToDraft(order);

      expect(result.entries.length, 1);
      expect(result.entries.first.toppings.first.length, 1);
      expect(result.entries.first.toppings.first.first.toppingId, 'veggie');
      expect(
        result.entries.first.toppings.first.first.priceAtOrderTime,
        50,
      );
      expect(result.additionalDrinks, {'drink_345ml': 2});
      // Only the drink counts as a skipped item; the dropped topping does
      // not (the pizza still reorders, minus that topping).
      expect(result.skippedCount, 1);
    });

    test('two deals then a standalone land on the right slots', () {
      final order = _order(
        items: [
          _pizza(flavorId: 'spicy_bbq', size: PizzaSize.small),
          _pizza(flavorId: 'malai_boti', size: PizzaSize.regular),
          _pizza(flavorId: 'chicken_fajita', size: PizzaSize.large),
        ],
        deals: [
          _storedDeal(id: 'deal_1', pizzaSizes: [PizzaSize.small]),
          _storedDeal(id: 'deal_2', pizzaSizes: [PizzaSize.regular]),
        ],
      );

      final result = mapOrderToDraft(order);

      expect(result.entries.length, 3);
      expect(result.entries[0].deal!.id, 'deal_1');
      expect(result.entries[0].flavorIds, ['spicy_bbq']);
      expect(result.entries[1].deal!.id, 'deal_2');
      expect(result.entries[1].flavorIds, ['malai_boti']);
      expect(result.entries[2].deal, isNull);
      expect(result.entries[2].standalonePizzaSize, PizzaSize.large);
      expect(result.entries[2].flavorIds, ['chicken_fajita']);
      expect(result.skippedCount, 0);
    });

    test('corrupt item count skips the deal and the leftovers', () {
      // The deal claims 2 pizzas but only 1 item was stored.
      final order = _order(
        items: [_pizza(flavorId: 'spicy_bbq', size: PizzaSize.small)],
        deals: [
          _storedDeal(
            id: 'deal_1',
            pizzaSizes: [PizzaSize.small, PizzaSize.small],
          ),
        ],
      );

      final result = mapOrderToDraft(order);

      expect(result.entries, isEmpty);
      expect(result.skippedCount, 1);
    });
  });

  group('applyReorder', () {
    test('replaces item fields only; totals re-price at current prices', () {
      final container = createTestContainer();
      final notifier = container.read(orderDraftProvider.notifier);

      notifier.setCustomerName('Ahmed Raza');
      notifier.setCustomerPhone('03001234567');
      notifier.setCustomerAddress('House 14');
      notifier.setDeliveryCharge(180);
      notifier.addStandalonePizza(PizzaSize.small);

      notifier.applyReorder(mapOrderToDraft(_fullOrder()));

      final draft = container.read(orderDraftProvider);
      expect(draft.entries.length, 2);
      expect(draft.additionalDrinks, {'drink_1ltr': 2});
      expect(draft.additionalDipSauceCount, 3);

      // Customer fields and the chosen charge are untouched.
      expect(draft.customerName, 'Ahmed Raza');
      expect(draft.customerPhone, '03001234567');
      expect(draft.customerAddress, 'House 14');
      expect(draft.deliveryCharge, 180);

      // Current prices: 800 (deal_3) + 700 (large) + 100 (meat topping)
      // + 2x170 (drinks) + 3x30 (dips) + 180 (charge) = 2210.
      expect(notifier.grandTotal, 2210);
    });
  });
}