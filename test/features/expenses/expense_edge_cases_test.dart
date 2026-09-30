import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/core/services/business_day_service.dart';
import 'package:hangout_sales_app/features/expenses/models/chicken_purchase_line.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category_display.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_edit_input.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_history_filter.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_line_item.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_draft_provider.dart';
import 'package:hangout_sales_app/features/expenses/widgets/expense_formatters.dart';

import '../../helpers/test_container.dart';

ExpenseDraftNotifier newDraft() {
  return createTestContainer().read(expenseDraftProvider.notifier);
}

Expense chickenExpense() => Expense(
      id: 'chk1',
      title: 'Morning chicken',
      category: ExpenseCategory.chicken,
      amount: 7500,
      date: DateTime(2026, 9, 28, 10),
      businessDate: DateTime(2026, 9, 28),
      pricePerKg: 500,
      chickenLines: const [
        ChickenPurchaseLine(chickenType: 'Malai Boti', quantityKg: 10),
        ChickenPurchaseLine(chickenType: 'Chicken Tikka', quantityKg: 5),
      ],
    );

void main() {
  test('chicken totals use price per kilogram', () {
    final draft = newDraft();
    draft.setCategory(ExpenseCategory.chicken);
    draft.setTitle('Chicken run');
    draft.setPricePerKg(1000);
    draft.addChickenLine(chickenType: 'Malai Boti', quantityKg: 2);
    draft.addChickenLine(chickenType: 'Chicken Fajita', quantityKg: 3);
    draft.addChickenLine(chickenType: 'Chicken Tikka', quantityKg: 1);
    expect(draft.totalKg, 6);
    expect(draft.computedAmount, 6000);
  });

  test('catalog lines sum independently', () {
    final draft = newDraft();
    draft.setCategory(ExpenseCategory.packaging);
    draft.setTitle('Boxes');
    draft.addLineItem(itemName: 'Boxes', price: 1200);
    draft.addLineItem(itemName: 'Shoppers', price: 800);
    expect(draft.computedAmount, 2000);
  });

  test('blank titles and negative amounts are rejected', () {
    final draft = newDraft();
    draft.setCategory(ExpenseCategory.gas);
    draft.setTitle('  ');
    draft.setAmount(-100);
    expect(draft.validationErrors, contains('Title is required.'));
    expect(draft.validationErrors, contains('Amount must be greater than zero.'));
  });

  test('chicken validation catches empty lines and negative price', () {
    final draft = newDraft();
    draft.setCategory(ExpenseCategory.chicken);
    draft.setTitle('Chicken run');
    draft.setPricePerKg(-5);
    draft.addChickenLine(chickenType: ' ', quantityKg: 0);
    expect(draft.validationErrors,
        contains('Chicken quantity must be greater than zero.'));
    expect(draft.validationErrors,
        contains('Price per kg must be greater than zero.'));
  });

  test('built chicken expense is a snapshot', () {
    final draft = newDraft();
    draft.setCategory(ExpenseCategory.chicken);
    draft.setTitle('Chicken run');
    draft.setPricePerKg(1000);
    draft.addChickenLine(chickenType: 'Malai Boti', quantityKg: 2);
    final expense = draft.buildExpense(businessDate: DateTime(2026, 9, 28));
    draft.addChickenLine(chickenType: 'Extra', quantityKg: 9);
    expect(expense.chickenLines, hasLength(1));
  });

  test('built expense trims text fields', () {
    final draft = newDraft();
    draft.setCategory(ExpenseCategory.workersWages);
    draft.setTitle('  Weekly wage  ');
    draft.setWorkerName('  Bilal  ');
    draft.setAmount(12000);
    final expense = draft.buildExpense(businessDate: DateTime(2026, 9, 28));
    expect(expense.title, 'Weekly wage');
    expect(expense.workerName, 'Bilal');
  });

  test('business-day boundaries handle month, year and leap dates', () {
    const service = BusinessDayService();
    expect(service.businessDate(DateTime(2026, 9, 28, 4, 59, 59, 999)),
        DateTime(2026, 9, 27));
    expect(service.businessDate(DateTime(2026, 9, 28, 5)), DateTime(2026, 9, 28));
    expect(service.businessDate(DateTime(2026, 10, 1, 2)), DateTime(2026, 9, 30));
    expect(service.businessDate(DateTime(2027, 1, 1, 3)), DateTime(2026, 12, 31));
    expect(service.businessDate(DateTime(2028, 3, 1, 4)), DateTime(2028, 2, 29));
  });

  test('history filters normalize end dates', () {
    final filter = ExpenseHistoryFilter(
      start: DateTime(2028, 2, 20),
      end: DateTime(2028, 2, 28),
    );
    expect(filter.endExclusive, DateTime(2028, 2, 29));
    expect(filter.copyWith(clearCategory: true), filter);
  });

  test('category labels are distinct and formatters are stable', () {
    final names = ExpenseCategory.values.map((value) => value.displayName);
    expect(names.toSet(), hasLength(ExpenseCategory.values.length));
    expect(formatExpenseRs(1234), 'Rs. 1234');
    expect(formatExpenseRs(999.4), 'Rs. 999');
    expect(formatExpenseNumber(3.0), '3');
    expect(formatExpenseNumber(2.5), '2.5');
    expect(formatExpenseDay(DateTime(2026, 1, 5)), '5 Jan 2026');
    expect(formatExpenseTime(DateTime(2026, 9, 28, 5, 7)), '05:07');
  });

  test('line item model remains a separate catalog snapshot', () {
    const item = ExpenseLineItem(itemName: 'Onion', price: 200);
    expect(item.itemName, 'Onion');
    expect(item.price, 200);
    expect(chickenExpense().chickenLines, hasLength(2));
    expect(ExpenseEditInput.fromExpense(chickenExpense()).pricePerKg, 500);
  });
}
