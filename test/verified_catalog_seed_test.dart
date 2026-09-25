import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/seed/verified_catalog_seed.dart';

void main() {
  group('Verified catalog seed', () {
    test('contains exactly 38 verified catalog items', () {
      expect(
        verifiedCatalogSeed,
        hasLength(38),
      );
    });

    test('contains the corrected category counts', () {
      final counts = <ExpenseCategory, int>{};

      for (final item in verifiedCatalogSeed) {
        counts[item.category] =
            (counts[item.category] ?? 0) + 1;
      }

      expect(
        counts[ExpenseCategory.chicken],
        3,
      );

      expect(
        counts[ExpenseCategory.vegetables],
        2,
      );

      expect(
        counts[ExpenseCategory.beveragesAndDrinks],
        7,
      );

      expect(
        counts[ExpenseCategory.packaging],
        5,
      );

      expect(
        counts[ExpenseCategory.marketBills],
        21,
      );
    });

    test('contains the seven verified beverage items', () {
      final beverages = verifiedCatalogSeed
          .where(
            (item) =>
                item.category ==
                ExpenseCategory.beveragesAndDrinks,
          )
          .map((item) => item.name)
          .toSet();

      expect(
        beverages,
        containsAll([
          'Cola Next 345ml',
          'Cola Next 1ltr',
          'Cola Next 1.5ltr',
          'Fizzup 345ml',
          'Fizzup 1ltr',
          'Fizzup 1.5ltr',
          'Coke 1ltr',
        ]),
      );
    });

    test('contains the five verified packaging items', () {
      final packagingItems = verifiedCatalogSeed
          .where(
            (item) =>
                item.category ==
                ExpenseCategory.packaging,
          )
          .map((item) => item.name)
          .toSet();

      expect(
        packagingItems,
        containsAll([
          'Boxes',
          'Shoppers',
          'P1',
          'Box Stopper',
          'Napkins',
        ]),
      );
    });

    test('contains the twenty-one verified market items', () {
      final marketItems = verifiedCatalogSeed
          .where(
            (item) =>
                item.category ==
                ExpenseCategory.marketBills,
          )
          .map((item) => item.name)
          .toSet();

      expect(
        marketItems,
        containsAll([
          'Mushroom Slices',
          'Black Olive',
          'Green Jalapeno',
          'Red Jalapeno',
          'Ketchup Sachet',
          'Chilli Garlic Sachet',
          'Tomato Ketchup 1kg',
          'Green Chilli Sauce 1kg',
          'Youngs Mayo 2kg (Blue)',
          'Goods Mayo (Carton)',
          'Acha Cheese (Blue) 2kg',
          'Dipitt Sriracha Sauce',
          'Crushed Chilli',
          'White Pepper',
          'Garlic Powder',
          'Rossmoore Mustard Sauce',
          'Irani Cream',
          'Safa Tomato Paste',
          'Chicken Pepperoni',
          'Chicken Sausage',
          'Chicken Powder',
        ]),
      );
    });

    test('beverages contain their verified brand and size metadata', () {
      final coke = verifiedCatalogSeed.firstWhere(
        (item) => item.name == 'Coke 1ltr',
      );

      expect(coke.brand, 'Coke');
      expect(coke.size, '1ltr');

      final colaNext = verifiedCatalogSeed.firstWhere(
        (item) => item.name == 'Cola Next 1.5ltr',
      );

      expect(colaNext.brand, 'Cola Next');
      expect(colaNext.size, '1.5ltr');
    });
  });
}