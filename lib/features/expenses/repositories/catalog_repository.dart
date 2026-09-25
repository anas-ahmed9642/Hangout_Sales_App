import '../models/catalog_item.dart';
import '../models/expense_category.dart';

abstract class CatalogRepository {
  Stream<List<CatalogItem>> streamCatalog({
    ExpenseCategory? category,
    bool activeOnly = false,
  });

  Future<String> createCatalogItem({
    required ExpenseCategory category,
    required String name,
    String? brand,
    String? size,
  });

  Future<void> updateCatalogItem(
    String catalogItemId, {
    required String name,
    String? brand,
    String? size,
  });

  Future<void> setCatalogItemActive(
    String catalogItemId,
    bool active,
  );
  Future<int> seedVerifiedCatalog();
}