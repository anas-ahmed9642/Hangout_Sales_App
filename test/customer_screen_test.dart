import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hangout_sales_app/core/constants/app_routes.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_repository_provider.dart';
import 'package:hangout_sales_app/features/customers/repositories/customer_repository.dart';
import 'package:hangout_sales_app/features/customers/screens/customer_screen.dart';
import 'package:hangout_sales_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:hangout_sales_app/features/delivery_areas/models/delivery_area.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_area_repository_provider.dart';
import 'package:hangout_sales_app/features/delivery_areas/repositories/delivery_area_repository.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

final _t = DateTime(2026, 10, 2);

Customer _customer({
  required String phone,
  String? name,
  bool archived = false,
  String? mergedInto,
  DateTime? lastOrderAt,
  List<CustomerAddress> addresses = const [],
  String? defaultAddressId,
}) {
  return Customer(
    phone: phone,
    name: name,
    archived: archived,
    mergedInto: mergedInto,
    addresses: addresses,
    defaultAddressId: defaultAddressId,
    createdAt: _t,
    updatedAt: _t,
    lastOrderAt: lastOrderAt,
  );
}

Order _order(
  String id, {
  OrderStatus status = OrderStatus.completed,
}) {
  return Order(
    id: id,
    orderNumber: 'ORD-$id',
    createdAt: _t,
    businessDate: _t,
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: 1000,
    status: status,
    paymentStatus: PaymentStatus.paid,
  );
}

/// Stateful fake: the customer stream emits the current snapshot on
/// listen and re-emits after every setArchived, like Firestore
/// snapshots. [hang] never emits (loading); [error] always errors.
class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this.customers, {this.error, this.hang = false});

  final List<Customer> customers;
  final Object? error;
  final bool hang;
  int streamCalls = 0;
  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  List<Customer> _snapshot(bool includeArchived) => customers
      .where((customer) => includeArchived || !customer.archived)
      .toList();

  Stream<List<Customer>> _snapshots(bool includeArchived) async* {
    yield _snapshot(includeArchived);
    yield* _changes.stream.map((_) => _snapshot(includeArchived));
  }

  @override
  Stream<List<Customer>> streamCustomers({bool includeArchived = false}) {
    streamCalls++;
    if (hang) {
      return StreamController<List<Customer>>().stream;
    }
    final error = this.error;
    if (error != null) {
      return Stream<List<Customer>>.error(error);
    }
    return _snapshots(includeArchived);
  }

  @override
  Future<Customer?> getByPhone(String phone) async {
    for (final customer in customers) {
      if (customer.phone == phone) return customer;
    }
    return null;
  }

  @override
  Future<void> setArchived(String phone, bool archived) async {
    final index = customers.indexWhere((c) => c.phone == phone);
    if (index < 0) {
      throw StateError('Customer $phone does not exist.');
    }
    customers[index] = customers[index].copyWith(
      archived: archived,
      updatedAt: DateTime.now(),
    );
    _changes.add(null);
  }

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
}

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({
    this.ordersByPhone = const {},
  });

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
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) =>
      throw UnimplementedError();

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

class _FakeExpenseRepository implements ExpenseRepository {
  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) {
    return Stream.value(const <Expense>[]);
  }

  @override
  Future<void> createExpense(Expense expense) => throw UnimplementedError();

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      throw UnimplementedError();

  @override
  Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      throw UnimplementedError();

  @override
  Future<Expense?> getExpense(String expenseId) =>
      throw UnimplementedError();

  @override
  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> voidExpense(
    String expenseId, {
    required String changeReason,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getExpenseHistory(String expenseId) =>
      throw UnimplementedError();
}

List<Override> _overrides({
  required _FakeCustomerRepository customers,
  _FakeOrderRepository? orders,
  List<DeliveryArea> areas = const [],
}) {
  return [
    customerRepositoryProvider.overrideWithValue(customers),
    orderRepositoryProvider
        .overrideWithValue(orders ?? _FakeOrderRepository()),
    deliveryAreaRepositoryProvider
        .overrideWithValue(_FakeDeliveryAreaRepository(areas)),
  ];
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeCustomerRepository customers,
  _FakeOrderRepository? orders,
  List<DeliveryArea> areas = const [],
}) async {
  tester.view.physicalSize = const Size(520, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(
        customers: customers,
        orders: orders,
        areas: areas,
      ),
      child: const MaterialApp(home: CustomerScreen()),
    ),
  );
}

Customer _ahmed({DateTime? lastOrderAt, bool withAddress = true}) {
  return _customer(
    phone: '03001234567',
    name: 'Ahmed Raza',
    lastOrderAt: lastOrderAt,
    addresses: withAddress
        ? [
            CustomerAddress(
              id: 'addr-1',
              label: 'Home',
              text: 'House 14, Street 3',
              areaId: 'area-11b',
            ),
          ]
        : const [],
    defaultAddressId: withAddress ? 'addr-1' : null,
  );
}

final _sector11b = DeliveryArea(
  id: 'area-11b',
  name: 'Sector 11B',
  defaultCharge: 100,
  createdAt: _t,
);

void main() {
  testWidgets(
      'shows name, phone, default-address area and last-order line',
      (tester) async {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    await _pumpScreen(
      tester,
      customers: _FakeCustomerRepository([
        _ahmed(lastOrderAt: threeDaysAgo),
        _customer(phone: '03115550002'),
      ]),
      areas: [_sector11b],
    );
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Raza'), findsOneWidget);
    expect(find.text('03001234567'), findsOneWidget);
    expect(
      find.text('Sector 11B · last order 3 days ago'),
      findsOneWidget,
    );
    // An unnamed customer is titled "Unnamed customer"; her phone
    // sits on the header line and her subtitle is just the
    // order-history line.
    expect(find.text('Unnamed customer'), findsOneWidget);
    expect(find.text('03115550002'), findsOneWidget);
    expect(find.text('No orders yet'), findsOneWidget);
  });

  testWidgets('search filters by partial phone and by name; clear '
      'restores the list', (tester) async {
    final now = DateTime.now();
    await _pumpScreen(
      tester,
      customers: _FakeCustomerRepository([
        _ahmed(lastOrderAt: now.subtract(const Duration(days: 3))),
        _customer(
          phone: '03211234567',
          name: 'Sara Khan',
          lastOrderAt: now.subtract(const Duration(days: 6)),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('customer_search_field')),
      '0300',
    );
    await tester.pump();
    expect(find.text('Ahmed Raza'), findsOneWidget);
    expect(find.text('Sara Khan'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Sara Khan'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('customer_search_field')),
      'sara',
    );
    await tester.pump();
    expect(find.text('Sara Khan'), findsOneWidget);
    expect(find.text('Ahmed Raza'), findsNothing);
  });

  testWidgets('win-back shows only 30d+ customers, ordered by order '
      'count, with the counts on the rows', (tester) async {
    final now = DateTime.now();
    final sara = _customer(
      phone: '03211234567',
      name: 'Sara Khan',
      lastOrderAt: now.subtract(const Duration(days: 41)),
    );
    final waqas = _customer(
      phone: '03008880001',
      name: 'Waqas Ali',
      lastOrderAt: now.subtract(const Duration(days: 50)),
    );
    await _pumpScreen(
      tester,
      customers: _FakeCustomerRepository([
        _ahmed(
          lastOrderAt: now.subtract(const Duration(days: 3)),
          withAddress: false,
        ),
        sara,
        waqas,
      ]),
      orders: _FakeOrderRepository(
        ordersByPhone: {
          '03211234567': [
            _order('a'),
            _order('b'),
            _order('c'),
            _order('x', status: OrderStatus.cancelled),
          ],
          '03008880001': [_order('d')],
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Win-back 30d+'));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Raza'), findsNothing);
    expect(find.text('Sara Khan'), findsOneWidget);
    expect(find.text('Waqas Ali'), findsOneWidget);
    // Cancelled orders are excluded from the derived count.
    expect(find.textContaining('3 orders'), findsOneWidget);
    expect(find.textContaining('1 order'), findsOneWidget);
    // 3 orders outranks 1, even though Waqas has been inactive longer.
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('customer_card_03211234567'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('customer_card_03008880001'))).dy,
      ),
    );
  });

  testWidgets('archive from the row menu hides the customer; restore '
      'from Archived brings it back', (tester) async {
    final now = DateTime.now();
    await _pumpScreen(
      tester,
      customers: _FakeCustomerRepository([
        _ahmed(
          lastOrderAt: now.subtract(const Duration(days: 3)),
          withAddress: false,
        ),
        _customer(
          phone: '03211234567',
          name: 'Sara Khan',
          lastOrderAt: now.subtract(const Duration(days: 6)),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('customer_card_03001234567')),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Ahmed Raza'), findsNothing);
    expect(find.text('Ahmed Raza archived.'), findsOneWidget);
    expect(find.text('Sara Khan'), findsOneWidget);

    // The chips scroll horizontally and the rightmost chip can sit
    // under the sort control at test-surface widths; scroll it fully
    // into view before tapping.
    await tester.ensureVisible(
      find.widgetWithText(FilterChip, 'Archived'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed Raza'), findsOneWidget);
    expect(find.text('Sara Khan'), findsNothing);

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('customer_card_03001234567')),
        matching: find.byIcon(Icons.more_vert),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    // The chips scrolled right above; scroll back before tapping All.
    await tester.ensureVisible(
      find.widgetWithText(FilterChip, 'All'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text('Ahmed Raza'), findsOneWidget);
    expect(find.text('Sara Khan'), findsOneWidget);

    // Flush the restore snackbar's dismiss timer so the test does
    // not end with a pending fake-async Timer.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('the archived slice shows the merged-into note',
      (tester) async {
    await _pumpScreen(
      tester,
      customers: _FakeCustomerRepository([
        _customer(
          phone: '03006660003',
          name: 'Omar Farooq',
          archived: true,
          mergedInto: '03001234567',
          lastOrderAt: DateTime.now().subtract(const Duration(days: 99)),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(FilterChip, 'Archived'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Archived'));
    await tester.pumpAndSettle();

    expect(find.text('Omar Farooq'), findsOneWidget);
    expect(find.text('Merged into 03001234567'), findsOneWidget);
    // A merged-away customer has no archive/restore menu: restoring
    // it would resurrect a merged identity into the active list.
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('win-back and archived slices have their own empty '
      'states', (tester) async {
    await _pumpScreen(
      tester,
      customers: _FakeCustomerRepository([
        _ahmed(
          lastOrderAt: DateTime.now().subtract(const Duration(days: 3)),
          withAddress: false,
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Win-back 30d+'));
    await tester.pumpAndSettle();
    expect(find.text('No customers to win back'), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(FilterChip, 'Archived'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Archived'));
    await tester.pumpAndSettle();
    expect(find.text('No archived customers'), findsOneWidget);
  });

  testWidgets('no customers at all shows the friendly empty state',
      (tester) async {
    await _pumpScreen(tester, customers: _FakeCustomerRepository([]));
    await tester.pumpAndSettle();

    expect(find.text('No customers yet'), findsOneWidget);
    expect(
      find.text('Customers saved from orders will appear here.'),
      findsOneWidget,
    );
  });

  testWidgets('a search with no matches shows the no-results state',
      (tester) async {
    await _pumpScreen(
      tester,
      customers: _FakeCustomerRepository([
        _ahmed(lastOrderAt: DateTime.now().subtract(const Duration(days: 3))),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('customer_search_field')),
      'zzz',
    );
    await tester.pump();

    expect(find.text('No customers found'), findsOneWidget);
    expect(find.text('Ahmed Raza'), findsNothing);
  });

  testWidgets('a stream error shows the error state and retry '
      're-subscribes', (tester) async {
    final fake = _FakeCustomerRepository(
      [],
      error: StateError('boom'),
    );
    await _pumpScreen(tester, customers: fake);
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load customers"), findsOneWidget);
    expect(find.text('Bad state: boom'), findsOneWidget);
    expect(fake.streamCalls, 1);

    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(fake.streamCalls, 2);
    expect(find.text("Couldn't load customers"), findsOneWidget);
  });

  testWidgets('a never-emitting stream shows the loading indicator',
      (tester) async {
    await _pumpScreen(
      tester,
      customers: _FakeCustomerRepository([], hang: true),
    );
    // One frame only: the stream has not emitted, and pumpAndSettle
    // would time out on the animated spinner.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const Key('customer_search_field')), findsOneWidget);
  });

  testWidgets('the dashboard Customers tile opens the customers '
      'screen', (tester) async {
    tester.view.physicalSize = const Size(520, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.customers,
          builder: (context, state) => const CustomerScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._overrides(
            customers: _FakeCustomerRepository([
              _ahmed(
                lastOrderAt:
                    DateTime.now().subtract(const Duration(days: 3)),
              ),
            ]),
            areas: [_sector11b],
          ),
          expenseRepositoryProvider
              .overrideWithValue(_FakeExpenseRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // No scrollUntilVisible here: the dashboard carries two
    // Scrollables (body + the shrink-wrapped overview GridView), so
    // the helper cannot pick one. The tall surface puts the tile on
    // screen directly.
    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomerScreen), findsOneWidget);
    expect(
      find.byKey(const Key('customer_search_field')),
      findsOneWidget,
    );
    expect(find.text('Ahmed Raza'), findsOneWidget);
  });
}
