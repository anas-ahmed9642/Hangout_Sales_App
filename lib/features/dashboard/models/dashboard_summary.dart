import '../../expenses/models/expense.dart';
import '../../orders/models/order.dart';

/// Today's rolled-up numbers for the dashboard overview cards.
///
/// Pure value object — all math is in the static helpers below, so it is
/// unit-testable without Firestore, providers, or widgets.
class DashboardSummary {
  /// Sum of [Order.total] over today's non-cancelled orders.
  ///
  /// [Order.total] already includes the delivery charge (grandTotal at save
  /// time), so this is the day's gross takings.
  final double totalSales;

  /// Sum of [Expense.amount] over today's operational expenses.
  ///
  /// Voided expenses never reach this object: the repository's operational
  /// stream excludes them by contract.
  final double totalExpenses;

  /// Count of today's non-cancelled orders.
  final int orderCount;

  const DashboardSummary({
    required this.totalSales,
    required this.totalExpenses,
    required this.orderCount,
  });

  const DashboardSummary.empty()
      : totalSales = 0,
        totalExpenses = 0,
        orderCount = 0;

  /// Gross takings minus expenses. May be negative on a slow day.
  double get profit => totalSales - totalExpenses;

  bool get hasSales => totalSales > 0;
  bool get hasExpenses => totalExpenses > 0;
  bool get hasData => hasSales || hasExpenses || orderCount > 0;

  /// Sum of [Order.total] over non-cancelled orders.
  ///
  /// Cancelled orders are excluded here because the repository's
  /// streamOrders includes them (precedent: the client-side cancelled
  /// filter in streamUnpaidOrders).
  static double salesOf(List<Order> orders) {
    var sales = 0.0;
    for (final order in orders) {
      if (order.status != OrderStatus.cancelled) {
        sales += order.total;
      }
    }
    return sales;
  }

  /// Count of non-cancelled orders.
  static int activeOrderCount(List<Order> orders) {
    var count = 0;
    for (final order in orders) {
      if (order.status != OrderStatus.cancelled) {
        count++;
      }
    }
    return count;
  }

  /// Sum of [Expense.amount] over operational expenses.
  static double expensesOf(List<Expense> expenses) {
    var total = 0.0;
    for (final expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  /// Builds the full summary from the day's raw lists.
  static DashboardSummary fromLists({
    required List<Order> orders,
    required List<Expense> expenses,
  }) {
    return DashboardSummary(
      totalSales: salesOf(orders),
      totalExpenses: expensesOf(expenses),
      orderCount: activeOrderCount(orders),
    );
  }
}