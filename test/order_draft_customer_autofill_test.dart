import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

import 'package:hangout_sales_app/core/utils/phone_normalizer.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_repository_provider.dart';
import 'package:hangout_sales_app/features/customers/repositories/customer_repository.dart';
import 'package:hangout_sales_app/features/delivery_areas/models/delivery_area.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_area_repository_provider.dart';
import 'package:hangout_sales_app/features/delivery_areas/repositories/delivery_area_repository.dart';
import 'package:hangout_sales_app/features/orders/models/menu_data.dart';
import 'package:hangout_sales_app/features/orders/models/order_draft.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';

final _t = DateTime(2026, 10, 2);

Customer _ahmed() {
  return Customer(
    phone: '03001234567',
    name: 'Ahmed Raza',
    addresses: [
      CustomerAddress(
        id: 'a1',
        label: 'Home',
        text: 'House 14, Street 3',
        mapLink:
            'https://www.google.com/maps/search/?api=1&query=24.8607,67.0011',
        areaId: 'area-1',
      ),
      CustomerAddress(
        id: 'a2',
        label: 'Office',
        text: 'Office 9, Main Boulevard',
      ),
    ],
    defaultAddressId: 'a1',
    deliveryNotes: 'Ring twice',
    createdAt: _t,
    updatedAt: _t,
  );
}

Customer _bilal() {
  return Customer(
    phone: '03007654321',
    name: 'Bilal',
    createdAt: _t,
    updatedAt: _t,
  );
}

DeliveryArea _sector11b() {
  return DeliveryArea(
    id: 'area-1',
    name: 'Sector 11B',
    defaultCharge: 180,
    createdAt: _t,
  );
}

class _FakeCustomerRepository implements CustomerRepository {
  final Map<String, Customer> customers;
  int lookups = 0;

  _FakeCustomerRepository(this.customers);

  @override
  Future<Customer?> getByPhone(String phone) async {
    lookups++;
    // Faithful to the real repository: normalize defensively.
    final id = PhoneNormalizer.normalize(phone) ?? phone;
    return customers[id];
  }

  @override
  Stream<List<Customer>> streamCustomers({bool includeArchived = false}) =>
      throw UnimplementedError();

  @override
  Future<void> createCustomer(Customer customer) =>
      throw UnimplementedError();

  @override
  Future<void> updateProfile(
    String phone, {
    String? name,
    String? notes,
    String? deliveryNotes,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> saveAddresses(
    String phone,
    List<CustomerAddress> addresses,
    String? defaultAddressId,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> setArchived(String phone, bool archived) =>
      throw UnimplementedError();
}

class _FakeDeliveryAreaRepository implements DeliveryAreaRepository {
  final List<DeliveryArea> areas;

  _FakeDeliveryAreaRepository(this.areas);

  @override
  Stream<List<DeliveryArea>> streamAreas({bool activeOnly = false}) async* {
    yield areas.where((area) => !activeOnly || area.active).toList();
  }

  @override
  Future<String> createArea({
    required String name,
    required double defaultCharge,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateArea(
    String areaId, {
    required String name,
    required double defaultCharge,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setAreaActive(String areaId, bool active) =>
      throw UnimplementedError();

  @override
  Future<int> seedVerifiedAreas() => throw UnimplementedError();
}

ProviderContainer _container({
  Map<String, Customer>? customers,
  List<DeliveryArea>? areas,
}) {
  return createTestContainer(overrides: [
    customerRepositoryProvider.overrideWithValue(
      _FakeCustomerRepository(customers ?? {}),
    ),
    deliveryAreaRepositoryProvider.overrideWithValue(
      _FakeDeliveryAreaRepository(areas ?? []),
    ),
  ]);
}

/// Simulates typing a phone: runs the debounced lookup to completion.
Future<void> _typePhone(ProviderContainer container, String phone) async {
  container.read(orderDraftProvider.notifier).onCustomerPhoneChanged(phone);
  // 400 ms debounce plus the (instant) fake lookup.
  await Future.delayed(const Duration(milliseconds: 600));
}

void main() {
  group('customer autofill (plan 8.1)', () {
    test('a stored phone autofills name, address, link, area, charge, notes',
        () async {
      final container = _container(
        customers: {'03001234567': _ahmed()},
        areas: [_sector11b()],
      );

      await _typePhone(container, '03001234567');

      final draft = container.read(orderDraftProvider);
      expect(draft.matchedCustomerPhone, '03001234567');
      expect(draft.customerName, 'Ahmed Raza');
      expect(draft.customerAddress, 'House 14, Street 3');
      expect(
        draft.customerMapLink,
        'https://www.google.com/maps/search/?api=1&query=24.8607,67.0011',
      );
      expect(draft.deliveryAreaId, 'area-1');
      expect(draft.deliveryAreaName, 'Sector 11B');
      expect(draft.deliveryCharge, 180);
      expect(draft.deliveryNotes, 'Ring twice');
      expect(draft.selectedAddressId, 'a1');
      expect(
        draft.autofilledFields,
        {'name', 'address', 'mapLink', 'area', 'deliveryNotes'},
      );
    });

    test('any valid phone format finds the same customer', () async {
      final container = _container(
        customers: {'03001234567': _ahmed()},
        areas: [_sector11b()],
      );

      await _typePhone(container, '+92 300 1234567');

      final draft = container.read(orderDraftProvider);
      expect(draft.matchedCustomerPhone, '03001234567');
      expect(draft.customerName, 'Ahmed Raza');
    });

    test('a typed name is kept when a stored phone is entered', () async {
      final container = _container(
        customers: {'03001234567': _ahmed()},
        areas: [_sector11b()],
      );
      final notifier = container.read(orderDraftProvider.notifier);

      notifier.setCustomerName('Walk-in Guest');
      await _typePhone(container, '03001234567');

      final draft = container.read(orderDraftProvider);
      expect(draft.customerName, 'Walk-in Guest');
      expect(draft.customerAddress, 'House 14, Street 3');
      expect(draft.autofilledFields.contains('name'), isFalse);
    });

    test('switching phones replaces autofilled fields, keeps typed ones',
        () async {
      final container = _container(
        customers: {'03001234567': _ahmed(), '03007654321': _bilal()},
        areas: [_sector11b()],
      );
      final notifier = container.read(orderDraftProvider.notifier);

      await _typePhone(container, '03001234567');
      expect(
        container.read(orderDraftProvider).customerName,
        'Ahmed Raza',
      );

      notifier.setCustomerName('Typed Name');
      await _typePhone(container, '03007654321');

      final draft = container.read(orderDraftProvider);
      expect(draft.matchedCustomerPhone, '03007654321');
      expect(draft.customerName, 'Typed Name');
      expect(draft.customerAddress, isNull);
      expect(draft.customerMapLink, isNull);
      expect(draft.deliveryAreaId, isNull);
      expect(draft.deliveryNotes, isNull);
    });

    test('clearing the phone clears autofilled fields, keeps typed ones',
        () async {
      final container = _container(
        customers: {'03001234567': _ahmed()},
        areas: [_sector11b()],
      );
      final notifier = container.read(orderDraftProvider.notifier);

      await _typePhone(container, '03001234567');
      notifier.setCustomerName('Typed Name');

      // Empty phone clears synchronously (no debounce).
      notifier.onCustomerPhoneChanged('');

      final draft = container.read(orderDraftProvider);
      expect(draft.customerPhone, '');
      expect(draft.matchedCustomerPhone, isNull);
      expect(draft.selectedAddressId, isNull);
      expect(draft.customerName, 'Typed Name');
      expect(draft.customerAddress, isNull);
      expect(draft.autofilledFields, isEmpty);
    });

    test('an invalid phone never blocks saving the order', () async {
      final container = _container(
        customers: {'03001234567': _ahmed()},
      );
      final notifier = container.read(orderDraftProvider.notifier);

      notifier.addStandalonePizza(PizzaSize.small);
      final entryId = container.read(orderDraftProvider).entries.single.id;
      notifier.setFlavor(entryId, 0, MenuData.flavors.first.id);

      await _typePhone(container, '0300');

      final draft = container.read(orderDraftProvider);
      expect(draft.matchedCustomerPhone, isNull);
      expect(notifier.validationErrors, isEmpty);
      expect(notifier.canConfirm, isTrue);
    });

    test('an unknown phone matches nothing and keeps the order saveable',
        () async {
      final container = _container(customers: {});

      await _typePhone(container, '03009999999');

      final draft = container.read(orderDraftProvider);
      expect(draft.matchedCustomerPhone, isNull);
      expect(draft.customerName, isNull);
    });

    test('selecting an address chip re-fills address, link, area, charge',
        () async {
      final container = _container(
        customers: {'03001234567': _ahmed()},
        areas: [_sector11b()],
      );
      final notifier = container.read(orderDraftProvider.notifier);

      await _typePhone(container, '03001234567');
      // Default is a1 (Home, has area). Switch to a2 (Office, no area).
      await notifier.selectCustomerAddress('a2');

      var draft = container.read(orderDraftProvider);
      expect(draft.selectedAddressId, 'a2');
      expect(draft.customerAddress, 'Office 9, Main Boulevard');
      expect(draft.customerMapLink, isNull);
      expect(draft.deliveryAreaId, isNull);
      expect(draft.deliveryAreaName, isNull);
      // Unlisted area: the charge stays as-is.
      expect(draft.deliveryCharge, 180);

      // And back to a1.
      await notifier.selectCustomerAddress('a1');

      draft = container.read(orderDraftProvider);
      expect(draft.selectedAddressId, 'a1');
      expect(draft.customerAddress, 'House 14, Street 3');
      expect(draft.deliveryAreaId, 'area-1');
      expect(draft.deliveryAreaName, 'Sector 11B');
      expect(draft.deliveryCharge, 180);
    });

    test('setDeliveryCharge(0) clears the area (Pickup)', () async {
      final container = _container(
        customers: {'03001234567': _ahmed()},
        areas: [_sector11b()],
      );
      final notifier = container.read(orderDraftProvider.notifier);

      await _typePhone(container, '03001234567');
      expect(
        container.read(orderDraftProvider).deliveryAreaId,
        'area-1',
      );

      notifier.setDeliveryCharge(0);

      final draft = container.read(orderDraftProvider);
      expect(draft.deliveryAreaId, isNull);
      expect(draft.deliveryAreaName, isNull);
      expect(draft.deliveryCharge, 0);
    });

    test('a hand-edited charge does not clear the area', () async {
      final container = _container(
        customers: {'03001234567': _ahmed()},
        areas: [_sector11b()],
      );
      final notifier = container.read(orderDraftProvider.notifier);

      await _typePhone(container, '03001234567');
      notifier.setDeliveryCharge(250);

      final draft = container.read(orderDraftProvider);
      expect(draft.deliveryAreaId, 'area-1');
      expect(draft.deliveryAreaName, 'Sector 11B');
      expect(draft.deliveryCharge, 250);
    });

    test('an address with an unknown area keeps the id, leaves the charge',
        () async {
      final customer = Customer(
        phone: '03001112222',
        name: 'Cathy',
        addresses: [
          CustomerAddress(id: 'a9', text: 'Far away', areaId: 'nope'),
        ],
        createdAt: _t,
        updatedAt: _t,
      );
      final container = _container(
        customers: {'03001112222': customer},
        areas: [_sector11b()],
      );

      await _typePhone(container, '03001112222');

      final draft = container.read(orderDraftProvider);
      expect(draft.deliveryAreaId, 'nope');
      expect(draft.deliveryAreaName, isNull);
      expect(draft.deliveryCharge, 0);
    });

    test('debounce: rapid typing triggers a single lookup', () async {
      final fake = _FakeCustomerRepository({'03001234567': _ahmed()});
      final container = createTestContainer(overrides: [
        customerRepositoryProvider.overrideWithValue(fake),
        deliveryAreaRepositoryProvider.overrideWithValue(
          _FakeDeliveryAreaRepository([_sector11b()]),
        ),
      ]);
      final notifier = container.read(orderDraftProvider.notifier);

      notifier.onCustomerPhoneChanged('03001234567');
      notifier.onCustomerPhoneChanged('0300123456');
      notifier.onCustomerPhoneChanged('03001234567');
      await Future.delayed(const Duration(milliseconds: 600));

      expect(fake.lookups, 1);
      expect(
        container.read(orderDraftProvider).matchedCustomerPhone,
        '03001234567',
      );
    });

    test('saveCustomer defaults to true and is settable', () {
      final container = _container();
      expect(container.read(orderDraftProvider).saveCustomer, isTrue);

      container.read(orderDraftProvider.notifier).setSaveCustomer(false);
      expect(container.read(orderDraftProvider).saveCustomer, isFalse);
    });

    test('clearDraft resets every Phase 4 field', () async {
      final container = _container(
        customers: {'03001234567': _ahmed()},
        areas: [_sector11b()],
      );
      final notifier = container.read(orderDraftProvider.notifier);

      await _typePhone(container, '03001234567');
      notifier.setSaveCustomer(false);
      notifier.setAddressDecision(AddressDecision.saveAsNewAddress);
      notifier.clearDraft();

      final draft = container.read(orderDraftProvider);
      expect(draft.matchedCustomerPhone, isNull);
      expect(draft.selectedAddressId, isNull);
      expect(draft.customerMapLink, isNull);
      expect(draft.deliveryAreaId, isNull);
      expect(draft.deliveryAreaName, isNull);
      expect(draft.deliveryNotes, isNull);
      expect(draft.saveCustomer, isTrue);
      expect(draft.addressDecision, isNull);
      expect(draft.newAddressLabel, isNull);
      expect(draft.autofilledFields, isEmpty);
      expect(draft.customerName, isNull);
      expect(draft.customerPhone, isNull);
      expect(draft.customerAddress, isNull);
    });

    test('copyWith clear flags clear the nullable customer fields', () {
      const draft = OrderDraft();
      final filled = draft.copyWith(
        matchedCustomerPhone: '03001234567',
        selectedAddressId: 'a1',
        customerMapLink: 'https://maps.test/x',
        deliveryAreaId: 'area-1',
        deliveryAreaName: 'Sector 11B',
        deliveryNotes: 'note',
      );

      final cleared = filled.copyWith(
        clearMatchedCustomerPhone: true,
        clearSelectedAddressId: true,
        clearCustomerMapLink: true,
        clearDeliveryAreaId: true,
        clearDeliveryAreaName: true,
        clearDeliveryNotes: true,
      );

      expect(cleared.matchedCustomerPhone, isNull);
      expect(cleared.selectedAddressId, isNull);
      expect(cleared.customerMapLink, isNull);
      expect(cleared.deliveryAreaId, isNull);
      expect(cleared.deliveryAreaName, isNull);
      expect(cleared.deliveryNotes, isNull);
    });
  });
}