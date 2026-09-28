import 'package:flutter/foundation.dart';

import '../models/order.dart';
import 'printer_device.dart';
import 'printer_device_store.dart';
import 'receipt_builder.dart';
import '../models/receipt_data.dart';
import 'thermal_printer_transport.dart';

class PrinterUnavailableException
    implements Exception {
  final String message;

  const PrinterUnavailableException(
    this.message,
  );

  @override
  String toString() => message;
}

class PrinterBluetoothDisabledException
    implements Exception {
  const PrinterBluetoothDisabledException();

  @override
  String toString() =>
      'Bluetooth is turned off. Please enable Bluetooth and try again.';
}

class PrinterPermissionException
    implements Exception {
  const PrinterPermissionException();

  @override
  String toString() =>
      'Bluetooth permission is not available. Please allow Bluetooth access in device settings.';
}

class PrinterNotConfiguredException
    implements Exception {
  const PrinterNotConfiguredException();

  @override
  String toString() =>
      'No thermal printer is configured. Pair the printer in Bluetooth settings and try again.';
}

class PrinterConnectionException
    implements Exception {
  final String printerName;

  const PrinterConnectionException(
    this.printerName,
  );

  @override
  String toString() =>
      'Unable to connect to $printerName.';
}

class PrinterWriteException
    implements Exception {
  final String printerName;

  const PrinterWriteException(
    this.printerName,
  );

  @override
  String toString() =>
      'The receipt could not be sent to $printerName.';
}

class OrderReceiptService {
  final ReceiptBuilder _builder;
  final ThermalPrinterTransport _transport;
  final PrinterDeviceStore _deviceStore;

  const OrderReceiptService({
    ReceiptBuilder builder =
        const ReceiptBuilder(),
    ThermalPrinterTransport transport =
        const BluetoothThermalPrinterTransport(),
    PrinterDeviceStore deviceStore =
        const SharedPreferencesPrinterDeviceStore(),
  })  : _builder = builder,
        _transport = transport,
        _deviceStore = deviceStore;

  Future<void> reprint(Order order) async {
    if (kIsWeb) {
      throw const PrinterUnavailableException(
        'Bluetooth receipt printing is not available in the web build. Use the Android app with a paired thermal printer.',
      );
    }

    final permissionGranted =
        await _transport.permissionGranted;

    if (!permissionGranted) {
      throw const PrinterPermissionException();
    }

    final bluetoothEnabled =
        await _transport.bluetoothEnabled;

    if (!bluetoothEnabled) {
      throw const PrinterBluetoothDisabledException();
    }

    final device =
        await _resolvePrinterDevice();

    if (device == null) {
      throw const PrinterNotConfiguredException();
    }

    var connected =
        await _transport.connectionStatus;

    if (!connected) {
      connected = await _transport.connect(
        device.macAddress,
      );
    }

    if (!connected) {
      throw PrinterConnectionException(
        device.name,
      );
    }

    final receiptData =
        ReceiptData.fromOrder(order);

    final bytes =
        await _builder.build(receiptData);

    await _writeBytes(bytes);
  }

  /// Writes raw ESC/POS [bytes] to the printer using the same
  /// connection logic as order reprints.
  Future<void> printBytes(List<int> bytes) async {
    if (kIsWeb) {
      throw const PrinterUnavailableException(
        'Bluetooth receipt printing is not available in the web build. Use the Android app with a paired thermal printer.',
      );
    }

    await _writeBytes(bytes);
  }

  Future<void> _writeBytes(List<int> bytes) async {
    final permissionGranted =
        await _transport.permissionGranted;

    if (!permissionGranted) {
      throw const PrinterPermissionException();
    }

    final bluetoothEnabled =
        await _transport.bluetoothEnabled;

    if (!bluetoothEnabled) {
      throw const PrinterBluetoothDisabledException();
    }

    final device =
        await _resolvePrinterDevice();

    if (device == null) {
      throw const PrinterNotConfiguredException();
    }

    var connected =
        await _transport.connectionStatus;

    if (!connected) {
      connected = await _transport.connect(
        device.macAddress,
      );
    }

    if (!connected) {
      throw PrinterConnectionException(
        device.name,
      );
    }

    final printed =
        await _transport.writeBytes(bytes);

    if (!printed) {
      await _transport.disconnect();

      throw PrinterWriteException(
        device.name,
      );
    }

    await _deviceStore.saveLastPairedDevice(
      device,
    );
  }

  Future<List<PrinterDevice>> getPairedDevices() {
    return _transport.pairedDevices;
  }

  Future<void> rememberPrinter(
    PrinterDevice device,
  ) {
    return _deviceStore.saveLastPairedDevice(
      device,
    );
  }

  Future<void> forgetPrinter() {
    return _deviceStore.clearLastPairedDevice();
  }

  Future<void> restoreConnection() async {
    if (kIsWeb) {
      return;
    }

    try {
      final permissionGranted =
          await _transport.permissionGranted;

      if (!permissionGranted) {
        return;
      }

      final bluetoothEnabled =
          await _transport.bluetoothEnabled;

      if (!bluetoothEnabled) {
        return;
      }

      final device =
          await _resolvePrinterDevice();

      if (device == null) {
        return;
      }

      final connected =
          await _transport.connectionStatus;

      if (connected) {
        return;
      }

      await _transport.connect(
        device.macAddress,
      );
    } catch (_) {
      // Startup printer restoration is intentionally
      // silent. Printing itself reports failures to
      // the cashier through the existing UI.
    }
  }

  Future<PrinterDevice?> _resolvePrinterDevice() async {
    final saved =
        await _deviceStore.readLastPairedDevice();

    if (saved != null) {
      return saved;
    }

    final paired =
        await _transport.pairedDevices;

    if (paired.length == 1) {
      final device = paired.single;

      await _deviceStore.saveLastPairedDevice(
        device,
      );

      return device;
    }

    return null;
  }
}