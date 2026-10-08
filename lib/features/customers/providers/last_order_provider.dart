import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/models/order.dart';
import 'customer_orders_provider.dart';

/// The customer's most recent non-cancelled order, or null.
///
/// The stream is already newest-first (createdAt descending), so this is
/// the first non-cancelled order. Cancelled orders are excluded like
/// every other customer-facing computation in the module (plan 8.8, F6).
/// Null while loading, on error, or when the customer has no orders —
/// the preview hides in all three cases (plan 8.10).
final lastOrderProvider =
    Provider.autoDispose.family<Order?, String>((ref, phone) {
  final orders =
      ref.watch(customerOrdersProvider(phone)).valueOrNull ?? const <Order>[];

  for (final order in orders) {
    if (order.status != OrderStatus.cancelled) {
      return order;
    }
  }
  return null;
});