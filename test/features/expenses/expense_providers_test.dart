import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_history_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> expenses;
  FakeExpenseRepository(this.expenses);
  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) => Stream.value(expenses.where((expense) => _isSameDay(expense.businessDate, businessDate) && !expense.voided).toList());
  @override Future<void> createExpense(Expense expense) => throw UnimplementedError();
  @override Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) => throw UnimplementedError();
  @override Future<double> getTotalExpensesByDateRange(DateTime start, DateTime end) => throw UnimplementedError();
  @override Future<Expense?> getExpense(String expenseId) => throw UnimplementedError();
  @override Future<void> updateExpense(String expenseId, Map<String, dynamic> changes, {required String changeReason}) => throw UnimplementedError();
  @override Future<void> voidExpense(String expenseId, {required String changeReason}) => throw UnimplementedError();
  @override Future<List<Map<String, dynamic>>> getExpenseHistory(String expenseId) => throw UnimplementedError();
}

void main() {
  test('expenseHistoryProvider streams operational expenses for the selected business day, excluding voided ones', () async {
    final businessDate = DateTime(2026, 9, 23);
    Expense buildExpense({required String id, required DateTime day, bool voided = false}) => Expense(
      id: id, title: 'Expense $id', category: ExpenseCategory.utilities, amount: 1000,
      date: day, businessDate: day, voided: voided,
    );
    final container = ProviderContainer(overrides: [
      expenseRepositoryProvider.overrideWithValue(FakeExpenseRepository([
        buildExpense(id: 'today-1', day: businessDate), buildExpense(id: 'today-2', day: businessDate),
        buildExpense(id: 'today-voided', day: businessDate, voided: true), buildExpense(id: 'yesterday', day: DateTime(2026, 9, 22)),
      ])),
      selectedExpenseDateProvider.overrideWith((ref) => businessDate),
    ]);
    addTearDown(container.dispose);
    final expenses = await container.read(expenseHistoryProvider.future);
    expect(expenses.map((expense) => expense.id).toList(), ['today-1', 'today-2']);
  });
}
