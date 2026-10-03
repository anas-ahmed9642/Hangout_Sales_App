import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_repository_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customers_provider.dart';
import 'package:hangout_sales_app/features/customers/repositories/customer_repository.dart';

final _t = DateTime(2026, 10, 2);

Customer _customer(String phone, {String? name, bool archived = false}) {
  return Customer(
    phone: phone,
    name: name,
    archived: archived,
    createdAt: _t,
    updatedAt: _t,
  );
}

class _FakeCustomerRepository implements CustomerRepository {
  final List<Customer> customers;

  _FakeCustomerRepository(this.customers);

  @override
  Future<Customer?> getByPhone(String phone) async {
    for (final customer in customers) {
      if (customer.phone == phone) {
        return customer;
      }
    }
    return null;
  }

  @override
  Stream<List<Customer>> streamCustomers({bool includeArchived = false}) async* {
    yield customers
        .where((customer) => includeArchived || !customer.archived)
        .toList();
  }

  @override
  Future<void> createCustomer(Customer customer) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile(
    String phone, {
    String? name,
    String? notes,
    String? deliveryNotes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveAddresses(
    String phone,
    List<CustomerAddress> addresses,
    String? defaultAddressId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> setArchived(String phone, bool archived) {
    throw UnimplementedError();
  }
}

ProviderContainer _container(_FakeCustomerRepository fake) {
  final container = ProviderContainer(
    overrides: [
      customerRepositoryProvider.overrideWithValue(fake),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('customerByPhoneProvider', () {
    test('returns the customer for a known phone', () async {
      final container = _container(_FakeCustomerRepository([
        _customer('03001234567', name: 'Ahmed'),
      ]));

      final customer = await container.read(
        customerByPhoneProvider('03001234567').future,
      );

      expect(customer?.name, 'Ahmed');
    });

    test('returns null for an unknown phone', () async {
      final container = _container(_FakeCustomerRepository([]));

      final customer = await container.read(
        customerByPhoneProvider('03009999999').future,
      );

      expect(customer, isNull);
    });
  });

  group('customersStreamProvider', () {
    test('excludes archived customers by default', () async {
      final container = _container(_FakeCustomerRepository([
        _customer('03001234567', name: 'Ahmed'),
        _customer('03007654321', name: 'Bilal', archived: true),
      ]));

      final customers = await container.read(customersStreamProvider.future);

      expect(
        customers.map((customer) => customer.phone).toList(),
        ['03001234567'],
      );
    });

    test('is empty when no customers exist', () async {
      final container = _container(_FakeCustomerRepository([]));

      final customers = await container.read(customersStreamProvider.future);

      expect(customers, isEmpty);
    });
  });
}