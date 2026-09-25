import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'printer_device.dart';

abstract class ThermalPrinterTransport {
  Future<bool> get bluetoothEnabled;

  Future<bool> get permissionGranted;

  Future<bool> get connectionStatus;

  Future<List<PrinterDevice>> get pairedDevices;

  Future<bool> connect(String macAddress);

  Future<bool> writeBytes(List<int> bytes);

  Future<bool> disconnect();
}

class BluetoothThermalPrinterTransport
    implements ThermalPrinterTransport {
  const BluetoothThermalPrinterTransport();

  @override
  Future<bool> get bluetoothEnabled async {
    if (kIsWeb) {
      return false;
    }

    return PrintBluetoothThermal.bluetoothEnabled;
  }

  @override
  Future<bool> get permissionGranted async {
    if (kIsWeb) {
      return false;
    }

    if (defaultTargetPlatform ==
        TargetPlatform.windows) {
      return true;
    }

    return PrintBluetoothThermal
        .isPermissionBluetoothGranted;
  }

  @override
  Future<bool> get connectionStatus async {
    if (kIsWeb) {
      return false;
    }

    return PrintBluetoothThermal.connectionStatus;
  }

  @override
  Future<List<PrinterDevice>> get pairedDevices async {
    if (kIsWeb) {
      return const [];
    }

    final devices =
        await PrintBluetoothThermal.pairedBluetooths;

    return devices
        .map(
          (device) => PrinterDevice(
            name: device.name,
            macAddress: device.macAdress,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> connect(
    String macAddress,
  ) async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await PrintBluetoothThermal.connect(
        macPrinterAddress: macAddress,
      );
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> writeBytes(
    List<int> bytes,
  ) async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await PrintBluetoothThermal.writeBytes(
        bytes,
      );
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    if (kIsWeb) {
      return false;
    }

    try {
      return await PrintBluetoothThermal.disconnect;
    } on PlatformException {
      return false;
    }
  }
} 