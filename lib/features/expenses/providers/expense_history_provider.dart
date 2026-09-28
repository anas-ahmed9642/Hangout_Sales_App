import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/business_day_service.dart';
import '../models/expense.dart';
import '../models/expense_history_filter.dart';
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

/// Phase 9: filter state for the history screen. Defaults to the current
/// business date as a single-day range; autoDispose resets it when the
/// screen is revisited.
///
/// Watched by ExpenseHistoryScreen for its whole lifetime, so this
/// autoDispose provider always has a subscriber while visible (no
/// Phase-7-style set-on-unwatched-provider trap).
final expenseHistoryFilterProvider =
    StateProvider.autoDispose<ExpenseHistoryFilter>((ref) {
  return defaultExpenseHistoryFilter(DateTime.now());
});

/// Phase 9: historical expenses for the selected filter range.
///
/// One-shot read through the repository's half-open [start, end) API.
/// Category filtering applies client-side on the operational
/// (voided-excluded) result; newest first by save date.
final expenseHistoricalListProvider =
    FutureProvider.autoDispose<List<Expense>>((ref) async {
  final filter = ref.watch(expenseHistoryFilterProvider);
  final repository = ref.watch(expenseRepositoryProvider);

  final expenses = await repository.getExpensesByDateRange(
    filter.start,
    filter.endExclusive,
  );

  final filtered = filter.category == null
      ? [...expenses]
      : expenses.where((e) => e.category == filter.category).toList();

  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

/// Phase 9: title search query. Kept separate from the filter so typing
/// never re-queries Firestore — search applies client-side on the
/// already-fetched list.
final expenseHistorySearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

/// Default history filter: the current business date as a single-day
/// range.
///
/// Pure in [now] so tests can pin the 5:00 AM boundary without
/// reimplementing BusinessDayService.
ExpenseHistoryFilter defaultExpenseHistoryFilter(DateTime now) {
  final businessDate = const BusinessDayService().businessDate(now);
  return ExpenseHistoryFilter(start: businessDate, end: businessDate);
}
