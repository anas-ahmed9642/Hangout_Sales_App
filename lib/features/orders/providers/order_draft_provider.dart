import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/deal.dart';
import '../models/order_draft.dart';
import '../models/order_draft_entry.dart';
import '../models/pizza_size.dart';
import '../models/topping_selection.dart';
import '../models/menu_data.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import 'order_repository_provider.dart';
final orderDraftProvider =
    NotifierProvider<OrderDraftNotifier, OrderDraft>(
  OrderDraftNotifier.new,
);

class OrderDraftNotifier extends Notifier<OrderDraft> {
  static const _uuid = Uuid();
  @override
  OrderDraft build() {
    return const OrderDraft();
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

  final newEntries = [
    ...state.entries,
    entry,
  ];

  state = state.copyWith(
    entries: newEntries,
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

  final newEntries = [
    ...state.entries,
    entry,
  ];

  state = state.copyWith(
    entries: newEntries,
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

  if (pizzaIndex < 0 || pizzaIndex >= entry.flavorIds.length) {
    return;
  }

  final updatedFlavorIds = [
    ...entry.flavorIds,
  ];

  updatedFlavorIds[pizzaIndex] = flavorId;

  final updatedEntry = entry.copyWith(
    flavorIds: updatedFlavorIds,
  );

  final newEntries = [
    ...state.entries,
  ];

  newEntries[entryIndex] = updatedEntry;

  state = state.copyWith(
    entries: newEntries,
  );
}

void removeEntry(String entryId) {
  final newEntries = state.entries
      .where((entry) => entry.id != entryId)
      .toList();

  state = state.copyWith(
    entries: newEntries,
  );
}

void setDeliveryCharge(double charge) {
  state = state.copyWith(
    deliveryCharge: charge,
  );
}
void setCustomerName(String? name) {
  state = state.copyWith(
    customerName: name,
  );
}

void setCustomerPhone(String? phone) {
  state = state.copyWith(
    customerPhone: phone,
  );
}

void setCustomerAddress(String? address) {
  state = state.copyWith(
    customerAddress: address,
  );
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

  if (pizzaIndex < 0 || pizzaIndex >= entry.toppings.length) {
    return;
  }

  // 1. Determine the size of this specific pizza
  final PizzaSize size = entry.deal != null
      ? entry.deal!.pizzaSizes[pizzaIndex]
      : entry.standalonePizzaSize!;

  // 2. Calculate the price dynamically
  final price = _getToppingPrice(toppingId, size);

  // 3. Create the selection object
  final topping = ToppingSelection(
    toppingId: toppingId,
    toppingName: toppingName,
    priceAtOrderTime: price,
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

  final newEntries = [
    ...state.entries,
  ];

  newEntries[entryIndex] = updatedEntry;

  state = state.copyWith(
    entries: newEntries,
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

  if (pizzaIndex < 0 || pizzaIndex >= entry.toppings.length) {
    return;
  }

  final updatedToppings = [
    ...entry.toppings,
  ];

  final updatedPizzaToppings = updatedToppings[pizzaIndex]
      .where((topping) => topping.toppingId != toppingId)
      .toList();

  updatedToppings[pizzaIndex] = updatedPizzaToppings;

  final updatedEntry = entry.copyWith(
    toppings: updatedToppings,
  );

  final newEntries = [
    ...state.entries,
  ];

  newEntries[entryIndex] = updatedEntry;

  state = state.copyWith(
    entries: newEntries,
  );
}
double _getToppingPrice(String toppingId, PizzaSize size) {
  if (toppingId == 'cheese') {
    return MenuData.cheesePrices[size] ?? 0;
  }
  return MenuData.toppingPrices[toppingId] ?? 0;
}
double _getPizzaExtras(
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

  for (final topping in entry.toppings[pizzaIndex]) {
    total += topping.priceAtOrderTime;
  }

  return total;
}
double entryTotal(OrderDraftEntry entry) {
  return _getEntryTotal(entry);
}

void addAdditionalDrink(String drinkId) {
  final updatedDrinks = {
    ...state.additionalDrinks,
    drinkId: (state.additionalDrinks[drinkId] ?? 0) + 1,
  };

  state = state.copyWith(
    additionalDrinks: updatedDrinks,
  );
}
void removeAdditionalDrink(String drinkId) {
  final currentQty = state.additionalDrinks[drinkId] ?? 0;
  
  if (currentQty == 0) return; // Nothing to remove

  // Create a fresh copy of the map for Riverpod immutability
  final updatedDrinks = Map<String, int>.from(state.additionalDrinks);

  if (currentQty == 1) {
    updatedDrinks.remove(drinkId); // Remove the key entirely if it hits 0
  } else {
    updatedDrinks[drinkId] = currentQty - 1; // Otherwise, just decrement
  }

  state = state.copyWith(
    additionalDrinks: updatedDrinks,
  );
}
void setAdditionalDipSauceCount(int count) {
  state = state.copyWith(
    additionalDipSauceCount: count,
  );
}

double _getEntryTotal(OrderDraftEntry entry) {
  double total = 0;

  if (entry.deal != null) {
    total += entry.deal!.price;

    for (var pizzaIndex = 0;
        pizzaIndex < entry.deal!.pizzaSizes.length;
        pizzaIndex++) {
      total += _getPizzaExtras(entry, pizzaIndex);
    }
  } else if (entry.standalonePizzaSize != null) {
    final basePrice =
        MenuData.pizzaPrices[entry.standalonePizzaSize!] ?? 0;

    total += basePrice;

    for (var pizzaIndex = 0;
        pizzaIndex < entry.flavorIds.length;
        pizzaIndex++) {
      total += _getPizzaExtras(entry, pizzaIndex);
    }
  }

  return total;
}

double get pizzaSubtotal {
  return state.entries.fold(
    0,
    (total, entry) => total + _getEntryTotal(entry),
  );
}

double get additionalDrinksTotal {
  double total = 0;

  for (final entry in state.additionalDrinks.entries) {
    final drinkPrice = MenuData.drinkPrices[entry.key] ?? 0;
    total += drinkPrice * entry.value;
  }

  return total;
}

double get additionalDipSauceTotal {
  return MenuData.dipSaucePrice * state.additionalDipSauceCount;
}

double get grandTotal {
  return pizzaSubtotal +
      additionalDrinksTotal +
      additionalDipSauceTotal +
      state.deliveryCharge;
}
List<String> get validationErrors {
  final errors = <String>[];

  if (state.entries.isEmpty) {
    errors.add('At least one pizza or deal is required.');
  }

  for (final entry in state.entries) {
    final hasDeal = entry.deal != null;
    final hasStandalonePizza = entry.standalonePizzaSize != null;

    if (hasDeal == hasStandalonePizza) {
      errors.add(
        'Each order entry must contain either a deal or a standalone pizza.',
      );
      continue;
    }

    final expectedPizzaCount = hasDeal
        ? entry.deal!.pizzaSizes.length
        : 1;

    if (entry.flavorIds.length != expectedPizzaCount) {
      errors.add(
        'An order entry has an incorrect number of flavor selections.',
      );
      continue;
    }

    if (entry.toppings.length != expectedPizzaCount) {
      errors.add(
        'An order entry has an incorrect number of topping lists.',
      );
      continue;
    }

    for (var pizzaIndex = 0;
        pizzaIndex < entry.flavorIds.length;
        pizzaIndex++) {
      final flavorId = entry.flavorIds[pizzaIndex];

      if (flavorId == null) {
        errors.add(
          'Every pizza must have a flavor selected.',
        );
        continue;
      }

      final flavorExists = MenuData.flavors.any(
        (flavor) => flavor.id == flavorId,
      );

      if (!flavorExists) {
        errors.add(
          'An invalid flavor was selected.',
        );
      }
    }
  }

  if (state.deliveryCharge < 0) {
    errors.add('Delivery charge cannot be negative.');
  }

  if (state.additionalDipSauceCount < 0) {
    errors.add('Additional dip sauce count cannot be negative.');
  }

  for (final entry in state.additionalDrinks.entries) {
    if (!MenuData.drinkPrices.containsKey(entry.key)) {
      errors.add('An invalid additional drink was selected.');
    }

    if (entry.value <= 0) {
      errors.add('Additional drink quantity must be greater than zero.');
    }
  }

  return errors;
}
Order buildOrder({
  required String orderNumber,
  required DateTime businessDate,
  DateTime? createdAt,
}) {
  final errors = validationErrors;

  if (errors.isNotEmpty) {
    throw StateError(
      errors.join(' '),
    );
  }

  final now = createdAt ?? DateTime.now();

  final items = <OrderItem>[];
  final deals = <Deal>[];

  for (final entry in state.entries) {
    if (entry.deal != null) {
      final deal = entry.deal!;

      deals.add(deal);

      for (var pizzaIndex = 0;
          pizzaIndex < deal.pizzaSizes.length;
          pizzaIndex++) {
        items.add(
          _buildOrderItem(
            entry,
            pizzaIndex,
            deal.pizzaSizes[pizzaIndex],
            isDealPizza: true,
          ),
        );
      }
    } else {
      items.add(
        _buildOrderItem(
          entry,
          0,
          entry.standalonePizzaSize!,
          isDealPizza: false,
        ),
      );
    }
  }

  return Order(
    id: _uuid.v4(),
    orderNumber: orderNumber,
    createdAt: now,
    businessDate: businessDate,
    customerName: state.customerName,
    customerPhone: state.customerPhone,
    customerAddress: state.customerAddress,
    items: items,
    deals: deals,
    additionalDrinks: Map.unmodifiable(
      state.additionalDrinks,
    ),
    additionalDipSauceCount: state.additionalDipSauceCount,
    deliveryCharge: state.deliveryCharge,
    total: grandTotal,
    status: OrderStatus.pending,
    paymentStatus: state.paymentStatus,
  );
}
OrderItem _buildOrderItem(
  OrderDraftEntry entry,
  int pizzaIndex,
  PizzaSize size, {
  required bool isDealPizza,
}) {
  final flavorId = entry.flavorIds[pizzaIndex];

  final flavor = MenuData.flavors.firstWhere(
    (flavor) => flavor.id == flavorId,
  );

  final toppings = List<ToppingSelection>.unmodifiable(
    entry.toppings[pizzaIndex],
  );

  final flavorExtra = flavor.priceExtra ?? 0;

  final toppingsTotal = toppings.fold(
    0.0,
    (total, topping) => total + topping.priceAtOrderTime,
  );

  final extrasTotal = flavorExtra + toppingsTotal;

  final basePrice = isDealPizza
      ? 0.0
      : MenuData.pizzaPrices[size] ?? 0;

  return OrderItem(
    flavorId: flavor.id,
    flavorName: flavor.name,
    flavorPriceExtra: flavor.priceExtra,
    size: size,
    toppings: toppings,
    quantity: 1,
    unitPrice: basePrice + extrasTotal,
  );
}
bool get canConfirm {
  return validationErrors.isEmpty;
}
void clearDraft() {
  state = const OrderDraft();
}

Future<void> saveOrder({
  required String orderNumber,
  required DateTime businessDate,
  DateTime? createdAt,
}) async {
  final order = buildOrder(
    orderNumber: orderNumber,
    businessDate: businessDate,
    createdAt: createdAt,
  );

  final repository = ref.read(orderRepositoryProvider);

  await repository.createOrder(order);
}

void setPaymentStatus(PaymentStatus paymentStatus) {
  state = state.copyWith(
    paymentStatus: paymentStatus,
  );
}



}