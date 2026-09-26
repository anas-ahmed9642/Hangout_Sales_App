import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_draft.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_draft_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';

class RecordingExpenseRepository implements ExpenseRepository {
  final List<Expense> created = [];

  @override
  Future<void> createExpense(Expense expense) async {
    created.add(expense);
  }

  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) {
    throw UnimplementedError();
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Expense?> getExpense(String expenseId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> voidExpense(
    String expenseId, {
    required String changeReason,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getExpenseHistory(
    String expenseId,
  ) {
    throw UnimplementedError();
  }
}

void main() {
  final businessDate = DateTime(2026, 9, 26);

  ProviderContainer makeContainer(RecordingExpenseRepository repository) {
    final container = ProviderContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  ExpenseDraftNotifier notifierOf(ProviderContainer container) {
    return container.read(expenseDraftProvider.notifier);
  }

  group('initial state', () {
    test('starts with no category and cannot confirm', () {
      final container = makeContainer(RecordingExpenseRepository());

      expect(container.read(expenseDraftProvider).category, isNull);
      expect(
        notifierOf(container).validationErrors,
        contains('Select an expense category.'),
      );
      expect(notifierOf(container).canConfirm, isFalse);
    });

    test('every category maps to its entry shape', () {
      expect(
        ExpenseCategory.utilities.entryShape,
        ExpenseEntryShape.plain,
      );
      expect(ExpenseCategory.gas.entryShape, ExpenseEntryShape.plain);
      expect(
        ExpenseCategory.electricity.entryShape,
        ExpenseEntryShape.plain,
      );
      expect(
        ExpenseCategory.internet.entryShape,
        ExpenseEntryShape.plain,
      );
      expect(
        ExpenseCategory.miscellaneous.entryShape,
        ExpenseEntryShape.plain,
      );
      expect(
        ExpenseCategory.chicken.entryShape,
        ExpenseEntryShape.chicken,
      );
      expect(
        ExpenseCategory.workersWages.entryShape,
        ExpenseEntryShape.wages,
      );
      expect(
        ExpenseCategory.marketBills.entryShape,
        ExpenseEntryShape.catalogItems,
      );
      expect(
        ExpenseCategory.vegetables.entryShape,
        ExpenseEntryShape.catalogItems,
      );
      expect(
        ExpenseCategory.beveragesAndDrinks.entryShape,
        ExpenseEntryShape.catalogItems,
      );
      expect(
        ExpenseCategory.packaging.entryShape,
        ExpenseEntryShape.catalogItems,
      );
    });
  });

  group('category switching', () {
    test('changing category restarts the draft', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.chicken);
      notifier.setTitle('Morning chicken');
      notifier.addChickenLine(chickenType: 'Broiler', quantityKg: 5);
      notifier.setPricePerKg(400);

      notifier.setCategory(ExpenseCategory.utilities);

      final draft = container.read(expenseDraftProvider);
      expect(draft.category, ExpenseCategory.utilities);
      expect(draft.title, isEmpty);
      expect(draft.chickenLines, isEmpty);
      expect(draft.pricePerKg, 0);
    });
  });

  group('plain shape', () {
    test('builds a valid expense with the manual amount', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.utilities);
      notifier.setTitle('Electricity bill');
      notifier.setAmount(2500);
      notifier.setNotes('September');

      expect(notifier.canConfirm, isTrue);
      expect(notifier.computedAmount, 2500);

      final expense = notifier.buildExpense(businessDate: businessDate);
      expect(expense.title, 'Electricity bill');
      expect(expense.category, ExpenseCategory.utilities);
      expect(expense.amount, 2500);
      expect(expense.notes, 'September');
      expect(expense.businessDate, businessDate);
      expect(expense.id, isNotEmpty);
      expect(expense.workerName, isNull);
      expect(expense.pricePerKg, isNull);
      expect(expense.chickenLines, isNull);
      expect(expense.lineItems, isNull);
    });

    test('empty notes become null on the built expense', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.gas);
      notifier.setTitle('Gas refill');
      notifier.setAmount(1800);

      final expense = notifier.buildExpense(businessDate: businessDate);
      expect(expense.notes, isNull);
    });

    test('requires a title and a positive amount', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.internet);

      expect(
        notifier.validationErrors,
        contains('Title is required.'),
      );
      expect(
        notifier.validationErrors,
        contains('Amount must be greater than zero.'),
      );

      notifier.setTitle('Internet');
      expect(
        notifier.validationErrors,
        contains('Amount must be greater than zero.'),
      );
      expect(notifier.canConfirm, isFalse);
    });
  });

  group('chicken shape', () {
    test('computes amount from lines and price per kg', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.chicken);
      notifier.setTitle('Morning chicken');
      notifier.addChickenLine(chickenType: 'Broiler', quantityKg: 5);
      notifier.addChickenLine(chickenType: 'Desi', quantityKg: 3);
      notifier.setPricePerKg(400);

      expect(notifier.totalKg, 8);
      expect(notifier.computedAmount, 3200);
      expect(notifier.canConfirm, isTrue);

      final expense = notifier.buildExpense(businessDate: businessDate);
      expect(expense.amount, 3200);
      expect(expense.pricePerKg, 400);
      expect(expense.chickenLines, hasLength(2));
      expect(expense.chickenLines!.first.chickenType, 'Broiler');
      expect(expense.chickenLines!.first.quantityKg, 5);
      expect(expense.workerName, isNull);
      expect(expense.lineItems, isNull);
    });

    test('requires lines, quantities, and a price per kg', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.chicken);
      notifier.setTitle('Chicken');

      expect(
        notifier.validationErrors,
        contains('Add at least one chicken line.'),
      );
      expect(
        notifier.validationErrors,
        contains('Price per kg must be greater than zero.'),
      );

      notifier.addChickenLine(chickenType: 'Broiler', quantityKg: 0);
      expect(
        notifier.validationErrors,
        contains('Chicken quantity must be greater than zero.'),
      );
    });

    test('updates and removes chicken lines; ignores bad indexes', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.chicken);
      notifier.addChickenLine(chickenType: 'Broiler', quantityKg: 5);
      notifier.addChickenLine(chickenType: 'Desi', quantityKg: 3);

      notifier.updateChickenLine(0, chickenType: 'Broiler', quantityKg: 7);
      expect(notifier.totalKg, 10);

      notifier.removeChickenLine(1);
      expect(notifier.totalKg, 7);

      notifier.updateChickenLine(5, chickenType: 'X', quantityKg: 1);
      notifier.removeChickenLine(-1);
      expect(notifier.totalKg, 7);
    });
  });

  group('catalog items shape', () {
    test('sums line items and stores names as plain text', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.marketBills);
      notifier.setTitle('Weekly market run');
      notifier.addLineItem(itemName: 'Tomatoes', price: 200);
      notifier.addLineItem(itemName: 'Onions', price: 450);

      expect(notifier.computedAmount, 650);
      expect(notifier.canConfirm, isTrue);

      final expense = notifier.buildExpense(businessDate: businessDate);
      expect(expense.amount, 650);
      expect(
        expense.lineItems!.map((item) => item.itemName).toList(),
        ['Tomatoes', 'Onions'],
      );
      expect(expense.chickenLines, isNull);
      expect(expense.workerName, isNull);
    });

    test('requires at least one item with a name and positive price', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.packaging);
      notifier.setTitle('Boxes');

      expect(
        notifier.validationErrors,
        contains('Add at least one item.'),
      );

      notifier.addLineItem(itemName: '', price: 0);
      expect(
        notifier.validationErrors,
        contains('Each item needs a name.'),
      );
      expect(
        notifier.validationErrors,
        contains('Item price must be greater than zero.'),
      );
    });

    test('updates and removes line items', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.vegetables);
      notifier.addLineItem(itemName: 'Tomatoes', price: 200);
      notifier.addLineItem(itemName: 'Onions', price: 450);

      notifier.updateLineItem(0, itemName: 'Tomatoes', price: 250);
      expect(notifier.computedAmount, 700);

      notifier.removeLineItem(1);
      expect(notifier.computedAmount, 250);
    });
  });

  group('wages shape', () {
    test('requires a worker name and saves it on the expense', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.workersWages);
      notifier.setTitle('Weekly wages');
      notifier.setAmount(5000);

      expect(
        notifier.validationErrors,
        contains('Worker name is required.'),
      );

      notifier.setWorkerName('Ahmed');
      expect(notifier.canConfirm, isTrue);

      final expense = notifier.buildExpense(businessDate: businessDate);
      expect(expense.workerName, 'Ahmed');
      expect(expense.amount, 5000);
      expect(expense.lineItems, isNull);
    });
  });

  group('build and save', () {
    test('buildExpense throws StateError when the draft is invalid', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.utilities);

      expect(
        () => notifier.buildExpense(businessDate: businessDate),
        throwsStateError,
      );
    });

    test('saveExpense persists the built expense through the repository',
        () async {
      final repository = RecordingExpenseRepository();
      final container = makeContainer(repository);
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.utilities);
      notifier.setTitle('Electricity bill');
      notifier.setAmount(2500);

      await notifier.saveExpense(businessDate: businessDate);

      expect(repository.created, hasLength(1));
      final saved = repository.created.single;
      expect(saved.title, 'Electricity bill');
      expect(saved.amount, 2500);
      expect(saved.businessDate, businessDate);
      expect(saved.id, isNotEmpty);
    });

    test('clearDraft resets to the initial state', () {
      final container = makeContainer(RecordingExpenseRepository());
      final notifier = notifierOf(container);

      notifier.setCategory(ExpenseCategory.chicken);
      notifier.setTitle('Chicken');
      notifier.addChickenLine(chickenType: 'Broiler', quantityKg: 5);

      notifier.clearDraft();

      final draft = container.read(expenseDraftProvider);
      expect(draft.category, isNull);
      expect(draft.title, isEmpty);
      expect(draft.chickenLines, isEmpty);
      expect(notifier.canConfirm, isFalse);
    });
  });
}
