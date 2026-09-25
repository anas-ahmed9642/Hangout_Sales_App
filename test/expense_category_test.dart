import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';

void main() {
  group('ExpenseCategory', () {
    test('contains exactly the eleven fixed expense categories', () {
      expect(ExpenseCategory.values, hasLength(11));
    });

    test('contains every category defined by the Expenses roadmap', () {
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

    test('does not contain catalog items as categories', () {
      final categoryNames = ExpenseCategory.values
          .map((category) => category.name)
          .toSet();

      expect(categoryNames, isNot(contains('malaiBoti')));
      expect(categoryNames, isNot(contains('fajita')));
      expect(categoryNames, isNot(contains('tikka')));
      expect(categoryNames, isNot(contains('onion')));
      expect(categoryNames, isNot(contains('capsicum')));
      expect(categoryNames, isNot(contains('coke1ltr')));
      expect(categoryNames, isNot(contains('boxes')));
    });
  });
}