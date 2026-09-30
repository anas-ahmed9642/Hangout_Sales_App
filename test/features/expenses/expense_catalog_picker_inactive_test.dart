import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/catalog_item.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/providers/catalog_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/catalog_repository.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_expense_repository.dart';
import 'package:hangout_sales_app/features/expenses/screens/expense_screen.dart';

class _LiveCatalogRepository implements CatalogRepository {
  _LiveCatalogRepository(this._items);
  List<CatalogItem> _items;
  final _changes = StreamController<void>.broadcast();

  void replace(List<CatalogItem> items) {
    _items = items;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();

  @override
  Stream<List<CatalogItem>> streamCatalog({
    ExpenseCategory? category,
    bool activeOnly = false,
  }) async* {
    List<CatalogItem> snapshot() => _items
        .where((item) => category == null || item.category == category)
        .where((item) => !activeOnly || item.active)
        .toList();
    yield snapshot();
    await for (final _ in _changes.stream) {
      yield snapshot();
    }
  }

  @override
  Future<String> createCatalogItem({
    required ExpenseCategory category,
    required String name,
    String? brand,
    String? size,
  }) async => 'fake-id';

  @override
  Future<void> updateCatalogItem(
    String catalogItemId, {
    required String name,
    String? brand,
    String? size,
  }) async {}

  @override
  Future<void> setCatalogItemActive(String catalogItemId, bool active) async {}

  @override
  Future<int> seedVerifiedCatalog() async => 0;
}

CatalogItem vegetable(String name, {required bool active}) => CatalogItem(
      id: 'id-$name',
      category: ExpenseCategory.vegetables,
      name: name,
      active: active,
      createdAt: DateTime(2026, 1, 1),
    );

Future<void> _pumpPicker(WidgetTester tester, _LiveCatalogRepository catalog) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      expenseRepositoryProvider.overrideWithValue(
        FirebaseExpenseRepository(firestore: FakeFirebaseFirestore()),
      ),
      catalogRepositoryProvider.overrideWithValue(catalog),
    ],
    child: const MaterialApp(home: ExpenseScreen()),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Vegetables'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('picker lists active catalog items only', (tester) async {
    final catalog = _LiveCatalogRepository([
      vegetable('Onion', active: true),
      vegetable('Capsicum', active: false),
    ]);
    addTearDown(catalog.dispose);
    await _pumpPicker(tester, catalog);
    expect(find.text('Onion'), findsOneWidget);
    expect(find.text('Capsicum'), findsNothing);
  });

  testWidgets('all inactive items show the empty state', (tester) async {
    final catalog = _LiveCatalogRepository([
      vegetable('Onion', active: false),
      vegetable('Capsicum', active: false),
    ]);
    addTearDown(catalog.dispose);
    await _pumpPicker(tester, catalog);
    expect(find.text('No catalog items in this category yet.'), findsOneWidget);
    expect(find.text('Onion'), findsNothing);
    expect(find.text('Capsicum'), findsNothing);
  });

  testWidgets('deactivation hides the chip but preserves a snapshot line',
      (tester) async {
    final catalog = _LiveCatalogRepository([
      vegetable('Onion', active: true),
      vegetable('Capsicum', active: true),
    ]);
    addTearDown(catalog.dispose);
    await _pumpPicker(tester, catalog);
    await tester.tap(find.text('Capsicum'));
    await tester.pumpAndSettle();
    expect(find.text('Capsicum'), findsNWidgets(2));
    catalog.replace([
      vegetable('Onion', active: true),
      vegetable('Capsicum', active: false),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Capsicum'), findsOneWidget);
    expect(find.byKey(const Key('line_price_field_0')), findsOneWidget);
  });
}
