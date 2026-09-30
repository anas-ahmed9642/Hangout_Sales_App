import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/core/services/business_day_service.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_edit_input.dart';
import 'package:hangout_sales_app/features/expenses/models/market_list.dart';
import 'package:hangout_sales_app/features/expenses/providers/catalog_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_actions_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_draft_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/market_list_draft_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/market_list_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_catalog_repository.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_expense_repository.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_market_list_repository.dart';

import '../../helpers/test_container.dart';

void main() {
  final day = DateTime(2026, 9, 28);
  final nextDay = DateTime(2026, 9, 29);
  late FakeFirebaseFirestore fake;
  late FirebaseExpenseRepository expenses;
  late FirebaseMarketListRepository marketLists;
  late FirebaseCatalogRepository catalog;
  late ProviderContainer container;

  setUp(() {
    fake = FakeFirebaseFirestore();
    expenses = FirebaseExpenseRepository(firestore: fake);
    marketLists = FirebaseMarketListRepository(firestore: fake);
    catalog = FirebaseCatalogRepository(firestore: fake);
    container = createTestContainer(overrides: [
      expenseRepositoryProvider.overrideWithValue(expenses),
      marketListRepositoryProvider.overrideWithValue(marketLists),
      catalogRepositoryProvider.overrideWithValue(catalog),
    ]);
  });

  test('chicken draft save, total, edit and void work end to end', () async {
    final draft = container.read(expenseDraftProvider.notifier);
    draft.setCategory(ExpenseCategory.chicken);
    draft.setTitle('Morning chicken');
    draft.setPricePerKg(1000);
    draft.addChickenLine(chickenType: 'Malai Boti', quantityKg: 2);
    draft.addChickenLine(chickenType: 'Chicken Fajita', quantityKg: 3);
    draft.addChickenLine(chickenType: 'Chicken Tikka', quantityKg: 1);
    expect(draft.computedAmount, 6000);
    await draft.saveExpense(businessDate: day);
    final saved = (await expenses.getExpensesByDateRange(day, nextDay)).single;
    expect(saved.amount, 6000);
    final wrote = await container.read(expenseActionsProvider).saveEdit(
          original: saved,
          input: const ExpenseEditInput(
            title: 'Morning chicken',
            pricePerKg: 1100,
            chickenQuantities: [2, 3, 1],
          ),
          changeReason: 'Supplier raised the rate',
        );
    expect(wrote, isTrue);
    expect(await expenses.getTotalExpensesByDateRange(day, nextDay), 6600);
    final edited = (await expenses.getExpense(saved.id))!;
    await container.read(expenseActionsProvider).voidExpense(
          expense: edited,
          changeReason: 'Order cancelled',
        );
    expect(await expenses.getTotalExpensesByDateRange(day, nextDay), 0);
    expect((await expenses.getExpense(saved.id))!.voided, isTrue);
  });

  test('the 5am boundary assigns the correct business date', () {
    const service = BusinessDayService();
    expect(service.businessDate(DateTime(2026, 9, 29, 2)), day);
    expect(service.businessDate(DateTime(2026, 9, 29, 5)), nextDay);
  });

  test('market list rejection leaves the draft available for retry', () async {
    final list = container.read(marketListDraftProvider.notifier);
    await list.addItem('Mushroom Slices');
    await expectLater(list.confirm(day), throwsStateError);
    expect((await fake.collection('expenses').get()).docs, isEmpty);
    final draftId = container.read(marketListDraftProvider).id;
    expect((await marketLists.getMarketList(draftId))!.status,
        MarketListStatus.draft);
    list.updateItemPrice(0, 300);
    await list.setHandedToWorker(true);
    final expenseId = await list.confirm(day);
    expect((await expenses.getExpense(expenseId))!.amount, 300);
  });

  test('confirmed market list links one expense and remains locked', () async {
    final list = container.read(marketListDraftProvider.notifier);
    await list.addItem('Mushroom Slices');
    await list.addItem('Black Olive');
    list.updateItemPrice(0, 300);
    list.updateItemPrice(1, 450);
    await list.setHandedToWorker(true);
    final expenseId = await list.confirm(day);
    final draftId = container.read(marketListDraftProvider).id;
    final expense = (await expenses.getExpense(expenseId))!;
    expect(expense.category, ExpenseCategory.marketBills);
    expect(expense.amount, 750);
    expect(expense.linkedMarketListId, draftId);
    expect((await marketLists.getMarketList(draftId))!.status,
        MarketListStatus.confirmed);
    await expectLater(
      marketLists.updateMarketList(
        draftId,
        items: const [MarketListItem(itemName: 'Black Olive', price: 1)],
      ),
      throwsStateError,
    );
  });
}
