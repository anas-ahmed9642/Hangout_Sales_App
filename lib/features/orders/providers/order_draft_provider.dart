import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/deal.dart';
import '../models/order_draft.dart';
import '../models/order_draft_entry.dart';
import '../models/pizza_size.dart';
import '../models/topping_selection.dart';
import '../models/menu_data.dart';

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
  ToppingSelection topping,
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
double _getToppingPrice(
  ToppingSelection topping,
  PizzaSize size,
) {
  if (topping.toppingId == 'cheese') {
    return MenuData.cheesePrices[size] ?? 0;
  }

  return MenuData.toppingPrices[topping.toppingId] ?? 0;
}
}