import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/business_day_service.dart';
import '../models/expense.dart';
import 'expense_repository_provider.dart';

/// Holds the exact, normalized business date (midnight).
final selectedExpenseDateProvider = StateProvider.autoDispose<DateTime>((ref) {
  return const BusinessDayService().businessDate(DateTime.now());
});

/// Operational expense stream for the selected business day.
///
/// Voided expenses are excluded by the repository, so this stream is only
/// ever used for operational views — never for historical/audit inspection.
final expenseHistoryProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final businessDate = ref.watch(selectedExpenseDateProvider);
  final repository = ref.watch(expenseRepositoryProvider);

  return repository.streamExpenses(businessDate);
});
