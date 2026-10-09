import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/models/order.dart';
import '../models/customer_stats.dart';
import 'customer_orders_provider.dart';

/// Derives [CustomerStats] from one customer's orders (plan 5.4, 8.8).
///
/// Pure and synchronous so it is testable without Firestore or a
/// widget tree: [customerStatsProvider] feeds it orders from
/// [customerOrdersProvider]. Cancelled orders are excluded
/// from every figure — the module-wide rule for derived numbers
/// (customer_unpaid_provider.dart, last_order_provider.dart). Deals
/// carry no flavor quantities, so the favorite flavor counts
/// `OrderItem.flavorName × quantity` only (plan 8.8).
CustomerStats computeCustomerStats(List<Order> orders) {
  final active = orders
      .where((order) => order.status != OrderStatus.cancelled)
      .toList();

  if (active.isEmpty) {
    return CustomerStats.empty;
  }

  var totalSpent = 0.0;
  var unpaidOrderCount = 0;
  var unpaidAmount = 0.0;
  var firstOrderAt = active.first.createdAt;
  var lastOrderAt = active.first.createdAt;
  final flavorQuantities = <String, int>{};
  final flavorLatestAt = <String, DateTime>{};

  for (final order in active) {
    totalSpent += order.total;
    if (order.paymentStatus == PaymentStatus.unpaid) {
      unpaidOrderCount++;
      unpaidAmount += order.total;
    }
    if (order.createdAt.isBefore(firstOrderAt)) {
      firstOrderAt = order.createdAt;
    }
    if (order.createdAt.isAfter(lastOrderAt)) {
      lastOrderAt = order.createdAt;
    }
    for (final item in order.items) {
      final flavor = item.flavorName.trim();
      if (flavor.isEmpty) {
        continue;
      }
      flavorQuantities[flavor] =
          (flavorQuantities[flavor] ?? 0) + item.quantity;
      final seen = flavorLatestAt[flavor];
      if (seen == null || order.createdAt.isAfter(seen)) {
        flavorLatestAt[flavor] = order.createdAt;
      }
    }
  }

  // Favorite flavor: highest total quantity (plan 8.8). Ties go to
  // the flavor whose most recent order is newest. Comparing
  // createdAt (not list position) keeps this correct even if the
  // caller hands over an unordered list.
  String? favoriteFlavor;
  for (final flavor in flavorQuantities.keys) {
    final current = favoriteFlavor;
    if (current == null) {
      favoriteFlavor = flavor;
      continue;
    }
    final byQuantity =
        flavorQuantities[flavor]!.compareTo(flavorQuantities[current]!);
    if (byQuantity > 0 ||
        (byQuantity == 0 &&
            flavorLatestAt[flavor]!.isAfter(flavorLatestAt[current]!))) {
      favoriteFlavor = flavor;
    }
  }

  return CustomerStats(
    orderCount: active.length,
    totalSpent: totalSpent,
    averageOrderValue: totalSpent / active.length,
    favoriteFlavor: favoriteFlavor,
    unpaidOrderCount: unpaidOrderCount,
    unpaidAmount: unpaidAmount,
    firstOrderAt: firstOrderAt,
    lastOrderAt: lastOrderAt,
  );
}

/// [CustomerStats] for one customer phone (plan 8.12 stats card).
///
/// Derives from [customerOrdersProvider], so each phone is read once
/// even though the stats card and the order-history list both render
/// on the detail screen. Loading and error states collapse to
/// [CustomerStats.empty] — the card shows the no-orders state instead
/// of blocking the screen (customer_unpaid_provider.dart precedent).
final customerStatsProvider =
    Provider.autoDispose.family<CustomerStats, String>((ref, phone) {
  final orders =
      ref.watch(customerOrdersProvider(phone)).valueOrNull ?? const <Order>[];

  return computeCustomerStats(orders);
});
