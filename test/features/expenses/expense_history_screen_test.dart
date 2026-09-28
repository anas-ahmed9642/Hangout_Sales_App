import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_history_filter.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_history_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';
import 'package:hangout_sales_app/features/expenses/screens/expense_history_screen.dart';
import 'package:hangout_sales_app/shared/widgets/hangout_app_bar.dart';

/// In-memory ExpenseRepository for history-screen tests.
///
/// getExpensesByDateRange mirrors the real contract: half-open
/// [start, end) on businessDate, voided expenses excluded. It records
/// the requested range so tests can verify the provider's conversion.
class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> expenses;
  final bool failRange;

  DateTime? lastRangeStart;
  DateTime? lastRangeEnd;

  FakeExpenseRepository(this.expenses, {this.failRange = false});

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    lastRangeStart = start;
    lastRangeEnd = end;
    if (failRange) {
      throw Exception('firestore unavailable');
    }
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
  bool voided = false,
  int editCount = 0,
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
    voided: voided,
    editCount: editCount,
  );
}

final _rangeStart = DateTime(2026, 9, 20);
final _rangeEnd = DateTime(2026, 9, 28);

Future<void> _pumpScreen(
  WidgetTester tester,
  FakeExpenseRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repository),
        expenseHistoryFilterProvider.overrideWith(
          (ref) => ExpenseHistoryFilter(
            start: _rangeStart,
            end: _rangeEnd,
          ),
        ),
      ],
      child: const MaterialApp(home: ExpenseHistoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  List<Expense> sampleExpenses() => [
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
          businessDate: DateTime(2026, 9, 27),
          hour: 12,
        ),
        _expense(
          id: 'e3',
          title: 'Old gas',
          category: ExpenseCategory.gas,
          amount: 500,
          businessDate: DateTime(2026, 9, 10),
        ),
      ];

  testWidgets('shows a loading indicator while the range read is pending',
      (tester) async {
    final completer = Completer<List<Expense>>();
    addTearDown(() {
      if (!completer.isCompleted) {
        completer.complete(const []);
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseHistoricalListProvider.overrideWith(
            (ref) => completer.future,
          ),
        ],
        child: const MaterialApp(home: ExpenseHistoryScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(HangoutAppBar), findsOneWidget);
  });

  testWidgets('displays the expenses inside the selected range, newest first',
      (tester) async {
    await _pumpScreen(tester, FakeExpenseRepository(sampleExpenses()));

    expect(find.text('20 Sep 2026 → 28 Sep 2026'), findsOneWidget);
    expect(find.text('Morning milk'), findsOneWidget);
    expect(find.text('Chicken tikka stock'), findsOneWidget);
    // Outside the range: not shown.
    expect(find.text('Old gas'), findsNothing);

    final newestTop = tester.getTopLeft(find.text('Morning milk')).dy;
    final olderTop =
        tester.getTopLeft(find.text('Chicken tikka stock')).dy;
    expect(newestTop, lessThan(olderTop));
  });

  testWidgets('category chip filters the range list', (tester) async {
    await _pumpScreen(tester, FakeExpenseRepository(sampleExpenses()));

    final chickenChip = find.widgetWithText(FilterChip, 'Chicken');
    await tester.ensureVisible(chickenChip);
    await tester.tap(chickenChip);
    await tester.pumpAndSettle();

    expect(find.text('Chicken tikka stock'), findsOneWidget);
    expect(find.text('Morning milk'), findsNothing);
    expect(find.text('1 expense'), findsOneWidget);
    // The row and the totals bar both render 'Rs. 1500' — scope the
    // finder to the totals bar so the assertion targets the sum.
    expect(
      find.descendant(
        of: find.byKey(const Key('expense_history_totals')),
        matching: find.text('Rs. 1500'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('search filters the fetched list by title', (tester) async {
    await _pumpScreen(tester, FakeExpenseRepository(sampleExpenses()));

    await tester.enterText(
      find.byKey(const Key('expense_history_search')),
      'tikka',
    );
    await tester.pumpAndSettle();

    expect(find.text('Chicken tikka stock'), findsOneWidget);
    expect(find.text('Morning milk'), findsNothing);
    // The row and the totals bar both render 'Rs. 1500' — scope the
    // finder to the totals bar so the assertion targets the sum.
    expect(
      find.descendant(
        of: find.byKey(const Key('expense_history_totals')),
        matching: find.text('Rs. 1500'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('totals bar shows the count and sum of the visible expenses',
      (tester) async {
    await _pumpScreen(tester, FakeExpenseRepository(sampleExpenses()));

    expect(find.text('2 expenses'), findsOneWidget);
    expect(find.text('Rs. 3500'), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing matches', (tester) async {
    await _pumpScreen(tester, FakeExpenseRepository(const []));

    expect(find.text('No expenses found'), findsOneWidget);
  });

  testWidgets('shows the error state with a working retry button',
      (tester) async {
    await _pumpScreen(
      tester,
      FakeExpenseRepository(const [], failRange: true),
    );

    expect(find.text("Couldn't load expenses"), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    // Still failing, but the retry must not crash the screen.
    expect(find.text("Couldn't load expenses"), findsOneWidget);
  });

  testWidgets('voided expenses never appear in the operational list',
      (tester) async {
    await _pumpScreen(
      tester,
      FakeExpenseRepository([
        _expense(
          id: 'e1',
          title: 'Morning milk',
          category: ExpenseCategory.marketBills,
          amount: 2000,
          businessDate: DateTime(2026, 9, 28),
        ),
        _expense(
          id: 'e-voided',
          title: 'Voided drinks',
          category: ExpenseCategory.beveragesAndDrinks,
          amount: 9999,
          businessDate: DateTime(2026, 9, 28),
          voided: true,
        ),
      ]),
    );

    expect(find.text('Voided drinks'), findsNothing);
    expect(find.text('1 expense'), findsOneWidget);
    // The row and the totals bar both render 'Rs. 2000' — scope the
    // finder to the totals bar so the assertion targets the sum.
    expect(
      find.descendant(
        of: find.byKey(const Key('expense_history_totals')),
        matching: find.text('Rs. 2000'),
      ),
      findsOneWidget,
    );
  });
}
