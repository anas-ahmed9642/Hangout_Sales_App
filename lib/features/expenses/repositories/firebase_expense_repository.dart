import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '../models/chicken_purchase_line.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/expense_line_item.dart';
import 'expense_repository.dart';

// Public (not private like the Orders mappers) so the serialization and
// audit-diff behavior required by Phase 12 can be unit-tested without a
// Firestore instance.

Map<String, dynamic> expenseToMap(Expense expense) {
  return {
    'id': expense.id,
    'title': expense.title,
    'category': expense.category.name,
    'amount': expense.amount,
    'notes': expense.notes,
    'date': Timestamp.fromDate(expense.date),
    'businessDate': Timestamp.fromDate(expense.businessDate),
    'voided': expense.voided,
    'editCount': expense.editCount,
    'workerName': expense.workerName,
    'linkedMarketListId': expense.linkedMarketListId,
    'pricePerKg': expense.pricePerKg,
    'chickenLines': expense.chickenLines?.map(chickenPurchaseLineToMap).toList(),
    'lineItems': expense.lineItems?.map(expenseLineItemToMap).toList(),
  };
}

Map<String, dynamic> chickenPurchaseLineToMap(ChickenPurchaseLine line) {
  return {'chickenType': line.chickenType, 'quantityKg': line.quantityKg};
}

Map<String, dynamic> expenseLineItemToMap(ExpenseLineItem item) {
  return {'itemName': item.itemName, 'price': item.price};
}

Expense expenseFromMap(Map<String, dynamic> data) {
  return Expense(
    id: data['id'] as String,
    title: data['title'] as String,
    category: ExpenseCategory.values.firstWhere(
      (category) => category.name == data['category'],
    ),
    amount: (data['amount'] as num).toDouble(),
    notes: data['notes'] as String?,
    date: (data['date'] as Timestamp).toDate(),
    businessDate: (data['businessDate'] as Timestamp).toDate(),
    voided: data['voided'] as bool? ?? false,
    editCount: (data['editCount'] as num?)?.toInt() ?? 0,
    workerName: data['workerName'] as String?,
    linkedMarketListId: data['linkedMarketListId'] as String?,
    pricePerKg: (data['pricePerKg'] as num?)?.toDouble(),
    chickenLines: (data['chickenLines'] as List<dynamic>?)?.map((line) =>
      chickenPurchaseLineFromMap(Map<String, dynamic>.from(line as Map)),
    ).toList(),
    lineItems: (data['lineItems'] as List<dynamic>?)?.map((item) =>
      expenseLineItemFromMap(Map<String, dynamic>.from(item as Map)),
    ).toList(),
  );
}

ChickenPurchaseLine chickenPurchaseLineFromMap(Map<String, dynamic> data) {
  return ChickenPurchaseLine(
    chickenType: data['chickenType'] as String,
    quantityKg: (data['quantityKg'] as num).toInt(),
  );
}

ExpenseLineItem expenseLineItemFromMap(Map<String, dynamic> data) {
  return ExpenseLineItem(
    itemName: data['itemName'] as String,
    price: (data['price'] as num).toDouble(),
  );
}

/// Pure audit-diff used by [FirebaseExpenseRepository.updateExpense].
///
/// Returns one history entry per field whose value actually changed
/// (deep-compared, so an identical line-items list writes no history).
/// Each entry carries field / oldValue / newValue / changeReason /
/// timestamp, mirroring the Orders updateOrder() audit shape.
List<Map<String, dynamic>> buildExpenseHistoryEntries({
  required Map<String, dynamic> currentData,
  required Map<String, dynamic> changes,
  required String changeReason,
  required DateTime timestamp,
}) {
  const deepEq = DeepCollectionEquality();
  final changedEntries = changes.entries.where((entry) {
    final oldValue = currentData[entry.key];
    final newValue = entry.value;
    return !deepEq.equals(oldValue, newValue);
  }).toList();
  final timestampValue = Timestamp.fromDate(timestamp);
  return changedEntries.map((entry) {
    return {
      'field': entry.key,
      'oldValue': currentData[entry.key],
      'newValue': entry.value,
      'changeReason': changeReason.trim(),
      'timestamp': timestampValue,
    };
  }).toList();
}

class FirebaseExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore;

  FirebaseExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection('expenses');

  @override
  Future<void> createExpense(Expense expense) async {
    await _expensesCollection.doc(expense.id).set(expenseToMap(expense));
  }

  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) {
    final startOfDay = Timestamp.fromDate(
      DateTime(businessDate.year, businessDate.month, businessDate.day),
    );
    final endOfDay = Timestamp.fromDate(
      DateTime(businessDate.year, businessDate.month, businessDate.day + 1),
    );
    return _expensesCollection
        .where('businessDate', isGreaterThanOrEqualTo: startOfDay)
        .where('businessDate', isLessThan: endOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => expenseFromMap(doc.data()))
            .where((expense) => !expense.voided)
            .toList());
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final startTimestamp = Timestamp.fromDate(DateTime(start.year, start.month, start.day));
    final endTimestamp = Timestamp.fromDate(DateTime(end.year, end.month, end.day));
    final snapshot = await _expensesCollection
        .where('businessDate', isGreaterThanOrEqualTo: startTimestamp)
        .where('businessDate', isLessThan: endTimestamp)
        .get();
    return snapshot.docs
        .map((doc) => expenseFromMap(doc.data()))
        .where((expense) => !expense.voided)
        .toList();
  }

  @override
  Future<double> getTotalExpensesByDateRange(DateTime start, DateTime end) async {
    final expenses = await getExpensesByDateRange(start, end);
    return expenses.fold<double>(0.0, (total, expense) => total + expense.amount);
  }

  @override
  Future<Expense?> getExpense(String expenseId) async {
    final snapshot = await _expensesCollection.doc(expenseId).get();
    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;
    return expenseFromMap(data);
  }

  @override
  Future<void> updateExpense(String expenseId, Map<String, dynamic> changes, {
    required String changeReason,
  }) async {
    if (changes.isEmpty) throw ArgumentError('Cannot update an expense with no changes.');
    if (changeReason.trim().isEmpty) throw ArgumentError('A change reason is required.');
    final expenseRef = _expensesCollection.doc(expenseId);
    final historyCollection = expenseRef.collection('history');
    await _firestore.runTransaction((transaction) async {
      final expenseSnapshot = await transaction.get(expenseRef);
      if (!expenseSnapshot.exists) throw StateError('Expense $expenseId does not exist.');
      final currentData = expenseSnapshot.data();
      if (currentData == null) throw StateError('Expense $expenseId contains no data.');
      if (currentData['voided'] == true) throw StateError('Voided expenses cannot be edited.');
      final historyEntries = buildExpenseHistoryEntries(
        currentData: currentData,
        changes: changes,
        changeReason: changeReason,
        timestamp: DateTime.now(),
      );
      final currentEditCount = (currentData['editCount'] as num?)?.toInt() ?? 0;
      final updateData = <String, dynamic>{...changes};
      if (historyEntries.isNotEmpty) {
        updateData['editCount'] = currentEditCount + 1;
      }
      transaction.update(expenseRef, updateData);
      for (final entry in historyEntries) {
        transaction.set(historyCollection.doc(), entry);
      }
    });
  }

  @override
  Future<void> voidExpense(String expenseId, {required String changeReason}) async {
    if (changeReason.trim().isEmpty) {
      throw ArgumentError('A change reason is required to void an expense.');
    }
    final expenseRef = _expensesCollection.doc(expenseId);
    final historyCollection = expenseRef.collection('history');
    await _firestore.runTransaction((transaction) async {
      final expenseSnapshot = await transaction.get(expenseRef);
      if (!expenseSnapshot.exists) throw StateError('Expense $expenseId does not exist.');
      final currentData = expenseSnapshot.data();
      if (currentData == null) throw StateError('Expense $expenseId contains no data.');
      if (currentData['voided'] == true) throw StateError('Expense $expenseId is already voided.');
      transaction.update(expenseRef, {'voided': true});
      transaction.set(historyCollection.doc(), {
        'field': 'voided',
        'oldValue': false,
        'newValue': true,
        'changeReason': changeReason.trim(),
        'timestamp': Timestamp.now(),
      });
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getExpenseHistory(String expenseId) async {
    final snapshot = await _expensesCollection
        .doc(expenseId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
