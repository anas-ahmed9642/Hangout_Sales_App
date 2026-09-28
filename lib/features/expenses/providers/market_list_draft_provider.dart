import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/business_day_service.dart';
import '../models/catalog_item.dart';
import '../models/expense_category.dart';
import '../models/market_list.dart';
import '../repositories/firebase_market_list_repository.dart';
import '../services/market_list_print_service.dart';
import 'catalog_repository_provider.dart';
import 'market_list_repository_provider.dart';

/// Active Market Bills catalog items for the market-list picker.
///
/// Plain-text snapshots: the picker copies the item NAME as text at add
/// time, so deactivating a catalog item later never alters existing lines.
final marketListCatalogProvider =
    StreamProvider.autoDispose<List<CatalogItem>>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return repository.streamCatalog(
    category: ExpenseCategory.marketBills,
    activeOnly: true,
  );
});

/// The newest persisted draft, for the "Resume previous list" card.
/// Null while loading or when no draft exists.
final persistedMarketListDraftProvider =
    FutureProvider.autoDispose<MarketList?>((ref) async {
  final repository = ref.watch(marketListRepositoryProvider);
  return repository.getLatestDraft();
});

class MarketListDraftNotifier extends Notifier<MarketList> {
  final _uuid = const Uuid();

  @override
  MarketList build() {
    return MarketList(
      id: _uuid.v4(),
      items: const [],
      total: 0,
      businessDate: BusinessDayService().businessDate(DateTime.now()),
      createdAt: DateTime.now(),
    );
  }

  /// Seeds the draft from a persisted list (resume flow).
  void loadDraft(MarketList draft) {
    state = draft;
  }

  /// Discards the local draft and starts a fresh one.
  void startNew() {
    state = MarketList(
      id: _uuid.v4(),
      items: const [],
      total: 0,
      businessDate: BusinessDayService().businessDate(DateTime.now()),
      createdAt: DateTime.now(),
    );
  }

  /// Adds a catalog item as a plain-text line. No-op for blank names.
  Future<void> addItem(String itemName) async {
    final name = itemName.trim();
    if (name.isEmpty) return;
    final items = [
      ...state.items,
      MarketListItem(itemName: name, price: 0),
    ];
    _setItems(items);
    await _persistItems(items);
  }

  /// Removes the line at [index]. No-op for out-of-range indexes.
  Future<void> removeItem(int index) async {
    if (index < 0 || index >= state.items.length) return;
    final items = [...state.items]..removeAt(index);
    _setItems(items);
    await _persistItems(items);
  }

  /// Local-only price edit while typing. Persisted on submit / before
  /// print / before confirm via [commitPrices].
  void updateItemPrice(int index, double price) {
    if (index < 0 || index >= state.items.length) return;
    final items = [...state.items];
    items[index] = items[index].copyWith(price: price);
    _setItems(items);
  }

  /// Persists the current prices (flush before print and confirm).
  Future<void> commitPrices() async {
    await _persistItems(state.items);
  }

  /// Marks the cash handover and persists it immediately.
  Future<void> setHandedToWorker(bool handed) async {
    state = state.copyWith(handedToWorker: handed);
    await _persistHandover(handed);
  }

  double get estimateTotal => computeMarketListTotal(state.items);

  /// Delegates to the pure [validateMarketListItems] helper so the UI
  /// and the confirm transaction enforce exactly the same rules.
  List<String> get validationErrors {
    final errors = validateMarketListItems(
      state.items,
      requirePrices: true,
    );
    if (!state.handedToWorker) {
      errors.add('Mark the cash as handed to the worker.');
    }
    return errors;
  }

  /// True while a save/print/confirm operation is in flight.
  bool get isBusy => _isBusy;
  bool _isBusy = false;

  /// Prints the estimate list through the shared [MarketListPrintService].
  /// Flushes prices first; throws on printer failure so the screen can
  /// show the error.
  Future<void> printList(MarketListPrintService printService) async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      await commitPrices();
      await printService.printEstimate(state);
    } finally {
      _isBusy = false;
    }
  }

  /// Confirms the draft: one Firestore transaction creates the linked
  /// Market Bills expense and locks the list. [businessDate] must be the
  /// value the screen computed once at confirm-press. Returns the new
  /// expense id. Throws [StateError] when invalid; the draft is preserved.
  Future<String> confirm(DateTime businessDate) async {
    final errors = validationErrors;
    if (errors.isNotEmpty) {
      throw StateError(errors.join(' '));
    }
    if (_isBusy) {
      throw StateError('A market list operation is already running.');
    }
    _isBusy = true;
    try {
      await commitPrices();
      final repository = ref.read(marketListRepositoryProvider);
      return await repository.confirmMarketList(
        marketListId: state.id,
        businessDate: businessDate,
      );
    } finally {
      _isBusy = false;
    }
  }

  void _setItems(List<MarketListItem> items) {
    state = state.copyWith(
      items: items,
      total: computeMarketListTotal(items),
    );
  }

  /// Persists [items]: creates the draft on first write, updates after.
  Future<void> _persistItems(List<MarketListItem> items) async {
    final repository = ref.read(marketListRepositoryProvider);
    final existing = await repository.getMarketList(state.id);
    if (existing == null) {
      await repository.createMarketList(state);
    } else {
      await repository.updateMarketList(state.id, items: items);
    }
  }

  Future<void> _persistHandover(bool handed) async {
    final repository = ref.read(marketListRepositoryProvider);
    final existing = await repository.getMarketList(state.id);
    if (existing == null) {
      await repository.createMarketList(state);
    } else {
      await repository.updateMarketList(
        state.id,
        handedToWorker: handed,
      );
    }
  }
}

final marketListDraftProvider =
    NotifierProvider<MarketListDraftNotifier, MarketList>(
  MarketListDraftNotifier.new,
);

