import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/shared/widgets/hangout_app_bar.dart';
import 'package:hangout_sales_app/features/expenses/models/catalog_item.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/market_list.dart';
import 'package:hangout_sales_app/features/expenses/providers/market_list_draft_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/market_list_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/market_list_repository.dart';
import 'package:hangout_sales_app/features/expenses/screens/market_list_screen.dart';

class FakeMarketListRepository implements MarketListRepository {
  @override
  Future createMarketList(MarketList marketList) async {}

  @override
  Future<MarketList?> getLatestDraft() async => null;

  @override
  Future<MarketList?> getMarketList(String marketListId) async => null;

  @override
  Future updateMarketList(
    String marketListId, {
    List? items,
    bool? handedToWorker,
  }) async {}

  @override
  Future<String> confirmMarketList({
    required String marketListId,
    required DateTime businessDate,
  }) async => 'exp-1';
}

CatalogItem fakeCatalogItem(String id, String name) {
  return CatalogItem(
    id: id,
    name: name,
    category: ExpenseCategory.marketBills,
    active: true,
    createdAt: DateTime(2026, 9, 28),
  );
}

Future<void> pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: MarketListScreen(),
      ),
    ),
  );
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        marketListRepositoryProvider.overrideWithValue(
          FakeMarketListRepository(),
        ),
        marketListCatalogProvider.overrideWith(
          (ref) => Stream.value([
            fakeCatalogItem('c1', 'Onion'),
            fakeCatalogItem('c2', 'Capsicum'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  testWidgets('renders the four lifecycle sections', (tester) async {
    await pumpScreen(tester, container);
    await tester.pumpAndSettle();
    expect(find.text('1. Add items'), findsOneWidget);
    expect(find.text('2. Estimates'), findsOneWidget);
    expect(find.text('3. Print & hand over'), findsOneWidget);
    expect(find.text('4. Reconcile & confirm'), findsOneWidget);
    expect(find.byType(HangoutAppBar), findsOneWidget);
  });

  testWidgets('adding a catalog chip creates a priced line', (tester) async {
    await pumpScreen(tester, container);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onion'));
    await tester.pumpAndSettle();
    expect(find.text('Onion'), findsWidgets);
    expect(find.byKey(const Key('price_field_0')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('price_field_0')),
      '450',
    );
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('estimate_total'))).data,
      'Rs. 450',
    );
  });

  testWidgets('confirm is disabled until prices and handover are set',
      (tester) async {
    await pumpScreen(tester, container);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onion'));
    await tester.pumpAndSettle();
    final confirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('confirm_list_button')),
    );
    expect(confirmButton.onPressed, isNull);
    expect(find.byKey(const Key('confirm_hint')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('price_field_0')),
      '450',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('handover_switch')));
    await tester.pumpAndSettle();
    final enabledButton = tester.widget<FilledButton>(
      find.byKey(const Key('confirm_list_button')),
    );
    expect(enabledButton.onPressed, isNotNull);
  });

  testWidgets('confirm dialog shows the summary and cancels cleanly',
      (tester) async {
    await pumpScreen(tester, container);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Onion'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('price_field_0')),
      '450',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('handover_switch')));
    await tester.pumpAndSettle();
    final confirmButton = find.byKey(const Key('confirm_list_button'));
    await tester.ensureVisible(confirmButton);
    await tester.pumpAndSettle();
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('confirm_market_list_dialog')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('confirm_market_list_dialog')),
        matching: find.textContaining('Market Bills expense'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('cancel_confirm_button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('confirm_market_list_dialog')),
      findsNothing,
    );
  });
}
