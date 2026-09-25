import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/business_day_service.dart';
import '../models/order.dart';
import 'order_repository_provider.dart';

/// Holds the exact, normalized business date (midnight).
final selectedDateProvider = StateProvider.autoDispose<DateTime>((ref) {
  // 1. Calculate the current business day once, right at the start.
  return const BusinessDayService().businessDate(DateTime.now());
});

final orderHistoryProvider = StreamProvider.autoDispose<List<Order>>((ref) {
  // 2. This is now a pure, normalized date (either from the default above, or the DatePicker).
  final businessDate = ref.watch(selectedDateProvider);

  final repository = ref.watch(orderRepositoryProvider);

  // 3. We pass it directly to the repository without running it through the service again!
  return repository.streamOrders(businessDate);
});

/// Streams every currently unpaid order across all business dates.
///
/// Cancelled orders are excluded by the repository because their
/// payment status is no longer relevant.
final allUnpaidOrdersProvider =
    StreamProvider.autoDispose<List<Order>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);

  return repository.streamUnpaidOrders();
});