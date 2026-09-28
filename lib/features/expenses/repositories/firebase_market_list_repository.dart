import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/expense_line_item.dart';
import '../models/market_list.dart';
import '../widgets/expense_formatters.dart';
import 'firebase_expense_repository.dart';
import 'market_list_repository.dart';

Map<String, dynamic> marketListItemToMap(MarketListItem item) {
  return {
    'itemName': item.itemName,
    'price': item.price,
  };
}

MarketListItem marketListItemFromMap(Map<String, dynamic> data) {
  return MarketListItem(
    itemName: data['itemName'] as String? ?? '',
    price: (data['price'] as num?)?.toDouble() ?? 0,
  );
}

Map<String, dynamic> marketListToMap(MarketList list) {
  return {
    'id': list.id,
    'items': list.items.map(marketListItemToMap).toList(),
    'total': list.total,
    'status': list.status.name,
    'handedToWorker': list.handedToWorker,
    'reconciledExpenseId': list.reconciledExpenseId,
    'businessDate': Timestamp.fromDate(list.businessDate),
    'createdAt': Timestamp.fromDate(list.createdAt),
  };
}

MarketList marketListFromMap(Map<String, dynamic> data) {
  return MarketList(
    id: data['id'] as String,
    items: ((data['items'] as List<dynamic>?) ?? [])
        .map((item) => marketListItemFromMap(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList(),
    total: (data['total'] as num).toDouble(),
    status: MarketListStatus.values.firstWhere(
      (status) => status.name == data['status'],
      orElse: () => MarketListStatus.draft,
    ),
    handedToWorker: data['handedToWorker'] as bool? ?? false,
    reconciledExpenseId: data['reconciledExpenseId'] as String?,
    businessDate: (data['businessDate'] as Timestamp).toDate(),
    createdAt: (data['createdAt'] as Timestamp).toDate(),
  );
}

/// Sum of all item prices. The only place a market list total is computed.
double computeMarketListTotal(List<MarketListItem> items) {
  return items.fold<double>(0, (total, item) => total + item.price);
}

/// Validation errors for [items]; empty means OK.
///
/// Saving a draft ([requirePrices] false) allows unpriced (0) items so a
/// list can be prepared before shopping. Confirming ([requirePrices] true)
/// needs at least one item and every price greater than zero.
List<String> validateMarketListItems(
  List<MarketListItem> items, {
  required bool requirePrices,
}) {
  final errors = <String>[];
  if (requirePrices && items.isEmpty) {
    errors.add('Add at least one item.');
  }
  if (items.any((item) => item.itemName.trim().isEmpty)) {
    errors.add('Each item needs a name.');
  }
  if (requirePrices) {
    if (items.any((item) => item.price <= 0)) {
      errors.add('Every item needs a price greater than zero.');
    }
  } else if (items.any((item) => item.price < 0)) {
    errors.add('Item price cannot be negative.');
  }
  return errors;
}

/// The Market Bills expense a confirmed [marketList] becomes.
///
/// Items are copied as plain text (snapshot-at-add), the amount is
/// recomputed from them, and the expense points back through
/// [Expense.linkedMarketListId]. [businessDate] is the business date of
/// the confirmation. Throws [StateError] if the list cannot be confirmed:
/// empty, unpriced, or the cash was never handed to the worker.
Expense buildExpenseFromMarketList(
  MarketList marketList, {
  required String expenseId,
  required DateTime businessDate,
  required DateTime createdAt,
}) {
  final errors = validateMarketListItems(
    marketList.items,
    requirePrices: true,
  );
  if (!marketList.handedToWorker) {
    errors.add('Mark the cash as handed to the worker.');
  }
  if (errors.isNotEmpty) {
    throw StateError(errors.join(' '));
  }
  return Expense(
    id: expenseId,
    title: 'Market list — ${formatExpenseDay(businessDate)}',
    category: ExpenseCategory.marketBills,
    amount: computeMarketListTotal(marketList.items),
    date: createdAt,
    businessDate: businessDate,
    linkedMarketListId: marketList.id,
    lineItems: marketList.items
        .map((item) => ExpenseLineItem(
              itemName: item.itemName,
              price: item.price,
            ))
        .toList(),
  );
}

class FirebaseMarketListRepository implements MarketListRepository {
  FirebaseMarketListRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _marketListsCollection =>
      _firestore.collection('marketLists');

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection('expenses');

  @override
  Future<void> createMarketList(MarketList marketList) async {
    await _marketListsCollection
        .doc(marketList.id)
        .set(marketListToMap(marketList));
  }

  @override
  Future<MarketList?> getLatestDraft() async {
    final query = await _marketListsCollection
        .where('status', isEqualTo: MarketListStatus.draft.name)
        .limit(20)
        .get();
    if (query.docs.isEmpty) return null;
    final drafts = query.docs
        .map((doc) => marketListFromMap(doc.data()))
        .toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return drafts.first;
  }

  @override
  Future<MarketList?> getMarketList(String marketListId) async {
    final doc = await _marketListsCollection.doc(marketListId).get();
    if (!doc.exists) return null;
    return marketListFromMap(doc.data()!);
  }

  @override
  Future<void> updateMarketList(
    String marketListId, {
    List<MarketListItem>? items,
    bool? handedToWorker,
  }) async {
    final data = <String, dynamic>{};
    if (items != null) {
      data['items'] = items.map(marketListItemToMap).toList();
      data['total'] = computeMarketListTotal(items);
    }
    if (handedToWorker != null) {
      data['handedToWorker'] = handedToWorker;
    }
    if (data.isEmpty) return;
    // Confirmed lists are locked: the guard lives here, not just in the
    // UI flow, so no caller can rewrite history.
    final docRef = _marketListsCollection.doc(marketListId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.data()?['status'] == MarketListStatus.confirmed.name) {
        throw StateError('Confirmed market lists cannot be edited.');
      }
      transaction.update(docRef, data);
    });
  }

  @override
  Future<String> confirmMarketList({
    required String marketListId,
    required DateTime businessDate,
  }) async {
    final listRef = _marketListsCollection.doc(marketListId);
    return _firestore.runTransaction((transaction) async {
      final listSnapshot = await transaction.get(listRef);
      if (!listSnapshot.exists) {
        throw StateError('Market list $marketListId does not exist.');
      }
      final data = listSnapshot.data();
      if (data == null) {
        throw StateError('Market list $marketListId contains no data.');
      }
      if (data['status'] != MarketListStatus.draft.name) {
        throw StateError(
          'Market list $marketListId is already confirmed.',
        );
      }
      final marketList = marketListFromMap(data);
      // The transaction is the sole source of truth: the expense is built
      // from the freshly re-read list, the total recomputed from
      // items[].price at this moment, never copied from whatever total
      // the client was holding. Throws StateError for an empty/unpriced
      // list or a missing handover; nothing has been written yet, so the
      // transaction leaves no partial state.
      final now = DateTime.now();
      final expenseRef = _expensesCollection.doc();
      final expense = buildExpenseFromMarketList(
        marketList,
        expenseId: expenseRef.id,
        businessDate: businessDate,
        createdAt: now,
      );
      transaction.set(expenseRef, expenseToMap(expense));
      transaction.update(listRef, {
        'status': MarketListStatus.confirmed.name,
        'total': expense.amount,
        'reconciledExpenseId': expenseRef.id,
      });
      return expenseRef.id;
    });
  }
}
