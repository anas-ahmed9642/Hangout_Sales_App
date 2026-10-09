import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_repository_provider.dart';
import 'package:hangout_sales_app/features/customers/repositories/customer_repository.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_draft.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';

Order _testOrder({
  String id = 'order-1',
  String? customerPhone = '03001234567',
}) {
  return Order(
    id: id,
    orderNumber: 'PENDING',
    createdAt: DateTime(2026, 10, 6, 18, 30),
    businessDate: DateTime(2026, 10, 6),
    customerName: 'Ahmed',
    customerPhone: customerPhone,
    customerAddress: 'House 1, Street 2',
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 100,
    total: 1100,
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
  );
}

CustomerUpsert _upsert({
  String phone = '03001234567',
  bool createIfMissing = true,
  String? name = 'Ahmed',
  String? deliveryNotes,
  CustomerAddress? address,
  AddressDecision? addressDecision,
  String? addressIdToUpdate,
  String? newAddressLabel,
}) {
  return CustomerUpsert(
    phone: phone,
    createIfMissing: createIfMissing,
    name: name,
    deliveryNotes: deliveryNotes,
    address: address,
    addressDecision: addressDecision,
    addressIdToUpdate: addressIdToUpdate,
    newAddressLabel: newAddressLabel,
  );
}

CustomerAddress _placedAddress({
  String id = 'placed-1',
  String? label,
  String text = 'House 1, Street 2',
  String? mapLink,
  String? areaId,
}) {
  return CustomerAddress(
    id: id,
    label: label,
    text: text,
    mapLink: mapLink,
    areaId: areaId,
  );
}

Future<void> _seedCustomer(
  FakeFirebaseFirestore fake, {
  String phone = '03001234567',
  String name = 'Ahmed',
  String? deliveryNotes = 'Ring twice',
  List<Map<String, dynamic>> addresses = const [],
  String? defaultAddressId,
}) async {
  await fake.collection('customers').doc(phone).set({
    'phone': phone,
    'name': name,
    'addresses': addresses,
    'defaultAddressId': defaultAddressId,
    'deliveryNotes': deliveryNotes,
    'notes': null,
    'archived': false,
    'mergedInto': null,
    'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
    'updatedAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
    'lastOrderAt': null,
  });
}

Map<String, dynamic> _savedAddress({
  required String id,
  String label = 'Home',
  String text = 'Old address',
  String? mapLink,
  String? areaId,
}) {
  return {
    'id': id,
    'label': label,
    'text': text,
    'mapLink': mapLink,
    'areaId': areaId,
  };
}

Future<bool> _docExists(
  FakeFirebaseFirestore fake,
  String collection,
  String id,
) async {
  final snapshot = await fake.collection(collection).doc(id).get();
  return snapshot.exists;
}

void main() {
  test(
    'new phone with switch ON creates the order and the customer',
    () async {
      final fake = FakeFirebaseFirestore();
      final repository = FirebaseOrderRepository(firestore: fake);
      final order = _testOrder();
      final address = _placedAddress();

      await repository.createOrder(
        order,
        customerUpsert: _upsert(
          deliveryNotes: 'Leave at gate',
          address: address,
        ),
      );

      final orderDoc =
          await fake.collection('orders').doc('order-1').get();
      expect(orderDoc.exists, isTrue);
      expect(orderDoc.data()?['orderNumber'], 'ORD-0001');

      final customerDoc =
          await fake.collection('customers').doc('03001234567').get();
      expect(customerDoc.exists, isTrue);
      final data = customerDoc.data()!;
      expect(data['name'], 'Ahmed');
      expect(data['deliveryNotes'], 'Leave at gate');
      expect(data['defaultAddressId'], address.id);
      expect((data['addresses'] as List).length, 1);
      expect(
        (data['addresses'] as List).first['text'],
        'House 1, Street 2',
      );
      expect(
        (data['lastOrderAt'] as Timestamp).toDate(),
        DateTime(2026, 10, 6, 18, 30),
      );
    },
  );

  test(
    'new phone with switch OFF saves the order but no customer',
    () async {
      final fake = FakeFirebaseFirestore();
      final repository = FirebaseOrderRepository(firestore: fake);

      await repository.createOrder(
        _testOrder(),
        customerUpsert: _upsert(createIfMissing: false),
      );

      expect(
        await _docExists(fake, 'orders', 'order-1'),
        isTrue,
      );
      expect(
        await _docExists(fake, 'customers', '03001234567'),
        isFalse,
      );
    },
  );

  test(
    'invalid phone saves the order as typed with no customer and no error',
    () async {
      final fake = FakeFirebaseFirestore();
      final repository = FirebaseOrderRepository(firestore: fake);

      // No upsert: buildCustomerUpsert returns null for invalid phones.
      await repository.createOrder(
        _testOrder(customerPhone: 'not-a-number'),
      );

      final orderDoc =
          await fake.collection('orders').doc('order-1').get();
      expect(orderDoc.data()?['customerPhone'], 'not-a-number');
      expect(
        await _docExists(fake, 'customers', 'not-a-number'),
        isFalse,
      );
    },
  );

  test(
    'existing customer gets lastOrderAt; profile stays unchanged',
    () async {
      final fake = FakeFirebaseFirestore();
      await _seedCustomer(fake);
      final repository = FirebaseOrderRepository(firestore: fake);

      await repository.createOrder(
        _testOrder(),
        // A different name/notes must NOT rewrite the saved profile
        // (Locked Decision 6).
        customerUpsert: _upsert(name: 'Changed', deliveryNotes: 'Changed'),
      );

      final data =
          (await fake.collection('customers').doc('03001234567').get())
              .data()!;
      expect(data['name'], 'Ahmed');
      expect(data['deliveryNotes'], 'Ring twice');
      expect(
        (data['lastOrderAt'] as Timestamp).toDate(),
        DateTime(2026, 10, 6, 18, 30),
      );
    },
  );

  test(
    'updateSavedAddress replaces text/link/area but keeps id and label',
    () async {
      final fake = FakeFirebaseFirestore();
      await _seedCustomer(
        fake,
        addresses: [_savedAddress(id: 'a1', text: 'Old address')],
        defaultAddressId: 'a1',
      );
      final repository = FirebaseOrderRepository(firestore: fake);

      await repository.createOrder(
        _testOrder(),
        customerUpsert: _upsert(
          address: _placedAddress(
            id: 'ignored',
            text: 'New address',
            areaId: 'area-9',
          ),
          addressDecision: AddressDecision.updateSavedAddress,
          addressIdToUpdate: 'a1',
        ),
      );

      final data =
          (await fake.collection('customers').doc('03001234567').get())
              .data()!;
      final addresses = data['addresses'] as List;
      expect(addresses.length, 1);
      expect(addresses.first['id'], 'a1');
      expect(addresses.first['label'], 'Home');
      expect(addresses.first['text'], 'New address');
      expect(addresses.first['areaId'], 'area-9');
      expect(data['defaultAddressId'], 'a1');
    },
  );

  test(
    'saveAsNewAddress appends with the sheet label',
    () async {
      final fake = FakeFirebaseFirestore();
      await _seedCustomer(
        fake,
        addresses: [_savedAddress(id: 'a1')],
        defaultAddressId: 'a1',
      );
      final repository = FirebaseOrderRepository(firestore: fake);

      await repository.createOrder(
        _testOrder(),
        customerUpsert: _upsert(
          address: _placedAddress(id: 'a2', text: 'Office address'),
          addressDecision: AddressDecision.saveAsNewAddress,
          newAddressLabel: 'Office',
        ),
      );

      final data =
          (await fake.collection('customers').doc('03001234567').get())
              .data()!;
      final addresses = data['addresses'] as List;
      expect(addresses.length, 2);
      expect(addresses.first['id'], 'a1');
      expect(addresses.last['text'], 'Office address');
      expect(addresses.last['label'], 'Office');
      expect(data['defaultAddressId'], 'a1');
    },
  );

  test(
    'useForThisOrderOnly leaves the saved addresses untouched',
    () async {
      final fake = FakeFirebaseFirestore();
      await _seedCustomer(
        fake,
        addresses: [_savedAddress(id: 'a1', text: 'Old address')],
        defaultAddressId: 'a1',
      );
      final repository = FirebaseOrderRepository(firestore: fake);

      await repository.createOrder(
        _testOrder(),
        customerUpsert: _upsert(
          address: _placedAddress(text: 'Different address'),
          addressDecision: AddressDecision.useForThisOrderOnly,
          addressIdToUpdate: 'a1',
        ),
      );

      final data =
          (await fake.collection('customers').doc('03001234567').get())
              .data()!;
      final addresses = data['addresses'] as List;
      expect(addresses.length, 1);
      expect(addresses.first['text'], 'Old address');
    },
  );

  test(
    'updateSavedAddress with an unknown id falls back to append',
    () async {
      final fake = FakeFirebaseFirestore();
      await _seedCustomer(
        fake,
        addresses: [_savedAddress(id: 'a1')],
        defaultAddressId: 'a1',
      );
      final repository = FirebaseOrderRepository(firestore: fake);

      await repository.createOrder(
        _testOrder(),
        customerUpsert: _upsert(
          address: _placedAddress(id: 'a2', text: 'Appended address'),
          addressDecision: AddressDecision.updateSavedAddress,
          addressIdToUpdate: 'gone',
        ),
      );

      final data =
          (await fake.collection('customers').doc('03001234567').get())
              .data()!;
      expect((data['addresses'] as List).length, 2);
    },
  );

  test(
    'counter increments exactly once per order, with and without upsert',
    () async {
      final fake = FakeFirebaseFirestore();
      final repository = FirebaseOrderRepository(firestore: fake);

      await repository.createOrder(
        _testOrder(id: 'order-1'),
        customerUpsert: _upsert(),
      );
      await repository.createOrder(_testOrder(id: 'order-2'));

      final first =
          (await fake.collection('orders').doc('order-1').get()).data()!;
      final second =
          (await fake.collection('orders').doc('order-2').get()).data()!;
      expect(first['orderNumber'], 'ORD-0001');
      expect(second['orderNumber'], 'ORD-0002');

      final counters =
          (await fake.collection('metadata').doc('counters').get()).data()!;
      expect(counters['order_count'], 2);
    },
  );

  test(
    'a validation failure inside the transaction writes nothing',
    () async {
      final fake = FakeFirebaseFirestore();
      final repository = FirebaseOrderRepository(firestore: fake);

      // A 61-char name fails the Customer constructor inside the
      // transaction, before any write. Atomicity is a Firestore server
      // guarantee; this asserts the repository never reaches the writes
      // with invalid model data.
      await expectLater(
        repository.createOrder(
          _testOrder(),
          customerUpsert: _upsert(name: 'x' * 61),
        ),
        throwsArgumentError,
      );

      expect(await _docExists(fake, 'orders', 'order-1'), isFalse);
      expect(await _docExists(fake, 'customers', '03001234567'), isFalse);
      expect(await _docExists(fake, 'metadata', 'counters'), isFalse);
    },
  );

  // ------------------------------------------------------------------
  // buildCustomerUpsert (notifier-level, plan 8.6)
  // ------------------------------------------------------------------

  test(
    'buildCustomerUpsert returns null for an invalid phone',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orderDraftProvider.notifier);
      notifier.setCustomerPhone('not-a-number');

      expect(notifier.buildCustomerUpsert(), isNull);
    },
  );

  test(
    'buildCustomerUpsert throws a clear error for an over-long name',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orderDraftProvider.notifier);
      notifier.setCustomerPhone('03001234567');
      notifier.setCustomerName('x' * 61);

      expect(() => notifier.buildCustomerUpsert(), throwsArgumentError);
    },
  );

  test(
    'buildCustomerUpsert carries the switch, decision and label',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orderDraftProvider.notifier);
      notifier.setCustomerPhone('+92 300 1234567');
      notifier.setSaveCustomer(false);
      notifier.setAddressDecision(AddressDecision.saveAsNewAddress);
      notifier.setNewAddressLabel('Office');
      notifier.setCustomerAddress('Some address');

      final upsert = notifier.buildCustomerUpsert();
      expect(upsert?.phone, '03001234567');
      expect(upsert?.createIfMissing, isFalse);
      expect(upsert?.addressDecision, AddressDecision.saveAsNewAddress);
      expect(upsert?.newAddressLabel, 'Office');
      expect(upsert?.address?.text, 'Some address');
    },
  );

  test(
    'buildCustomerUpsert drops an unrecognized map link from the address',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orderDraftProvider.notifier);
      notifier.setCustomerPhone('03001234567');
      notifier.setCustomerAddress('Some address');
      notifier.setCustomerMapLink('not a link');

      final upsert = notifier.buildCustomerUpsert();
      expect(upsert?.address?.mapLink, isNull);
    },
  );

  // ------------------------------------------------------------------
  // addressDecisionNeeded (notifier-level, plan 8.4)
  // ------------------------------------------------------------------

  test(
    'addressDecisionNeeded fires only when the address differs',
    () async {
      final address = CustomerAddress(
        id: 'a1',
        label: 'Home',
        text: 'Old address',
      );
      final stub = _StubCustomerRepository()
        ..stubCustomer = Customer(
          phone: '03001234567',
          name: 'Ahmed',
          addresses: [address],
          defaultAddressId: 'a1',
          createdAt: DateTime(2026, 10, 1),
          updatedAt: DateTime(2026, 10, 1),
        );

      final container = ProviderContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(stub),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(orderDraftProvider.notifier);
      notifier.onCustomerPhoneChanged('03001234567');
      // Debounce (400 ms) + lookup + autofill.
      await Future.delayed(const Duration(milliseconds: 700));

      // Autofill applied the saved address: no sheet.
      expect(await notifier.addressDecisionNeeded(), isNull);

      // The cashier edits the address: the sheet is needed.
      notifier.setCustomerAddress('New address');
      final needed = await notifier.addressDecisionNeeded();
      expect(needed?.id, 'a1');

      // After the sheet answers, it is not asked again.
      notifier.setAddressDecision(AddressDecision.useForThisOrderOnly);
      expect(await notifier.addressDecisionNeeded(), isNull);
    },
  );

  test(
    'addressDecisionNeeded never throws when the lookup fails',
    () async {
      final stub = _StubCustomerRepository()..throwOnLookup = true;

      final container = ProviderContainer(
        overrides: [
          customerRepositoryProvider.overrideWithValue(stub),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(orderDraftProvider.notifier);
      notifier.onCustomerPhoneChanged('03001234567');
      await Future.delayed(const Duration(milliseconds: 700));

      expect(await notifier.addressDecisionNeeded(), isNull);
    },
  );

  test(
    'no phone at all saves the order, creates no customer, still counts',
    () async {
      final fake = FakeFirebaseFirestore();
      final repository = FirebaseOrderRepository(firestore: fake);

      // No upsert: a walk-in order has no phone to look a customer
      // up by (Locked Decision 3), but the counter still advances.
      await repository.createOrder(_testOrder(customerPhone: null));

      final orderDoc =
          await fake.collection('orders').doc('order-1').get();
      expect(orderDoc.exists, isTrue);
      expect(orderDoc.data()?['customerPhone'], isNull);
      expect(orderDoc.data()?['orderNumber'], 'ORD-0001');

      final customers = await fake.collection('customers').get();
      expect(customers.docs, isEmpty);
    },
  );

  test(
    'buildCustomerUpsert returns null when no phone was entered',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(orderDraftProvider.notifier);

      // Nothing typed yet.
      expect(notifier.buildCustomerUpsert(), isNull);

      notifier.setCustomerPhone('');
      expect(notifier.buildCustomerUpsert(), isNull);

      notifier.setCustomerPhone('   ');
      expect(notifier.buildCustomerUpsert(), isNull);
    },
  );
}

/// Stub for the notifier-level tests: only getByPhone is functional.
class _StubCustomerRepository implements CustomerRepository {
  Customer? stubCustomer;
  bool throwOnLookup = false;

  @override
  Future<Customer?> getByPhone(String phone) async {
    if (throwOnLookup) {
      throw StateError('network down');
    }
    return stubCustomer;
  }

  @override
  Stream<List<Customer>> streamCustomers({bool includeArchived = false}) =>
      const Stream.empty();

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
