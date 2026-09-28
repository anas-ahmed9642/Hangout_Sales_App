import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/business_day_service.dart';
import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/expense_category_display.dart';
import '../models/expense_history_filter.dart';
import '../providers/expense_history_provider.dart';
import '../widgets/expense_history_item.dart';

/// Phase 9 — historical Expense browsing.
///
/// Range-based: [expenseHistoryFilterProvider] holds an inclusive
/// [start, end] business-date range (default: current business date).
/// [expenseHistoricalListProvider] reads the range through the
/// repository's half-open [start, end) API. Category filtering applies
/// client-side on the operational (voided-excluded) result; title search
/// applies client-side on the fetched list so typing never re-queries
/// Firestore. Totals are computed from the visible list so the number on
/// screen always matches the rows.
///
/// Tapping a row opens the Phase 10 expense detail screen.
class ExpenseHistoryScreen extends ConsumerWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(expenseHistoryFilterProvider);
    final searchQuery = ref.watch(expenseHistorySearchQueryProvider);
    final asyncExpenses = ref.watch(expenseHistoricalListProvider);

    return Scaffold(
      appBar: const HangoutAppBar(title: 'Expense History'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _RangeButton(
              filter: filter,
              onTap: () => _pickRange(context, ref, filter),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _RecentDaysRow(
              filter: filter,
              onSelectDay: (day) => ref
                  .read(expenseHistoryFilterProvider.notifier)
                  .state = filter.copyWith(start: day, end: day),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('expense_history_search'),
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref
                            .read(expenseHistorySearchQueryProvider.notifier)
                            .state = '',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Uncontrolled on purpose: typing writes the provider only,
              // so the field never rebuilds its own value and never loses
              // focus (Phase 7 lesson).
              onChanged: (value) => ref
                  .read(expenseHistorySearchQueryProvider.notifier)
                  .state = value,
            ),
          ),
          _CategoryFilterRow(
            selected: filter.category,
            onSelected: (category) => ref
                .read(expenseHistoryFilterProvider.notifier)
                .state = filter.copyWith(
              category: category,
              clearCategory: category == null,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(expenseHistoricalListProvider);
                await ref.read(expenseHistoricalListProvider.future);
              },
              child: asyncExpenses.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => _HistoryError(
                  message: _friendlyErrorMessage(error),
                  onRetry: () =>
                      ref.invalidate(expenseHistoricalListProvider),
                ),
                data: (expenses) {
                  final visible = _applySearch(expenses, searchQuery);
                  if (visible.isEmpty) {
                    return const _HistoryEmpty();
                  }
                  final total = visible.fold<double>(
                    0,
                    (sum, expense) => sum + expense.amount,
                  );
                  return Column(
                    children: [
                      _TotalsBar(count: visible.length, total: total),
                      Expanded(
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: visible.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final expense = visible[index];
                            return ExpenseHistoryItem(
                              expense: expense,
                              onTap: () => context.push(
                                AppRoutes.expenseDetailPath(expense.id),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Case-insensitive title substring filter on the already-fetched list.
List<Expense> _applySearch(List<Expense> expenses, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) {
    return expenses;
  }
  return expenses
      .where((expense) => expense.title.toLowerCase().contains(q))
      .toList();
}

Future<void> _pickRange(
  BuildContext context,
  WidgetRef ref,
  ExpenseHistoryFilter filter,
) async {
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2024),
    lastDate: DateTime.now().add(const Duration(days: 1)),
    initialDateRange: DateTimeRange(start: filter.start, end: filter.end),
  );
  // The picker callback updates provider state only; the list provider
  // reacts to the new filter. Never query Firestore from here.
  if (picked != null) {
    ref.read(expenseHistoryFilterProvider.notifier).state =
        filter.copyWith(
      start: _normalizeDay(picked.start),
      end: _normalizeDay(picked.end),
    );
  }
}

/// Strips any time component so the filter always holds exact business
/// dates (midnight).
DateTime _normalizeDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

const List<String> _monthNames = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDay(DateTime date) =>
    '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

String _formatRange(ExpenseHistoryFilter filter) {
  final start = _formatDay(filter.start);
  final end = _formatDay(filter.end);
  return start == end ? start : '$start → $end';
}

String _friendlyErrorMessage(Object error) {
  final raw = error.toString();
  return raw.startsWith('Exception: ')
      ? raw.substring('Exception: '.length)
      : raw;
}

class _RangeButton extends StatelessWidget {
  final ExpenseHistoryFilter filter;
  final VoidCallback onTap;

  const _RangeButton({required this.filter, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('expense_history_range_button'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Color(0xFFD4AF37)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatRange(filter),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onSelected;

  const _CategoryFilterRow({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _chip(
            label: 'All',
            selected: selected == null,
            onSelected: () => onSelected(null),
          ),
          for (final category in ExpenseCategory.values) ...[
            const SizedBox(width: 8),
            _chip(
              label: category.displayName,
              selected: selected == category,
              onSelected: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFD4AF37).withValues(alpha: 0.25),
      onSelected: (_) => onSelected(),
    );
  }
}

/// Horizontal strip of the last 7 business days for one-tap day jumps.
///
/// Tapping a day sets the filter to that single day (category and search
/// are preserved). The date-range button still handles arbitrary ranges;
/// when a multi-day range is active, no chip is highlighted.
class _RecentDaysRow extends StatelessWidget {
  final ExpenseHistoryFilter filter;
  final ValueChanged<DateTime> onSelectDay;

  const _RecentDaysRow({
    required this.filter,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final today = const BusinessDayService().businessDate(DateTime.now());
    // DateTime normalizes day <= 0 into the previous month.
    final days = List<DateTime>.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day - i),
    ).reversed.toList();

    final selectedDay = filter.start == filter.end ? filter.start : null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _DayChip(
              day: days[i],
              selected: selectedDay == days[i],
              onTap: () => onSelectDay(days[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      key: ValueKey('history_day_${day.day}_${day.month}'),
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD4AF37) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _weekdayNames[day.weekday - 1],
              style: textTheme.labelSmall?.copyWith(
                color: selected ? Colors.white : const Color(0xFF6B4E12),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: textTheme.titleSmall?.copyWith(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _weekdayNames = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

class _TotalsBar extends StatelessWidget {
  final int count;
  final double total;

  const _TotalsBar({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('expense_history_totals'),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            count == 1 ? '1 expense' : '$count expenses',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            'Rs. ${total.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scrollable so RefreshIndicator's pull gesture still works
        // when there is nothing to scroll.
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No recorded expenses match this date range and category.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HistoryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Couldn't load expenses",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

