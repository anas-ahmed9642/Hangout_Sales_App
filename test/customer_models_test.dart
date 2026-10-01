import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/models/customer_stats.dart';

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

void main() {
  group('Customer', () {
    test('id is always the normalized phone', () {
      final customer = _customer();
      expect(customer.id, '03001234567');
      expect(customer.phone, '03001234567');
    });

    test('rejects a non-normalized phone', () {
      expect(() => _customer(phone: '0300-1234567'), throwsArgumentError);
      expect(() => _customer(phone: '02134567890'), throwsArgumentError);
      expect(() => _customer(phone: ''), throwsArgumentError);
    });

    test('name is trimmed; blank becomes null; over 60 chars throws', () {
      expect(_customer(name: '  Ahmed Raza  ').name, 'Ahmed Raza');
      expect(_customer(name: '   ').name, isNull);
      expect(_customer().name, isNull);
      expect(
        () => _customer(name: List.filled(61, 'A').join()),
        throwsArgumentError,
      );
    });

    test('addresses may be empty', () {
      expect(_customer().addresses, isEmpty);
    });

    test('defaultAddressId must reference an entry in addresses', () {
      final address = CustomerAddress(id: 'a1', text: 'House 14');
      expect(
        () => _customer(addresses: [address], defaultAddressId: 'nope'),
        throwsArgumentError,
      );
      final ok = _customer(addresses: [address], defaultAddressId: 'a1');
      expect(ok.defaultAddressId, 'a1');
    });

    test('deliveryNotes over 200 chars and notes over 300 chars throw', () {
      expect(() => _customer(deliveryNotes: List.filled(201, 'x').join()), throwsArgumentError);
      expect(() => _customer(notes: List.filled(301, 'x').join()), throwsArgumentError);
    });

    test('copyWith clears nullable fields back to null', () {
      final address = CustomerAddress(id: 'a1', text: 'House 14');
      final customer = _customer(
        addresses: [address],
        defaultAddressId: 'a1',
        notes: 'pays by transfer',
        deliveryNotes: 'ring twice',
      );

      final cleared = customer.copyWith(
        defaultAddressId: null,
        notes: null,
        deliveryNotes: null,
      );
      expect(cleared.defaultAddressId, isNull);
      expect(cleared.notes, isNull);
      expect(cleared.deliveryNotes, isNull);

      // Omitting a field keeps its value.
      final kept = customer.copyWith();
      expect(kept.defaultAddressId, 'a1');
      expect(kept.notes, 'pays by transfer');
    });

    test('phone survives copyWith — it is immutable', () {
      final customer = _customer();
      expect(customer.copyWith(archived: true).phone, '03001234567');
      expect(customer.copyWith(archived: true).id, '03001234567');
    });
  });

  group('CustomerAddress', () {
    test('label defaults to Home', () {
      expect(CustomerAddress(id: 'a1', text: 'House 14').label, 'Home');
      expect(CustomerAddress(id: 'a1', label: '  ', text: 'x').label, 'Home');
      expect(
        CustomerAddress(id: 'a1', label: 'Office', text: 'x').label,
        'Office',
      );
    });

    test('label over 20 chars throws', () {
      expect(
        () => CustomerAddress(id: 'a1', label: List.filled(21, 'x').join(), text: 'x'),
        throwsArgumentError,
      );
    });

    test('text is required and capped at 200 chars', () {
      expect(
        () => CustomerAddress(id: 'a1', text: '   '),
        throwsArgumentError,
      );
      expect(
        () => CustomerAddress(id: 'a1', text: List.filled(201, 'x').join()),
        throwsArgumentError,
      );
    });

    test('mapLink is validated and stored raw', () {
      const link = 'https://maps.app.goo.gl/AbCdEfGh';
      final address = CustomerAddress(id: 'a1', text: 'x', mapLink: link);
      expect(address.mapLink, link);
      expect(
        () => CustomerAddress(id: 'a1', text: 'x', mapLink: 'not a link'),
        throwsArgumentError,
      );
    });

    test('create() generates an id and applies the Home default', () {
      final address = CustomerAddress.create(text: 'House 14');
      expect(address.id, isNotEmpty);
      expect(address.label, 'Home');
    });

    test('copyWith clears nullable fields with explicit null', () {
      final address = CustomerAddress(
        id: 'a1',
        text: 'x',
        mapLink: 'https://maps.app.goo.gl/AbCdEfGh',
        areaId: 'area1',
      );
      final cleared = address.copyWith(mapLink: null, areaId: null);
      expect(cleared.mapLink, isNull);
      expect(cleared.areaId, isNull);

      // Omitting a field keeps its value.
      expect(address.copyWith().mapLink, isNotNull);
      expect(address.copyWith().areaId, 'area1');
    });
  });

  group('CustomerStats', () {
    test('empty represents a customer with no orders', () {
      expect(CustomerStats.empty.orderCount, 0);
      expect(CustomerStats.empty.totalSpent, 0);
      expect(CustomerStats.empty.averageOrderValue, 0);
      expect(CustomerStats.empty.favoriteFlavor, isNull);
      expect(CustomerStats.empty.unpaidOrderCount, 0);
      expect(CustomerStats.empty.unpaidAmount, 0);
    });

    test('copyWith carries the derived values', () {
      final stats = CustomerStats.empty.copyWith(
        orderCount: 12,
        totalSpent: 27600,
        averageOrderValue: 2300,
        favoriteFlavor: 'Fajita',
        unpaidOrderCount: 1,
        unpaidAmount: 1850,
      );
      expect(stats.orderCount, 12);
      expect(stats.totalSpent, 27600);
      expect(stats.averageOrderValue, 2300);
      expect(stats.favoriteFlavor, 'Fajita');
      expect(stats.unpaidOrderCount, 1);
      expect(stats.unpaidAmount, 1850);
    });

    test('copyWith clears nullable fields with explicit null', () {
      final stats = CustomerStats.empty.copyWith(favoriteFlavor: 'Fajita');
      expect(stats.copyWith(favoriteFlavor: null).favoriteFlavor, isNull);
      expect(stats.copyWith().favoriteFlavor, 'Fajita');
    });
  });
}