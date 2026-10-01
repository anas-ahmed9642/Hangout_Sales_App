import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/business_day_service.dart';
import '../../expenses/models/expense.dart';
import '../../expenses/providers/expense_repository_provider.dart';
import '../../orders/models/order.dart';
import '../../orders/providers/order_repository_provider.dart';

/// The business day the dashboard reports on: always the CURRENT business
/// day (5:00 AM cutoff), computed on first read.
///
/// Deliberately its own provider, separate from the history screens'
/// user-changeable date providers (selectedDateProvider,
/// selectedExpenseDateProvider) — browsing another day in Order/Expense
/// History must never change the dashboard's numbers.
///
/// autoDispose so a screen left open past the 5:00 AM cutoff recomputes the
/// date when the refresh button invalidates it.
final dashboardBusinessDateProvider = Provider.autoDispose<DateTime>((ref) {
  return const BusinessDayService().businessDate(DateTime.now());
});

/// Live stream of the current business day's orders.
///
/// The repository does not exclude cancelled orders; DashboardSummary
/// does, client-side.
final dashboardOrdersProvider =
    StreamProvider.autoDispose<List<Order>>((ref) {
  final businessDate = ref.watch(dashboardBusinessDateProvider);
  final repository = ref.watch(orderRepositoryProvider);

  return repository.streamOrders(businessDate);
});

/// Live stream of the current business day's operational expenses.
///
/// Voided expenses are already excluded by the repository contract.
final dashboardExpensesProvider =
    StreamProvider.autoDispose<List<Expense>>((ref) {
  final businessDate = ref.watch(dashboardBusinessDateProvider);
  final repository = ref.watch(expenseRepositoryProvider);

  return repository.streamExpenses(businessDate);
});