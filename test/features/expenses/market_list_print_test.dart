import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/market_list.dart';
import 'package:hangout_sales_app/features/expenses/services/market_list_print_service.dart';
import 'package:hangout_sales_app/features/expenses/services/market_list_receipt_builder.dart';
import 'package:hangout_sales_app/features/orders/services/order_receipt_service.dart';

MarketList makeList({double total = 750}) {
  return MarketList(
    id: 'ml-1',
    items: const [
      MarketListItem(itemName: 'Onion', price: 450),
      MarketListItem(itemName: 'Capsicum', price: 300),
    ],
    total: total,
    businessDate: DateTime(2026, 9, 28),
    createdAt: DateTime(2026, 9, 28, 10),
  );
}

class _RecordingReceiptService extends OrderReceiptService {
  _RecordingReceiptService({this.error}) : super();
  final Object? error;
  final received = <List<int>>[];

  @override
  Future<void> printBytes(List<int> bytes) async {
    if (error != null) throw error!;
    received.add(bytes);
  }
}

void main() {
  test('receipt starts with init and ends with cut', () {
    final bytes = MarketListReceiptBuilder().buildEstimate(makeList());
    expect(bytes.take(2).toList(), [0x1B, 0x40]);
    expect(bytes.skip(bytes.length - 4).toList(), [0x1D, 0x56, 0x41, 0x03]);
  });

  test('receipt includes header, date, items and reminder', () {
    final text = String.fromCharCodes(
      MarketListReceiptBuilder().buildEstimate(makeList()),
    );
    expect(text, contains('HANGOUT'));
    expect(text, contains('MARKET LIST'));
    expect(text, contains('Date: 28 Sep 2026'));
    expect(text, contains('Onion${' ' * 20}Rs. 450\n'));
    expect(text, contains('Capsicum${' ' * 17}Rs. 300\n'));
    expect(text, contains('Hand this list + cash to the worker.'));
  });

  test('receipt recomputes stale totals and truncates names', () {
    final list = MarketList(
      id: 'ml-1',
      items: [MarketListItem(itemName: 'A' * 40, price: 450)],
      total: 99999,
      businessDate: DateTime(2026, 9, 28),
      createdAt: DateTime(2026, 9, 28),
    );
    final text = String.fromCharCodes(
      MarketListReceiptBuilder().buildEstimate(list),
    );
    expect(text, contains('${'A' * 32} Rs. 450\n'));
    expect(text, isNot(contains('99999')));
  });

  test('print service forwards builder bytes', () async {
    final recorder = _RecordingReceiptService();
    final service = MarketListPrintService(orderReceiptService: recorder);
    await service.printEstimate(makeList());
    expect(recorder.received, hasLength(1));
  });

  test('printer exceptions propagate', () async {
    final service = MarketListPrintService(
      orderReceiptService: _RecordingReceiptService(
        error: const PrinterBluetoothDisabledException(),
      ),
    );
    await expectLater(
      service.printEstimate(makeList()),
      throwsA(isA<PrinterBluetoothDisabledException>()),
    );
  });

  test('receipt builder handles an empty list', () {
    final empty = makeList(total: 0).copyWith(items: const []);
    final text = String.fromCharCodes(
      MarketListReceiptBuilder().buildEstimate(empty),
    );
    expect(text, contains('ESTIMATE TOTAL'));
    expect(text, contains('Rs. 0'));
  });

  test('a blocking service can be represented by a future gate', () async {
    final gate = Completer<void>();
    final recorder = _RecordingReceiptService();
    final future = gate.future.then((_) => recorder.printBytes(const []));
    expect(future, isA<Future<void>>());
    gate.complete();
    await future;
  });
}
