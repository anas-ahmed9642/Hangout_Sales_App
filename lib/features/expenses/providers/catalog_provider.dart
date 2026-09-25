import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog_item.dart';
import '../models/expense_category.dart';
import 'catalog_repository_provider.dart';

final selectedCatalogCategoryProvider =
    StateProvider.autoDispose<ExpenseCategory>(
  (ref) => ExpenseCategory.marketBills,
);

final catalogItemsProvider =
    StreamProvider.autoDispose<List<CatalogItem>>((ref) {
  final category = ref.watch(selectedCatalogCategoryProvider);
  final repository = ref.watch(catalogRepositoryProvider);

  return repository.streamCatalog(
    category: category,
  );
});