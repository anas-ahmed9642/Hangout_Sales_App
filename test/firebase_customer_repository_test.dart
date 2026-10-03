import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/repositories/firebase_customer_repository.dart';

final _t = DateTime(2026, 10, 2);

Customer _customer({
  String phone = '03001234567',
  String? name,
  List<CustomerAddress>? addresses,
  String? defaultAddressId,
  String? deliveryNotes,
  String? notes,
}) {
  return Customer(
    phone: phone,
    name: name,
    addresses: addresses,
    defaultAddressId: defaultAddressId,
    deliveryNotes: deliveryNotes,
    notes: notes,
    createdAt: _t,
    updatedAt: _t,
  );
}

CustomerAddress _address({
  String id = 'a1',
  String? label,
  String text = 'House 14, Street 3',
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

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseCustomerRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseCustomerRepository(firestore: firestore);
  });

  group('FirebaseCustomerRepository', () {
    test('creates a customer with the phone as document id', () async {
      await repository.createCustomer(_customer(name: 'Ahmed'));

      final snapshot = await firestore
          .collection('customers')
          .doc('03001234567')
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['phone'], '03001234567');
      expect(snapshot.data()?['name'], 'Ahmed');
      expect(snapshot.data()?['archived'], isFalse);
    });

    test('create stamps server timestamps, ignoring the model values',
        () async {
      await repository.createCustomer(_customer());

      final stored = await repository.getByPhone('03001234567');

      expect(stored, isNotNull);
      expect(stored!.createdAt, isNot(equals(_t)));
      expect(stored.updatedAt, isNot(equals(_t)));
      expect(stored.createdAt.millisecondsSinceEpoch, greaterThan(0));
    });

    test('create throws StateError when the phone already exists', () async {
      await repository.createCustomer(_customer());

      expect(
        () => repository.createCustomer(_customer(name: 'Other')),
        throwsStateError,
      );
    });

    test('create then getByPhone round-trips every field', () async {
      final address = _address(
        mapLink: 'https://www.google.com/maps/search/?api=1&query=24.8607,67.0011',
        areaId: 'area-1',
      );

      await repository.createCustomer(
        _customer(
          name: 'Ahmed Raza',
          addresses: [address],
          defaultAddressId: 'a1',
          deliveryNotes: 'Call on arrival',
          notes: 'Prefers thin crust',
        ),
      );

      final stored = await repository.getByPhone('03001234567');

      expect(stored, isNotNull);
      expect(stored!.phone, '03001234567');
      expect(stored.id, '03001234567');
      expect(stored.name, 'Ahmed Raza');
      expect(stored.addresses.length, 1);
      expect(stored.addresses.single.id, 'a1');
      expect(stored.addresses.single.label, 'Home');
      expect(stored.addresses.single.text, 'House 14, Street 3');
      expect(
        stored.addresses.single.mapLink,
        'https://www.google.com/maps/search/?api=1&query=24.8607,67.0011',
      );
      expect(stored.addresses.single.areaId, 'area-1');
      expect(stored.defaultAddressId, 'a1');
      expect(stored.deliveryNotes, 'Call on arrival');
      expect(stored.notes, 'Prefers thin crust');
      expect(stored.archived, isFalse);
      expect(stored.lastOrderAt, isNull);
    });

    test('getByPhone returns null for a missing number', () async {
      expect(await repository.getByPhone('03009876543'), isNull);
    });

    test('getByPhone finds the customer from any valid phone format',
        () async {
      await repository.createCustomer(_customer(name: 'Ahmed'));

      final stored = await repository.getByPhone('+92 300 1234567');

      expect(stored, isNotNull);
      expect(stored!.name, 'Ahmed');
    });

    test('updateProfile updates fields and bumps updatedAt', () async {
      await repository.createCustomer(_customer(name: 'Ahmed'));

      final before = await repository.getByPhone('03001234567');

      await repository.updateProfile(
        '03001234567',
        name: '  Ahmed Raza  ',
        deliveryNotes: 'Ring twice',
      );

      final after = await repository.getByPhone('03001234567');

      expect(after!.name, 'Ahmed Raza');
      expect(after.deliveryNotes, 'Ring twice');
      expect(after.notes, isNull);
      expect(
        after.updatedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before!.updatedAt.millisecondsSinceEpoch),
      );
    });

    test('updateProfile clears a field with an empty string', () async {
      await repository.createCustomer(_customer(notes: 'Internal'));

      await repository.updateProfile('03001234567', notes: '   ');

      final stored = await repository.getByPhone('03001234567');
      expect(stored!.notes, isNull);
    });

    test('updateProfile rejects an over-long name', () async {
      await repository.createCustomer(_customer());

      expect(
        () => repository.updateProfile(
          '03001234567',
          name: List.filled(61, 'A').join(),
        ),
        throwsArgumentError,
      );
    });

    test('updateProfile throws StateError for a missing customer', () async {
      expect(
        () => repository.updateProfile('03009876543', name: 'Ghost'),
        throwsStateError,
      );
    });

    test('updateProfile cannot change the phone (identity is immutable)',
        () async {
      await repository.createCustomer(_customer(name: 'Ahmed'));
      await repository.updateProfile('03001234567', name: 'Ahmed Raza');

      final stored = await repository.getByPhone('03001234567');
      expect(stored!.phone, '03001234567');
      expect(stored.name, 'Ahmed Raza');

      final all = await firestore.collection('customers').get();
      expect(all.docs.length, 1);
    });

    test('saveAddresses replaces addresses and the default', () async {
      await repository.createCustomer(
        _customer(addresses: [_address()], defaultAddressId: 'a1'),
      );

      await repository.saveAddresses(
        '03001234567',
        [_address(id: 'a1'), _address(id: 'a2', label: 'Office')],
        'a2',
      );

      final stored = await repository.getByPhone('03001234567');
      expect(stored!.addresses.map((a) => a.id).toList(), ['a1', 'a2']);
      expect(stored.addresses[1].label, 'Office');
      expect(stored.defaultAddressId, 'a2');
    });

    test('saveAddresses rejects a defaultAddressId that is not in the list',
        () async {
      await repository.createCustomer(
        _customer(addresses: [_address()], defaultAddressId: 'a1'),
      );

      expect(
        () => repository.saveAddresses(
          '03001234567',
          [_address()],
          'nope',
        ),
        throwsArgumentError,
      );
    });

    test('saveAddresses throws StateError for a missing customer', () async {
      expect(
        () => repository.saveAddresses('03009876543', [_address()], null),
        throwsStateError,
      );
    });

    test('setArchived archives and streamCustomers hides it by default',
        () async {
      await repository.createCustomer(_customer(phone: '03001234567'));
      await repository.createCustomer(_customer(phone: '03007654321'));

      await repository.setArchived('03007654321', true);

      final visible = await repository.streamCustomers().first;
      expect(visible.map((c) => c.phone).toList(), ['03001234567']);

      final all =
          await repository.streamCustomers(includeArchived: true).first;
      expect(all.length, 2);

      final archived = await repository.getByPhone('03007654321');
      expect(archived!.archived, isTrue);
    });

    test('setArchived throws StateError for a missing customer', () async {
      expect(
        () => repository.setArchived('03009876543', true),
        throwsStateError,
      );
    });

    test('saveAddresses clears the default when defaultAddressId is null',
        () async {
      await repository.createCustomer(
        _customer(addresses: [_address()], defaultAddressId: 'a1'),
      );

      await repository.saveAddresses('03001234567', [_address()], null);

      final stored = await repository.getByPhone('03001234567');
      expect(stored!.defaultAddressId, isNull);
      expect(stored.addresses.length, 1);
    });

    test('setArchived bumps updatedAt', () async {
      await repository.createCustomer(_customer());

      final before = await repository.getByPhone('03001234567');
      await repository.setArchived('03001234567', true);
      final after = await repository.getByPhone('03001234567');

      expect(after!.archived, isTrue);
      expect(
        after.updatedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before!.updatedAt.millisecondsSinceEpoch),
      );
    });

    test('updateProfile rejects over-long deliveryNotes and notes', () async {
      await repository.createCustomer(_customer());

      expect(
        () => repository.updateProfile(
          '03001234567',
          deliveryNotes: List.filled(201, 'A').join(),
        ),
        throwsArgumentError,
      );
      expect(
        () => repository.updateProfile(
          '03001234567',
          notes: List.filled(301, 'A').join(),
        ),
        throwsArgumentError,
      );
    });

    test('round-trips lastOrderAt and mergedInto', () async {
      final lastOrder = DateTime(2026, 10, 1, 19, 30);
      final customer = Customer(
        phone: '03001234567',
        mergedInto: '03007654321',
        createdAt: _t,
        updatedAt: _t,
        lastOrderAt: lastOrder,
      );

      await repository.createCustomer(customer);

      final stored = await repository.getByPhone('03001234567');
      expect(
        stored!.lastOrderAt?.millisecondsSinceEpoch,
        lastOrder.millisecondsSinceEpoch,
      );
      expect(stored.mergedInto, '03007654321');
    });

    test('streamCustomers reflects archiving in a later emission', () async {
      await repository.createCustomer(_customer(phone: '03001234567'));

      expect((await repository.streamCustomers().first).length, 1);

      await repository.setArchived('03001234567', true);

      final after = await repository.streamCustomers().first;
      expect(after, isEmpty);
    });
  });
}