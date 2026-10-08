import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hangout_sales_app/core/constants/app_routes.dart';
import 'package:hangout_sales_app/core/services/business_day_service.dart';
import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:hangout_sales_app/features/dashboard/widgets/dashboard_formatters.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_history_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';
import 'package:hangout_sales_app/features/expenses/screens/expense_history_screen.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_history_provider.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';
import 'package:hangout_sales_app/features/orders/screens/order_history_screen.dart';

final _day = DateTime(2026, 9, 30);

Order _order({
  required String id,
  required double total,
  OrderStatus status = OrderStatus.completed,
}) {
  return Order(
    id: id,
    orderNumber: 'ORD-$id',
    createdAt: _day,
    businessDate: _day,
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: total,
    status: status,
    paymentStatus: PaymentStatus.paid,
  );
}

Expense _expense({required String id, required double amount}) {
  return Expense(
    id: id,
    title: 'test $id',
    category: ExpenseCategory.marketBills,
    amount: amount,
    date: _day,
    businessDate: _day,
  );
}

/// Fake that returns a FRESH stream per call so refresh re-subscription
/// works, and optionally hangs (loading state) or fails (error state).
class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({
    this.orders = const [],
    this.hang = false,
  });

  final List<Order> orders;
  final bool hang;
  int streamCalls = 0;
  final List<StreamController<List<Order>>> _controllers = [];

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) {
    streamCalls++;
    if (hang) {
      final controller = StreamController<List<Order>>();
      _controllers.add(controller);
      return controller.stream;
    }
    return Stream<List<Order>>.value(orders);
  }

  void dispose() {
    for (final controller in _controllers) {
      controller.close();
    }
  }

  @override
    Future<void> createOrder(
      Order order, {
      CustomerUpsert? customerUpsert,
    }) async {}

  @override
    Stream<List<Order>> streamUnpaidOrders() =>
      Stream<List<Order>>.value(const <Order>[]);

  @override
  Stream<List<Order>> streamOrdersByCustomerPhone(String phone) =>
      throw UnimplementedError();

  @override
    Future<List<Order>> searchOrdersByPhone(String phoneNumber) async =>
      <Order>[];

  @override
  Future<Order?> getOrder(String orderId) async => null;

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async =>
      <Map<String, dynamic>>[];
}

class _FakeExpenseRepository implements ExpenseRepository {
  _FakeExpenseRepository({
    this.expenses = const [],
    this.hang = false,
  });

  final List<Expense> expenses;
  final bool hang;
  int streamCalls = 0;
  final List<StreamController<List<Expense>>> _controllers = [];

  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) {
    streamCalls++;
    if (hang) {
      final controller = StreamController<List<Expense>>();
      _controllers.add(controller);
      return controller.stream;
    }
    return Stream<List<Expense>>.value(expenses);
  }

  void dispose() {
    for (final controller in _controllers) {
      controller.close();
    }
  }

  @override
  Future<void> createExpense(Expense expense) async {}

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
    ) async =>
      <Expense>[];

  @override
    Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
    ) async =>
      0.0;

  @override
  Future<Expense?> getExpense(String expenseId) async => null;

  @override
  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {}

  @override
  Future<void> voidExpense(
    String expenseId, {
    required String changeReason,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getExpenseHistory(
    String expenseId,
  ) async =>
      <Map<String, dynamic>>[];
}

Future _pumpDashboard(
  WidgetTester tester,
  _FakeOrderRepository orderRepo,
  _FakeExpenseRepository expenseRepo, {
  Size size = const Size(520, 1200),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  addTearDown(orderRepo.dispose);
  addTearDown(expenseRepo.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(orderRepo),
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
}

Future<void> _pumpDashboardWithRouter(
  WidgetTester tester,
  _FakeOrderRepository orderRepo,
  _FakeExpenseRepository expenseRepo,
) async {
  tester.view.physicalSize = const Size(520, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  addTearDown(orderRepo.dispose);
  addTearDown(expenseRepo.dispose);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.expenseHistory,
        builder: (context, state) => const ExpenseHistoryScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orderRepositoryProvider.overrideWithValue(orderRepo),
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('shows loading placeholders while streams are pending',
      (tester) async {
    await _pumpDashboard(
      tester,
      _FakeOrderRepository(hang: true),
      _FakeExpenseRepository(hang: true),
    );
    await tester.pump();

    expect(find.text('Ã¢â‚¬Â¦'), findsNWidgets(4));
  });

  testWidgets('empty day keeps the original empty-state strings',
      (tester) async {
    await _pumpDashboard(
      tester,
      _FakeOrderRepository(),
      _FakeExpenseRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.text('No sales yet today'), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Ã¢â‚¬â€'), findsOneWidget);
    expect(find.text('Waiting for sales'), findsOneWidget);
  });

  testWidgets('cards show live values with cancelled orders excluded',
      (tester) async {
    await _pumpDashboard(
      tester,
      _FakeOrderRepository(
        orders: [
          _order(id: '1', total: 1000),
          _order(id: '2', total: 2000),
          _order(id: '3', total: 5000, status: OrderStatus.cancelled),
        ],
      ),
      _FakeExpenseRepository(
        expenses: [_expense(id: 'e1', amount: 700)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rs. 3000'), findsOneWidget);
    expect(find.text('Rs. 700'), findsOneWidget);
    expect(find.text('2 orders'), findsOneWidget);
    expect(find.text('Rs. 2300'), findsOneWidget);
  });

  testWidgets('a loss renders with a leading minus', (tester) async {
    await _pumpDashboard(
      tester,
      _FakeOrderRepository(
        orders: [_order(id: '1', total: 500)],
      ),
      _FakeExpenseRepository(
        expenses: [_expense(id: 'e1', amount: 1200)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rs. 500'), findsOneWidget);
    expect(find.text('Rs. 1200'), findsOneWidget);
    expect(find.text('-Rs. 700'), findsOneWidget);
  });

  testWidgets('header shows the real current business date', (tester) async {
    await _pumpDashboard(
      tester,
      _FakeOrderRepository(),
      _FakeExpenseRepository(),
    );
    await tester.pumpAndSettle();

    final expected = formatDashboardHeaderDate(
      const BusinessDayService().businessDate(DateTime.now()),
    );
    expect(find.text(expected), findsOneWidget);
    expect(find.text('Thursday, 14 August'), findsNothing);
  });

  testWidgets('refresh re-subscribes both streams', (tester) async {
    final orderRepo = _FakeOrderRepository(
      orders: [_order(id: '1', total: 1000)],
    );
    final expenseRepo = _FakeExpenseRepository(
      expenses: [_expense(id: 'e1', amount: 700)],
    );

    await _pumpDashboard(tester, orderRepo, expenseRepo);
    await tester.pumpAndSettle();

    expect(orderRepo.streamCalls, 1);
    expect(expenseRepo.streamCalls, 1);

    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();

    expect(orderRepo.streamCalls, 2);
    expect(expenseRepo.streamCalls, 2);
  });

  testWidgets(
      'tapping ORDERS opens order history at today\'s business date',
      (tester) async {
    await _pumpDashboard(
      tester,
      _FakeOrderRepository(
        orders: [_order(id: '1', total: 500)],
      ),
      _FakeExpenseRepository(),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen)),
    );

    container.read(selectedDateProvider.notifier).state = DateTime(2026, 9, 29);
    tester.view.physicalSize = const Size(640, 1200);
    await tester.pump();

    await tester.tap(find.text('1 order'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderHistoryScreen), findsOneWidget);
    expect(
      container.read(selectedDateProvider),
      const BusinessDayService().businessDate(DateTime.now()),
    );
  });

  testWidgets(
      'tapping EXPENSES opens expense history at today\'s business date',
      (tester) async {
    await _pumpDashboardWithRouter(
      tester,
      _FakeOrderRepository(),
      _FakeExpenseRepository(
        expenses: [_expense(id: 'e1', amount: 250)],
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen)),
    );

    container.read(selectedExpenseDateProvider.notifier).state =
        DateTime(2026, 9, 29);

    await tester.tap(find.text('Rs. 250'));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseHistoryScreen), findsOneWidget);
    expect(
      container.read(selectedExpenseDateProvider),
      const BusinessDayService().businessDate(DateTime.now()),
    );
  });
}