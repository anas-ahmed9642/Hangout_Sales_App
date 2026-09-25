import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/chicken_purchase_line.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_line_item.dart';
import 'package:hangout_sales_app/features/expenses/models/market_list.dart';

void main() {
  group('ChickenPurchaseLine', () {
    test('stores chicken type and whole-kilogram quantity', () {
      const line = ChickenPurchaseLine(
        chickenType: 'Malai Boti',
        quantityKg: 2,
      );

      expect(line.chickenType, 'Malai Boti');
      expect(line.quantityKg, 2);
    });
  });

  group('ExpenseLineItem', () {
    test('stores item name and independent price', () {
      const line = ExpenseLineItem(
        itemName: 'Coke 1ltr',
        price: 180,
      );

      expect(line.itemName, 'Coke 1ltr');
      expect(line.price, 180);
    });
  });

  group('ExpenseCategory', () {
    test('contains the eleven fixed business categories', () {
      expect(
        ExpenseCategory.values,
        hasLength(11),
      );

      expect(
        ExpenseCategory.values,
        containsAll([
          ExpenseCategory.marketBills,
          ExpenseCategory.vegetables,
          ExpenseCategory.chicken,
          ExpenseCategory.beveragesAndDrinks,
          ExpenseCategory.utilities,
          ExpenseCategory.gas,
          ExpenseCategory.electricity,
          ExpenseCategory.internet,
          ExpenseCategory.workersWages,
          ExpenseCategory.packaging,
          ExpenseCategory.miscellaneous,
        ]),
      );
    });
  });
    group('Expense', () {
    test('stores common expense fields with operational defaults', () {
      final date = DateTime(2026, 9, 21, 19, 30);
      final businessDate = DateTime(2026, 9, 21);

      final expense = Expense(
        id: 'expense-1',
        title: 'Electricity Bill',
        category: ExpenseCategory.electricity,
        amount: 4500,
        date: date,
        businessDate: businessDate,
      );

      expect(expense.id, 'expense-1');
      expect(expense.title, 'Electricity Bill');
      expect(expense.category, ExpenseCategory.electricity);
      expect(expense.amount, 4500);
      expect(expense.date, date);
      expect(expense.businessDate, businessDate);
      expect(expense.voided, isFalse);
      expect(expense.editCount, 0);
      expect(expense.notes, isNull);
      expect(expense.workerName, isNull);
      expect(expense.linkedMarketListId, isNull);
      expect(expense.pricePerKg, isNull);
      expect(expense.chickenLines, isNull);
      expect(expense.lineItems, isNull);
    });

    test('supports the Chicken-specific fields', () {
      const chickenLines = [
        ChickenPurchaseLine(
          chickenType: 'Malai Boti',
          quantityKg: 2,
        ),
        ChickenPurchaseLine(
          chickenType: 'Fajita',
          quantityKg: 3,
        ),
      ];

      final expense = Expense(
        id: 'expense-chicken',
        title: 'Chicken Purchase',
        category: ExpenseCategory.chicken,
        amount: 5000,
        date: DateTime(2026, 9, 21, 20),
        businessDate: DateTime(2026, 9, 21),
        pricePerKg: 1000,
        chickenLines: chickenLines,
      );

      expect(expense.pricePerKg, 1000);
      expect(expense.chickenLines, hasLength(2));
      expect(expense.chickenLines![0].chickenType, 'Malai Boti');
      expect(expense.chickenLines![0].quantityKg, 2);
      expect(expense.chickenLines![1].quantityKg, 3);
    });

    test('supports independent multi-line expense items', () {
      const lineItems = [
        ExpenseLineItem(
          itemName: 'Coke 1ltr',
          price: 180,
        ),
        ExpenseLineItem(
          itemName: 'Fizzup 1ltr',
          price: 160,
        ),
      ];

      final expense = Expense(
        id: 'expense-drinks',
        title: 'Beverages',
        category: ExpenseCategory.beveragesAndDrinks,
        amount: 340,
        date: DateTime(2026, 9, 21, 21),
        businessDate: DateTime(2026, 9, 21),
        lineItems: lineItems,
      );

      expect(expense.lineItems, hasLength(2));
      expect(expense.lineItems![0].itemName, 'Coke 1ltr');
      expect(expense.lineItems![0].price, 180);
      expect(expense.lineItems![1].itemName, 'Fizzup 1ltr');
      expect(expense.lineItems![1].price, 160);
    });

    test('supports Worker Wage and Market List extensions', () {
      final wageExpense = Expense(
        id: 'expense-wage',
        title: 'Worker Wage',
        category: ExpenseCategory.workersWages,
        amount: 2500,
        date: DateTime(2026, 9, 21, 22),
        businessDate: DateTime(2026, 9, 21),
        workerName: 'Worker A',
      );

      final marketExpense = Expense(
        id: 'expense-market',
        title: 'Market Bills',
        category: ExpenseCategory.marketBills,
        amount: 7500,
        date: DateTime(2026, 9, 21, 23),
        businessDate: DateTime(2026, 9, 21),
        linkedMarketListId: 'market-list-1',
      );

      expect(wageExpense.workerName, 'Worker A');
      expect(marketExpense.linkedMarketListId, 'market-list-1');
    });

    test('supports an explicitly voided expense and edit count', () {
      final expense = Expense(
        id: 'expense-voided',
        title: 'Old Utility Bill',
        category: ExpenseCategory.utilities,
        amount: 1000,
        date: DateTime(2026, 9, 21),
        businessDate: DateTime(2026, 9, 21),
        voided: true,
        editCount: 2,
      );

      expect(expense.voided, isTrue);
      expect(expense.editCount, 2);
    });
  });


    group('MarketListItem', () {
    test('stores catalog snapshot name and price', () {
      const item = MarketListItem(
        itemName: 'Onion',
        price: 450,
      );

      expect(item.itemName, 'Onion');
      expect(item.price, 450);
    });
  });

  group('MarketList', () {
    test('defaults to a draft list that has not been handed to a worker', () {
      final createdAt = DateTime(2026, 9, 21, 18);
      final businessDate = DateTime(2026, 9, 21);

      const items = [
        MarketListItem(
          itemName: 'Onion',
          price: 450,
        ),
        MarketListItem(
          itemName: 'Capsicum',
          price: 300,
        ),
      ];

      final marketList = MarketList(
        id: 'market-list-1',
        items: items,
        total: 750,
        businessDate: businessDate,
        createdAt: createdAt,
      );

      expect(marketList.id, 'market-list-1');
      expect(marketList.items, hasLength(2));
      expect(marketList.total, 750);
      expect(marketList.status, MarketListStatus.draft);
      expect(marketList.handedToWorker, isFalse);
      expect(marketList.reconciledExpenseId, isNull);
      expect(marketList.businessDate, businessDate);
      expect(marketList.createdAt, createdAt);
    });

    test('supports a confirmed list linked to an Expense', () {
      final marketList = MarketList(
        id: 'market-list-2',
        items: const [
          MarketListItem(
            itemName: 'Onion',
            price: 500,
          ),
        ],
        total: 500,
        status: MarketListStatus.confirmed,
        handedToWorker: true,
        reconciledExpenseId: 'expense-market-1',
        businessDate: DateTime(2026, 9, 21),
        createdAt: DateTime(2026, 9, 21, 19),
      );

      expect(marketList.status, MarketListStatus.confirmed);
      expect(marketList.handedToWorker, isTrue);
      expect(marketList.reconciledExpenseId, 'expense-market-1');
    });
  });
}