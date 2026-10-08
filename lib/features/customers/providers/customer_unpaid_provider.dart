import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/models/order.dart';
import 'customer_orders_provider.dart';

/// Unpaid-balance summary for one customer phone (plan 8.9, F6).
///
/// Source in Phases 1-12: the customer's unpaid, non-cancelled orders.
/// Phase 15 re-points this at the ledger-aware remaining balance.
/// The banner is informational — it never blocks saving.
class UnpaidSummary {
  final int count;
  final double amount;

  const UnpaidSummary({this.count = 0, this.amount = 0});

  bool get hasUnpaid => count > 0;
}

/// Derives [UnpaidSummary] from [customerOrdersProvider]. Loading and
/// error states collapse to an empty summary — the banner hides instead
/// of blocking (plan 8.9).
final customerUnpaidProvider =
    Provider.autoDispose.family<UnpaidSummary, String>((ref, phone) {
  final orders =
      ref.watch(customerOrdersProvider(phone)).valueOrNull ?? const <Order>[];

  var count = 0;
  var amount = 0.0;
  for (final order in orders) {
    if (order.paymentStatus == PaymentStatus.unpaid &&
        order.status != OrderStatus.cancelled) {
      count++;
      amount += order.total;
    }
  }
  return UnpaidSummary(count: count, amount: amount);
});