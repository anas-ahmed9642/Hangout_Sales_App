import '../models/expense.dart';

abstract class ExpenseRepository {
  /// Phase 5: Persist a newly created expense.
  ///
  /// The caller supplies the [Expense.id]; the repository writes it as-is,
  /// mirroring OrderRepository.createOrder.
  Future<void> createExpense(Expense expense);

  /// Phase 5: Stream operational expenses for one business day.
  ///
  /// Voided expenses are excluded — this stream feeds operational views,
  /// never historical/audit inspection.
  Stream<List<Expense>> streamExpenses(DateTime businessDate);

  /// Phase 5: One-shot read of operational expenses across a business-date
  /// range. [start] is inclusive, [end] is exclusive. Voided expenses are
  /// excluded.
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Phase 5: Operational total across a business-date range.
  ///
  /// Voided expenses are excluded, so this is safe to use for Dashboard
  /// totals, future Reports totals, and current-total queries.
  Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Phase 5: Retrieve one specific saved expense.
  Future<Expense?> getExpense(String expenseId);

  /// Phase 5: Update an already-saved expense and record why it changed.
  ///
  /// One history document is written per actually-changed field, and
  /// [Expense.editCount] increments only when at least one field really
  /// changed. A non-empty [changeReason] is required. Voided expenses
  /// cannot be edited — they are historical records.
  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> changes, {
    required String changeReason,
  });

  /// Phase 5: Soft-void an expense. The record stays in Firestore for
  /// historical/audit inspection but is excluded from every operational
  /// query.
  ///
  /// A non-empty [changeReason] is required and is written to the history
  /// subcollection with field 'voided'. There is no separate voidReason,
  /// and voiding never hard-deletes.
  Future<void> voidExpense(
    String expenseId, {
    required String changeReason,
  });

  /// Phase 5: Read the audit history of one expense, newest first.
  Future<List<Map<String, dynamic>>> getExpenseHistory(
    String expenseId,
  );
}
