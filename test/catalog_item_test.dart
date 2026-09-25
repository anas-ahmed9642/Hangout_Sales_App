import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/catalog_item.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';

void main() {
  group('CatalogItem', () {
    test('stores the complete catalog state', () {
      final createdAt = DateTime(2026, 9, 21);

      final item = CatalogItem(
        id: 'catalog-1',
        category: ExpenseCategory.beveragesAndDrinks,
        name: 'Coke 1ltr',
        brand: 'Coke',
        size: '1ltr',
        active: true,
        createdAt: createdAt,
      );

      expect(item.id, 'catalog-1');
      expect(
        item.category,
        ExpenseCategory.beveragesAndDrinks,
      );
      expect(item.name, 'Coke 1ltr');
      expect(item.brand, 'Coke');
      expect(item.size, '1ltr');
      expect(item.active, isTrue);
      expect(item.createdAt, createdAt);
    });

    test('copyWith changes only requested values', () {
      final original = CatalogItem(
        id: 'catalog-1',
        category: ExpenseCategory.chicken,
        name: 'Malai Boti',
        active: true,
        createdAt: DateTime(2026, 9, 21),
      );

      final updated = original.copyWith(
        name: 'Malai Boti Premium',
        active: false,
      );

      expect(updated.id, original.id);
      expect(updated.category, original.category);
      expect(updated.name, 'Malai Boti Premium');
      expect(updated.active, isFalse);
      expect(updated.createdAt, original.createdAt);
    });
  });
}