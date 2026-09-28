import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../models/expense_audit_entry.dart';
import 'expense_repository_provider.dart';

final expenseDetailProvider = FutureProvider.autoDispose.family<Expense?, String>((ref, id) => ref.watch(expenseRepositoryProvider).getExpense(id));
final expenseAuditTrailProvider = FutureProvider.autoDispose.family<List<ExpenseAuditEntry>, String>((ref, id) async => (await ref.watch(expenseRepositoryProvider).getExpenseHistory(id)).map(expenseAuditEntryFromMap).toList());
ExpenseAuditEntry expenseAuditEntryFromMap(Map<String, dynamic> data) {
  final raw = data['timestamp'];
  final timestamp = raw is Timestamp ? raw.toDate() : raw is DateTime ? raw : null;
  return ExpenseAuditEntry(field: data['field'] as String? ?? '', oldValue: data['oldValue'], newValue: data['newValue'], changeReason: data['changeReason'] as String? ?? '', timestamp: timestamp);
}
