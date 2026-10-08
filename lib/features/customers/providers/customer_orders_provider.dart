import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/models/order.dart';
import '../../orders/providers/order_repository_provider.dart';

/// All orders for one customer phone, newest first.
///
/// One Firestore query: customerPhone == phone, ordered by createdAt
/// descending (composite index from firestore.indexes.json, Phase 5).
/// The unpaid summary and the last-order preview both derive from this
/// stream, so each phone is read once. Keyed by the NORMALIZED phone —
/// callers pass draft.matchedCustomerPhone.
final customerOrdersProvider =
    StreamProvider.autoDispose.family<List<Order>, String>((ref, phone) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.streamOrdersByCustomerPhone(phone);
});