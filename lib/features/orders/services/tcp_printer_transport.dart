import 'dart:io';

import 'printer_device.dart';
import 'thermal_printer_transport.dart';

/// Dev-only transport that sends ESC/POS bytes to a local
/// TCP printer emulator (e.g. escpresso on localhost:9100)
/// instead of a real Bluetooth printer.
class TcpPrinterTransport implements ThermalPrinterTransport {
  final String host;
  final int port;

  Socket? _socket;

  TcpPrinterTransport({
    this.host = 'localhost',
    this.port = 9100,
  });

  @override
  Future<bool> get bluetoothEnabled async => true;

  @override
  Future<bool> get permissionGranted async => true;

  @override
  Future<bool> get connectionStatus async => _socket != null;

  @override
  Future<List<PrinterDevice>> get pairedDevices async => [
        PrinterDevice(name: 'Escpresso Emulator', macAddress: '$host:$port'),
      ];

  @override
  Future<bool> connect(String macAddress) async {
    try {
      _socket = await Socket.connect(host, port,
          timeout: const Duration(seconds: 3));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> writeBytes(List<int> bytes) async {
    if (_socket == null) return false;
    try {
      _socket!.add(bytes);
      await _socket!.flush();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> disconnect() async {
    await _socket?.close();
    _socket = null;
    return true;
  }
}