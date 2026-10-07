import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/core/services/business_day_service.dart';
import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/dashboard/models/dashboard_summary.dart';
import 'package:hangout_sales_app/features/dashboard/providers/dashboard_providers.dart';
import 'package:hangout_sales_app/features/dashboard/widgets/dashboard_formatters.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_history_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_history_provider.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

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

/// Fake that counts stream subscriptions and records the requested date.
/// Returns a FRESH stream per call so re-subscription (refresh) works.
class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository({this.orders = const []});

  final List<Order> orders;
  int streamCalls = 0;
  DateTime? lastBusinessDate;

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) {
    streamCalls++;
    lastBusinessDate = businessDate;
    return Stream<List<Order>>.value(orders);
  }

  @override
  @override
  Future<void> createOrder(
    Order order, {
    CustomerUpsert? customerUpsert,
  }) async {}

  @override
  Stream<List<Order>> streamUnpaidOrders() =>
      Stream<List<Order>>.value(const <Order>[]);

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
  _FakeExpenseRepository({this.expenses = const [], this.fail = false});

  final List<Expense> expenses;
  final bool fail;
  int streamCalls = 0;
  DateTime? lastBusinessDate;

  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) {
    streamCalls++;
    lastBusinessDate = businessDate;
    if (fail) {
      return Stream<List<Expense>>.error(
        Exception('expenses unavailable'),
      );
    }
    return Stream<List<Expense>>.value(expenses);
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

void main() {
  group('DashboardSummary.fromLists', () {
    test('sums non-cancelled order totals and counts them', () {
      final summary = DashboardSummary.fromLists(
        orders: [
          _order(id: '1', total: 1000),
          _order(id: '2', total: 2000),
          _order(id: '3', total: 5000, status: OrderStatus.cancelled),
        ],
        expenses: const [],
      );

      expect(summary.totalSales, 3000);
      expect(summary.orderCount, 2);
    });

    test('sums operational expenses', () {
      final summary = DashboardSummary.fromLists(
        orders: const [],
        expenses: [
          _expense(id: 'e1', amount: 400),
          _expense(id: 'e2', amount: 300),
        ],
      );

      expect(summary.totalExpenses, 700);
    });

    test('profit is sales minus expenses', () {
      final summary = DashboardSummary.fromLists(
        orders: [_order(id: '1', total: 3000)],
        expenses: [_expense(id: 'e1', amount: 700)],
      );

      expect(summary.profit, 2300);
    });

    test('profit can be negative on a slow day', () {
      final summary = DashboardSummary.fromLists(
        orders: const [],
        expenses: [_expense(id: 'e1', amount: 700)],
      );

      expect(summary.profit, -700);
    });

    test('empty day has zero totals and no data', () {
      const summary = DashboardSummary.empty();

      expect(summary.totalSales, 0);
      expect(summary.totalExpenses, 0);
      expect(summary.orderCount, 0);
      expect(summary.profit, 0);
      expect(summary.hasData, isFalse);
    });
  });

  group('DashboardSummary static helpers', () {
    test('salesOf and activeOrderCount exclude cancelled orders', () {
      final orders = [
        _order(id: '1', total: 1000),
        _order(id: '2', total: 500, status: OrderStatus.cancelled),
      ];

      expect(DashboardSummary.salesOf(orders), 1000);
      expect(DashboardSummary.activeOrderCount(orders), 1);
    });

    test('expensesOf sums amounts', () {
      final expenses = [
        _expense(id: 'e1', amount: 400),
        _expense(id: 'e2', amount: 300),
      ];

      expect(DashboardSummary.expensesOf(expenses), 700);
    });
  });

  group('dashboard formatters', () {
    test('formatDashboardRs renders whole rupees', () {
      expect(formatDashboardRs(12500), 'Rs. 12500');
      expect(formatDashboardRs(0), 'Rs. 0');
    });

    test('formatDashboardRs keeps the raw minus sign on negatives', () {
      // The raw rule; card-level profit display uses formatDashboardProfit.
      expect(formatDashboardRs(-500), 'Rs. -500');
    });

    test('formatDashboardProfit renders profit as whole rupees', () {
      expect(formatDashboardProfit(2900), 'Rs. 2900');
      expect(formatDashboardProfit(1234.5), 'Rs. 1235');
    });

    test('formatDashboardProfit renders a loss with a leading minus', () {
      expect(formatDashboardProfit(-1500), '-Rs. 1500');
      expect(formatDashboardProfit(-1499.6), '-Rs. 1500');
    });

    test('formatDashboardProfit never renders negative zero', () {
      expect(formatDashboardProfit(0), 'Rs. 0');
      expect(formatDashboardProfit(-0.4), 'Rs. 0');
    });

    test('formatDashboardHeaderDate renders weekday, day and month', () {
      expect(
        formatDashboardHeaderDate(DateTime(2026, 9, 30)),
        'Wednesday, 30 September',
      );
      expect(
        formatDashboardHeaderDate(DateTime(2026, 8, 14)),
        'Friday, 14 August',
      );
    });
  });

  group('dashboard providers', () {
    test('orders stream serves the current business date', () async {
      final repository = _FakeOrderRepository(
        orders: [_order(id: '1', total: 1000)],
      );
      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final orders = await container.read(dashboardOrdersProvider.future);

      expect(orders, hasLength(1));
      expect(
        repository.lastBusinessDate,
        const BusinessDayService().businessDate(DateTime.now()),
      );
    });

    test('expenses stream serves the current business date', () async {
      final repository = _FakeExpenseRepository(
        expenses: [_expense(id: 'e1', amount: 700)],
      );
      final container = ProviderContainer(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final expenses = await container.read(dashboardExpensesProvider.future);

      expect(expenses, hasLength(1));
      expect(
        repository.lastBusinessDate,
        const BusinessDayService().businessDate(DateTime.now()),
      );
    });

    test('stream errors surface as provider errors', () async {
      final container = ProviderContainer(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(
            _FakeExpenseRepository(fail: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(dashboardExpensesProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('dashboard business date matches the service for now', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(dashboardBusinessDateProvider),
        const BusinessDayService().businessDate(DateTime.now()),
      );
    });

    test('streams ignore the history screens selected dates', () async {
      final orders = _FakeOrderRepository();
      final expenses = _FakeExpenseRepository();
      final container = ProviderContainer(
        overrides: [
          orderRepositoryProvider.overrideWithValue(orders),
          expenseRepositoryProvider.overrideWithValue(expenses),
        ],
      );
      addTearDown(container.dispose);

      // Simulate the user browsing another day in the history screens.
      // The listens keep the autoDispose date providers alive.
      final browsed = DateTime(2020, 1, 15);
      container.listen(selectedDateProvider, (_, _) {});
      container.listen(selectedExpenseDateProvider, (_, _) {});
      container.read(selectedDateProvider.notifier).state = browsed;
      container.read(selectedExpenseDateProvider.notifier).state = browsed;

      await container.read(dashboardOrdersProvider.future);
      await container.read(dashboardExpensesProvider.future);

      final expected = const BusinessDayService().businessDate(DateTime.now());
      expect(orders.lastBusinessDate, expected);
      expect(expenses.lastBusinessDate, expected);
      expect(expected, isNot(browsed));
    });
  });
}