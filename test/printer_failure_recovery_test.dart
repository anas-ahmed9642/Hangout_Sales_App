import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/services/order_receipt_service.dart';

void main() {
  group('Printer failure recovery exceptions', () {
    test(
      'web/unavailable printer exception contains actionable guidance',
      () {
        const exception = PrinterUnavailableException(
          'Bluetooth receipt printing is not available in the web build.',
        );

        expect(
          exception.toString(),
          contains('Bluetooth receipt printing is not available'),
        );
      },
    );

    test(
      'Bluetooth disabled exception explains recovery',
      () {
        const exception =
            PrinterBluetoothDisabledException();

        expect(
          exception.toString(),
          contains('Bluetooth is turned off'),
        );

        expect(
          exception.toString(),
          contains('enable Bluetooth'),
        );
      },
    );

    test(
      'permission exception explains recovery',
      () {
        const exception =
            PrinterPermissionException();

        expect(
          exception.toString(),
          contains('Bluetooth permission'),
        );

        expect(
          exception.toString(),
          contains('device settings'),
        );
      },
    );

    test(
      'not configured exception explains recovery',
      () {
        const exception =
            PrinterNotConfiguredException();

        expect(
          exception.toString(),
          contains('No thermal printer is configured'),
        );

        expect(
          exception.toString(),
          contains('Pair the printer'),
        );
      },
    );

    test(
      'connection exception identifies the printer',
      () {
        const exception =
            PrinterConnectionException('Speed-X BT500M');

        expect(
          exception.toString(),
          contains('Speed-X BT500M'),
        );

        expect(
          exception.toString(),
          contains('Unable to connect'),
        );
      },
    );

    test(
      'write exception identifies the printer',
      () {
        const exception =
            PrinterWriteException('Speed-X BT500M');

        expect(
          exception.toString(),
          contains('Speed-X BT500M'),
        );

        expect(
          exception.toString(),
          contains('receipt could not be sent'),
        );
      },
    );
  });
}