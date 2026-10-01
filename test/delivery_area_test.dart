import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/delivery_areas/models/delivery_area.dart';

final _t = DateTime(2026, 10, 2);

void main() {
  group('DeliveryArea', () {
    test('stores the area state; active defaults to true', () {
      final area = DeliveryArea(
        id: 'a1',
        name: 'Sector 5C/1',
        defaultCharge: 150,
        createdAt: _t,
      );
      expect(area.id, 'a1');
      expect(area.name, 'Sector 5C/1');
      expect(area.defaultCharge, 150);
      expect(area.active, isTrue);
    });

    test('name is trimmed; empty name throws', () {
      final area = DeliveryArea(
        id: 'a1',
        name: '  Sector 4  ',
        defaultCharge: 150,
        createdAt: _t,
      );
      expect(area.name, 'Sector 4');
      expect(
        () => DeliveryArea(
          id: 'a1',
          name: '   ',
          defaultCharge: 150,
          createdAt: _t,
        ),
        throwsArgumentError,
      );
    });

    test('defaultCharge must be greater than zero', () {
      expect(
        () => DeliveryArea(
          id: 'a1',
          name: 'Sector 4',
          defaultCharge: 0,
          createdAt: _t,
        ),
        throwsArgumentError,
      );
      expect(
        () => DeliveryArea(
          id: 'a1',
          name: 'Sector 4',
          defaultCharge: -10,
          createdAt: _t,
        ),
        throwsArgumentError,
      );
    });

    test('copyWith deactivates without touching other fields', () {
      final area = DeliveryArea(
        id: 'a1',
        name: 'Sector 4',
        defaultCharge: 150,
        createdAt: _t,
      );
      final off = area.copyWith(active: false);
      expect(off.active, isFalse);
      expect(off.id, 'a1');
      expect(off.name, 'Sector 4');
      expect(off.defaultCharge, 150);
    });
  });
}