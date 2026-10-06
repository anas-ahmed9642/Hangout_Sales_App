import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hangout_sales_app/core/utils/phone_normalizer.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_repository_provider.dart';
import 'package:hangout_sales_app/features/delivery_areas/models/delivery_area.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_areas_provider.dart';
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

  /// Debounce for the customer phone lookup (~400 ms, plan 8.1).
  Timer? _lookupTimer;

  @override
  OrderDraft build() {
    ref.onDispose(() {
      _lookupTimer?.cancel();
    });
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
  // Pickup (charge 0) hides and clears the area; switching back to a
  // delivery charge does not resurrect it (plan 8.3). A hand-edited
  // charge never clears the area.
  final isPickup = charge == MenuData.pickupCharge;

  state = state.copyWith(
    deliveryCharge: charge,
    clearDeliveryAreaId: isPickup,
    clearDeliveryAreaName: isPickup,
  );
}
void setCustomerName(String? name) {
  state = state.copyWith(
    customerName: name,
    // Hand-typed: a later autofill must not overwrite it.
    autofilledFields: state.autofilledFields.difference(const {'name'}),
  );
}

void setCustomerPhone(String? phone) {
  state = state.copyWith(
    customerPhone: phone,
  );
}

/// Entry point for the phone field: keeps the draft in sync and runs the
/// debounced customer lookup (plan 8.1). An empty phone clears the
/// autofill state immediately, without waiting for the debounce.
void onCustomerPhoneChanged(String rawPhone) {
  setCustomerPhone(rawPhone);
  _lookupTimer?.cancel();

  if (rawPhone.trim().isEmpty) {
    _clearAutofilledFields();
    return;
  }

  _lookupTimer = Timer(const Duration(milliseconds: 400), () {
    _performLookup(rawPhone);
  });
}

void setCustomerAddress(String? address) {
  state = state.copyWith(
    customerAddress: address,
    autofilledFields: state.autofilledFields.difference(const {'address'}),
  );
}

void setCustomerMapLink(String? mapLink) {
  state = state.copyWith(
    customerMapLink: mapLink,
    autofilledFields: state.autofilledFields.difference(const {'mapLink'}),
  );
}

void setDeliveryNotes(String? notes) {
  state = state.copyWith(
    deliveryNotes: notes,
    autofilledFields:
        state.autofilledFields.difference(const {'deliveryNotes'}),
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
  // ------------------------------------------------------------------
  // Customer autofill, area and address (Phase 4, plan 8.1-8.3)
  // ------------------------------------------------------------------

  /// Runs ~400 ms after the last keystroke: normalizes the phone, looks
  /// the customer up, and applies the autofill state machine (plan 8.1).
  /// An invalid or unknown phone clears the autofill state; the order
  /// stays saveable either way. Never throws.
  Future<void> _performLookup(String rawPhone) async {
    try {
      final normalized = PhoneNormalizer.normalize(rawPhone);

      if (normalized == null) {
        _clearAutofilledFields();
        return;
      }

      final Customer? customer =
          await ref.read(customerRepositoryProvider).getByPhone(normalized);

      // The phone changed while the lookup was in flight: drop this result.
      if (state.customerPhone != rawPhone) {
        return;
      }

      if (customer == null) {
        _clearAutofilledFields();
        return;
      }

      state = state.copyWith(matchedCustomerPhone: customer.phone);
      await _applyAutofill(customer);
    } catch (_) {
      // A failed lookup (e.g. network) must never break order entry.
      _clearAutofilledFields();
    }
  }

  /// True when autofill may write [key]: the field is empty or it already
  /// holds an autofilled value. Typed values are never overwritten.
  bool _canAutofill(String key, String? current) {
    return current == null ||
        current.isEmpty ||
        state.autofilledFields.contains(key);
  }

  /// Applies a found customer to the draft: name (only when empty or
  /// already autofilled), the default (or first) address with its link
  /// and area, the area's default charge, and the delivery notes.
  Future<void> _applyAutofill(Customer customer) async {
    final nextMarked = <String>{};

    var name = state.customerName;
    var address = state.customerAddress;
    var mapLink = state.customerMapLink;
    var areaId = state.deliveryAreaId;
    var areaName = state.deliveryAreaName;
    var notes = state.deliveryNotes;
    var charge = state.deliveryCharge;
    String? selectedAddressId;

    if (_canAutofill('name', name)) {
      name = customer.name;
      nextMarked.add('name');
    }

    final addresses = customer.addresses;
    if (addresses.isNotEmpty) {
      CustomerAddress? selected;
      for (final a in addresses) {
        if (a.id == customer.defaultAddressId) {
          selected = a;
          break;
        }
      }
      selected ??= addresses.first;
      selectedAddressId = selected.id;

      if (_canAutofill('address', address)) {
        address = selected.text;
        nextMarked.add('address');
      }
      if (_canAutofill('mapLink', mapLink)) {
        mapLink = selected.mapLink;
        nextMarked.add('mapLink');
      }
      if (_canAutofill('area', areaId)) {
        final area = selected.areaId == null
            ? null
            : await _findArea(selected.areaId!);
        areaId = selected.areaId;
        areaName = area?.name;
        if (area != null) {
          charge = area.defaultCharge;
        }
        nextMarked.add('area');
      }
    } else {
      // The new customer has no saved addresses: drop any autofilled
      // address, link, or area left over from the previous customer.
      // Hand-typed values are never cleared.
      if (_canAutofill('address', address)) {
        address = null;
      }
      if (_canAutofill('mapLink', mapLink)) {
        mapLink = null;
      }
      if (_canAutofill('area', areaId)) {
        areaId = null;
        areaName = null;
      }
    }

    if (_canAutofill('deliveryNotes', notes)) {
      notes = customer.deliveryNotes;
      nextMarked.add('deliveryNotes');
    }

    state = state.copyWith(
      customerName: name,
      clearCustomerName: name == null,
      customerAddress: address,
      clearCustomerAddress: address == null,
      customerMapLink: mapLink,
      clearCustomerMapLink: mapLink == null,
      deliveryAreaId: areaId,
      clearDeliveryAreaId: areaId == null,
      deliveryAreaName: areaName,
      clearDeliveryAreaName: areaName == null,
      deliveryNotes: notes,
      clearDeliveryNotes: notes == null,
      deliveryCharge: charge,
      selectedAddressId: selectedAddressId,
      clearSelectedAddressId: selectedAddressId == null,
      autofilledFields: nextMarked,
    );
  }
  /// Resolves an area id using ALL areas (not only active), so a saved
  /// address referencing a deactivated area still resolves. Returns null
  /// when areas fail to load or the id is unknown; callers then keep the
  /// id with no name and leave the charge as-is.
  Future<DeliveryArea?> _findArea(String areaId) async {
    try {
      final areas = await ref.read(deliveryAreasProvider.future);
      for (final area in areas) {
        if (area.id == areaId) {
          return area;
        }
      }
    } catch (_) {
      // Offline/cache failure: the order stays saveable; the cashier can
      // still pick the area by hand.
    }
    return null;
  }

  /// Clears every field that currently holds an autofilled value.
  /// Hand-typed values are kept. The delivery charge is left untouched.
  void _clearAutofilledFields() {
    final marked = state.autofilledFields;
    state = state.copyWith(
      clearMatchedCustomerPhone: true,
      clearSelectedAddressId: true,
      clearCustomerName: marked.contains('name'),
      clearCustomerAddress: marked.contains('address'),
      clearCustomerMapLink: marked.contains('mapLink'),
      clearDeliveryAreaId: marked.contains('area'),
      clearDeliveryAreaName: marked.contains('area'),
      clearDeliveryNotes: marked.contains('deliveryNotes'),
      autofilledFields: const {},
    );
  }

  /// Applies a saved address chosen from the chooser chips (plan 8.2):
  /// re-fills address, location link, area and charge. Chip values come
  /// from the saved record, so a later phone change may replace them; a
  /// hand edit removes the keys again.
  Future<void> selectCustomerAddress(String addressId) async {
    try {
      final phone = state.matchedCustomerPhone;
      if (phone == null) {
        return;
      }

      final customer =
          await ref.read(customerRepositoryProvider).getByPhone(phone);

      CustomerAddress? selected;
      for (final a in customer?.addresses ?? const <CustomerAddress>[]) {
        if (a.id == addressId) {
          selected = a;
          break;
        }
      }
      if (selected == null) {
        return;
      }

      final area =
          selected.areaId == null ? null : await _findArea(selected.areaId!);

      state = state.copyWith(
        selectedAddressId: selected.id,
        customerAddress: selected.text,
        customerMapLink: selected.mapLink,
        clearCustomerMapLink: selected.mapLink == null,
        deliveryAreaId: selected.areaId,
        clearDeliveryAreaId: selected.areaId == null,
        deliveryAreaName: area?.name,
        clearDeliveryAreaName: area == null,
        deliveryCharge: area?.defaultCharge ?? state.deliveryCharge,
        autofilledFields: {
          ...state.autofilledFields,
          'address',
          'mapLink',
          'area',
        },
      );
    } catch (_) {
      // A failed lookup must never break order entry.
    }
  }
  /// Sets the delivery area from the picker sheet (plan 8.3). Choosing an
  /// area presets the charge; calling with no area ("Not listed / other")
  /// clears the area and keeps the charge as-is. A hand-picked area is
  /// never overwritten by a later autofill.
  void setDeliveryArea({
    String? areaId,
    String? areaName,
    double? defaultCharge,
  }) {
    state = state.copyWith(
      deliveryAreaId: areaId,
      clearDeliveryAreaId: areaId == null,
      deliveryAreaName: areaName,
      clearDeliveryAreaName: areaName == null,
      deliveryCharge: defaultCharge ?? state.deliveryCharge,
      autofilledFields: state.autofilledFields.difference(const {'area'}),
    );
  }

  /// Phase 5 companions: the "New customer" switch and the "address
  /// changed" sheet write here.
  void setSaveCustomer(bool value) {
    state = state.copyWith(saveCustomer: value);
  }

  void setAddressDecision(AddressDecision? decision) {
    state = state.copyWith(
      addressDecision: decision,
      clearAddressDecision: decision == null,
    );
  }

  void setNewAddressLabel(String? label) {
    state = state.copyWith(
      newAddressLabel: label,
      clearNewAddressLabel: label == null,
    );
  }

}