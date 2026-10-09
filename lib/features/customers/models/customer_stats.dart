/// Statistics derived from a customer's orders (F19, F6, F8).
///
/// Never stored — always computed on demand from orders, because orders
/// can be edited, cancelled and re-marked paid. The computation lives in
/// `computeCustomerStats` (customer_stats_provider.dart); this class is
/// the shape that computation returns.
class CustomerStats {
  /// Count of non-cancelled orders.
  final int orderCount;

  /// Sum of `total` over non-cancelled orders.
  final double totalSpent;

  /// totalSpent / orderCount; 0 when there are no orders.
  final double averageOrderValue;

  /// Most frequent flavorName across order items (ties go to the most
  /// recent); null when there are no items.
  final String? favoriteFlavor;

  final int unpaidOrderCount;

  /// Sum still owed across unpaid, non-cancelled orders.
  /// (Phase 15: becomes ledger-aware.)
  final double unpaidAmount;

  final DateTime? firstOrderAt;
  final DateTime? lastOrderAt;

  const CustomerStats({
    this.orderCount = 0,
    this.totalSpent = 0,
    this.averageOrderValue = 0,
    this.favoriteFlavor,
    this.unpaidOrderCount = 0,
    this.unpaidAmount = 0,
    this.firstOrderAt,
    this.lastOrderAt,
  });

  /// Convenience for customers with no orders.
  static const empty = CustomerStats();

  static const _sentinel = Object();

  CustomerStats copyWith({
    int? orderCount,
    double? totalSpent,
    double? averageOrderValue,
    Object? favoriteFlavor = _sentinel,
    int? unpaidOrderCount,
    double? unpaidAmount,
    Object? firstOrderAt = _sentinel,
    Object? lastOrderAt = _sentinel,
  }) {
    return CustomerStats(
      orderCount: orderCount ?? this.orderCount,
      totalSpent: totalSpent ?? this.totalSpent,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      favoriteFlavor: favoriteFlavor == _sentinel
          ? this.favoriteFlavor
          : favoriteFlavor as String?,
      unpaidOrderCount: unpaidOrderCount ?? this.unpaidOrderCount,
      unpaidAmount: unpaidAmount ?? this.unpaidAmount,
      firstOrderAt: firstOrderAt == _sentinel
          ? this.firstOrderAt
          : firstOrderAt as DateTime?,
      lastOrderAt: lastOrderAt == _sentinel
          ? this.lastOrderAt
          : lastOrderAt as DateTime?,
    );
  }
}