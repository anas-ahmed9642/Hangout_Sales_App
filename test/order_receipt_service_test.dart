import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/models/receipt_data.dart';
import 'package:hangout_sales_app/features/orders/services/order_receipt_service.dart';
import 'package:hangout_sales_app/features/orders/services/printer_device.dart';
import 'package:hangout_sales_app/features/orders/services/printer_device_store.dart';
import 'package:hangout_sales_app/features/orders/services/receipt_builder.dart';
import 'package:hangout_sales_app/features/orders/services/thermal_printer_transport.dart';

class FakePrinterTransport
  implements ThermalPrinterTransport {
  bool bluetoothIsEnabled = true;
  bool permissionIsGranted = true;
  bool connected = false;
  bool writeSucceeds = true;

  final List<PrinterDevice> devices;

  List<int>? writtenBytes;
  String? connectedAddress;

  FakePrinterTransport({
    this.devices = const [
      PrinterDevice(
        name: 'Speed-X BT500M',
        macAddress: '00:11:22:33:44:55',
      ),
    ],
  });

  @override
  Future<bool> get bluetoothEnabled async =>
      bluetoothIsEnabled;

  @override
  Future<bool> get permissionGranted async =>
      permissionIsGranted;

  @override
  Future<bool> get connectionStatus async =>
      connected;

  @override
  Future<List<PrinterDevice>> get pairedDevices async =>
      devices;

  @override
  Future<bool> connect(
    String macAddress,
  ) async {
    connectedAddress = macAddress;

    if (macAddress.isEmpty) {
      return false;
    }

    connected = true;
    return true;
  }

  @override
  Future<bool> writeBytes(
    List<int> bytes,
  ) async {
    writtenBytes = bytes;

    if (!writeSucceeds) {
      return false;
    }

    return true;
  }

  @override
  Future<bool> disconnect() async {
    connected = false;
    return true;
  }
}

class FakePrinterDeviceStore
  implements PrinterDeviceStore {
  PrinterDevice? savedDevice;

  @override
  Future<PrinterDevice?> readLastPairedDevice() async =>
      savedDevice;

  @override
  Future<void> saveLastPairedDevice(
    PrinterDevice device,
  ) async {
    savedDevice = device;
  }

  @override
  Future<void> clearLastPairedDevice() async {
    savedDevice = null;
  }
}

class FakeReceiptBuilder extends ReceiptBuilder {
  bool called = false;

  @override
  Future<List<int>> build(
    ReceiptData data,
  ) async {
    called = true;
    return [1, 2, 3, 4];
  }
}

Order createTestOrder() {
  return Order(
    id: 'order-1',
    orderNumber: 'ORD-0042',
    createdAt:
      DateTime(2026, 9, 3, 15, 0),
    businessDate:
      DateTime(2026, 9, 3),
    customerName: 'Test Customer',
    items: const [
      OrderItem(
        flavorId: 'chicken_tikka',
        flavorName: 'Chicken Tikka',
        size: PizzaSize.large,
        quantity: 1,
        unitPrice: 650,
      ),
    ],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: 650,
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
  );
}

void main() {
  test(
    'reprint connects to saved printer and writes receipt bytes',
    () async {
      final transport =
          FakePrinterTransport();

      final store =
          FakePrinterDeviceStore()
            ..savedDevice =
                const PrinterDevice(
              name: 'Speed-X BT500M',
              macAddress:
                  '00:11:22:33:44:55',
            );

      final builder =
          FakeReceiptBuilder();

      final service =
          OrderReceiptService(
        builder: builder,
        transport: transport,
        deviceStore: store,
      );

      await service.reprint(
        createTestOrder(),
      );

      expect(
        builder.called,
        isTrue,
      );

      expect(
        transport.connectedAddress,
        '00:11:22:33:44:55',
      );

      expect(
        transport.writtenBytes,
        [1, 2, 3, 4],
      );
    },
  );

  test(
    'reprint automatically remembers the only paired printer',
    () async {
      final transport =
          FakePrinterTransport();

      final store =
          FakePrinterDeviceStore();

      final service =
          OrderReceiptService(
        builder: FakeReceiptBuilder(),
        transport: transport,
        deviceStore: store,
      );

      await service.reprint(
        createTestOrder(),
      );

      expect(
        store.savedDevice?.name,
        'Speed-X BT500M',
      );

      expect(
        store.savedDevice?.macAddress,
        '00:11:22:33:44:55',
      );
    },
  );

  test(
    'printBytes connects to the configured printer and writes raw bytes',
    () async {
      final transport =
          FakePrinterTransport();

      final store =
          FakePrinterDeviceStore()
            ..savedDevice =
                const PrinterDevice(
              name: 'Speed-X BT500M',
              macAddress:
                  '00:11:22:33:44:55',
            );

      final service =
          OrderReceiptService(
        transport: transport,
        deviceStore: store,
      );

      await service.printBytes(
        [27, 64],
      );

      expect(
        transport.connectedAddress,
        '00:11:22:33:44:55',
      );
      expect(
        transport.writtenBytes,
        [27, 64],
      );
      expect(
        store.savedDevice?.name,
        'Speed-X BT500M',
      );
    },
  );

  test(
    'reprint reports Bluetooth disabled',
    () async {
      final transport =
          FakePrinterTransport()
            ..bluetoothIsEnabled = false;

      final service =
          OrderReceiptService(
        builder: FakeReceiptBuilder(),
        transport: transport,
        deviceStore:
            FakePrinterDeviceStore(),
      );

      expect(
        () => service.reprint(
          createTestOrder(),
        ),
        throwsA(
          isA<
              PrinterBluetoothDisabledException>(),
        ),
      );
    },
  );

  test(
    'reprint reports missing Bluetooth permission',
    () async {
      final transport =
          FakePrinterTransport()
            ..permissionIsGranted = false;

      final service =
          OrderReceiptService(
        builder: FakeReceiptBuilder(),
        transport: transport,
        deviceStore:
            FakePrinterDeviceStore(),
      );

      expect(
        () => service.reprint(
          createTestOrder(),
        ),
        throwsA(
          isA<PrinterPermissionException>(),
        ),
      );
    },
  );

  test(
    'reprint reports failed printer write',
    () async {
      final transport =
          FakePrinterTransport(
            devices: const [
              PrinterDevice(
                name: 'Speed-X BT500M',
                macAddress:
                    '00:11:22:33:44:55',
              ),
            ],
          )..writeSucceeds = false;

      final store =
          FakePrinterDeviceStore()
            ..savedDevice =
                const PrinterDevice(
              name: 'Speed-X BT500M',
              macAddress:
                  '00:11:22:33:44:55',
            );

      final service =
          OrderReceiptService(
        builder: FakeReceiptBuilder(),
        transport: transport,
        deviceStore: store,
      );

      expect(
        () => service.reprint(
          createTestOrder(),
        ),
        throwsA(
          isA<PrinterWriteException>(),
        ),
      );

      expect(
        transport.connected,
        isFalse,
      );
    },
  );

  test(
    'multiple paired printers are not guessed',
    () async {
      final transport =
          FakePrinterTransport(
            devices: const [
              PrinterDevice(
                name: 'Printer A',
                macAddress:
                    '00:00:00:00:00:01',
              ),
              PrinterDevice(
                name: 'Printer B',
                macAddress:
                    '00:00:00:00:00:02',
              ),
            ],
          );

      final service =
          OrderReceiptService(
        builder: FakeReceiptBuilder(),
        transport: transport,
        deviceStore:
            FakePrinterDeviceStore(),
      );

      expect(
        () => service.reprint(
          createTestOrder(),
        ),
        throwsA(
          isA<
              PrinterNotConfiguredException>(),
        ),
      );
    },
  );
}
