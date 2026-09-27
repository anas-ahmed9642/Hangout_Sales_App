import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog_item.dart';
import '../models/expense_category.dart';
import 'catalog_repository_provider.dart';

final selectedCatalogCategoryProvider =
    StateProvider.autoDispose<ExpenseCategory>(
  (ref) => ExpenseCategory.marketBills,
);

/// Catalog items for a single [ExpenseCategory], keyed by the caller.
///
/// A family — instead of reading [selectedCatalogCategoryProvider]
/// internally — so screens that derive the category from their own state
/// (the add-expense form reads it from the draft) never depend on the
/// timing of a shared filter provider.
final catalogItemsProvider = StreamProvider.autoDispose
  .family<List<CatalogItem>, ExpenseCategory>((ref, category) {
  final repository = ref.watch(catalogRepositoryProvider);

  return repository.streamCatalog(
    category: category,
  );
});