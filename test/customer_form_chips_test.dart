import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_repository_provider.dart';
import 'package:hangout_sales_app/features/customers/repositories/customer_repository.dart';
import 'package:hangout_sales_app/features/delivery_areas/models/delivery_area.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_area_repository_provider.dart';
import 'package:hangout_sales_app/features/delivery_areas/repositories/delivery_area_repository.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';
import 'package:hangout_sales_app/features/orders/widgets/customer_form.dart';

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
        areaId: 'area-1',
      ),
      CustomerAddress(
        id: 'a2',
        label: 'Office',
        text: 'Office 9, Main Boulevard',
      ),
    ],
    defaultAddressId: 'a1',
    createdAt: _t,
    updatedAt: _t,
  );
}

class _FakeCustomerRepository implements CustomerRepository {
  final Map<String, Customer> customers;

  _FakeCustomerRepository(this.customers);

  @override
  Future<Customer?> getByPhone(String phone) async => customers[phone];

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
  @override
  Stream<List<DeliveryArea>> streamAreas({bool activeOnly = false}) async* {
    yield [
      DeliveryArea(
        id: 'area-1',
        name: 'Sector 11B',
        defaultCharge: 180,
        createdAt: _t,
      ),
    ];
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

ProviderContainer _container() {
  return createTestContainer(overrides: [
    customerRepositoryProvider.overrideWithValue(
      _FakeCustomerRepository({'03001234567': _ahmed()}),
    ),
    deliveryAreaRepositoryProvider.overrideWithValue(
      _FakeDeliveryAreaRepository(),
    ),
  ]);
}

Future<void> _pumpForm(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: CustomerForm()),
      ),
    ),
  );
  await tester.pump();
}

/// Types a phone and lets the 400 ms debounce elapse. Widget tests run
/// in a FakeAsync zone, so the debounce timer fires on pump(duration).
Future<void> _typePhone(WidgetTester tester, String phone) async {
  await tester.enterText(find.byType(TextField).at(0), phone);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('address chips appear for a matched multi-address customer',
      (tester) async {
    final container = _container();
    await _pumpForm(tester, container);

    expect(find.byType(ChoiceChip), findsNothing);

    await _typePhone(tester, '03001234567');

    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(find.text('Home · Sector 11B'), findsOneWidget);
    expect(find.text('Office'), findsOneWidget);
    // The name controller was synced by the autofill.
    expect(find.text('Ahmed Raza'), findsOneWidget);
  });

  testWidgets('tapping a chip switches the applied address', (tester) async {
    final container = _container();
    await _pumpForm(tester, container);

    await _typePhone(tester, '03001234567');
    expect(find.byType(ChoiceChip), findsNWidgets(2));

    await tester.tap(find.text('Office'));
    await tester.pump();

    final draft = container.read(orderDraftProvider);
    expect(draft.selectedAddressId, 'a2');
    expect(draft.customerAddress, 'Office 9, Main Boulevard');
  });

  testWidgets('discard clears the autofilled controllers', (tester) async {
    final container = _container();
    await _pumpForm(tester, container);

    await _typePhone(tester, '03001234567');
    expect(find.text('Ahmed Raza'), findsOneWidget);

    container.read(orderDraftProvider.notifier).clearDraft();
    await tester.pump();

    expect(find.text('Ahmed Raza'), findsNothing);
    expect(find.text('03001234567'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('a bad map link shows an inline message without blocking save',
      (tester) async {
    final container = _container();
    await _pumpForm(tester, container);

    // Field order: phone, name, address, location link, notes.
    await tester.enterText(find.byType(TextField).at(3), 'not a link');
    await tester.pump();

    expect(
      find.text('Not a recognized Google Maps link or coordinates.'),
      findsOneWidget,
    );
    // The message is decoration-only: nothing about saving changes.
    expect(
      container.read(orderDraftProvider).customerMapLink,
      'not a link',
    );
  });

  testWidgets(
      'a single saved address fills the fields with no chooser chips',
      (tester) async {
    final singleAddressCustomer = Customer(
      phone: '03001234567',
      name: 'Ahmed Raza',
      addresses: [
        CustomerAddress(
          id: 'a1',
          label: 'Home',
          text: 'House 14, Street 3',
          areaId: 'area-1',
        ),
      ],
      defaultAddressId: 'a1',
      createdAt: _t,
      updatedAt: _t,
    );
    final container = createTestContainer(overrides: [
      customerRepositoryProvider.overrideWithValue(
        _FakeCustomerRepository({'03001234567': singleAddressCustomer}),
      ),
      deliveryAreaRepositoryProvider.overrideWithValue(
        _FakeDeliveryAreaRepository(),
      ),
    ]);
    await _pumpForm(tester, container);

    await _typePhone(tester, '03001234567');

    // One address -> no chooser (plan 8.2), just the filled fields.
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Ahmed Raza'), findsOneWidget);
    expect(find.text('House 14, Street 3'), findsOneWidget);

    final draft = container.read(orderDraftProvider);
    expect(draft.selectedAddressId, 'a1');
    expect(draft.customerAddress, 'House 14, Street 3');
    expect(draft.deliveryAreaId, 'area-1');
    expect(draft.deliveryCharge, 180);
  });
}