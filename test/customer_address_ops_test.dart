import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/services/customer_address_ops.dart';

final _t = DateTime(2026, 10, 2);

CustomerAddress _address(String id, String text) =>
    CustomerAddress(id: id, label: id, text: text);

Customer _customer({
  List<CustomerAddress> addresses = const [],
  String? defaultAddressId,
}) {
  return Customer(
    phone: '03001234567',
    name: 'Ahmed Raza',
    addresses: addresses,
    defaultAddressId: defaultAddressId,
    createdAt: _t,
    updatedAt: _t,
  );
}

List<String> _ids(AddressListUpdate update) =>
    update.addresses.map((address) => address.id).toList();

void main() {
  group('effectiveDefaultAddressId', () {
    test('null when there are no addresses', () {
      expect(effectiveDefaultAddressId(_customer()), isNull);
    });

    test('uses the explicit default', () {
      final customer = _customer(
        addresses: [_address('a', 'One'), _address('b', 'Two')],
        defaultAddressId: 'b',
      );
      expect(effectiveDefaultAddressId(customer), 'b');
    });

    test('falls back to the first address when no explicit default',
        () {
      final customer = _customer(
        addresses: [_address('a', 'One'), _address('b', 'Two')],
      );
      expect(effectiveDefaultAddressId(customer), 'a');
    });
  });

  group('addAddress', () {
    test('the first address becomes the default', () {
      final update = addAddress(
        _customer(),
        _address('a', 'One'),
        makeDefault: false,
      );
      expect(_ids(update), ['a']);
      expect(update.defaultAddressId, 'a');
    });

    test('a later address keeps the existing default', () {
      final customer = _customer(
        addresses: [_address('a', 'One')],
        defaultAddressId: 'a',
      );
      final update =
          addAddress(customer, _address('b', 'Two'), makeDefault: false);
      expect(_ids(update), ['a', 'b']);
      expect(update.defaultAddressId, 'a');
    });

    test('makeDefault moves the default to the new address', () {
      final customer = _customer(
        addresses: [_address('a', 'One')],
        defaultAddressId: 'a',
      );
      final update =
          addAddress(customer, _address('b', 'Two'), makeDefault: true);
      expect(update.defaultAddressId, 'b');
    });
  });

  group('replaceAddress', () {
    test('replaces by id and keeps the default', () {
      final customer = _customer(
        addresses: [_address('a', 'One'), _address('b', 'Two')],
        defaultAddressId: 'a',
      );
      final update = replaceAddress(
        customer,
        _address('b', 'Two edited'),
        makeDefault: false,
      );
      expect(_ids(update), ['a', 'b']);
      expect(update.addresses.last.text, 'Two edited');
      expect(update.defaultAddressId, 'a');
    });

    test('makeDefault promotes the edited address', () {
      final customer = _customer(
        addresses: [_address('a', 'One'), _address('b', 'Two')],
        defaultAddressId: 'a',
      );
      final update = replaceAddress(
        customer,
        _address('b', 'Two'),
        makeDefault: true,
      );
      expect(update.defaultAddressId, 'b');
    });
  });

  test('setDefaultAddress changes only the default', () {
    final customer = _customer(
      addresses: [_address('a', 'One'), _address('b', 'Two')],
      defaultAddressId: 'a',
    );
    final update = setDefaultAddress(customer, 'b');
    expect(_ids(update), ['a', 'b']);
    expect(update.defaultAddressId, 'b');
  });

  group('removeAddress', () {
    test('removing a non-default address keeps the default', () {
      final customer = _customer(
        addresses: [_address('a', 'One'), _address('b', 'Two')],
        defaultAddressId: 'a',
      );
      final update = removeAddress(customer, 'b');
      expect(_ids(update), ['a']);
      expect(update.defaultAddressId, 'a');
    });

    test('removing the default promotes the first remaining address',
        () {
      final customer = _customer(
        addresses: [
          _address('a', 'One'),
          _address('b', 'Two'),
          _address('c', 'Three'),
        ],
        defaultAddressId: 'a',
      );
      final update = removeAddress(customer, 'a');
      expect(_ids(update), ['b', 'c']);
      expect(update.defaultAddressId, 'b');
    });

    test('removing the implicit default (no explicit one) promotes '
        'the next', () {
      final customer = _customer(
        addresses: [_address('a', 'One'), _address('b', 'Two')],
      );
      final update = removeAddress(customer, 'a');
      expect(_ids(update), ['b']);
      expect(update.defaultAddressId, 'b');
    });

    test('removing the last address leaves an empty list and no '
        'default', () {
      final customer = _customer(
        addresses: [_address('a', 'One')],
        defaultAddressId: 'a',
      );
      final update = removeAddress(customer, 'a');
      expect(update.addresses, isEmpty);
      expect(update.defaultAddressId, isNull);
    });

    test('the update is always a valid customer', () {
      final customer = _customer(
        addresses: [_address('a', 'One'), _address('b', 'Two')],
        defaultAddressId: 'a',
      );
      final update = removeAddress(customer, 'a');
      // The Customer constructor enforces defaultAddressId integrity.
      expect(
        () => customer.copyWith(
          addresses: update.addresses,
          defaultAddressId: update.defaultAddressId,
        ),
        returnsNormally,
      );
    });
  });
}
