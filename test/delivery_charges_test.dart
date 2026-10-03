import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/menu_data.dart';

void main() {
  group('MenuData.deliveryCharges', () {
    test('contains the full charge list including 180', () {
      expect(
        MenuData.deliveryCharges,
        [70, 100, 130, 150, 180, 200, 250, 300],
      );
    });

    test('still contains every previously available charge', () {
      expect(
        MenuData.deliveryCharges,
        containsAll([70, 100, 130, 150, 200, 250, 300]),
      );
    });
  });
}