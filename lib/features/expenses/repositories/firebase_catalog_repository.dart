import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hangout_sales_app/features/expenses/seed/verified_catalog_seed.dart';

import '../models/catalog_item.dart';
import '../models/expense_category.dart';
import 'catalog_repository.dart';

class FirebaseCatalogRepository implements CatalogRepository {
  final FirebaseFirestore _firestore;

  FirebaseCatalogRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _catalogCollection =>
      _firestore.collection('expenseItemCatalog');

  static const _catalogCategories = {
    ExpenseCategory.marketBills,
    ExpenseCategory.chicken,
    ExpenseCategory.vegetables,
    ExpenseCategory.beveragesAndDrinks,
    ExpenseCategory.packaging,
  };

  void _validateCatalogCategory(ExpenseCategory category) {
    if (!_catalogCategories.contains(category)) {
      throw ArgumentError(
        '${category.name} is not a catalog-backed expense category.',
      );
    }
  }

  @override
  Stream<List<CatalogItem>> streamCatalog({
    ExpenseCategory? category,
    bool activeOnly = false,
  }) {
    if (category != null) {
      _validateCatalogCategory(category);
    }

    Query<Map<String, dynamic>> query = _catalogCollection;

    if (category != null) {
      query = query.where(
        'category',
        isEqualTo: category.name,
      );
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map(_catalogItemFromDocument)
          .where((item) => !activeOnly || item.active)
          .toList();

      items.sort((a, b) {
        final categoryComparison =
            a.category.name.compareTo(b.category.name);

        if (categoryComparison != 0) {
          return categoryComparison;
        }

        return a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            );
      });

      return items;
    });
  }

  @override
  Future<String> createCatalogItem({
    required ExpenseCategory category,
    required String name,
    String? brand,
    String? size,
  }) async {
    _validateCatalogCategory(category);

    final normalizedName = name.trim();
    final normalizedBrand = _normalizeOptional(brand);
    final normalizedSize = _normalizeOptional(size);

    if (normalizedName.isEmpty) {
      throw ArgumentError('Catalog item name is required.');
    }

    _validateBeverageMetadata(
      category,
      normalizedBrand,
      normalizedSize,
    );

    final document = _catalogCollection.doc();

    await document.set({
      'category': category.name,
      'name': normalizedName,
      'brand': normalizedBrand,
      'size': normalizedSize,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  @override
  Future<void> updateCatalogItem(
    String catalogItemId, {
    required String name,
    String? brand,
    String? size,
  }) async {
    final normalizedName = name.trim();
    final normalizedBrand = _normalizeOptional(brand);
    final normalizedSize = _normalizeOptional(size);

    if (normalizedName.isEmpty) {
      throw ArgumentError('Catalog item name is required.');
    }

    final document = _catalogCollection.doc(catalogItemId);
    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw StateError(
        'Catalog item $catalogItemId does not exist.',
      );
    }

    final data = snapshot.data();

    if (data == null) {
      throw StateError(
        'Catalog item $catalogItemId contains no data.',
      );
    }

    final categoryName = data['category'] as String?;

    if (categoryName == null) {
      throw StateError(
        'Catalog item $catalogItemId has no category.',
      );
    }

    final category = ExpenseCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () {
        throw StateError(
          'Unknown catalog category: $categoryName',
        );
      },
    );

    _validateCatalogCategory(category);

    _validateBeverageMetadata(
      category,
      normalizedBrand,
      normalizedSize,
    );

    await document.update({
      'name': normalizedName,
      'brand': normalizedBrand,
      'size': normalizedSize,
    });
  }

  @override
  Future<void> setCatalogItemActive(
    String catalogItemId,
    bool active,
  ) async {
    final document = _catalogCollection.doc(catalogItemId);

    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw StateError(
        'Catalog item $catalogItemId does not exist.',
      );
    }

    await document.update({
      'active': active,
    });
  }

  @override
Future<int> seedVerifiedCatalog() async {
  final existingSnapshot = await _catalogCollection.get();

  final existingKeys = existingSnapshot.docs.map((document) {
    final data = document.data();

    final category = data['category'] as String? ?? '';
    final name = data['name'] as String? ?? '';
    final brand = data['brand'] as String? ?? '';
    final size = data['size'] as String? ?? '';

    return _catalogSeedKey(
      category: category,
      name: name,
      brand: brand,
      size: size,
    );
  }).toSet();

  final missingItems = verifiedCatalogSeed.where((item) {
    final key = _catalogSeedKey(
      category: item.category.name,
      name: item.name,
      brand: item.brand ?? '',
      size: item.size ?? '',
    );

    return !existingKeys.contains(key);
  }).toList();

  if (missingItems.isEmpty) {
    return 0;
  }

  final batch = _firestore.batch();

  for (final item in missingItems) {
    final document = _catalogCollection.doc();

    batch.set(document, {
      'category': item.category.name,
      'name': item.name,
      'brand': item.brand,
      'size': item.size,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();

  return missingItems.length;
}

String _catalogSeedKey({
  required String category,
  required String name,
  required String brand,
  required String size,
}) {
  return [
    category.trim().toLowerCase(),
    name.trim().toLowerCase(),
    brand.trim().toLowerCase(),
    size.trim().toLowerCase(),
  ].join('|');
}

  CatalogItem _catalogItemFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final categoryName = data['category'] as String?;

    if (categoryName == null) {
      throw StateError(
        'Catalog item ${document.id} has no category.',
      );
    }

    final category = ExpenseCategory.values.firstWhere(
      (value) => value.name == categoryName,
      orElse: () {
        throw StateError(
          'Unknown catalog category: $categoryName',
        );
      },
    );

    return CatalogItem(
      id: document.id,
      category: category,
      name: data['name'] as String? ?? '',
      brand: data['brand'] as String?,
      size: data['size'] as String?,
      active: data['active'] as bool? ?? false,
      createdAt: _readCreatedAt(data['createdAt']),
    );
  }

  DateTime _readCreatedAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  void _validateBeverageMetadata(
    ExpenseCategory category,
    String? brand,
    String? size,
  ) {
    if (category != ExpenseCategory.beveragesAndDrinks) {
      if (brand != null || size != null) {
        throw ArgumentError(
          'Brand and size are only valid for Beverages and Drinks.',
        );
      }

      return;
    }

    if (brand == null || brand.isEmpty) {
      throw ArgumentError(
        'A beverage brand is required.',
      );
    }

    if (size == null || size.isEmpty) {
      throw ArgumentError(
        'A beverage size is required.',
      );
    }
  }
}