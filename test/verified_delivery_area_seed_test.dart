import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/delivery_areas/seed/verified_delivery_area_seed.dart';
import 'package:hangout_sales_app/features/orders/models/menu_data.dart';

void main() {
  group('Verified delivery area seed', () {
    test('contains exactly 15 verified areas', () {
      expect(
        verifiedDeliveryAreaSeed,
        hasLength(15),
      );
    });

    test('contains the exact owner-supplied area names', () {
      final names = verifiedDeliveryAreaSeed
          .map((item) => item.name)
          .toSet();

      expect(
        names,
        containsAll([
          'Sector 2',
          'Sector 3',
          'Sector 4',
          'Sector 5C/1',
          'Sector 5C/2',
          'Sector 5C/3',
          'Sector 5C/4',
          'Sector 8',
          'Sector 9',
          'Sector 10',
          'Sector 11A',
          'Sector 11B',
          'Sector 11C/1',
          'Sector 11C/2',
          'Sector 11C/3',
        ]),
      );
    });

    test('Sector 2 carries the Rs 180 charge', () {
      final sector2 = verifiedDeliveryAreaSeed.firstWhere(
        (item) => item.name == 'Sector 2',
      );
      expect(sector2.defaultCharge, 180);
    });

    test('Sector 9 carries the Rs 70 charge', () {
      final sector9 = verifiedDeliveryAreaSeed.firstWhere(
        (item) => item.name == 'Sector 9',
      );
      expect(sector9.defaultCharge, 70);
    });

    test('Sector 11C/1, 11C/2 and 11C/3 are all Rs 100', () {
      for (final name in ['Sector 11C/1', 'Sector 11C/2', 'Sector 11C/3']) {
        final area = verifiedDeliveryAreaSeed.firstWhere(
          (item) => item.name == name,
        );
        expect(area.defaultCharge, 100);
      }
    });

    test('every seed charge is a valid MenuData delivery charge', () {
      for (final item in verifiedDeliveryAreaSeed) {
        expect(
          MenuData.deliveryCharges.contains(item.defaultCharge),
          isTrue,
          reason: '${item.name} has charge ${item.defaultCharge}',
        );
      }
    });
  });
}