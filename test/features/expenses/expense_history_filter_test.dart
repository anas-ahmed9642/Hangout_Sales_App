import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_history_filter.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_history_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';

/// In-memory ExpenseRepository mirroring the real half-open
/// [start, end) contract on businessDate, voided excluded. Records the
/// requested range so tests can verify the provider's conversion.
class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> expenses;

  DateTime? lastRangeStart;
  DateTime? lastRangeEnd;

  FakeExpenseRepository(this.expenses);

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    lastRangeStart = start;
    lastRangeEnd = end;
    return expenses
        .where(
          (expense) =>
              !expense.businessDate.isBefore(start) &&
              expense.businessDate.isBefore(end) &&
              !expense.voided,
        )
        .toList();
  }

  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) =>
      throw UnimplementedError();
  @override
  Future<void> createExpense(Expense expense) => throw UnimplementedError();
  @override
  Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      throw UnimplementedError();
  @override
  Future<Expense?> getExpense(String expenseId) => throw UnimplementedError();
  @override
  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> voidExpense(
    String expenseId, {
    required String changeReason,
  }) =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getExpenseHistory(String expenseId) =>
      throw UnimplementedError();
}

Expense _expense({
  required String id,
  required String title,
  required ExpenseCategory category,
  required double amount,
  required DateTime businessDate,
  int hour = 10,
}) {
  return Expense(
    id: id,
    title: title,
    category: category,
    amount: amount,
    date: DateTime(
      businessDate.year,
      businessDate.month,
      businessDate.day,
      hour,
    ),
    businessDate: businessDate,
  );
}

void main() {
  test(
      'default filter uses the current business date as a single-day range',
      () {
    final filter = defaultExpenseHistoryFilter(DateTime(2026, 9, 28, 10, 0));

    expect(filter.start, DateTime(2026, 9, 28));
    expect(filter.end, DateTime(2026, 9, 28));
    expect(filter.category, isNull);
  });

  test(
      'default filter respects the 5:00 AM business-day boundary '
      'via the real BusinessDayService',
      () {
    // 4:30 AM still belongs to the previous business day.
    final filter = defaultExpenseHistoryFilter(DateTime(2026, 9, 28, 4, 30));

    expect(filter.start, DateTime(2026, 9, 27));
    expect(filter.end, DateTime(2026, 9, 27));
  });

  test('endExclusive is the day after end, across month boundaries', () {
    final filter = ExpenseHistoryFilter(
      start: DateTime(2026, 9, 20),
      end: DateTime(2026, 9, 30),
    );

    expect(filter.endExclusive, DateTime(2026, 10, 1));
  });

  test(
      'changing the range requests exactly [start, endExclusive) '
      'from the repository',
      () async {
    final repository = FakeExpenseRepository(const []);
    final container = ProviderContainer(overrides: [
      expenseRepositoryProvider.overrideWithValue(repository),
      expenseHistoryFilterProvider.overrideWith(
        (ref) => ExpenseHistoryFilter(
          start: DateTime(2026, 9, 20),
          end: DateTime(2026, 9, 23),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await container.read(expenseHistoricalListProvider.future);

    expect(repository.lastRangeStart, DateTime(2026, 9, 20));
    // Inclusive end 23 Sep becomes exclusive 24 Sep.
    expect(repository.lastRangeEnd, DateTime(2026, 9, 24));
  });

  test(
      'provider applies the category filter client-side and sorts '
      'newest first',
      () async {
    final repository = FakeExpenseRepository([
      _expense(
        id: 'e1',
        title: 'Morning milk',
        category: ExpenseCategory.marketBills,
        amount: 2000,
        businessDate: DateTime(2026, 9, 28),
        hour: 9,
      ),
      _expense(
        id: 'e2',
        title: 'Chicken tikka stock',
        category: ExpenseCategory.chicken,
        amount: 1500,
        businessDate: DateTime(2026, 9, 28),
        hour: 12,
      ),
    ]);
    final container = ProviderContainer(overrides: [
      expenseRepositoryProvider.overrideWithValue(repository),
      expenseHistoryFilterProvider.overrideWith(
        (ref) => ExpenseHistoryFilter(
          start: DateTime(2026, 9, 20),
          end: DateTime(2026, 9, 28),
          category: ExpenseCategory.chicken,
        ),
      ),
    ]);
    addTearDown(container.dispose);

    final expenses =
        await container.read(expenseHistoricalListProvider.future);

    expect(expenses.map((e) => e.id).toList(), ['e2']);
  });

  test('changing the category preserves the selected date range', () {
    final filter = ExpenseHistoryFilter(
      start: DateTime(2026, 9, 20),
      end: DateTime(2026, 9, 28),
      category: ExpenseCategory.chicken,
    );

    final changed = filter.copyWith(category: ExpenseCategory.gas);
    expect(changed.start, filter.start);
    expect(changed.end, filter.end);
    expect(changed.category, ExpenseCategory.gas);

    final cleared = filter.copyWith(clearCategory: true);
    expect(cleared.start, filter.start);
    expect(cleared.end, filter.end);
    expect(cleared.category, isNull);
  });

  test('changing the date range preserves the selected category', () {
    final filter = ExpenseHistoryFilter(
      start: DateTime(2026, 9, 20),
      end: DateTime(2026, 9, 28),
      category: ExpenseCategory.chicken,
    );

    final changed = filter.copyWith(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 30),
    );

    expect(changed.category, ExpenseCategory.chicken);
    expect(changed.start, DateTime(2026, 9, 1));
    expect(changed.end, DateTime(2026, 9, 30));
  });
}
