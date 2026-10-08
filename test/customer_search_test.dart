import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_orders_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_repository_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_search_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customers_provider.dart';
import 'package:hangout_sales_app/features/customers/repositories/customer_repository.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

import 'helpers/test_container.dart';

final _now = DateTime(2026, 10, 8, 12);
final _t = DateTime(2026, 10, 2);

Customer _customer(
  String phone, {
  String? name,
  bool archived = false,
  String? mergedInto,
  DateTime? lastOrderAt,
}) {
  return Customer(
    phone: phone,
    name: name,
    archived: archived,
    mergedInto: mergedInto,
    createdAt: _t,
    updatedAt: _t,
    lastOrderAt: lastOrderAt,
  );
}

Order _order(String id, {OrderStatus status = OrderStatus.completed}) {
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

/// Pure-fixture customers for filterAndSortCustomers (fixed _now):
/// Ahmed (ordered 3d ago), Bilal Ahmed (18d), Sara (41d), Nadia
/// (never ordered), Zara (archived, 68d), Omar (archived + merged, 99d).
List<Customer> _fixtures() => [
      _customer(
        '03001234567',
        name: 'Ahmed Raza',
        lastOrderAt: DateTime(2026, 10, 5, 12),
      ),
      _customer(
        '03007654321',
        name: 'Bilal Ahmed',
        lastOrderAt: DateTime(2026, 9, 20, 12),
      ),
      _customer(
        '03211234567',
        name: 'Sara Khan',
        lastOrderAt: DateTime(2026, 8, 28, 12),
      ),
      _customer('03115550002', name: 'Nadia Noor'),
      _customer(
        '03009990001',
        name: 'Zara Sheikh',
        archived: true,
        lastOrderAt: DateTime(2026, 8, 1, 12),
      ),
      _customer(
        '03006660003',
        name: 'Omar Farooq',
        archived: true,
        mergedInto: '03001234567',
        lastOrderAt: DateTime(2026, 7, 1, 12),
      ),
    ];

List<String> _phones(List<Customer> customers) =>
    customers.map((customer) => customer.phone).toList();

List<Customer> _run(
  List<Customer> customers, {
  String query = '',
  CustomerFilter filter = CustomerFilter.all,
  CustomerSort sort = CustomerSort.recentFirst,
  Map<String, int> orderCounts = const {},
}) {
  return filterAndSortCustomers(
    customers,
    query: query,
    filter: filter,
    sort: sort,
    now: _now,
    orderCounts: orderCounts,
  );
}

class _FakeCustomerRepository implements CustomerRepository {
  final List<Customer> customers;

  _FakeCustomerRepository(this.customers);

  @override
  Future<Customer?> getByPhone(String phone) async {
    for (final customer in customers) {
      if (customer.phone == phone) return customer;
    }
    return null;
  }

  @override
  Stream<List<Customer>> streamCustomers({bool includeArchived = false}) {
    return Stream.value(
      customers
          .where((customer) => includeArchived || !customer.archived)
          .toList(),
    );
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

  @override
  Future<void> setArchived(String phone, bool archived) =>
      throw UnimplementedError();
}

class _FakeOrderRepository implements OrderRepository {
  final Map<String, List<Order>> ordersByPhone;

  _FakeOrderRepository(this.ordersByPhone);

  @override
  Stream<List<Order>> streamOrdersByCustomerPhone(String phone) {
    return Stream.value(ordersByPhone[phone] ?? const <Order>[]);
  }

  @override
  Future<void> createOrder(Order order, {CustomerUpsert? customerUpsert}) =>
      throw UnimplementedError();

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) =>
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

void main() {
  group('filterAndSortCustomers', () {
    test('All defaults to non-archived, most recent order first, '
        'never-ordered last', () {
      expect(_phones(_run(_fixtures())), [
        '03001234567', // Ahmed, 3d ago
        '03007654321', // Bilal, 18d ago
        '03211234567', // Sara, 41d ago
        '03115550002', // Nadia, no orders
      ]);
    });

    test('name A-Z orders by name; the never-ordered customer sorts '
        'by her name, not last', () {
      expect(
        _phones(_run(_fixtures(), sort: CustomerSort.nameAsc)),
        [
          '03001234567', // Ahmed Raza
          '03007654321', // Bilal Ahmed
          '03115550002', // Nadia Noor
          '03211234567', // Sara Khan
        ],
      );
    });

    test('name A-Z puts unnamed customers last', () {
      final customers = [
        _customer('03115550002'),
        _customer(
          '03211234567',
          name: 'Sara Khan',
          lastOrderAt: DateTime(2026, 8, 28, 12),
        ),
        _customer(
          '03001234567',
          name: 'Ahmed Raza',
          lastOrderAt: DateTime(2026, 10, 5, 12),
        ),
      ];

      expect(
        _phones(_run(customers, sort: CustomerSort.nameAsc)),
        ['03001234567', '03211234567', '03115550002'],
      );
    });

    test('partial phone 0300 matches every phone containing it', () {
      expect(_phones(_run(_fixtures(), query: '0300')), [
        '03001234567',
        '03007654321',
      ]);
    });

    test('partial phone 1234 matches across different prefixes', () {
      expect(_phones(_run(_fixtures(), query: '1234')), [
        '03001234567', // 0300-1234-567
        '03211234567', // 0321-1234-567
      ]);
    });

    test('a dashed phone query matches on its digits', () {
      expect(_phones(_run(_fixtures(), query: '0300-1234')), [
        '03001234567',
      ]);
    });

    test('name search is a case-insensitive contains', () {
      const expected = ['03001234567', '03007654321'];
      expect(_phones(_run(_fixtures(), query: 'ahmed')), expected);
      expect(_phones(_run(_fixtures(), query: 'AHMED')), expected);
      expect(_phones(_run(_fixtures(), query: '  Ahmed  ')), expected);
    });

    test('win-back keeps only non-archived customers older than '
        '30 days', () {
      // Sara (41d) is the only match: Bilal is 18d, Ahmed 3d, Nadia
      // never ordered, Zara is old enough but archived.
      expect(_phones(_run(_fixtures(), filter: CustomerFilter.winBack)), [
        '03211234567',
      ]);
    });

    test('win-back boundary: exactly 30 days is not older than 30', () {
      final boundary = [
        _customer(
          '03001110001',
          name: 'Exactly Thirty',
          lastOrderAt: DateTime(2026, 9, 8, 12),
        ),
        _customer(
          '03001110002',
          name: 'Thirty Plus A Second',
          lastOrderAt: DateTime(2026, 9, 8, 11, 59, 59),
        ),
        _customer(
          '03001110003',
          name: 'Twenty Nine',
          lastOrderAt: DateTime(2026, 9, 9, 12),
        ),
      ];

      expect(
        _phones(_run(boundary, filter: CustomerFilter.winBack)),
        ['03001110002'],
      );
    });

    test('win-back orders by order count descending, longest '
        'inactive first on a tie, ignoring the sort setting', () {
      final customers = [
        ..._fixtures(),
        _customer(
          '03007770004',
          name: 'Frequent Old',
          lastOrderAt: DateTime(2026, 8, 19, 12), // 50d
        ),
        _customer(
          '03007770005',
          name: 'Older Frequent',
          lastOrderAt: DateTime(2026, 8, 9, 12), // 60d
        ),
      ];
      const counts = {
        '03211234567': 2, // Sara
        '03007770004': 5,
        '03007770005': 5,
      };
      const expected = [
        '03007770005', // 5 orders, inactive longest
        '03007770004', // 5 orders
        '03211234567', // 2 orders
      ];

      expect(
        _phones(_run(
          customers,
          filter: CustomerFilter.winBack,
          orderCounts: counts,
        )),
        expected,
      );
      // The sort dropdown does not override the win-back order.
      expect(
        _phones(_run(
          customers,
          filter: CustomerFilter.winBack,
          sort: CustomerSort.nameAsc,
          orderCounts: counts,
        )),
        expected,
      );
    });

    test('archived slice shows only archived customers, most recent '
        'first; All never shows them even when the query matches',
        () {
      expect(_phones(_run(_fixtures(), filter: CustomerFilter.archived)), [
        '03009990001', // Zara, Aug 1
        '03006660003', // Omar, Jul 1
      ]);
      expect(
        _phones(_run(
          _fixtures(),
          filter: CustomerFilter.archived,
          query: 'omar',
        )),
        ['03006660003'],
      );
      expect(_run(_fixtures(), query: 'omar'), isEmpty);
      expect(
        _run(_fixtures(), filter: CustomerFilter.winBack, query: 'zara'),
        isEmpty,
      );
    });
  });

  group('customerSearchResultsProvider', () {
    test('defaults to non-archived customers, most recent first',
        () async {
      final now = DateTime.now();
      final container = createTestContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            _FakeCustomerRepository([
              _customer(
                '03001234567',
                name: 'Ahmed Raza',
                lastOrderAt: now.subtract(const Duration(days: 2)),
              ),
              _customer(
                '03007654321',
                name: 'Bilal Ahmed',
                lastOrderAt: now.subtract(const Duration(days: 9)),
              ),
              _customer(
                '03009990001',
                name: 'Zara Sheikh',
                archived: true,
                lastOrderAt: now.subtract(const Duration(days: 60)),
              ),
            ]),
          ),
          orderRepositoryProvider
              .overrideWithValue(_FakeOrderRepository(const {})),
        ],
      );
      // Timing contract, step 1-2: live subscription, then await the
      // first stream emission before reading any derived result.
      final subscription =
          container.listen(customerSearchResultsProvider, (_, _) {});
      await container.read(allCustomersStreamProvider.future);

      expect(_phones(subscription.read()), [
        '03001234567',
        '03007654321',
      ]);
    });

    test('query and sort state filter the streamed list in memory',
        () async {
      final now = DateTime.now();
      final container = createTestContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            _FakeCustomerRepository([
              _customer(
                '03001234567',
                name: 'Ahmed Raza',
                lastOrderAt: now.subtract(const Duration(days: 2)),
              ),
              _customer(
                '03007654321',
                name: 'Bilal Ahmed',
                lastOrderAt: now.subtract(const Duration(days: 9)),
              ),
              _customer(
                '03211234567',
                name: 'Sara Khan',
                lastOrderAt: now.subtract(const Duration(days: 4)),
              ),
            ]),
          ),
          orderRepositoryProvider
              .overrideWithValue(_FakeOrderRepository(const {})),
        ],
      );
      final subscription =
          container.listen(customerSearchResultsProvider, (_, _) {});
      await container.read(allCustomersStreamProvider.future);

      // Step 3: the results provider is watching these state
      // providers (step 1), so writing them cannot lose the value.
      container.read(customerSearchQueryProvider.notifier).state = 'ahmed';
      expect(_phones(subscription.read()), [
        '03001234567',
        '03007654321',
      ]);

      container.read(customerSortProvider.notifier).state =
          CustomerSort.nameAsc;
      container.read(customerSearchQueryProvider.notifier).state = '';
      expect(_phones(subscription.read()), [
        '03001234567', // Ahmed Raza
        '03007654321', // Bilal Ahmed
        '03211234567', // Sara Khan
      ]);
    });

    test('win-back derives order counts and orders by them; archived '
        'and recent customers stay out', () async {
      final now = DateTime.now();
      final container = createTestContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            _FakeCustomerRepository([
              _customer(
                '03001234567',
                name: 'Old One',
                lastOrderAt: now.subtract(const Duration(days: 40)),
              ),
              _customer(
                '03007654321',
                name: 'Old Two',
                lastOrderAt: now.subtract(const Duration(days: 50)),
              ),
              _customer(
                '03211234567',
                name: 'Recent',
                lastOrderAt: now.subtract(const Duration(days: 2)),
              ),
              _customer(
                '03009990001',
                name: 'Archived Old',
                archived: true,
                lastOrderAt: now.subtract(const Duration(days: 90)),
              ),
            ]),
          ),
          orderRepositoryProvider.overrideWithValue(
            _FakeOrderRepository({
              '03001234567': [
                _order('a'),
                _order('b'),
                _order('c'),
                _order('x', status: OrderStatus.cancelled),
              ],
              '03007654321': [_order('d')],
            }),
          ),
        ],
      );
      final subscription =
          container.listen(customerSearchResultsProvider, (_, _) {});
      await container.read(allCustomersStreamProvider.future);

      container.read(customerFilterProvider.notifier).state =
          CustomerFilter.winBack;

      // Step 4: await each candidate's orders on the same family
      // instances the results provider now watches, so the counts
      // are loaded (cancelled excluded: Old One counts 3, not 4).
      await container.read(customerOrdersProvider('03001234567').future);
      await container.read(customerOrdersProvider('03007654321').future);

      // Step 5: read through the live subscription.
      expect(_phones(subscription.read()), [
        '03001234567', // 3 orders — ahead of Old Two despite being newer
        '03007654321', // 1 order
      ]);
    });

    test('archived filter state shows only archived customers',
        () async {
      final now = DateTime.now();
      final container = createTestContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(
            _FakeCustomerRepository([
              _customer(
                '03001234567',
                name: 'Ahmed Raza',
                lastOrderAt: now.subtract(const Duration(days: 2)),
              ),
              _customer(
                '03009990001',
                name: 'Zara Sheikh',
                archived: true,
                lastOrderAt: now.subtract(const Duration(days: 60)),
              ),
            ]),
          ),
          orderRepositoryProvider
              .overrideWithValue(_FakeOrderRepository(const {})),
        ],
      );
      final subscription =
          container.listen(customerSearchResultsProvider, (_, _) {});
      await container.read(allCustomersStreamProvider.future);

      container.read(customerFilterProvider.notifier).state =
          CustomerFilter.archived;

      expect(_phones(subscription.read()), ['03009990001']);
    });
  });
}
