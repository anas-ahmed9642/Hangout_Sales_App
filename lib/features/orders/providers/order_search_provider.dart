import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import 'order_repository_provider.dart';

/// Holds the current phone number the cashier is typing.
final orderSearchQueryProvider = StateProvider.autoDispose<String>((ref) {
  return '';
});
/// Toggles whether the UI should only display unpaid (pending) orders.
final unpaidFilterProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
final editedFilterProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});
/// Automatically fetches orders whenever the search query changes.
final orderSearchProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final query = ref.watch(orderSearchQueryProvider);

  // If the search box is empty, don't waste a Firebase read!
  if (query.trim().isEmpty) {
    return const [];
  }

  // Fetch from the repository.
  final repository = ref.watch(orderRepositoryProvider);
  return repository.searchOrdersByPhone(query.trim());
});