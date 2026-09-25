import 'package:shared_preferences/shared_preferences.dart';

import 'printer_device.dart';

abstract class PrinterDeviceStore {
  Future<PrinterDevice?> readLastPairedDevice();

  Future<void> saveLastPairedDevice(
    PrinterDevice device,
  );

  Future<void> clearLastPairedDevice();
}

class SharedPreferencesPrinterDeviceStore
    implements PrinterDeviceStore {
  static const _nameKey =
      'orders.last_printer.name';

  static const _macAddressKey =
      'orders.last_printer.mac_address';

  const SharedPreferencesPrinterDeviceStore();

  @override
  Future<PrinterDevice?> readLastPairedDevice() async {
    final preferences = SharedPreferencesAsync();

    final name = await preferences.getString(_nameKey);
    final macAddress =
        await preferences.getString(_macAddressKey);

    if (name == null ||
        name.trim().isEmpty ||
        macAddress == null ||
        macAddress.trim().isEmpty) {
      return null;
    }

    return PrinterDevice(
      name: name,
      macAddress: macAddress,
    );
  }

  @override
  Future<void> saveLastPairedDevice(
    PrinterDevice device,
  ) async {
    final preferences = SharedPreferencesAsync();

    await preferences.setString(
      _nameKey,
      device.name,
    );

    await preferences.setString(
      _macAddressKey,
      device.macAddress,
    );
  }

  @override
  Future<void> clearLastPairedDevice() async {
    final preferences = SharedPreferencesAsync();

    await preferences.remove(_nameKey);
    await preferences.remove(_macAddressKey);
  }
}