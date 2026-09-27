import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/core/services/business_day_service.dart';
import 'package:hangout_sales_app/features/expenses/models/catalog_item.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/providers/catalog_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/catalog_repository.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';
import 'package:hangout_sales_app/features/expenses/screens/expense_screen.dart';

/// Phase-8-specific behaviors of the save flow: the confirmation dialog,
/// cancel semantics, the in-flight guard, and failure handling.
///
/// The happy-path save itself (Save → dialog → Confirm → write) is covered
/// integration-style by the chicken test in add_expense_screen_test.dart.
class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> created = [];

  /// When set, [createExpense] waits on it before recording the write.
  Completer<void>? gate;

  /// When set, [createExpense] throws it instead of recording the write.
  Object? throwOnCreate;

  @override
  Future<void> createExpense(Expense expense) async {
    if (throwOnCreate != null) {
      throw throwOnCreate!;
    }
    final pendingGate = gate;
    if (pendingGate != null) {
      await pendingGate.future;
    }
    created.add(expense);
  }

  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) =>
      Stream.value(const []);

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return const [];
  }

  @override
  Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return 0;
  }

  @override
  Future<Expense?> getExpense(String expenseId) async => null;

  @override
  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {}

  @override
  Future<void> voidExpense(
    String expenseId, {
    required String changeReason,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getExpenseHistory(
    String expenseId,
  ) async {
    return const [];
  }
}

class FakeCatalogRepository implements CatalogRepository {
  final List<CatalogItem> items;

  FakeCatalogRepository(this.items);

  @override
  Stream<List<CatalogItem>> streamCatalog({
    ExpenseCategory? category,
    bool activeOnly = false,
  }) {
    if (category == null) {
      return Stream.value(items);
    }
    return Stream.value(
      items.where((item) => item.category == category).toList(),
    );
  }

  @override
  Future<String> createCatalogItem({
    required ExpenseCategory category,
    required String name,
    String? brand,
    String? size,
  }) async {
    return 'fake-id';
  }

  @override
  Future<void> updateCatalogItem(
    String catalogItemId, {
    required String name,
    String? brand,
    String? size,
  }) async {}

  @override
  Future<void> setCatalogItemActive(
    String catalogItemId,
    bool active,
  ) async {}

  @override
  Future<int> seedVerifiedCatalog() async => 0;
}

Widget _testApp({
  required FakeExpenseRepository expenses,
  required List<CatalogItem> catalog,
}) {
  return ProviderScope(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(expenses),
      catalogRepositoryProvider
          .overrideWithValue(FakeCatalogRepository(catalog)),
    ],
    child: const MaterialApp(
      home: ExpenseScreen(),
    ),
  );
}

String _formatDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Fills a valid plain-shape draft (Utilities): title + amount.
Future<void> _fillPlainDraft(WidgetTester tester) async {
  await tester.tap(find.text('Utilities'));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('expense_title_field')),
    'Internet bill',
  );
  await tester.enterText(
    find.byKey(const Key('expense_amount_field')),
    '2500',
  );
  await tester.pump();
}

Future<void> _tapSave(WidgetTester tester) async {
  final saveButton = find.byKey(const Key('save_expense_button'));
  await tester.ensureVisible(saveButton);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'save opens a confirmation dialog and writes nothing before confirm',
    (tester) async {
      final expenses = FakeExpenseRepository();
      await tester.pumpWidget(
        _testApp(expenses: expenses, catalog: const []),
      );
      await tester.pumpAndSettle();

      await _fillPlainDraft(tester);
      await _tapSave(tester);

      final dialog = find.byKey(const Key('save_confirmation_dialog'));
      expect(dialog, findsOneWidget);

      // The dialog shows what is about to be saved…
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Internet bill'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Utilities')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('Rs. 2500')),
        findsOneWidget,
      );
      final businessDate =
          const BusinessDayService().businessDate(DateTime.now());
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(_formatDate(businessDate)),
        ),
        findsOneWidget,
      );

      // …but nothing has been written yet.
      expect(expenses.created, isEmpty);
    },
  );

  testWidgets(
    'cancel closes the dialog, writes nothing, and keeps the draft',
    (tester) async {
      final expenses = FakeExpenseRepository();
      await tester.pumpWidget(
        _testApp(expenses: expenses, catalog: const []),
      );
      await tester.pumpAndSettle();

      await _fillPlainDraft(tester);
      await _tapSave(tester);

      expect(
        find.byKey(const Key('save_confirmation_dialog')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('cancel_save_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('save_confirmation_dialog')),
        findsNothing,
      );
      expect(expenses.created, isEmpty);

      // The draft survived: the entered title is still in the field and
      // the save button is still enabled.
      expect(find.text('Internet bill'), findsOneWidget);
      final saveButton = find.byKey(const Key('save_expense_button'));
      expect(
        tester.widget<FilledButton>(saveButton).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'confirm saves the computed line-item amount with the business date',
    (tester) async {
      final expenses = FakeExpenseRepository();
      await tester.pumpWidget(
        _testApp(
          expenses: expenses,
          catalog: [
            CatalogItem(
              id: 'id-tomatoes',
              category: ExpenseCategory.vegetables,
              name: 'Tomatoes',
              active: true,
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vegetables'));
      await tester.pump();
      // Flush the catalog stream emission before asserting.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Tomatoes'));
      await tester.tap(find.text('Tomatoes'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('expense_title_field')),
        'Veg run',
      );
      await tester.enterText(
        find.byKey(const Key('line_price_field_0')),
        '350',
      );
      await tester.pump();

      await _tapSave(tester);

      await tester.tap(find.byKey(const Key('confirm_save_button')));
      await tester.pumpAndSettle();

      expect(expenses.created, hasLength(1));
      final saved = expenses.created.single;
      // Computed from the line item (Rs. 350), not typed anywhere else.
      expect(saved.amount, 350);
      expect(
        saved.businessDate,
        const BusinessDayService().businessDate(DateTime.now()),
      );
    },
  );

  testWidgets(
    'save button is disabled while a confirmed save is in flight',
    (tester) async {
      final expenses = FakeExpenseRepository()
        ..gate = Completer<void>();
      await tester.pumpWidget(
        _testApp(expenses: expenses, catalog: const []),
      );
      await tester.pumpAndSettle();

      await _fillPlainDraft(tester);
      await _tapSave(tester);
      await tester.tap(find.byKey(const Key('confirm_save_button')));
      // Pumps, not pumpAndSettle: the progress indicator animates forever
      // while the write is gated.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final saveButton = find.byKey(const Key('save_expense_button'));
      expect(
        tester.widget<FilledButton>(saveButton).onPressed,
        isNull,
      );

      expenses.gate!.complete();
      await tester.pumpAndSettle();

      expect(expenses.created, hasLength(1));
      expect(
        find.text('Expense saved successfully!'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'failed save keeps the draft and reports the error',
    (tester) async {
      final expenses = FakeExpenseRepository()
        ..throwOnCreate = Exception('offline');
      await tester.pumpWidget(
        _testApp(expenses: expenses, catalog: const []),
      );
      await tester.pumpAndSettle();

      await _fillPlainDraft(tester);
      await _tapSave(tester);
      await tester.tap(find.byKey(const Key('confirm_save_button')));
      await tester.pumpAndSettle();

      expect(expenses.created, isEmpty);
      expect(
        find.textContaining('Failed to save expense'),
        findsOneWidget,
      );

      // The draft survived the failure: everything is still entered and
      // the save button is enabled again for a retry.
      expect(find.text('Internet bill'), findsOneWidget);
      final saveButton = find.byKey(const Key('save_expense_button'));
      expect(
        tester.widget<FilledButton>(saveButton).onPressed,
        isNotNull,
      );
    },
  );
}
