
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hangout_sales_app/core/constants/app_routes.dart';
import 'package:hangout_sales_app/features/expenses/models/chicken_purchase_line.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_history_filter.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_history_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';
import 'package:hangout_sales_app/features/expenses/screens/expense_detail_screen.dart';
import 'package:hangout_sales_app/features/expenses/screens/expense_edit_screen.dart';
import 'package:hangout_sales_app/features/expenses/screens/expense_history_screen.dart';

Expense _copy(
  Expense e, {
  String? title,
  double? amount,
  bool? voided,
  int? editCount,
}) {
  return Expense(
    id: e.id,
    title: title ?? e.title,
    category: e.category,
    amount: amount ?? e.amount,
    notes: e.notes,
    date: e.date,
    businessDate: e.businessDate,
    voided: voided ?? e.voided,
    editCount: editCount ?? e.editCount,
    workerName: e.workerName,
    linkedMarketListId: e.linkedMarketListId,
    pricePerKg: e.pricePerKg,
    chickenLines: e.chickenLines,
    lineItems: e.lineItems,
  );
}

/// In-memory ExpenseRepository. getExpense returns voided records (like
/// the real one); updates and voids mutate the store and append audit
/// rows so screens can be checked end to end.
class _FakeRepo implements ExpenseRepository {
  final Map<String, Expense> expenses;
  final Map<String, List<Map<String, dynamic>>> history;
  final bool failUpdate;
  final bool failVoid;

  final List<Map<String, dynamic>> updateCalls = [];
  final List<Map<String, String>> voidCalls = [];

  _FakeRepo(
    List<Expense> seed, {
    Map<String, List<Map<String, dynamic>>>? history,
    this.failUpdate = false,
    this.failVoid = false,
  })  : expenses = {for (final e in seed) e.id: e},
        history = history ?? {};

  @override
  Future<Expense?> getExpense(String expenseId) async => expenses[expenseId];

  @override
  Future<List<Map<String, dynamic>>> getExpenseHistory(
    String expenseId,
  ) async {
    return List<Map<String, dynamic>>.of(
      history[expenseId] ?? <Map<String, dynamic>>[],
    );
  }

  @override
  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {
    if (failUpdate) {
      throw Exception('firestore unavailable');
    }
    updateCalls.add({
      'id': expenseId,
      'changes': changes,
      'reason': changeReason,
    });
    final current = expenses[expenseId]!;
    expenses[expenseId] = _copy(
      current,
      title: changes['title'] as String?,
      amount: changes['amount'] as double?,
      editCount: current.editCount + 1,
    );
    final rows = history.putIfAbsent(expenseId, () => <Map<String, dynamic>>[]);
    for (final entry in changes.entries) {
      rows.insert(0, {
        'id': 'h_${rows.length}',
        'field': entry.key,
        'oldValue': null,
        'newValue': entry.value,
        'changeReason': changeReason,
        'timestamp': Timestamp.fromDate(DateTime(2026, 9, 28, 12)),
      });
    }
  }

  @override
  Future<void> voidExpense(
    String expenseId, {
    required String changeReason,
  }) async {
    if (failVoid) {
      throw Exception('firestore unavailable');
    }
    voidCalls.add({'id': expenseId, 'reason': changeReason});
    expenses[expenseId] = _copy(expenses[expenseId]!, voided: true);
    history.putIfAbsent(expenseId, () => <Map<String, dynamic>>[]).insert(0, {
      'id': 'h_void',
      'field': 'voided',
      'oldValue': false,
      'newValue': true,
      'changeReason': changeReason,
      'timestamp': Timestamp.fromDate(DateTime(2026, 9, 28, 12)),
    });
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return expenses.values
        .where(
          (e) =>
              !e.businessDate.isBefore(start) &&
              e.businessDate.isBefore(end) &&
              !e.voided,
        )
        .toList();
  }

  @override
  Future<void> createExpense(Expense expense) => throw UnimplementedError();
  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) =>
      throw UnimplementedError();
  @override
  Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      throw UnimplementedError();
}

Expense _chicken({bool voided = false}) => Expense(
      id: 'chk1',
      title: 'Morning chicken',
      category: ExpenseCategory.chicken,
      amount: 7500,
      notes: 'Delivered early',
      date: DateTime(2026, 9, 28, 9, 5),
      businessDate: DateTime(2026, 9, 28),
      voided: voided,
      pricePerKg: 500,
      chickenLines: const [
        ChickenPurchaseLine(chickenType: 'Malai Boti', quantityKg: 10),
        ChickenPurchaseLine(chickenType: 'Chicken Tikka', quantityKg: 5),
      ],
    );

Expense _plain() => Expense(
      id: 'plain1',
      title: 'Gas cylinder',
      category: ExpenseCategory.gas,
      amount: 4500,
      date: DateTime(2026, 9, 28, 10),
      businessDate: DateTime(2026, 9, 28),
    );

Future<void> _pumpApp(
  WidgetTester tester,
  _FakeRepo repo, {
  required String location,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.expenseHistory,
        builder: (context, state) => const ExpenseHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.expenseDetail,
        builder: (context, state) => ExpenseDetailScreen(
          expenseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.expenseEdit,
        builder: (context, state) => ExpenseEditScreen(
          expenseId: state.pathParameters['id']!,
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repo),
        expenseHistoryFilterProvider.overrideWith(
          (ref) => ExpenseHistoryFilter(
            start: DateTime(2026, 9, 28),
            end: DateTime(2026, 9, 28),
          ),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _confirmReason(WidgetTester tester, String reason) async {
  await tester.enterText(
    find.byKey(const Key('expense_reason_field')),
    reason,
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('expense_reason_confirm_button')));
  await tester.pumpAndSettle();
}

void main() {
  group('ExpenseDetailScreen', () {
    testWidgets('shows the expense, its lines and its audit history',
        (tester) async {
      final repo = _FakeRepo(
        [_chicken()],
        history: {
          'chk1': [
            {
              'id': 'h1',
              'field': 'amount',
              'oldValue': 7000.0,
              'newValue': 7500.0,
              'changeReason': 'Wrong price',
              'timestamp': Timestamp.fromDate(DateTime(2026, 9, 28, 11, 30)),
            },
          ],
        },
      );
      await _pumpApp(tester, repo, location: '/expenses/detail/chk1');

      expect(
        tester.widget<Text>(find.byKey(const Key('expense_detail_title'))).data,
        'Morning chicken',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('expense_detail_amount'))).data,
        'Rs. 7500',
      );
      expect(find.text('Chicken'), findsOneWidget);
      expect(find.text('Malai Boti'), findsOneWidget);
      expect(find.text('10 kg • Rs. 5000'), findsOneWidget);
      expect(find.text('Delivered early'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Rs. 7000 → Rs. 7500'), findsOneWidget);
      expect(find.text('Reason: Wrong price'), findsOneWidget);
      expect(find.byKey(const Key('expense_detail_edit_button')), findsOneWidget);
      expect(find.byKey(const Key('expense_detail_void_button')), findsOneWidget);
    });

    testWidgets('a voided expense shows the banner and no actions',
        (tester) async {
      final repo = _FakeRepo([_chicken(voided: true)]);
      await _pumpApp(tester, repo, location: '/expenses/detail/chk1');

      expect(
        find.byKey(const Key('expense_detail_voided_banner')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('expense_detail_edit_button')), findsNothing);
      expect(find.byKey(const Key('expense_detail_void_button')), findsNothing);
      expect(find.byKey(const Key('audit_trail_empty')), findsOneWidget);
    });

    testWidgets('an unknown id shows "Expense not found"', (tester) async {
      final repo = _FakeRepo([_chicken()]);
      await _pumpApp(tester, repo, location: '/expenses/detail/missing');

      expect(find.text('Expense not found'), findsOneWidget);
      expect(find.byKey(const Key('expense_detail_edit_button')), findsNothing);
    });

    testWidgets('voiding requires a reason, writes it, then shows voided',
        (tester) async {
      final repo = _FakeRepo([_chicken()]);
      await _pumpApp(tester, repo, location: '/expenses/detail/chk1');

      await tester.tap(find.byKey(const Key('expense_detail_void_button')));
      await tester.pumpAndSettle();

      final confirm = find.byKey(const Key('expense_reason_confirm_button'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('expense_reason_field')),
        'Entered twice',
      );
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(repo.voidCalls, [
        {'id': 'chk1', 'reason': 'Entered twice'},
      ]);
      expect(
        find.byKey(const Key('expense_detail_voided_banner')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('expense_detail_edit_button')), findsNothing);
      expect(find.text('Reason: Entered twice'), findsOneWidget);
      expect(find.text('Expense voided.'), findsOneWidget);
    });

    testWidgets('cancelling the void dialog writes nothing', (tester) async {
      final repo = _FakeRepo([_chicken()]);
      await _pumpApp(tester, repo, location: '/expenses/detail/chk1');

      await tester.tap(find.byKey(const Key('expense_detail_void_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expense_reason_cancel_button')));
      await tester.pumpAndSettle();

      expect(repo.voidCalls, isEmpty);
      expect(find.byKey(const Key('expense_detail_voided_banner')), findsNothing);
    });

    testWidgets('a failed void shows an error and keeps the actions',
        (tester) async {
      final repo = _FakeRepo([_chicken()], failVoid: true);
      await _pumpApp(tester, repo, location: '/expenses/detail/chk1');

      await tester.tap(find.byKey(const Key('expense_detail_void_button')));
      await tester.pumpAndSettle();
      await _confirmReason(tester, 'Entered twice');

      expect(find.textContaining('Failed to void expense'), findsOneWidget);
      expect(find.byKey(const Key('expense_detail_voided_banner')), findsNothing);
      expect(find.byKey(const Key('expense_detail_void_button')), findsOneWidget);
    });
  });

  group('ExpenseEditScreen', () {
    testWidgets('edit flow: save enables on change, writes changes + reason, '
        'returns to a refreshed detail', (tester) async {
      final repo = _FakeRepo([_chicken()]);
      await _pumpApp(tester, repo, location: '/expenses/detail/chk1');

      await tester.tap(find.byKey(const Key('expense_detail_edit_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseEditScreen), findsOneWidget);

      final save = find.byKey(const Key('save_edit_button'));
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('edit_price_per_kg_field')))
            .controller!
            .text,
        '500',
      );

      await tester.enterText(find.byKey(const Key('edit_chicken_kg_0')), '12');
      await tester.pump();
      expect(
        tester.widget<Text>(find.byKey(const Key('edit_total_text'))).data,
        'Rs. 8500',
      );
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

      await tester.tap(save);
      await tester.pumpAndSettle();
      await _confirmReason(tester, 'Miscounted');

      expect(repo.updateCalls, hasLength(1));
      expect(repo.updateCalls.single['id'], 'chk1');
      expect(repo.updateCalls.single['reason'], 'Miscounted');
      expect(repo.updateCalls.single['changes'], {
        'chickenLines': [
          {'chickenType': 'Malai Boti', 'quantityKg': 12},
          {'chickenType': 'Chicken Tikka', 'quantityKg': 5},
        ],
        'amount': 8500.0,
      });

      expect(find.byType(ExpenseEditScreen), findsNothing);
      expect(find.byType(ExpenseDetailScreen), findsOneWidget);
      expect(find.text('Expense updated.'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('expense_detail_amount'))).data,
        'Rs. 8500',
      );
    });

    testWidgets('clearing the title shows an error and disables save',
        (tester) async {
      final repo = _FakeRepo([_plain()]);
      await _pumpApp(tester, repo, location: '/expenses/detail/plain1/edit');

      await tester.enterText(find.byKey(const Key('edit_title_field')), '');
      await tester.pump();

      expect(find.text('Title is required.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save_edit_button')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('cancelling the reason dialog writes nothing',
        (tester) async {
      final repo = _FakeRepo([_plain()]);
      await _pumpApp(tester, repo, location: '/expenses/detail/plain1/edit');

      await tester.enterText(find.byKey(const Key('edit_amount_field')), '5000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('save_edit_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('expense_reason_cancel_button')));
      await tester.pumpAndSettle();

      expect(repo.updateCalls, isEmpty);
      expect(find.byType(ExpenseEditScreen), findsOneWidget);
    });

    testWidgets('a failed save shows an error and stays on the form',
        (tester) async {
      final repo = _FakeRepo([_plain()], failUpdate: true);
      await _pumpApp(tester, repo, location: '/expenses/detail/plain1/edit');

      await tester.enterText(find.byKey(const Key('edit_amount_field')), '5000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('save_edit_button')));
      await tester.pumpAndSettle();
      await _confirmReason(tester, 'Price was wrong');

      expect(find.textContaining('Failed to save changes'), findsOneWidget);
      expect(find.byType(ExpenseEditScreen), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('save_edit_button')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('a voided expense cannot be edited', (tester) async {
      final repo = _FakeRepo([_chicken(voided: true)]);
      await _pumpApp(tester, repo, location: '/expenses/detail/chk1/edit');

      expect(find.text('Voided expenses cannot be edited.'), findsOneWidget);
      expect(find.byKey(const Key('save_edit_button')), findsNothing);
    });
  });

  group('ExpenseHistoryScreen navigation', () {
    testWidgets('tapping a row opens its detail screen', (tester) async {
      final repo = _FakeRepo([_chicken()]);
      await _pumpApp(tester, repo, location: AppRoutes.expenseHistory);

      expect(find.text('Morning chicken'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('expense_history_item_chk1')));
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseDetailScreen), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('expense_detail_title'))).data,
        'Morning chicken',
      );
    });
  });
}