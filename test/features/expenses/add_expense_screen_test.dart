import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/catalog_item.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/providers/catalog_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/catalog_repository.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';
import 'package:hangout_sales_app/features/expenses/screens/expense_screen.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> created = [];

  @override
  Future<void> createExpense(Expense expense) async {
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

CatalogItem _catalogItem(String name, ExpenseCategory category) {
  return CatalogItem(
    id: 'id-$name',
    category: category,
    name: name,
    active: true,
    createdAt: DateTime(2026, 1, 1),
  );
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

void main() {
  testWidgets(
    'selecting Chicken renders the chicken entry section',
    (tester) async {
      final expenses = FakeExpenseRepository();
      await tester.pumpWidget(
        _testApp(expenses: expenses, catalog: const []),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Select a category above to start.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Chicken'));
      await tester.pumpAndSettle();

      expect(find.text('Price per kg (Rs.)'), findsOneWidget);
      expect(find.text('Chicken lines'), findsOneWidget);
    },
  );

  testWidgets(
    'catalog shape shows only the selected category items',
    (tester) async {
      final expenses = FakeExpenseRepository();
      final catalog = [
        _catalogItem('Tomatoes', ExpenseCategory.vegetables),
        _catalogItem('Onions', ExpenseCategory.vegetables),
        _catalogItem('Sugar', ExpenseCategory.marketBills),
      ];
      await tester.pumpWidget(
        _testApp(expenses: expenses, catalog: catalog),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Vegetables'));
      await tester.pump();
      // Flush the catalog stream emission before asserting.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Tomatoes'), findsOneWidget);
      expect(find.text('Onions'), findsOneWidget);
      expect(find.text('Sugar'), findsNothing);

      await tester.ensureVisible(find.text('Tomatoes'));
      await tester.tap(find.text('Tomatoes'));
      await tester.pumpAndSettle();

      // One in the picker, one in the added-items list.
      expect(find.text('Tomatoes'), findsNWidgets(2));
    },
  );

  testWidgets(
    'valid chicken expense saves, clears the draft, and confirms',
    (tester) async {
      final expenses = FakeExpenseRepository();
      await tester.pumpWidget(
        _testApp(expenses: expenses, catalog: const []),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chicken'));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('save_expense_button'));
      expect(
        tester.widget<FilledButton>(saveButton).onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('expense_title_field')),
        'Daily chicken',
      );
      await tester.enterText(
        find.byKey(const Key('expense_price_per_kg_field')),
        '500',
      );
      await tester.tap(find.byKey(const Key('chicken_type_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Malai Boti').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('chicken_kg_field')),
        '10',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('add_chicken_line_button')),
      );
      await tester.tap(find.byKey(const Key('add_chicken_line_button')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(saveButton).onPressed,
        isNotNull,
      );

      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(expenses.created, hasLength(1));
      expect(expenses.created.single.title, 'Daily chicken');
      expect(expenses.created.single.amount, 5000);
      expect(
        find.text('Expense saved successfully!'),
        findsOneWidget,
      );
      // Draft cleared after save: the button is disabled again.
      expect(
        tester.widget<FilledButton>(saveButton).onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'switching categories inside one shape resets the fields',
    (tester) async {
      final expenses = FakeExpenseRepository();
      await tester.pumpWidget(
        _testApp(expenses: expenses, catalog: const []),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Utilities'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('expense_amount_field')),
      );
      await tester.enterText(
        find.byKey(const Key('expense_amount_field')),
        '1500',
      );
      await tester.pump();
      expect(find.text('1500'), findsOneWidget);

      await tester.ensureVisible(find.text('Gas'));
      await tester.tap(find.text('Gas'));
      await tester.pumpAndSettle();

      // The section rebuilt under a new ValueKey(category):
      // the stale amount is gone from the fresh field.
      expect(find.text('1500'), findsNothing);
    },
  );

  testWidgets(
    'summary lists validation errors for an incomplete draft',
    (tester) async {
      final expenses = FakeExpenseRepository();
      await tester.pumpWidget(
        _testApp(expenses: expenses, catalog: const []),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Internet'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Title is required.'));
      expect(find.text('Title is required.'), findsOneWidget);
      expect(
        find.text('Amount must be greater than zero.'),
        findsOneWidget,
      );
    },
  );
}
