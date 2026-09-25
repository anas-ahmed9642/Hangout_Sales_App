import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_catalog_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseCatalogRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirebaseCatalogRepository(firestore: firestore);
  });

  group('FirebaseCatalogRepository', () {
    test('creates a catalog item', () async {
      final id = await repository.createCatalogItem(
        category: ExpenseCategory.chicken,
        name: 'Malai Boti',
      );

      final snapshot = await firestore
          .collection('expenseItemCatalog')
          .doc(id)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['category'], 'chicken');
      expect(snapshot.data()?['name'], 'Malai Boti');
      expect(snapshot.data()?['active'], isTrue);
    });

    test('creates beverage item with brand and size', () async {
      final id = await repository.createCatalogItem(
        category: ExpenseCategory.beveragesAndDrinks,
        name: 'Coke 1ltr',
        brand: 'Coke',
        size: '1ltr',
      );

      final snapshot = await firestore
          .collection('expenseItemCatalog')
          .doc(id)
          .get();

      expect(snapshot.data()?['brand'], 'Coke');
      expect(snapshot.data()?['size'], '1ltr');
    });

    test('rejects brand and size for non-beverage categories', () async {
      expect(
        () => repository.createCatalogItem(
          category: ExpenseCategory.chicken,
          name: 'Malai Boti',
          brand: 'Coke',
          size: '1ltr',
        ),
        throwsArgumentError,
      );
    });

    test('rejects beverage without brand', () async {
      expect(
        () => repository.createCatalogItem(
          category: ExpenseCategory.beveragesAndDrinks,
          name: 'Coke 1ltr',
          size: '1ltr',
        ),
        throwsArgumentError,
      );
    });

    test('streams catalog items filtered by category', () async {
      await repository.createCatalogItem(
        category: ExpenseCategory.chicken,
        name: 'Malai Boti',
      );

      await repository.createCatalogItem(
        category: ExpenseCategory.vegetables,
        name: 'Onion',
      );

      final items = await repository
          .streamCatalog(category: ExpenseCategory.chicken)
          .first;

      expect(items, hasLength(1));
      expect(items.single.name, 'Malai Boti');
      expect(items.single.category, ExpenseCategory.chicken);
    });

    test('deactivates an item without deleting it', () async {
      final id = await repository.createCatalogItem(
        category: ExpenseCategory.vegetables,
        name: 'Onion',
      );

      await repository.setCatalogItemActive(id, false);

      final snapshot = await firestore
          .collection('expenseItemCatalog')
          .doc(id)
          .get();

      expect(snapshot.exists, isTrue);
      expect(snapshot.data()?['active'], isFalse);
    });

    test('active-only stream excludes inactive items', () async {
      final activeId = await repository.createCatalogItem(
        category: ExpenseCategory.packaging,
        name: 'Boxes',
      );

      final inactiveId = await repository.createCatalogItem(
        category: ExpenseCategory.packaging,
        name: 'Old Boxes',
      );

      await repository.setCatalogItemActive(inactiveId, false);

      final items = await repository
          .streamCatalog(category: ExpenseCategory.packaging, activeOnly: true)
          .first;

      expect(items.map((item) => item.id), contains(activeId));

      expect(items.map((item) => item.id), isNot(contains(inactiveId)));
    });

    test('updates an existing catalog item', () async {
      final id = await repository.createCatalogItem(
        category: ExpenseCategory.vegetables,
        name: 'Onion',
      );

      await repository.updateCatalogItem(id, name: 'Red Onion');

      final snapshot = await firestore
          .collection('expenseItemCatalog')
          .doc(id)
          .get();

      expect(snapshot.data()?['name'], 'Red Onion');
    });

    test('catalog does not contain a price field', () async {
      final id = await repository.createCatalogItem(
        category: ExpenseCategory.chicken,
        name: 'Tikka',
      );

      final snapshot = await firestore
          .collection('expenseItemCatalog')
          .doc(id)
          .get();

      expect(snapshot.data(), isNot(contains('price')));
    });

    test('createdAt is stored as a Firestore timestamp', () async {
      final id = await repository.createCatalogItem(
        category: ExpenseCategory.packaging,
        name: 'Napkins',
      );

      final snapshot = await firestore
          .collection('expenseItemCatalog')
          .doc(id)
          .get();

      expect(snapshot.data()?['createdAt'], isA<Timestamp>());
    });
    test('seed creates 38 items and is idempotent', () async {
      final firstRun = await repository.seedVerifiedCatalog();

      expect(firstRun, 38);

      final firstSnapshot = await firestore
          .collection('expenseItemCatalog')
          .get();

      expect(firstSnapshot.docs, hasLength(38));

      final secondRun = await repository.seedVerifiedCatalog();

      expect(secondRun, 0);

      final secondSnapshot = await firestore
          .collection('expenseItemCatalog')
          .get();

      expect(secondSnapshot.docs, hasLength(38));
    });
    test(
  'seed preserves an existing catalog item',
  () async {
    final id = await repository.createCatalogItem(
      category: ExpenseCategory.chicken,
      name: 'Malai Boti',
    );

    await repository.setCatalogItemActive(
      id,
      false,
    );

    final createdCount =
        await repository.seedVerifiedCatalog();

    expect(createdCount, 37);

    final snapshot = await firestore
        .collection('expenseItemCatalog')
        .doc(id)
        .get();

    expect(snapshot.exists, isTrue);
    expect(snapshot.data()?['active'], isFalse);
  },
);
  });
}
