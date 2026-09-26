import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/chicken_purchase_line.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_line_item.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_expense_repository.dart';

void main() {
  group('expenseToMap / expenseFromMap', () {
    test('round-trips a plain expense', () {
      final expense = Expense(
        id: 'exp-1', title: 'Shop electricity', category: ExpenseCategory.electricity,
        amount: 12500, notes: 'August bill', date: DateTime(2026, 9, 23, 10, 30),
        businessDate: DateTime(2026, 9, 23),
      );
      final map = expenseToMap(expense);
      expect(map['id'], 'exp-1'); expect(map['category'], 'electricity'); expect(map['amount'], 12500.0);
      expect(map['date'], isA<Timestamp>()); expect(map['businessDate'], isA<Timestamp>());
      expect(map['voided'], false); expect(map['editCount'], 0); expect(map['workerName'], isNull);
      expect(map['chickenLines'], isNull); expect(map['lineItems'], isNull);
      final restored = expenseFromMap(map);
      expect(restored.id, 'exp-1'); expect(restored.title, 'Shop electricity'); expect(restored.category, ExpenseCategory.electricity);
      expect(restored.amount, 12500.0); expect(restored.notes, 'August bill'); expect(restored.date, DateTime(2026, 9, 23, 10, 30));
      expect(restored.businessDate, DateTime(2026, 9, 23)); expect(restored.voided, false); expect(restored.editCount, 0);
      expect(restored.workerName, isNull); expect(restored.chickenLines, isNull); expect(restored.lineItems, isNull);
    });

    test('round-trips a chicken expense with whole-kg lines', () {
      final expense = Expense(
        id: 'exp-2', title: 'Chicken', category: ExpenseCategory.chicken, amount: 6000,
        date: DateTime(2026, 9, 23, 9, 0), businessDate: DateTime(2026, 9, 23), pricePerKg: 1000,
        chickenLines: const [
          ChickenPurchaseLine(chickenType: 'Malai Boti', quantityKg: 2),
          ChickenPurchaseLine(chickenType: 'Fajita', quantityKg: 3),
          ChickenPurchaseLine(chickenType: 'Tikka', quantityKg: 1),
        ],
      );
      final restored = expenseFromMap(expenseToMap(expense));
      expect(restored.pricePerKg, 1000.0); expect(restored.chickenLines, hasLength(3));
      expect(restored.chickenLines![0].chickenType, 'Malai Boti'); expect(restored.chickenLines![0].quantityKg, 2);
      expect(restored.chickenLines![0].quantityKg, isA<int>()); expect(restored.chickenLines![2].quantityKg, 1);
    });

    test('round-trips a multi-line beverage expense', () {
      final expense = Expense(
        id: 'exp-3', title: 'Beverages', category: ExpenseCategory.beveragesAndDrinks, amount: 650,
        date: DateTime(2026, 9, 23, 11, 0), businessDate: DateTime(2026, 9, 23),
        lineItems: const [
          ExpenseLineItem(itemName: 'Cola Next 1ltr', price: 250),
          ExpenseLineItem(itemName: 'Coke 1ltr', price: 400),
        ],
      );
      final restored = expenseFromMap(expenseToMap(expense));
      expect(restored.lineItems, hasLength(2)); expect(restored.lineItems![0].itemName, 'Cola Next 1ltr');
      expect(restored.lineItems![0].price, 250.0); expect(restored.lineItems![1].price, 400.0);
    });

    test('round-trips a wages expense with worker name', () {
      final expense = Expense(
        id: 'exp-4', title: 'Weekly wages', category: ExpenseCategory.workersWages, amount: 15000,
        date: DateTime(2026, 9, 23, 18, 0), businessDate: DateTime(2026, 9, 23), workerName: 'Ahmed',
      );
      final restored = expenseFromMap(expenseToMap(expense));
      expect(restored.workerName, 'Ahmed');
    });

    test('defaults voided and editCount when missing from stored data', () {
      final map = expenseToMap(Expense(
        id: 'exp-5', title: 'Gas refill', category: ExpenseCategory.gas, amount: 3000,
        date: DateTime(2026, 9, 23), businessDate: DateTime(2026, 9, 23),
      ));
      map.remove('voided'); map.remove('editCount');
      final restored = expenseFromMap(map);
      expect(restored.voided, false); expect(restored.editCount, 0);
    });
  });
}
