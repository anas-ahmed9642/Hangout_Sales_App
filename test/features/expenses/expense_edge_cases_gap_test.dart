import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/core/services/business_day_service.dart';
import 'package:hangout_sales_app/features/expenses/models/chicken_purchase_line.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category_display.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_edit_input.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_history_filter.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_line_item.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_actions_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_draft_provider.dart';
import 'package:hangout_sales_app/features/expenses/widgets/expense_formatters.dart';

import '../../helpers/test_container.dart';


ExpenseDraftNotifier newDraft() {
  final container = createTestContainer();
  return container.read(expenseDraftProvider.notifier);
}

ExpenseDraftNotifier chickenDraft({
  required double pricePerKg,
  required List<int> kilograms,
}) {
  const types = ['Malai Boti', 'Chicken Fajita', 'Chicken Tikka'];
  final draft = newDraft();
  draft.setCategory(ExpenseCategory.chicken);
  draft.setTitle('Chicken run');
  draft.setPricePerKg(pricePerKg);
  for (var i = 0; i < kilograms.length; i++) {
    draft.addChickenLine(
      chickenType: types[i % types.length],
      quantityKg: kilograms[i],
    );
  }
  return draft;
}

Expense makeExpense({
  required String id,
  required String title,
  required ExpenseCategory category,
  required double amount,
  String? notes,
  String? workerName,
  double? pricePerKg,
  List<ChickenPurchaseLine>? chickenLines,
  List<ExpenseLineItem>? lineItems,
}) {
  return Expense(
    id: id,
    title: title,
    category: category,
    amount: amount,
    notes: notes,
    date: DateTime(2026, 9, 28, 10),
    businessDate: DateTime(2026, 9, 28),
    workerName: workerName,
    pricePerKg: pricePerKg,
    chickenLines: chickenLines,
    lineItems: lineItems,
  );
}

Expense chickenExpense() => makeExpense(
      id: 'chk1',
      title: 'Morning chicken',
      category: ExpenseCategory.chicken,
      amount: 7500,
      pricePerKg: 500,
      chickenLines: const [
        ChickenPurchaseLine(chickenType: 'Malai Boti', quantityKg: 10),
        ChickenPurchaseLine(chickenType: 'Chicken Tikka', quantityKg: 5),
      ],
    );

Expense marketBillsExpense() => makeExpense(
      id: 'mb1',
      title: 'Market run',
      category: ExpenseCategory.marketBills,
      amount: 500,
      lineItems: const [
        ExpenseLineItem(itemName: 'Onion', price: 200),
        ExpenseLineItem(itemName: 'Tomato', price: 300),
      ],
    );

void main() {

  group('draft money calculations', () {
    test('chicken: a large whole-kilogram order stays exact', () {
      final draft = chickenDraft(pricePerKg: 1250, kilograms: [250]);

      expect(draft.computedAmount, 312500);
    });

    test('chicken: removing a line lowers the amount immediately', () {
      final draft = chickenDraft(pricePerKg: 1000, kilograms: [2, 3, 1]);

      draft.removeChickenLine(1);

      expect(draft.totalKg, 3);
      expect(draft.computedAmount, 3000);
    });

    test('chicken: an exactly representable half-rupee price multiplies '
        'cleanly', () {
      final draft = chickenDraft(pricePerKg: 1234.5, kilograms: [7]);

      expect(draft.computedAmount, 8641.5);
    });

    test('beverages: every line carries its own independent price', () {
      final draft = newDraft();
      draft.setCategory(ExpenseCategory.beveragesAndDrinks);
      draft.addLineItem(itemName: 'Cola Next 1ltr', price: 200);
      draft.addLineItem(itemName: 'Coke 1ltr', price: 250);
      draft.addLineItem(itemName: 'Fizzup 345ml', price: 90);

      expect(draft.computedAmount, 540);
    });

    test('beverages: the same item on two lines keeps two separate prices',
        () {
      final draft = newDraft();
      draft.setCategory(ExpenseCategory.beveragesAndDrinks);
      draft.addLineItem(itemName: 'Cola Next 1ltr', price: 200);
      draft.addLineItem(itemName: 'Cola Next 1ltr', price: 220);

      expect(draft.computedAmount, 420);
    });

    test('plain and wages shapes use the entered amount', () {
      final plain = newDraft();
      plain.setCategory(ExpenseCategory.gas);
      plain.setAmount(4500);
      expect(plain.computedAmount, 4500);

      final wages = newDraft();
      wages.setCategory(ExpenseCategory.workersWages);
      wages.setAmount(12000);
      expect(wages.computedAmount, 12000);
    });

    test('with no category the computed amount is zero', () {
      expect(newDraft().computedAmount, 0);
    });

  });

  group('draft validation edge cases', () {
    test('a whitespace-only worker name is rejected', () {
      final draft = newDraft();
      draft.setCategory(ExpenseCategory.workersWages);
      draft.setTitle('Weekly wage');
      draft.setWorkerName('   ');
      draft.setAmount(12000);

      expect(draft.validationErrors, contains('Worker name is required.'));
    });

    test('an empty chicken draft reports every missing piece at once', () {
      final draft = newDraft();
      draft.setCategory(ExpenseCategory.chicken);

      expect(
        draft.validationErrors,
        containsAll([
          'Title is required.',
          'Add at least one chicken line.',
          'Price per kg must be greater than zero.',
        ]),
      );
    });

    test('a catalog line with no price or no name is rejected', () {
      final draft = newDraft();
      draft.setCategory(ExpenseCategory.vegetables);
      draft.setTitle('Veg run');
      draft.addLineItem(itemName: 'Onion', price: 0);
      draft.addLineItem(itemName: '  ', price: 100);

      expect(
        draft.validationErrors,
        containsAll([
          'Item price must be greater than zero.',
          'Each item needs a name.',
        ]),
      );
    });

  });

  group('built expense edge cases', () {
    test('only the fields of its own shape are populated', () {
      final plain = newDraft();
      plain.setCategory(ExpenseCategory.gas);
      plain.setTitle('Gas cylinder');
      plain.setAmount(4500);
      final plainExpense =
          plain.buildExpense(businessDate: DateTime(2026, 9, 28));
      expect(plainExpense.workerName, isNull);
      expect(plainExpense.pricePerKg, isNull);
      expect(plainExpense.chickenLines, isNull);
      expect(plainExpense.lineItems, isNull);

      final chicken = chickenDraft(pricePerKg: 1000, kilograms: [2]);
      final builtChicken =
          chicken.buildExpense(businessDate: DateTime(2026, 9, 28));
      expect(builtChicken.pricePerKg, 1000);
      expect(builtChicken.chickenLines, hasLength(1));
      expect(builtChicken.lineItems, isNull);
      expect(builtChicken.workerName, isNull);

      final catalog = newDraft();
      catalog.setCategory(ExpenseCategory.packaging);
      catalog.setTitle('Boxes');
      catalog.addLineItem(itemName: 'Boxes', price: 1200);
      final catalogExpense =
          catalog.buildExpense(businessDate: DateTime(2026, 9, 28));
      expect(catalogExpense.lineItems, hasLength(1));
      expect(catalogExpense.pricePerKg, isNull);
      expect(catalogExpense.chickenLines, isNull);
    });

    test('the built line lists cannot be mutated', () {
      final chicken = chickenDraft(pricePerKg: 1000, kilograms: [2]);
      final builtChicken =
          chicken.buildExpense(businessDate: DateTime(2026, 9, 28));
      expect(
        () => builtChicken.chickenLines!.add(
          const ChickenPurchaseLine(chickenType: 'Extra', quantityKg: 1),
        ),
        throwsUnsupportedError,
      );

      final catalog = newDraft();
      catalog.setCategory(ExpenseCategory.packaging);
      catalog.setTitle('Boxes');
      catalog.addLineItem(itemName: 'Boxes', price: 1200);
      final catalogExpense =
          catalog.buildExpense(businessDate: DateTime(2026, 9, 28));
      expect(
        () => catalogExpense.lineItems!.add(
          const ExpenseLineItem(itemName: 'Extra', price: 1),
        ),
        throwsUnsupportedError,
      );
    });

    test('every build gets a fresh id', () {
      final draft = chickenDraft(pricePerKg: 1000, kilograms: [2]);

      final first = draft.buildExpense(businessDate: DateTime(2026, 9, 28));
      final second = draft.buildExpense(businessDate: DateTime(2026, 9, 28));

      expect(first.id, isNot(second.id));
    });

    test('uses the supplied business date and timestamp exactly', () {
      final draft = chickenDraft(pricePerKg: 1000, kilograms: [2]);
      final savedAt = DateTime(2026, 9, 29, 2, 15);

      final expense = draft.buildExpense(
        businessDate: DateTime(2026, 9, 28),
        createdAt: savedAt,
      );

      expect(expense.businessDate, DateTime(2026, 9, 28));
      expect(expense.date, savedAt);
    });

  });

  group('business-day boundary edges', () {
    const service = BusinessDayService();

    test('midnight belongs to the previous business day', () {
      expect(service.businessDate(DateTime(2026, 9, 29)), DateTime(2026, 9, 28));
    });

    test('the result is always normalized to midnight', () {
      final result = service.businessDate(DateTime(2026, 9, 28, 23, 59, 59));

      expect(result, DateTime(2026, 9, 28));
      expect(result.hour, 0);
      expect(result.minute, 0);
    });

    test('rolls back onto a leap day, and onto Feb 28 in a common year', () {
      expect(
        service.businessDate(DateTime(2028, 3, 1, 4)),
        DateTime(2028, 2, 29),
      );
      expect(
        service.businessDate(DateTime(2027, 3, 1, 4)),
        DateTime(2027, 2, 28),
      );
    });

  });

  group('history filter edges', () {
    test('endExclusive crosses a year boundary and a leap day', () {
      expect(
        ExpenseHistoryFilter(
          start: DateTime(2026, 12, 25),
          end: DateTime(2026, 12, 31),
        ).endExclusive,
        DateTime(2027, 1, 1),
      );
      expect(
        ExpenseHistoryFilter(
          start: DateTime(2028, 2, 20),
          end: DateTime(2028, 2, 28),
        ).endExclusive,
        DateTime(2028, 2, 29),
      );
    });

    test('clearCategory removes the category and equal filters compare equal',
        () {
      final base = ExpenseHistoryFilter(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 30),
      );
      final withCategory = base.copyWith(category: ExpenseCategory.gas);

      expect(withCategory.category, ExpenseCategory.gas);
      expect(withCategory.copyWith(clearCategory: true), base);
      expect(
        withCategory.copyWith(clearCategory: true).hashCode,
        base.hashCode,
      );
      expect(withCategory == base, isFalse);
    });

  });

  group('edit input and diff edges', () {
    test('ExpenseEditInput.fromExpense mirrors every shape', () {
      final chicken = ExpenseEditInput.fromExpense(chickenExpense());
      expect(chicken.title, 'Morning chicken');
      expect(chicken.pricePerKg, 500);
      expect(chicken.chickenQuantities, [10, 5]);
      expect(chicken.notes, '');
      expect(chicken.workerName, '');

      final catalog = ExpenseEditInput.fromExpense(marketBillsExpense());
      expect(catalog.lineItemPrices, [200, 300]);

      final wages = ExpenseEditInput.fromExpense(
        makeExpense(
          id: 'w1',
          title: 'Weekly wage',
          category: ExpenseCategory.workersWages,
          amount: 12000,
          workerName: 'Bilal',
        ),
      );
      expect(wages.workerName, 'Bilal');
      expect(wages.amount, 12000);
    });

    test('computeEditedAmount for chicken matches the draft formula', () {
      final original = chickenExpense();
      final draft = chickenDraft(pricePerKg: 500, kilograms: [10, 5]);

      final edited = computeEditedAmount(
        original,
        ExpenseEditInput.fromExpense(original),
      );

      expect(edited, 7500);
      expect(edited, draft.computedAmount);
    });

    test('swapping chicken quantities changes the lines but not the amount',
        () {
      final original = chickenExpense();

      final changes = buildExpenseChanges(
        original,
        const ExpenseEditInput(
          title: 'Morning chicken',
          pricePerKg: 500,
          chickenQuantities: [5, 10],
        ),
      );

      expect(changes.keys, ['chickenLines']);
      expect(changes['chickenLines'], [
        {'chickenType': 'Malai Boti', 'quantityKg': 5},
        {'chickenType': 'Chicken Tikka', 'quantityKg': 10},
      ]);
    });

    test('swapping catalog prices changes the lines but not the amount', () {
      final changes = buildExpenseChanges(
        marketBillsExpense(),
        const ExpenseEditInput(
          title: 'Market run',
          lineItemPrices: [300, 200],
        ),
      );

      expect(changes.keys, ['lineItems']);
    });

    test('a Market Bills price change rewrites the lines and the amount', () {
      final changes = buildExpenseChanges(
        marketBillsExpense(),
        const ExpenseEditInput(
          title: 'Market run',
          lineItemPrices: [250, 300],
        ),
      );

      expect(changes.keys, unorderedEquals(['lineItems', 'amount']));
      expect(changes['amount'], 550);
    });

    test('padding the title or adding blank notes is not a change', () {
      final original = makeExpense(
        id: 'plain1',
        title: 'Gas cylinder',
        category: ExpenseCategory.gas,
        amount: 4500,
      );

      final changes = buildExpenseChanges(
        original,
        const ExpenseEditInput(
          title: '  Gas cylinder  ',
          notes: '   ',
          amount: 4500,
        ),
      );

      expect(changes, isEmpty);
    });

    test('a zero-kg chicken quantity is rejected', () {
      final errors = validateExpenseEdit(
        chickenExpense(),
        const ExpenseEditInput(
          title: 'Morning chicken',
          pricePerKg: 500,
          chickenQuantities: [0, 5],
        ),
      );

      expect(errors, contains('Chicken quantity must be greater than zero.'));
    });

  });
}
