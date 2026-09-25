import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'order_repository_provider.dart';

final orderEditHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);

  return repository.getOrderHistory(orderId);
});