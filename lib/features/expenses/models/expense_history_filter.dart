import 'expense_category.dart';

/// Phase 9: immutable filter state for historical expense browsing.
///
/// [start] and [end] are inclusive business dates (midnight) as the user
/// sees them. [endExclusive] converts to the half-open [start, end)
/// the repository API expects — the repository's semantics are never
/// altered. Strongly typed: never a dynamic map.
class ExpenseHistoryFilter {
  final DateTime start;
  final DateTime end;
  final ExpenseCategory? category;

  const ExpenseHistoryFilter({
    required this.start,
    required this.end,
    this.category,
  });

  ExpenseHistoryFilter copyWith({
    DateTime? start,
    DateTime? end,
    ExpenseCategory? category,
    bool clearCategory = false,
  }) {
    return ExpenseHistoryFilter(
      start: start ?? this.start,
      end: end ?? this.end,
      category: clearCategory ? null : (category ?? this.category),
    );
  }

  /// Exclusive end boundary for
  /// ExpenseRepository.getExpensesByDateRange. DateTime normalizes
  /// month/year overflow (e.g. Sep 30 + 1 day = Oct 1).
  DateTime get endExclusive => DateTime(end.year, end.month, end.day + 1);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseHistoryFilter &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          category == other.category;

  @override
  int get hashCode => Object.hash(start, end, category);
}
