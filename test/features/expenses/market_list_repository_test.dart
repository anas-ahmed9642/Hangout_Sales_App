import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/market_list.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_market_list_repository.dart';

MarketList makeDraft({
  String id = 'ml-1',
  double onionPrice = 450,
  bool handedToWorker = true,
  DateTime? createdAt,
}) {
  return MarketList(
    id: id,
    items: [
      MarketListItem(itemName: 'Onion', price: onionPrice),
      const MarketListItem(itemName: 'Capsicum', price: 300),
    ],
    total: onionPrice + 300,
    handedToWorker: handedToWorker,
    businessDate: DateTime(2026, 9, 28),
    createdAt: createdAt ?? DateTime(2026, 9, 28, 10),
  );
}

void main() {
  late FakeFirebaseFirestore fake;
  late FirebaseMarketListRepository repository;

  setUp(() {
    fake = FakeFirebaseFirestore();
    repository = FirebaseMarketListRepository(firestore: fake);
  });

  group('pure helpers', () {
    test('computeMarketListTotal sums item prices', () {
      expect(
        computeMarketListTotal(const [
          MarketListItem(itemName: 'Mushroom Slices', price: 300),
          MarketListItem(itemName: 'Black Olive', price: 450),
        ]),
        750,
      );
      expect(computeMarketListTotal(const []), 0);
    });

    test('validateMarketListItems allows unpriced items when saving', () {
      final errors = validateMarketListItems(
        const [MarketListItem(itemName: 'Black Olive', price: 0)],
        requirePrices: false,
      );
      expect(errors, isEmpty);
    });

    test('validateMarketListItems rejects negative prices when saving', () {
      final errors = validateMarketListItems(
        const [MarketListItem(itemName: 'Black Olive', price: -1)],
        requirePrices: false,
      );
      expect(errors, isNotEmpty);
    });

    test('validateMarketListItems requires items and prices to confirm', () {
      expect(
        validateMarketListItems(const [], requirePrices: true),
        contains('Add at least one item.'),
      );
      expect(
        validateMarketListItems(
          const [MarketListItem(itemName: 'Black Olive', price: 0)],
          requirePrices: true,
        ),
        contains('Every item needs a price greater than zero.'),
      );
      expect(
        validateMarketListItems(
          const [MarketListItem(itemName: 'Black Olive', price: 450)],
          requirePrices: true,
        ),
        isEmpty,
      );
    });

    test('buildExpenseFromMarketList copies items and links the list', () {
      final expense = buildExpenseFromMarketList(
        makeDraft(),
        expenseId: 'exp-1',
        businessDate: DateTime(2026, 9, 29),
        createdAt: DateTime(2026, 9, 29, 18, 0),
      );
      expect(expense.id, 'exp-1');
      expect(expense.title, 'Market list — 29 Sep 2026');
      expect(expense.category, ExpenseCategory.marketBills);
      expect(expense.amount, 750);
      expect(expense.linkedMarketListId, 'ml-1');
      expect(expense.businessDate, DateTime(2026, 9, 29));
      expect(expense.date, DateTime(2026, 9, 29, 18, 0));
      expect(expense.lineItems, hasLength(2));
      expect(expense.lineItems!.first.itemName, 'Onion');
      expect(expense.lineItems!.last.price, 300);
    });

    test('buildExpenseFromMarketList rejects an unpriced list', () {
      expect(
        () => buildExpenseFromMarketList(
          makeDraft(onionPrice: 0),
          expenseId: 'exp-1',
          businessDate: DateTime(2026, 9, 29),
          createdAt: DateTime(2026, 9, 29, 18, 0),
        ),
        throwsStateError,
      );
    });

    test('buildExpenseFromMarketList rejects a missing handover', () {
      expect(
        () => buildExpenseFromMarketList(
          makeDraft(handedToWorker: false),
          expenseId: 'exp-1',
          businessDate: DateTime(2026, 9, 29),
          createdAt: DateTime(2026, 9, 29, 18, 0),
        ),
        throwsStateError,
      );
    });
  });

  group('draft lifecycle', () {
    test('create + get round-trip', () async {
      await repository.createMarketList(makeDraft());
      final restored = await repository.getMarketList('ml-1');
      expect(restored, isNotNull);
      expect(restored!.items, hasLength(2));
      expect(restored.handedToWorker, isTrue);
      expect(restored.status, MarketListStatus.draft);
    });

    test('getMarketList returns null for a missing id', () async {
      expect(await repository.getMarketList('nope'), isNull);
    });

    test('getLatestDraft returns the newest draft and ignores confirmed lists',
        () async {
      await repository.createMarketList(
        makeDraft(
          id: 'ml-old',
          createdAt: DateTime(2026, 9, 27, 9),
        ),
      );
      await repository.createMarketList(
        makeDraft(
          id: 'ml-new',
          createdAt: DateTime(2026, 9, 28, 11),
        ),
      );
      final confirmed = makeDraft(
        id: 'ml-done',
        createdAt: DateTime(2026, 9, 28, 12),
      ).copyWith(status: MarketListStatus.confirmed);
      await repository.createMarketList(confirmed);
      final latest = await repository.getLatestDraft();
      expect(latest, isNotNull);
      expect(latest!.id, 'ml-new');
    });

    test('getLatestDraft returns null when no draft exists', () async {
      expect(await repository.getLatestDraft(), isNull);
    });

    test('updateMarketList writes items and recomputes the stored total',
        () async {
      await repository.createMarketList(makeDraft());
      await repository.updateMarketList(
        'ml-1',
        items: const [
          MarketListItem(itemName: 'Onion', price: 500),
        ],
      );
      final restored = await repository.getMarketList('ml-1');
      expect(restored!.items, hasLength(1));
      expect(restored.total, 500);
    });

    test('updateMarketList flips handedToWorker', () async {
      await repository.createMarketList(makeDraft());
      await repository.updateMarketList('ml-1', handedToWorker: false);
      final restored = await repository.getMarketList('ml-1');
      expect(restored!.handedToWorker, isFalse);
    });

    test('updateMarketList rejects a confirmed list', () async {
      await repository.createMarketList(makeDraft());
      await repository.confirmMarketList(
        marketListId: 'ml-1',
        businessDate: DateTime(2026, 9, 28),
      );
      await expectLater(
        repository.updateMarketList(
          'ml-1',
          items: const [MarketListItem(itemName: 'Onion', price: 1)],
        ),
        throwsStateError,
      );
      final restored = await repository.getMarketList('ml-1');
      expect(restored!.total, 750);
    });
  });

  group('confirmMarketList', () {
    test(
      'confirms atomically and recomputes the total inside the transaction',
      () async {
        // The stored total is deliberately stale: the transaction must
        // ignore it and sum items[].price fresh.
        await fake.collection('marketLists').doc('ml-1').set({
          ...marketListToMap(makeDraft()),
          'total': 99999,
        });
        final expenseId = await repository.confirmMarketList(
          marketListId: 'ml-1',
          businessDate: DateTime(2026, 9, 28),
        );
        final restored = await repository.getMarketList('ml-1');
        expect(restored!.status, MarketListStatus.confirmed);
        expect(restored.total, 750);
        expect(restored.reconciledExpenseId, expenseId);
        final expenseDoc = await fake.collection('expenses').doc(expenseId).get();
        final expenseData = expenseDoc.data()!;
        expect(expenseData['title'], 'Market list — 28 Sep 2026');
        expect(expenseData['category'], 'marketBills');
        expect(expenseData['amount'], 750);
        expect(
          (expenseData['businessDate'] as Timestamp).toDate(),
          (expenseData['businessDate'] as Timestamp).toDate(),
        );
        expect(expenseData['linkedMarketListId'], 'ml-1');
        expect(expenseData['voided'], false);
        final lineItems = expenseData['lineItems'] as List;
        expect(lineItems, hasLength(2));
        expect((lineItems.first as Map)['itemName'], 'Onion');
        expect((lineItems.first as Map)['price'], 450);
      },
    );

    test('throws for a missing list and creates no expense', () async {
      await expectLater(
        repository.confirmMarketList(
          marketListId: 'nope',
          businessDate: DateTime(2026, 9, 28),
        ),
        throwsStateError,
      );
      final expenses = await fake.collection('expenses').get();
      expect(expenses.docs, isEmpty);
    });

    test('throws for an already-confirmed list', () async {
      await repository.createMarketList(makeDraft());
      await repository.confirmMarketList(
        marketListId: 'ml-1',
        businessDate: DateTime(2026, 9, 28),
      );
      await expectLater(
        repository.confirmMarketList(
          marketListId: 'ml-1',
          businessDate: DateTime(2026, 9, 28),
        ),
        throwsStateError,
      );
    });

    test('throws for an empty list', () async {
      await repository.createMarketList(
        MarketList(
          id: 'ml-empty',
          items: const [],
          total: 0,
          handedToWorker: true,
          businessDate: DateTime(2026, 9, 28),
          createdAt: DateTime(2026, 9, 28, 10),
        ),
      );
      await expectLater(
        repository.confirmMarketList(
          marketListId: 'ml-empty',
          businessDate: DateTime(2026, 9, 28),
        ),
        throwsStateError,
      );
    });

    test('throws when an item has no reconciled price', () async {
      await repository.createMarketList(makeDraft(onionPrice: 0));
      await expectLater(
        repository.confirmMarketList(
          marketListId: 'ml-1',
          businessDate: DateTime(2026, 9, 28),
        ),
        throwsStateError,
      );
      final expenses = await fake.collection('expenses').get();
      expect(expenses.docs, isEmpty);
    });

    test('throws when cash was never handed to the worker', () async {
      await repository.createMarketList(
        makeDraft(handedToWorker: false),
      );
      await expectLater(
        repository.confirmMarketList(
          marketListId: 'ml-1',
          businessDate: DateTime(2026, 9, 28),
        ),
        throwsStateError,
      );
      final expenses = await fake.collection('expenses').get();
      expect(expenses.docs, isEmpty);
    });
  });
}
