import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/core/services/business_day_service.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';

void main() {
  const businessDayService = BusinessDayService();

  group('Expenses business-day wiring', () {
    test('expense after 5 AM belongs to the current calendar business date', () {
      final expenseDate = DateTime(2026, 9, 21, 5, 0);

      final businessDate = businessDayService.businessDate(expenseDate);

      final expense = Expense(
        id: 'expense-1',
        title: 'Utility bill',
        category: ExpenseCategory.utilities,
        amount: 500,
        date: expenseDate,
        businessDate: businessDate,
      );

      expect(
        expense.businessDate,
        DateTime(2026, 9, 21),
      );
    });

    test('expense before 5 AM belongs to the previous business date', () {
      final expenseDate = DateTime(2026, 9, 21, 4, 59);

      final businessDate = businessDayService.businessDate(expenseDate);

      final expense = Expense(
        id: 'expense-2',
        title: 'Gas',
        category: ExpenseCategory.gas,
        amount: 1200,
        date: expenseDate,
        businessDate: businessDate,
      );

      expect(
        expense.businessDate,
        DateTime(2026, 9, 20),
      );
    });

    test('expense at exactly 5 AM starts the new business date', () {
      final expenseDate = DateTime(2026, 9, 21, 5, 0);

      final businessDate = businessDayService.businessDate(expenseDate);

      expect(
        businessDate,
        DateTime(2026, 9, 21),
      );
    });

    test('late-night expense remains on the current business date', () {
      final expenseDate = DateTime(2026, 9, 21, 23, 30);

      final businessDate = businessDayService.businessDate(expenseDate);

      expect(
        businessDate,
        DateTime(2026, 9, 21),
      );
    });

    test('2 AM expense belongs to the previous business date', () {
      final expenseDate = DateTime(2026, 9, 22, 2, 0);

      final businessDate = businessDayService.businessDate(expenseDate);

      expect(
        businessDate,
        DateTime(2026, 9, 21),
      );
    });

    test('expense stores the normalized business date supplied by the service', () {
      final expenseDate = DateTime(2026, 9, 22, 1, 30);

      final businessDate = businessDayService.businessDate(expenseDate);

      final expense = Expense(
        id: 'expense-3',
        title: 'Worker wage',
        category: ExpenseCategory.workersWages,
        amount: 3000,
        date: expenseDate,
        businessDate: businessDate,
      );

      expect(expense.date, expenseDate);
      expect(expense.businessDate, DateTime(2026, 9, 21));
      expect(expense.businessDate.hour, 0);
      expect(expense.businessDate.minute, 0);
      expect(expense.businessDate.second, 0);
      expect(expense.businessDate.millisecond, 0);
      expect(expense.businessDate.microsecond, 0);
    });
  });
}