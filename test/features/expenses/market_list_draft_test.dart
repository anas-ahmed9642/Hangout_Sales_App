import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/market_list.dart';
import 'package:hangout_sales_app/features/expenses/providers/market_list_draft_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/market_list_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/market_list_repository.dart';

class FakeMarketListRepository implements MarketListRepository {
  final lists = <String, MarketList>{};
  int confirmCalls = 0;

  @override
  Future createMarketList(MarketList marketList) async {
    lists[marketList.id] = marketList;
  }

  @override
  Future<MarketList?> getLatestDraft() async {
    final drafts = lists.values
        .where((list) => list.status == MarketListStatus.draft)
        .toList();
    if (drafts.isEmpty) return null;
    drafts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return drafts.first;
  }

  @override
  Future<MarketList?> getMarketList(String marketListId) async {
    return lists[marketListId];
  }

  @override
  Future updateMarketList(
    String marketListId, {
    List<MarketListItem>? items,
    bool? handedToWorker,
  }) async {
    final existing = lists[marketListId];
    if (existing == null) return;
    lists[marketListId] = existing.copyWith(
      items: items ?? existing.items,
      total: items == null
          ? existing.total
          : items.fold(0, (sum, item) => sum! + item.price),
      handedToWorker: handedToWorker ?? existing.handedToWorker,
    );
  }

  @override
  Future<String> confirmMarketList({
    required String marketListId,
    required DateTime businessDate,
  }) async {
    confirmCalls++;
    return 'exp-1';
  }
}

void main() {
  late ProviderContainer container;
  late FakeMarketListRepository fakeRepository;
  late MarketListDraftNotifier notifier;

  setUp(() {
    fakeRepository = FakeMarketListRepository();
    container = ProviderContainer(
      overrides: [
        marketListRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
    notifier = container.read(marketListDraftProvider.notifier);
    addTearDown(container.dispose);
  });

  test('starts with a pristine empty draft', () {
    final draft = container.read(marketListDraftProvider);
    expect(draft.items, isEmpty);
    expect(draft.total, 0);
    expect(draft.handedToWorker, isFalse);
    expect(draft.status, MarketListStatus.draft);
  });

  test('addItem appends a plain-text line and persists', () async {
    await notifier.addItem(' Onion ');
    final draft = container.read(marketListDraftProvider);
    expect(draft.items, hasLength(1));
    expect(draft.items.first.itemName, 'Onion');
    expect(draft.items.first.price, 0);
    final persisted = await fakeRepository.getMarketList(draft.id);
    expect(persisted, isNotNull);
    expect(persisted!.items, hasLength(1));
  });

  test('addItem ignores blank names', () async {
    await notifier.addItem(' ');
    expect(container.read(marketListDraftProvider).items, isEmpty);
    expect(fakeRepository.lists, isEmpty);
  });

  test('removeItem drops the line and persists', () async {
    await notifier.addItem('Onion');
    await notifier.addItem('Capsicum');
    final draftId = container.read(marketListDraftProvider).id;
    await notifier.removeItem(0);
    final draft = container.read(marketListDraftProvider);
    expect(draft.items, hasLength(1));
    expect(draft.items.first.itemName, 'Capsicum');
    final persisted = await fakeRepository.getMarketList(draftId);
    expect(persisted!.items, hasLength(1));
  });

  test('removeItem ignores out-of-range indexes', () async {
    await notifier.addItem('Onion');
    await notifier.removeItem(5);
    await notifier.removeItem(-1);
    expect(container.read(marketListDraftProvider).items, hasLength(1));
  });

  test('updateItemPrice stays local until commitPrices', () async {
    await notifier.addItem('Onion');
    final draftId = container.read(marketListDraftProvider).id;
    notifier.updateItemPrice(0, 450);
    expect(container.read(marketListDraftProvider).total, 450);
    final beforeCommit = await fakeRepository.getMarketList(draftId);
    expect(beforeCommit!.total, 0);
    await notifier.commitPrices();
    final afterCommit = await fakeRepository.getMarketList(draftId);
    expect(afterCommit!.total, 450);
  });

  test('updateItemPrice ignores out-of-range indexes', () async {
    await notifier.addItem('Onion');
    notifier.updateItemPrice(3, 999);
    expect(container.read(marketListDraftProvider).total, 0);
  });

  test('setHandedToWorker flips and persists the handover', () async {
    await notifier.addItem('Onion');
    await notifier.setHandedToWorker(true);
    expect(container.read(marketListDraftProvider).handedToWorker, isTrue);
    final draftId = container.read(marketListDraftProvider).id;
    final persisted = await fakeRepository.getMarketList(draftId);
    expect(persisted!.handedToWorker, isTrue);
  });

  test('estimateTotal sums local prices', () async {
    await notifier.addItem('Onion');
    await notifier.addItem('Capsicum');
    notifier.updateItemPrice(0, 450);
    notifier.updateItemPrice(1, 300);
    expect(notifier.estimateTotal, 750);
  });

  test('validationErrors requires items, prices, and handover', () async {
    expect(
      notifier.validationErrors,
      contains('Add at least one item.'),
    );
    await notifier.addItem('Onion');
    expect(
      notifier.validationErrors,
      contains('Every item needs a price greater than zero.'),
    );
    notifier.updateItemPrice(0, 450);
    expect(
      notifier.validationErrors,
      contains('Mark the cash as handed to the worker.'),
    );
    await notifier.setHandedToWorker(true);
    expect(notifier.validationErrors, isEmpty);
  });

  test('confirm throws when invalid and never calls the repository', () async {
    await expectLater(
      notifier.confirm(DateTime(2026, 9, 28)),
      throwsStateError,
    );
    expect(fakeRepository.confirmCalls, 0);
  });

  test('confirm flushes prices then delegates to the repository', () async {
    await notifier.addItem('Onion');
    notifier.updateItemPrice(0, 450);
    await notifier.setHandedToWorker(true);
    final draftId = container.read(marketListDraftProvider).id;
    final expenseId = await notifier.confirm(DateTime(2026, 9, 28));
    expect(expenseId, 'exp-1');
    expect(fakeRepository.confirmCalls, 1);
    final persisted = await fakeRepository.getMarketList(draftId);
    expect(persisted!.total, 450);
  });

  test('loadDraft seeds the notifier and startNew resets it', () async {
    final persisted = MarketList(
      id: 'ml-old',
      items: const [MarketListItem(itemName: 'Onion', price: 450)],
      total: 450,
      handedToWorker: true,
      businessDate: DateTime(2026, 9, 27),
      createdAt: DateTime(2026, 9, 27, 9),
    );
    notifier.loadDraft(persisted);
    expect(container.read(marketListDraftProvider).id, 'ml-old');
    expect(container.read(marketListDraftProvider).items, hasLength(1));
    notifier.startNew();
    final fresh = container.read(marketListDraftProvider);
    expect(fresh.id, isNot('ml-old'));
    expect(fresh.items, isEmpty);
    expect(fresh.handedToWorker, isFalse);
  });
}
