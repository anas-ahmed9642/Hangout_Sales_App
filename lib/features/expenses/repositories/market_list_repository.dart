import '../models/market_list.dart';

/// Firestore access for Market Lists. The UI never touches Firestore
/// directly — it goes through MarketListDraftNotifier, which goes through
/// this repository.
abstract class MarketListRepository {
  /// Persists a new draft. Overwrites nothing; ids are uuids.
  Future<void> createMarketList(MarketList marketList);

  /// Returns the newest draft (status == draft), or null when none exists.
  /// Confirmed lists are never returned here.
  Future<MarketList?> getLatestDraft();

  /// Returns the list with [marketListId], or null when missing.
  Future<MarketList?> getMarketList(String marketListId);

  /// Updates items and/or the handover flag of a DRAFT list.
  /// Throws [StateError] when the list is already confirmed.
  /// When [items] is given, the stored total is recomputed from them.
  Future<void> updateMarketList(
    String marketListId, {
    List<MarketListItem>? items,
    bool? handedToWorker,
  });

  /// Confirms the draft and creates the linked Market Bills expense in ONE
  /// Firestore transaction. The transaction re-reads the list, recomputes
  /// the total from items[].price, and rejects missing, already-confirmed,
  /// empty, unpriced, or not-handed-over lists with [StateError].
  /// Returns the new expense id. The draft is untouched on failure.
  Future<String> confirmMarketList({
    required String marketListId,
    required DateTime businessDate,
  });
}
