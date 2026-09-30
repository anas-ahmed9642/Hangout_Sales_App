import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/market_list.dart';
import 'package:hangout_sales_app/features/expenses/providers/market_list_draft_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/market_list_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_market_list_repository.dart';
import 'package:hangout_sales_app/features/expenses/services/market_list_print_service.dart';
import 'package:hangout_sales_app/features/expenses/services/market_list_receipt_builder.dart';
import 'package:hangout_sales_app/features/orders/services/order_receipt_service.dart';

import '../../helpers/test_container.dart';


MarketList makeList({
  List<MarketListItem>? items,
  double total = 750,
}) {
  return MarketList(
    id: 'ml-1',
    items: items ??
        const [
          MarketListItem(itemName: 'Onion', price: 450),
          MarketListItem(itemName: 'Capsicum', price: 300),
        ],
    total: total,
    businessDate: DateTime(2026, 9, 28),
    createdAt: DateTime(2026, 9, 28, 10),
  );
}

String render(MarketList list) {
  return String.fromCharCodes(MarketListReceiptBuilder().buildEstimate(list));
}

/// Records the bytes it is asked to print, or fails like a real printer.
class _RecordingReceiptService extends OrderReceiptService {
  _RecordingReceiptService({this.error}) : super();

  final Object? error;
  final received = <List<int>>[];

  @override
  Future<void> printBytes(List<int> bytes) async {
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    received.add(bytes);
  }
}

/// Holds the print open until [gate] completes, to test the busy guard.
class _BlockingReceiptService extends OrderReceiptService {
  _BlockingReceiptService() : super();

  final gate = Completer<void>();
  int calls = 0;

  @override
  Future<void> printBytes(List<int> bytes) async {
    calls++;
    await gate.future;
  }
}

void main() {

  group('MarketListReceiptBuilder', () {
    test('prints the estimate total as the sum of the item prices', () {
      final text = render(makeList());

      // "ESTIMATE TOTAL" (14) + "Rs. 750" (7) leaves an 11-space gap.
      expect(text, contains('ESTIMATE TOTAL${' ' * 11}Rs. 750\n'));
    });

    test('an unpriced item prints as Rs. 0', () {
      final text = render(
        makeList(
          items: const [MarketListItem(itemName: 'Onion', price: 0)],
          total: 0,
        ),
      );

      expect(text, contains('Onion${' ' * 22}Rs. 0\n'));
    });

  });

  group('MarketListDraftNotifier.printList', () {
    late FakeFirebaseFirestore fake;
    late FirebaseMarketListRepository repository;
    late ProviderContainer container;
    late MarketListDraftNotifier notifier;

    setUp(() {
      fake = FakeFirebaseFirestore();
      repository = FirebaseMarketListRepository(firestore: fake);
      container = createTestContainer(
        overrides: [marketListRepositoryProvider.overrideWithValue(repository)],
      );
      notifier = container.read(marketListDraftProvider.notifier);
    });

    test('flushes typed prices to Firestore before printing', () async {
      await notifier.addItem('Onion');
      notifier.updateItemPrice(0, 450); // local only until flushed
      final recorder = _RecordingReceiptService();

      await notifier.printList(
        MarketListPrintService(orderReceiptService: recorder),
      );

      final stored = await repository.getMarketList(
        container.read(marketListDraftProvider).id,
      );
      expect(stored!.items.single.price, 450);
      expect(stored.total, 450);
      expect(recorder.received, hasLength(1));
      expect(String.fromCharCodes(recorder.received.single), contains('Rs. 450'));
    });

    test('printing never confirms the list or creates an expense', () async {
      await notifier.addItem('Onion');
      notifier.updateItemPrice(0, 450);

      await notifier.printList(
        MarketListPrintService(orderReceiptService: _RecordingReceiptService()),
      );

      final stored = await repository.getMarketList(
        container.read(marketListDraftProvider).id,
      );
      expect(stored!.status, MarketListStatus.draft);
      expect((await fake.collection('expenses').get()).docs, isEmpty);
    });

    test('a second print while one is in flight is ignored', () async {
      await notifier.addItem('Onion');
      final blocking = _BlockingReceiptService();
      final service = MarketListPrintService(orderReceiptService: blocking);

      final first = notifier.printList(service);
      // The busy flag is set synchronously; the printer itself is reached
      // after the price flush — wait for that, not a fixed delay.
      while (blocking.calls == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(notifier.isBusy, isTrue);

      await notifier.printList(service); // returns immediately, prints nothing
      expect(blocking.calls, 1);

      blocking.gate.complete();
      await first;
      expect(notifier.isBusy, isFalse);
    });

    test('a printer failure keeps the draft, frees the busy flag and can be '
        'retried', () async {
      await notifier.addItem('Onion');
      notifier.updateItemPrice(0, 450);

      await expectLater(
        notifier.printList(
          MarketListPrintService(
            orderReceiptService: _RecordingReceiptService(
              error: const PrinterWriteException('Kitchen printer'),
            ),
          ),
        ),
        throwsA(isA<PrinterWriteException>()),
      );

      expect(notifier.isBusy, isFalse);
      expect(container.read(marketListDraftProvider).items.single.price, 450);

      final retry = _RecordingReceiptService();
      await notifier.printList(
        MarketListPrintService(orderReceiptService: retry),
      );
      expect(retry.received, hasLength(1));
    });

  });
}
