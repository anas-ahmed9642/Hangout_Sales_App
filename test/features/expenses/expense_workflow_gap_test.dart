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

/// NOTE: the fake cannot roll a transaction back, so these tests prove
/// "validate before write, nothing persisted on rejection" — not true
/// Firestore atomicity. That needs the Firestore emulator.


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
    container = createTestContainer(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(expenses),
        marketListRepositoryProvider.overrideWithValue(marketLists),
        catalogRepositoryProvider.overrideWithValue(catalog),
      ],
    );
  });


  group('expense lifecycle', () {
    test('chicken expense: save, total, edit, audit trail, void', () async {
      final draft = container.read(expenseDraftProvider.notifier);
      draft.setCategory(ExpenseCategory.chicken);
      draft.setTitle('Morning chicken');
      draft.setPricePerKg(1000);
      draft.addChickenLine(chickenType: 'Malai Boti', quantityKg: 2);
      draft.addChickenLine(chickenType: 'Chicken Fajita', quantityKg: 3);
      draft.addChickenLine(chickenType: 'Chicken Tikka', quantityKg: 1);
      expect(draft.computedAmount, 6000);
      expect(draft.canConfirm, isTrue);

      await draft.saveExpense(businessDate: day);

      expect(await expenses.getTotalExpensesByDateRange(day, nextDay), 6000);
      final saved = (await expenses.getExpensesByDateRange(day, nextDay)).single;
      expect(saved.category, ExpenseCategory.chicken);
      expect(saved.amount, 6000);
      expect(saved.businessDate, day);
      expect(saved.editCount, 0);

      // Edit: the supplier raised the rate.
      final actions = container.read(expenseActionsProvider);
      final input = ExpenseEditInput(
        title: saved.title,
        pricePerKg: 1100,
        chickenQuantities: const [2, 3, 1],
      );
      final wrote = await actions.saveEdit(
        original: saved,
        input: input,
        changeReason: 'Supplier raised the rate',
      );

      expect(wrote, isTrue);
      expect(await expenses.getTotalExpensesByDateRange(day, nextDay), 6600);
      final edited = (await expenses.getExpense(saved.id))!;
      expect(edited.pricePerKg, 1100);
      expect(edited.amount, 6600);
      expect(edited.editCount, 1);
      final trail = await expenses.getExpenseHistory(saved.id);
      expect(trail.map((row) => row['field']),
          unorderedEquals(['pricePerKg', 'amount']));
      expect(
        trail.every((row) => row['changeReason'] == 'Supplier raised the rate'),
        isTrue,
      );

      // Void: gone from every operational read, still readable as history.
      await actions.voidExpense(
        expense: edited,
        changeReason: 'Order cancelled',
      );

      expect(await expenses.getTotalExpensesByDateRange(day, nextDay), 0);
      expect(await expenses.getExpensesByDateRange(day, nextDay), isEmpty);
      expect(await expenses.streamExpenses(day).first, isEmpty);
      final voided = (await expenses.getExpense(saved.id))!;
      expect(voided.voided, isTrue);
      final finalTrail = await expenses.getExpenseHistory(saved.id);
      expect(finalTrail, hasLength(3));
      expect(finalTrail.where((row) => row['field'] == 'voided'), hasLength(1));

      // A voided expense can never be edited again.
      await expectLater(
        actions.saveEdit(
          original: voided,
          input: input,
          changeReason: 'Trying again',
        ),
        throwsStateError,
      );
    });

    test('a 2:00 AM save lands on the previous business day end to end',
        () async {
      const service = BusinessDayService();
      final savedAt = DateTime(2026, 9, 29, 2, 0);
      final businessDate = service.businessDate(savedAt);
      expect(businessDate, DateTime(2026, 9, 28));

      final draft = container.read(expenseDraftProvider.notifier);
      draft.setCategory(ExpenseCategory.electricity);
      draft.setTitle('Night generator fuel');
      draft.setAmount(3500);
      final expense = draft.buildExpense(
        businessDate: businessDate,
        createdAt: savedAt,
      );
      await expenses.createExpense(expense);

      final onPreviousDay =
          await expenses.streamExpenses(DateTime(2026, 9, 28)).first;
      final onCalendarDay =
          await expenses.streamExpenses(DateTime(2026, 9, 29)).first;
      expect(onPreviousDay.map((e) => e.id), [expense.id]);
      expect(onCalendarDay, isEmpty);

      // Exactly 5:00 AM opens the new business day.
      expect(
        service.businessDate(DateTime(2026, 9, 29, 5, 0)),
        DateTime(2026, 9, 29),
      );
    });

    test('renaming or deactivating a catalog item never touches saved expenses',
        () async {
      await catalog.seedVerifiedCatalog();
      final vegetables = await catalog
          .streamCatalog(category: ExpenseCategory.vegetables)
          .first;
      final onion = vegetables.firstWhere((item) => item.name == 'Onion');

      final draft = container.read(expenseDraftProvider.notifier);
      draft.setCategory(ExpenseCategory.vegetables);
      draft.setTitle('Onions for the week');
      draft.addLineItem(itemName: onion.name, price: 900);
      await draft.saveExpense(businessDate: day);

      await catalog.updateCatalogItem(onion.id, name: 'Red Onion');
      await catalog.setCatalogItemActive(onion.id, false);

      final saved = (await expenses.getExpensesByDateRange(day, nextDay)).single;
      expect(saved.lineItems!.single.itemName, 'Onion');
      expect(saved.amount, 900);

      final active = await catalog
          .streamCatalog(
            category: ExpenseCategory.vegetables,
            activeOnly: true,
          )
          .first;
      expect(active.map((item) => item.name), ['Capsicum']);
      final everything = await catalog
          .streamCatalog(category: ExpenseCategory.vegetables)
          .first;
      expect(everything, hasLength(2));
    });

  });

  group('market list to expense', () {
    Future<String> buildConfirmedList(MarketListDraftNotifier list) async {
      await list.addItem('Mushroom Slices');
      await list.addItem('Black Olive');
      list.updateItemPrice(0, 300);
      list.updateItemPrice(1, 450);
      // confirm() flushes the locally-typed prices itself before the
      // transaction re-reads the list.
      await list.setHandedToWorker(true);
      return list.confirm(day);
    }

    test('draft lists add nothing to expense totals', () async {
      final list = container.read(marketListDraftProvider.notifier);
      await list.addItem('Mushroom Slices');
      list.updateItemPrice(0, 300);
      await list.commitPrices();

      expect(await expenses.getTotalExpensesByDateRange(day, nextDay), 0);
      expect((await fake.collection('expenses').get()).docs, isEmpty);
    });

    test('voiding the linked expense removes it from totals but leaves the '
        'list confirmed and locked', () async {
      final list = container.read(marketListDraftProvider.notifier);
      final expenseId = await buildConfirmedList(list);
      final draftId = container.read(marketListDraftProvider).id;
      final expense = (await expenses.getExpense(expenseId))!;

      await container.read(expenseActionsProvider).voidExpense(
            expense: expense,
            changeReason: 'Worker returned the cash',
          );

      expect(await expenses.getTotalExpensesByDateRange(day, nextDay), 0);
      final afterVoid = (await marketLists.getMarketList(draftId))!;
      expect(afterVoid.status, MarketListStatus.confirmed);
      expect(afterVoid.reconciledExpenseId, expenseId);
      await expectLater(
        marketLists.updateMarketList(
          draftId,
          items: const [MarketListItem(itemName: 'Black Olive', price: 1)],
        ),
        throwsStateError,
      );
    });

    test('editing the linked expense never rewrites the confirmed list',
        () async {
      final list = container.read(marketListDraftProvider.notifier);
      final expenseId = await buildConfirmedList(list);
      final draftId = container.read(marketListDraftProvider).id;
      final expense = (await expenses.getExpense(expenseId))!;

      await container.read(expenseActionsProvider).saveEdit(
            original: expense,
            input: ExpenseEditInput(
              title: expense.title,
              lineItemPrices: const [300, 500],
            ),
            changeReason: 'Olive price corrected',
          );

      final edited = (await expenses.getExpense(expenseId))!;
      expect(edited.amount, 800);
      expect(edited.editCount, 1);

      final lockedList = (await marketLists.getMarketList(draftId))!;
      expect(lockedList.total, 750);
      expect(lockedList.items.map((item) => item.price), [300, 450]);
    });

  });
}
