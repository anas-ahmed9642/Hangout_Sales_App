// Display formatting for the dashboard overview.
//
// Mirrors the expenses feature's `formatExpenseRs` rule (whole rupees,
// `Rs. ` prefix) so every money figure in the app renders identically.
// Kept in the dashboard feature because lib/ has no cross-feature imports.

const List<String> _weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// 'Thursday, 14 August' — the dashboard header date line.
String formatDashboardHeaderDate(DateTime date) =>
    '${_weekdayNames[date.weekday - 1]}, ${date.day} ${_monthNames[date.month - 1]}';

/// 'Rs. 12500' — whole rupees, no decimals, matching the expenses module.
String formatDashboardRs(num amount) => 'Rs. ${amount.toStringAsFixed(0)}';

/// Profit figure with a leading minus on losses: '-Rs. 1500'.
///
/// Rounds to whole rupees first so a tiny negative floating-point residue
/// never renders as '-Rs. 0'.
String formatDashboardProfit(double amount) {
  final rounded = amount.round();

  if (rounded < 0) {
    return '-${formatDashboardRs(-rounded)}';
  }

  return formatDashboardRs(rounded);
}