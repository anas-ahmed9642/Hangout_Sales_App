import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/deal.dart';
import '../models/order.dart';
import '../models/order_draft.dart';
import '../models/order_draft_entry.dart';
import '../models/order_item.dart';
import '../models/pizza_size.dart';
import '../models/topping_selection.dart';
import '../models/menu_data.dart';

final orderEditProvider = NotifierProvider.family<
    OrderEditNotifier,
    OrderDraft,
    Order
>(
  OrderEditNotifier.new,
);

class OrderEditNotifier extends FamilyNotifier<OrderDraft, Order> {
  static const _uuid = Uuid();

  late Order _originalOrder;

  @override
  OrderDraft build(Order order) {
    _originalOrder = order;

    return _draftFromOrder(order);
  }

  OrderDraft _draftFromOrder(Order order) {
    final entries = <OrderDraftEntry>[];

    var itemIndex = 0;

    for (final deal in order.deals) {
      final pizzaCount = deal.pizzaSizes.length;

      if (itemIndex + pizzaCount > order.items.length) {
        break;
      }

      final flavorIds = <String?>[];
      final toppings = <List<ToppingSelection>>[];

      for (var pizzaIndex = 0;
          pizzaIndex < pizzaCount;
          pizzaIndex++) {
        final item = order.items[itemIndex++];

        flavorIds.add(item.flavorId);
        toppings.add(
          List<ToppingSelection>.from(
            item.toppings ?? const [],
          ),
        );
      }

      entries.add(
        OrderDraftEntry(
          id: _uuid.v4(),
          deal: deal,
          flavorIds: flavorIds,
          toppings: toppings,
        ),
      );
    }

    while (itemIndex < order.items.length) {
      final item = order.items[itemIndex++];

      entries.add(
        OrderDraftEntry(
          id: _uuid.v4(),
          standalonePizzaSize: item.size,
          flavorIds: [item.flavorId],
          toppings: [
            List<ToppingSelection>.from(
              item.toppings ?? const [],
            ),
          ],
        ),
      );
    }

    return OrderDraft(
      entries: entries,
      additionalDrinks: Map<String, int>.from(
        order.additionalDrinks,
      ),
      additionalDipSauceCount: order.additionalDipSauceCount,
      deliveryCharge: order.deliveryCharge,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      customerAddress: order.customerAddress,
      paymentStatus: order.paymentStatus,
    );
  }

  void addDeal(Deal deal) {
    final entry = OrderDraftEntry(
      id: _uuid.v4(),
      deal: deal,
      flavorIds: List<String?>.filled(
        deal.pizzaSizes.length,
        null,
      ),
      toppings: List<List<ToppingSelection>>.generate(
        deal.pizzaSizes.length,
        (_) => <ToppingSelection>[],
      ),
    );

    state = state.copyWith(
      entries: [
        ...state.entries,
        entry,
      ],
    );
  }

  void addStandalonePizza(PizzaSize size) {
    final entry = OrderDraftEntry(
      id: _uuid.v4(),
      standalonePizzaSize: size,
      flavorIds: [null],
      toppings: const [
        [],
      ],
    );

    state = state.copyWith(
      entries: [
        ...state.entries,
        entry,
      ],
    );
  }

  void removeEntry(String entryId) {
    state = state.copyWith(
      entries: state.entries
          .where((entry) => entry.id != entryId)
          .toList(),
    );
  }

  void setFlavor(
    String entryId,
    int pizzaIndex,
    String flavorId,
  ) {
    final entryIndex = state.entries.indexWhere(
      (entry) => entry.id == entryId,
    );

    if (entryIndex == -1) {
      return;
    }

    final entry = state.entries[entryIndex];

    if (pizzaIndex < 0 ||
        pizzaIndex >= entry.flavorIds.length) {
      return;
    }

    final updatedFlavorIds = [
      ...entry.flavorIds,
    ];

    updatedFlavorIds[pizzaIndex] = flavorId;

    final updatedEntry = entry.copyWith(
      flavorIds: updatedFlavorIds,
    );

    final entries = [
      ...state.entries,
    ];

    entries[entryIndex] = updatedEntry;

    state = state.copyWith(
      entries: entries,
    );
  }

  double _getToppingPrice(
    String toppingId,
    PizzaSize size,
  ) {
    if (toppingId == 'cheese') {
      return MenuData.cheesePrices[size] ?? 0;
    }

    return MenuData.toppingPrices[toppingId] ?? 0;
  }

  void addTopping(
    String entryId,
    int pizzaIndex,
    String toppingId,
    String toppingName,
  ) {
    final entryIndex = state.entries.indexWhere(
      (entry) => entry.id == entryId,
    );

    if (entryIndex == -1) {
      return;
    }

    final entry = state.entries[entryIndex];

    if (pizzaIndex < 0 ||
        pizzaIndex >= entry.toppings.length) {
      return;
    }

    final size = entry.deal != null
        ? entry.deal!.pizzaSizes[pizzaIndex]
        : entry.standalonePizzaSize!;

    final topping = ToppingSelection(
      toppingId: toppingId,
      toppingName: toppingName,
      priceAtOrderTime: _getToppingPrice(
        toppingId,
        size,
      ),
    );

    final updatedToppings = [
      ...entry.toppings,
    ];

    updatedToppings[pizzaIndex] = [
      ...updatedToppings[pizzaIndex],
      topping,
    ];

    final updatedEntry = entry.copyWith(
      toppings: updatedToppings,
    );

    final entries = [
      ...state.entries,
    ];

    entries[entryIndex] = updatedEntry;

    state = state.copyWith(
      entries: entries,
    );
  }

  void removeTopping(
    String entryId,
    int pizzaIndex,
    String toppingId,
  ) {
    final entryIndex = state.entries.indexWhere(
      (entry) => entry.id == entryId,
    );

    if (entryIndex == -1) {
      return;
    }

    final entry = state.entries[entryIndex];

    if (pizzaIndex < 0 ||
        pizzaIndex >= entry.toppings.length) {
      return;
    }

    final updatedToppings = [
      ...entry.toppings,
    ];

    updatedToppings[pizzaIndex] = updatedToppings[pizzaIndex]
        .where(
          (topping) => topping.toppingId != toppingId,
        )
        .toList();

    final updatedEntry = entry.copyWith(
      toppings: updatedToppings,
    );

    final entries = [
      ...state.entries,
    ];

    entries[entryIndex] = updatedEntry;

    state = state.copyWith(
      entries: entries,
    );
  }

  void addAdditionalDrink(String drinkId) {
    final drinks = {
      ...state.additionalDrinks,
      drinkId: (state.additionalDrinks[drinkId] ?? 0) + 1,
    };

    state = state.copyWith(
      additionalDrinks: drinks,
    );
  }

  void removeAdditionalDrink(String drinkId) {
    final quantity = state.additionalDrinks[drinkId] ?? 0;

    if (quantity == 0) {
      return;
    }

    final drinks = Map<String, int>.from(
      state.additionalDrinks,
    );

    if (quantity == 1) {
      drinks.remove(drinkId);
    } else {
      drinks[drinkId] = quantity - 1;
    }

    state = state.copyWith(
      additionalDrinks: drinks,
    );
  }

  void setAdditionalDipSauceCount(int count) {
    state = state.copyWith(
      additionalDipSauceCount: count < 0 ? 0 : count,
    );
  }

  void setDeliveryCharge(double charge) {
    state = state.copyWith(
      deliveryCharge: charge,
    );
  }

  void setCustomerName(String? value) {
    state = state.copyWith(
      customerName: value,
    );
  }

  void setCustomerPhone(String? value) {
    state = state.copyWith(
      customerPhone: value,
    );
  }

  void setCustomerAddress(String? value) {
    state = state.copyWith(
      customerAddress: value,
    );
  }

  double _entryTotal(OrderDraftEntry entry) {
    double total = 0;

    if (entry.deal != null) {
      total += entry.deal!.price;

      for (var i = 0;
          i < entry.deal!.pizzaSizes.length;
          i++) {
        total += _pizzaExtras(entry, i);
      }
    } else if (entry.standalonePizzaSize != null) {
      total += MenuData.pizzaPrices[
            entry.standalonePizzaSize!
          ] ??
          0;

      for (var i = 0;
          i < entry.flavorIds.length;
          i++) {
        total += _pizzaExtras(entry, i);
      }
    }

    return total;
  }

  double _pizzaExtras(
    OrderDraftEntry entry,
    int pizzaIndex,
  ) {
    double total = 0;

    final flavorId = entry.flavorIds[pizzaIndex];

    if (flavorId != null) {
      final flavor = MenuData.flavors.firstWhere(
        (flavor) => flavor.id == flavorId,
      );

      total += flavor.priceExtra ?? 0;
    }

    for (final topping
        in entry.toppings[pizzaIndex]) {
      total += topping.priceAtOrderTime;
    }

    return total;
  }

  double get pizzaSubtotal {
    return state.entries.fold(
      0,
      (total, entry) => total + _entryTotal(entry),
    );
  }

  double get additionalDrinksTotal {
    double total = 0;

    for (final entry
        in state.additionalDrinks.entries) {
      final price =
          MenuData.drinkPrices[entry.key] ?? 0;

      total += price * entry.value;
    }

    return total;
  }

  double get additionalDipSauceTotal {
    return MenuData.dipSaucePrice *
        state.additionalDipSauceCount;
  }

  double get total {
    return pizzaSubtotal +
        additionalDrinksTotal +
        additionalDipSauceTotal +
        state.deliveryCharge;
  }

  List<String> get validationErrors {
    final errors = <String>[];

    if (state.entries.isEmpty) {
      errors.add(
        'At least one pizza or deal is required.',
      );
    }

    for (final entry in state.entries) {
      final hasDeal = entry.deal != null;
      final hasStandalone =
          entry.standalonePizzaSize != null;

      if (hasDeal == hasStandalone) {
        errors.add(
          'Each order entry must contain either a deal or a standalone pizza.',
        );
        continue;
      }

      final expectedPizzaCount = hasDeal
          ? entry.deal!.pizzaSizes.length
          : 1;

      if (entry.flavorIds.length !=
          expectedPizzaCount) {
        errors.add(
          'An order entry has an incorrect number of flavor selections.',
        );
        continue;
      }

      if (entry.toppings.length !=
          expectedPizzaCount) {
        errors.add(
          'An order entry has an incorrect number of topping lists.',
        );
        continue;
      }

      for (final flavorId in entry.flavorIds) {
        if (flavorId == null) {
          errors.add(
            'Every pizza must have a flavor selected.',
          );
          continue;
        }

        if (!MenuData.flavors.any(
          (flavor) => flavor.id == flavorId,
        )) {
          errors.add(
            'An invalid flavor was selected.',
          );
        }
      }
    }

    return errors;
  }

  bool get canSave => validationErrors.isEmpty;

  Order buildEditedOrder() {
    if (!canSave) {
      throw StateError(
        validationErrors.join(' '),
      );
    }

    final items = <OrderItem>[];
    final deals = <Deal>[];

    for (final entry in state.entries) {
      if (entry.deal != null) {
        final deal = entry.deal!;

        deals.add(deal);

        for (var i = 0;
            i < deal.pizzaSizes.length;
            i++) {
          final flavorId = entry.flavorIds[i];

          final flavor = MenuData.flavors.firstWhere(
            (flavor) => flavor.id == flavorId,
          );

          final toppings =
              List<ToppingSelection>.unmodifiable(
            entry.toppings[i],
          );

          final flavorExtra =
              flavor.priceExtra ?? 0;

          final toppingsTotal =
              toppings.fold<double>(
            0,
            (sum, topping) =>
                sum + topping.priceAtOrderTime,
          );

          items.add(
            OrderItem(
              flavorId: flavor.id,
              flavorName: flavor.name,
              flavorPriceExtra: flavor.priceExtra,
              size: deal.pizzaSizes[i],
              toppings: toppings,
              quantity: 1,
              unitPrice:
                  flavorExtra + toppingsTotal,
            ),
          );
        }
      } else {
        final size = entry.standalonePizzaSize!;

        final flavorId = entry.flavorIds.first;

        final flavor = MenuData.flavors.firstWhere(
          (flavor) => flavor.id == flavorId,
        );

        final toppings =
            List<ToppingSelection>.unmodifiable(
          entry.toppings.first,
        );

        final flavorExtra =
            flavor.priceExtra ?? 0;

        final toppingsTotal =
            toppings.fold<double>(
          0,
          (sum, topping) =>
              sum + topping.priceAtOrderTime,
        );

        final basePrice =
            MenuData.pizzaPrices[size] ?? 0;

        items.add(
          OrderItem(
            flavorId: flavor.id,
            flavorName: flavor.name,
            flavorPriceExtra: flavor.priceExtra,
            size: size,
            toppings: toppings,
            quantity: 1,
            unitPrice:
                basePrice +
                flavorExtra +
                toppingsTotal,
          ),
        );
      }
    }

    return Order(
      id: _originalOrder.id,
      orderNumber: _originalOrder.orderNumber,
      createdAt: _originalOrder.createdAt,
      businessDate: _originalOrder.businessDate,
      customerName: state.customerName,
      customerPhone: state.customerPhone,
      customerAddress: state.customerAddress,
      items: items,
      deals: deals,
      additionalDrinks:
          Map.unmodifiable(state.additionalDrinks),
      additionalDipSauceCount:
          state.additionalDipSauceCount,
      deliveryCharge: state.deliveryCharge,
      total: total,
      status: _originalOrder.status,
      paymentStatus: _originalOrder.paymentStatus,
      editCount: _originalOrder.editCount,
    );
  }
}