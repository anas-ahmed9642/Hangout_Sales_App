import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hangout_sales_app/core/constants/app_routes.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_actions_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_repository_provider.dart';
import 'package:hangout_sales_app/features/customers/repositories/customer_repository.dart';
import 'package:hangout_sales_app/features/customers/screens/customer_detail_screen.dart';
import 'package:hangout_sales_app/features/customers/screens/customer_screen.dart';
import 'package:hangout_sales_app/features/customers/services/contact_launcher.dart';
import 'package:hangout_sales_app/features/delivery_areas/models/delivery_area.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_area_repository_provider.dart';
import 'package:hangout_sales_app/features/delivery_areas/repositories/delivery_area_repository.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';
import 'package:hangout_sales_app/features/orders/screens/order_detail_screen.dart';
import 'package:hangout_sales_app/features/orders/widgets/order_history_item.dart';

final _t = DateTime(2026, 10, 2);

Customer _customer({
  required String phone,
  String? name,
  bool archived = false,
  String? mergedInto,
  String? deliveryNotes,
  String? notes,
  List<CustomerAddress> addresses = const [],
  String? defaultAddressId,
}) {
  return Customer(
    phone: phone,
    name: name,
    archived: archived,
    mergedInto: mergedInto,
    deliveryNotes: deliveryNotes,
    notes: notes,
    addresses: addresses,
    defaultAddressId: defaultAddressId,
    createdAt: _t,
    updatedAt: _t,
  );
}

OrderItem _item(String flavorName, int quantity) {
  return OrderItem(
    flavorId: flavorName.toLowerCase(),
    flavorName: flavorName,
    size: PizzaSize.large,
    quantity: quantity,
    unitPrice: 1000,
  );
}

Order _order(
  String id, {
  required double total,
  PaymentStatus paymentStatus = PaymentStatus.paid,
  OrderStatus status = OrderStatus.completed,
  DateTime? createdAt,
  List<OrderItem> items = const [],
  String? customerPhone,
  String? customerAddress,
  String? deliveryAreaName,
  String? deliveryNotes,
}) {
  return Order(
    id: id,
    orderNumber: 'ORD-$id',
    createdAt: createdAt ?? _t,
    businessDate: _t,
    customerName: 'Ahmed Raza',
    customerPhone: customerPhone,
    customerAddress: customerAddress,
    deliveryAreaName: deliveryAreaName,
    deliveryNotes: deliveryNotes,
    items: items,
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: total,
    status: status,
    paymentStatus: paymentStatus,
  );
}

/// Stateful fake in the customer_screen_test.dart shape: the stream
/// emits the current snapshot on listen and re-emits after every
/// mutation, like Firestore snapshots. Write arguments are captured
/// so tests can pin what the UI alone cannot (default promotion,
/// profile fields).
class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this.customers);

  final List<Customer> customers;
  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  int saveAddressesCalls = 0;
  List<CustomerAddress>? lastSavedAddresses;
  String? lastSavedDefaultAddressId;
  final List<String> profileWrites = [];
  final List<bool> archivedWrites = [];

  List<Customer> _snapshot(bool includeArchived) => customers
      .where((customer) => includeArchived || !customer.archived)
      .toList();

  @override
  Stream<List<Customer>> streamCustomers({bool includeArchived = false}) {
    return () async* {
      yield _snapshot(includeArchived);
      yield* _changes.stream.map((_) => _snapshot(includeArchived));
    }();
  }

  @override
  Future<Customer?> getByPhone(String phone) async {
    for (final customer in customers) {
      if (customer.phone == phone) return customer;
    }
    return null;
  }

  @override
  Future<void> createCustomer(Customer customer) async {
    customers.add(customer);
    _changes.add(null);
  }

  @override
  Future<void> updateProfile(
    String phone, {
    String? name,
    String? notes,
    String? deliveryNotes,
  }) async {
    final index = customers.indexWhere((c) => c.phone == phone);
    if (index < 0) {
      throw StateError('Customer $phone does not exist.');
    }
    var updated = customers[index];
    if (name != null) {
      profileWrites.add('name=$name');
      updated = updated.copyWith(name: name);
    }
    if (notes != null) {
      profileWrites.add('notes=$notes');
      updated = updated.copyWith(notes: notes);
    }
    if (deliveryNotes != null) {
      profileWrites.add('deliveryNotes=$deliveryNotes');
      updated = updated.copyWith(deliveryNotes: deliveryNotes);
    }
    customers[index] = updated;
    _changes.add(null);
  }

  @override
  Future<void> saveAddresses(
    String phone,
    List<CustomerAddress> addresses,
    String? defaultAddressId,
  ) async {
    final index = customers.indexWhere((c) => c.phone == phone);
    if (index < 0) {
      throw StateError('Customer $phone does not exist.');
    }
    saveAddressesCalls++;
    lastSavedAddresses = addresses;
    lastSavedDefaultAddressId = defaultAddressId;
    customers[index] = customers[index].copyWith(
      addresses: addresses,
      defaultAddressId: defaultAddressId,
    );
    _changes.add(null);
  }

  @override
  Future<void> setArchived(String phone, bool archived) async {
    final index = customers.indexWhere((c) => c.phone == phone);
    if (index < 0) {
      throw StateError('Customer $phone does not exist.');
    }
    archivedWrites.add(archived);
    customers[index] = customers[index].copyWith(archived: archived);
    _changes.add(null);
  }
}

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({this.ordersByPhone = const {}});

  final Map<String, List<Order>> ordersByPhone;

  @override
  Stream<List<Order>> streamOrdersByCustomerPhone(String phone) {
    return Stream.value(ordersByPhone[phone] ?? const <Order>[]);
  }

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) {
    return Stream.value(const <Order>[]);
  }

  @override
  Future<void> createOrder(Order order, {CustomerUpsert? customerUpsert}) =>
      throw UnimplementedError();

  @override
  Future<List<Order>> searchOrdersByPhone(String phoneNumber) =>
      throw UnimplementedError();

  @override
  Future<Order?> getOrder(String orderId) => throw UnimplementedError();

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async {
    return const [];
  }

  @override
  Stream<List<Order>> streamUnpaidOrders() => throw UnimplementedError();
}

class _FakeDeliveryAreaRepository implements DeliveryAreaRepository {
  _FakeDeliveryAreaRepository(this.areas);

  final List<DeliveryArea> areas;

  @override
  Stream<List<DeliveryArea>> streamAreas({bool activeOnly = false}) {
    return Stream.value(
      activeOnly ? areas.where((area) => area.active).toList() : areas,
    );
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

final _sector11b = DeliveryArea(
  id: 'area-11b',
  name: 'Sector 11B',
  defaultCharge: 100,
  createdAt: _t,
);

final _sector4 = DeliveryArea(
  id: 'area-4',
  name: 'Sector 4',
  defaultCharge: 130,
  createdAt: _t,
);

const _phone = '03001234567';

Customer _ahmed() {
  return _customer(
    phone: _phone,
    name: 'Ahmed Raza',
    deliveryNotes: 'Gate is blue, ring twice',
    notes: 'Pays by bank transfer',
    addresses: [
      CustomerAddress(
        id: 'addr-1',
        label: 'Home',
        text: 'House 14, Street 3',
        mapLink: 'https://maps.app.goo.gl/abc123',
        areaId: 'area-11b',
      ),
      CustomerAddress(
        id: 'addr-2',
        label: 'Office',
        text: 'Office 9, Street 1',
        areaId: 'area-4',
      ),
    ],
    defaultAddressId: 'addr-1',
  );
}

List<Order> _ahmedOrders() {
  return [
    _order(
      '0102',
      total: 2300,
      createdAt: DateTime(2026, 10, 5),
      items: [_item('Fajita', 2)],
      customerPhone: _phone,
      customerAddress: 'House 14, Street 3',
      deliveryAreaName: 'Sector 11B',
      deliveryNotes: 'Gate is blue, ring twice',
    ),
    _order(
      '0101',
      total: 1850,
      paymentStatus: PaymentStatus.unpaid,
      status: OrderStatus.pending,
      createdAt: DateTime(2026, 10, 1),
      items: [_item('Fajita', 1)],
      customerPhone: _phone,
    ),
    _order(
      '0100',
      total: 9999,
      paymentStatus: PaymentStatus.unpaid,
      status: OrderStatus.cancelled,
      createdAt: DateTime(2026, 9, 30),
      items: [_item('Fajita', 9)],
      customerPhone: _phone,
    ),
  ];
}

class _Harness {
  _Harness({
    required this.customers,
    this.orders,
    this.launched = const [],
  });

  final _FakeCustomerRepository customers;
  final _FakeOrderRepository? orders;
  final List<String> launched;
}

Future<_Harness> _pumpDetail(
  WidgetTester tester, {
  required _FakeCustomerRepository customers,
  _FakeOrderRepository? orders,
  String phone = _phone,
  List<DeliveryArea> areas = const [],
}) async {
  tester.view.physicalSize = const Size(520, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final launched = <String>[];
  final launcher = ContactLauncher(
    canLaunch: (_) async => true,
    launch: (uri) async {
      launched.add(uri.toString());
      return true;
    },
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customerRepositoryProvider.overrideWithValue(customers),
        orderRepositoryProvider
            .overrideWithValue(orders ?? _FakeOrderRepository()),
        deliveryAreaRepositoryProvider
            .overrideWithValue(_FakeDeliveryAreaRepository(areas)),
        contactLauncherProvider.overrideWithValue(launcher),
      ],
      child: MaterialApp(home: CustomerDetailScreen(phone: phone)),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(customers: customers, orders: orders, launched: launched);
}

Future<void> _pumpOrderDetail(
  WidgetTester tester,
  Order order, {
  required _FakeCustomerRepository customers,
}) async {
  tester.view.physicalSize = const Size(520, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        customerRepositoryProvider.overrideWithValue(customers),
        orderRepositoryProvider.overrideWithValue(_FakeOrderRepository()),
        deliveryAreaRepositoryProvider
            .overrideWithValue(_FakeDeliveryAreaRepository(const [])),
        contactLauncherProvider.overrideWithValue(ContactLauncher()),
      ],
      child: MaterialApp(home: OrderDetailScreen(order: order)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'renders profile, contact actions, addresses, notes, stats and '
      'history', (tester) async {
    await _pumpDetail(
      tester,
      customers: _FakeCustomerRepository([_ahmed()]),
      orders: _FakeOrderRepository(ordersByPhone: {_phone: _ahmedOrders()}),
      areas: [_sector11b, _sector4],
    );

    expect(find.text('Ahmed Raza'), findsWidgets);
    expect(find.text(_phone), findsOneWidget);
    expect(find.byKey(const Key('call_button')), findsOneWidget);
    expect(find.byKey(const Key('whatsapp_button')), findsOneWidget);

    // Addresses: default first with its star, area names resolved.
    expect(find.text('Home · Sector 11B'), findsOneWidget);
    expect(find.text('House 14, Street 3'), findsOneWidget);
    expect(find.text('Office · Sector 4'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('address_addr-1')),
        matching: find.byIcon(Icons.star),
      ),
      findsOneWidget,
    );

    expect(find.text('Gate is blue, ring twice'), findsOneWidget);
    expect(find.text('Pays by bank transfer'), findsOneWidget);

    // Stats: the cancelled Rs. 9999 order contributes nothing.
    expect(find.text('2 orders · Rs. 4150 · avg Rs. 2075'), findsOneWidget);
    expect(
      find.text('Favorite: Fajita · Rs. 1850 unpaid (1 order)'),
      findsOneWidget,
    );

    // History lists every order, cancelled included. Scroll down
    // step by step: rows above the fold are asserted before later
    // rows scroll them out of the built range.
    await tester.scrollUntilVisible(find.text('ORD-0102'), 200);
    expect(find.text('ORD-0102'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ORD-0101'), 200);
    expect(find.text('ORD-0101'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ORD-0100'), 200);
    expect(find.text('ORD-0100'), findsOneWidget);
  });

  testWidgets('call opens the dialer and WhatsApp opens wa.me/92',
      (tester) async {
    final harness = await _pumpDetail(
      tester,
      customers: _FakeCustomerRepository([_ahmed()]),
    );

    await tester.tap(find.byKey(const Key('call_button')));
    await tester.pump();
    expect(harness.launched, contains('tel:03001234567'));

    await tester.tap(find.byKey(const Key('whatsapp_button')));
    await tester.pump();
    expect(harness.launched, contains('https://wa.me/923001234567'));
  });

  testWidgets('map button appears only on addresses with a link and '
      'opens Maps', (tester) async {
    final coords = _customer(
      phone: _phone,
      name: 'Ahmed Raza',
      addresses: [
        CustomerAddress(
          id: 'addr-1',
          label: 'Home',
          text: 'House 14, Street 3',
          mapLink: 'https://maps.app.goo.gl/abc123',
        ),
        CustomerAddress(
          id: 'addr-2',
          label: 'Office',
          text: 'Office 9, Street 1',
          mapLink: '24.8607, 67.0011',
        ),
        CustomerAddress(
          id: 'addr-3',
          label: 'Shop',
          text: 'Shop 4, Main Road',
        ),
      ],
      defaultAddressId: 'addr-1',
    );
    final harness = await _pumpDetail(
      tester,
      customers: _FakeCustomerRepository([coords]),
    );

    // Link and coordinates both earn a button; no link, no button.
    expect(find.byTooltip('Open in Maps'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Open in Maps').first);
    await tester.pump();
    expect(
      harness.launched,
      contains('https://maps.app.goo.gl/abc123'),
    );

    await tester.tap(find.byTooltip('Open in Maps').last);
    await tester.pump();
    expect(
      harness.launched,
      contains(
        'https://www.google.com/maps/search/?api=1&query=24.8607,67.0011',
      ),
    );
  });

  testWidgets('adding an address with a different area saves it and '
      'renders its area name', (tester) async {
    final fake = _FakeCustomerRepository([_ahmed()]);
    await _pumpDetail(
      tester,
      customers: fake,
      areas: [_sector11b, _sector4],
    );

    await tester.tap(find.byKey(const Key('add_address_button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('address_label_field')),
      'Shop',
    );
    await tester.enterText(
      find.byKey(const Key('address_text_field')),
      'Shop 4, Main Road',
    );

    await tester.tap(find.byKey(const Key('address_area_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sector 4'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('address_editor_save')));
    await tester.pumpAndSettle();

    expect(fake.saveAddressesCalls, 1);
    expect(fake.lastSavedAddresses, hasLength(3));
    final added = fake.lastSavedAddresses!.last;
    expect(added.label, 'Shop');
    expect(added.text, 'Shop 4, Main Road');
    expect(added.areaId, 'area-4');
    // Not the first address and the switch stayed off: default kept.
    expect(fake.lastSavedDefaultAddressId, 'addr-1');
    expect(find.text('Shop · Sector 4'), findsOneWidget);
    expect(find.text('Address added.'), findsOneWidget);

    // Flush the success snackbar's dismiss timer.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('editing an address updates its text', (tester) async {
    final fake = _FakeCustomerRepository([_ahmed()]);
    await _pumpDetail(tester, customers: fake, areas: [_sector11b, _sector4]);

    await tester.tap(
      find.byKey(const ValueKey('edit_address_addr-2')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('address_text_field')),
      'Office 9, Street 2',
    );
    await tester.tap(find.byKey(const Key('address_editor_save')));
    await tester.pumpAndSettle();

    expect(fake.saveAddressesCalls, 1);
    expect(fake.lastSavedAddresses![1].text, 'Office 9, Street 2');
    expect(fake.lastSavedAddresses![1].id, 'addr-2');
    expect(find.text('Office 9, Street 2'), findsOneWidget);

    // Flush the success snackbar's dismiss timer.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('removing the default address promotes the first '
      'remaining one', (tester) async {
    final fake = _FakeCustomerRepository([_ahmed()]);
    await _pumpDetail(tester, customers: fake, areas: [_sector11b, _sector4]);

    await tester.tap(
      find.byKey(const ValueKey('remove_address_addr-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(fake.saveAddressesCalls, 1);
    expect(fake.lastSavedAddresses, hasLength(1));
    expect(fake.lastSavedDefaultAddressId, 'addr-2');
    expect(find.text('House 14, Street 3'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('address_addr-2')),
        matching: find.byIcon(Icons.star),
      ),
      findsOneWidget,
    );

    // Flush the success snackbar's dismiss timer.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('removing the last address leaves a valid customer '
      'with none', (tester) async {
    final single = _customer(
      phone: _phone,
      name: 'Ahmed Raza',
      addresses: [
        CustomerAddress(
          id: 'addr-1',
          label: 'Home',
          text: 'House 14, Street 3',
        ),
      ],
      defaultAddressId: 'addr-1',
    );
    final fake = _FakeCustomerRepository([single]);
    await _pumpDetail(tester, customers: fake);

    await tester.tap(
      find.byKey(const ValueKey('remove_address_addr-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(fake.lastSavedAddresses, isEmpty);
    expect(fake.lastSavedDefaultAddressId, isNull);
    expect(find.text('No saved addresses'), findsOneWidget);
    expect(find.text('Ahmed Raza'), findsWidgets);

    // Flush the success snackbar's dismiss timer.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('make default promotes a non-default address',
      (tester) async {
    final fake = _FakeCustomerRepository([_ahmed()]);
    await _pumpDetail(tester, customers: fake, areas: [_sector11b, _sector4]);

    await tester.tap(
      find.byKey(const ValueKey('make_default_addr-2')),
    );
    await tester.pumpAndSettle();

    expect(fake.saveAddressesCalls, 1);
    expect(fake.lastSavedDefaultAddressId, 'addr-2');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('address_addr-2')),
        matching: find.byIcon(Icons.star),
      ),
      findsOneWidget,
    );
    // The promoted address no longer offers Make default.
    expect(
      find.byKey(const ValueKey('make_default_addr-2')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('make_default_addr-1')),
      findsOneWidget,
    );

    // Flush the success snackbar's dismiss timer.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('profile dialogs save name, delivery notes and '
      'internal notes', (tester) async {
    final fake = _FakeCustomerRepository([_ahmed()]);
    await _pumpDetail(tester, customers: fake, areas: [_sector11b, _sector4]);

    await tester.tap(find.byKey(const Key('edit_name_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile_edit_field')),
      'Ahmed R.',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(fake.profileWrites, contains('name=Ahmed R.'));
    expect(find.text('Ahmed R.'), findsWidgets);

    await tester.tap(
      find.byKey(const Key('edit_delivery_notes_button')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile_edit_field')),
      'Ring twice',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(fake.profileWrites, contains('deliveryNotes=Ring twice'));
    expect(find.text('Ring twice'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit_notes_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile_edit_field')),
      'Pays cash',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(fake.profileWrites, contains('notes=Pays cash'));
    expect(find.text('Pays cash'), findsOneWidget);

    // Flush the three success snackbars' dismiss timers.
    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('an invalid map link blocks saving with an inline '
      'error', (tester) async {
    final fake = _FakeCustomerRepository([_ahmed()]);
    await _pumpDetail(tester, customers: fake);

    await tester.tap(find.byKey(const Key('add_address_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('address_text_field')),
      'Shop 4, Main Road',
    );
    await tester.enterText(
      find.byKey(const Key('address_map_link_field')),
      'not a map link',
    );
    await tester.tap(find.byKey(const Key('address_editor_save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Not a recognized Google Maps link or coordinates.'),
      findsOneWidget,
    );
    expect(fake.saveAddressesCalls, 0);
    // The sheet is still open.
    expect(find.byKey(const Key('address_editor_save')), findsOneWidget);
  });

  testWidgets('archive from the app bar menu flips the menu to '
      'Restore', (tester) async {
    final fake = _FakeCustomerRepository([_ahmed()]);
    await _pumpDetail(tester, customers: fake);

    await tester.tap(find.byKey(const Key('customer_detail_menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(fake.archivedWrites, [true]);
    expect(find.text('Ahmed Raza archived.'), findsOneWidget);
    expect(find.text('This customer is archived.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('customer_detail_menu')));
    await tester.pumpAndSettle();
    expect(find.text('Restore'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(fake.archivedWrites, [true, false]);

    // Flush the snackbar dismiss timer (precedent:
    // customer_screen_test.dart).
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a merged-away customer shows the note and no menu',
      (tester) async {
    final merged = _customer(
      phone: _phone,
      name: 'Ahmed Raza',
      archived: true,
      mergedInto: '03211234567',
    );
    await _pumpDetail(tester, customers: _FakeCustomerRepository([merged]));

    expect(find.text('Merged into 03211234567'), findsOneWidget);
    expect(find.byKey(const Key('customer_detail_menu')), findsNothing);
  });

  testWidgets('an unknown phone shows the not-found state',
      (tester) async {
    await _pumpDetail(
      tester,
      customers: _FakeCustomerRepository([_ahmed()]),
      phone: '03999999999',
    );

    expect(find.text('Customer not found'), findsOneWidget);
    expect(
      find.text('This customer may have been removed.'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a history row opens Order Detail with the '
      'area, notes and map button', (tester) async {
    await _pumpDetail(
      tester,
      customers: _FakeCustomerRepository([_ahmed()]),
      orders: _FakeOrderRepository(ordersByPhone: {_phone: _ahmedOrders()}),
      areas: [_sector11b, _sector4],
    );

    await tester.scrollUntilVisible(find.text('ORD-0102'), 200);
    await tester.tap(find.text('ORD-0102'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    final detail = find.byType(OrderDetailScreen);
    // Area and delivery notes come from the order snapshot; the map
    // button resolves the customer live and matches the address by
    // text ('House 14, Street 3' -> addr-1, which has a link).
    expect(
      find.descendant(of: detail, matching: find.text('Sector 11B')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: detail,
        matching: find.text('Gate is blue, ring twice'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: detail, matching: find.byTooltip('Open in Maps')),
      findsOneWidget,
    );
  });

  testWidgets('history caps at 20 orders behind a Show all button',
      (tester) async {
    final orders = [
      for (var i = 0; i < 22; i++)
        _order(
          'n$i',
          total: 100,
          createdAt: _t.subtract(Duration(days: i)),
          customerPhone: _phone,
        ),
    ];
    await _pumpDetail(
      tester,
      customers: _FakeCustomerRepository([_ahmed()]),
      orders: _FakeOrderRepository(ordersByPhone: {_phone: orders}),
    );

    // Scroll the history section into the built range first.
    await tester.scrollUntilVisible(find.text('Show all 22 orders'), 200);
    expect(find.byType(OrderHistoryItem), findsNWidgets(20));
    expect(find.text('Show all 22 orders'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('show_all_orders_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('show_all_orders_button')));
    await tester.pumpAndSettle();

    expect(find.byType(OrderHistoryItem), findsNWidgets(22));
    expect(find.byKey(const Key('show_all_orders_button')), findsNothing);
  });

  testWidgets('order detail hides area and notes rows when absent and '
      'shows no map button for a one-off address', (tester) async {
    await _pumpOrderDetail(
      tester,
      _order(
        '0201',
        total: 1000,
        customerPhone: _phone,
        customerAddress: 'Somewhere else entirely',
      ),
      customers: _FakeCustomerRepository([_ahmed()]),
    );

    expect(find.text('Area'), findsNothing);
    expect(find.text('Delivery notes'), findsNothing);
    // The order's address matches no saved address, so no driver is
    // ever sent to a different saved address (File 16 rule).
    expect(find.byTooltip('Open in Maps'), findsNothing);
  });

  testWidgets('order detail shows no map button without a phone',
      (tester) async {
    await _pumpOrderDetail(
      tester,
      _order('0202', total: 1000),
      customers: _FakeCustomerRepository([_ahmed()]),
    );

    expect(find.byTooltip('Open in Maps'), findsNothing);
  });

  testWidgets('tapping a list row navigates to Customer Detail',
      (tester) async {
    tester.view.physicalSize = const Size(520, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      initialLocation: AppRoutes.customers,
      routes: [
        GoRoute(
          path: AppRoutes.customers,
          builder: (context, state) => const CustomerScreen(),
        ),
        GoRoute(
          path: AppRoutes.customerDetail,
          builder: (context, state) => CustomerDetailScreen(
            phone: state.pathParameters['phone']!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerRepositoryProvider
              .overrideWithValue(_FakeCustomerRepository([_ahmed()])),
          orderRepositoryProvider.overrideWithValue(_FakeOrderRepository()),
          deliveryAreaRepositoryProvider.overrideWithValue(
            _FakeDeliveryAreaRepository([_sector11b, _sector4]),
          ),
          contactLauncherProvider.overrideWithValue(ContactLauncher()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('customer_card_03001234567')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CustomerDetailScreen), findsOneWidget);
    expect(find.byKey(const Key('call_button')), findsOneWidget);
  });
}
