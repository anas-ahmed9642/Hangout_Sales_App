const List<String> _monthNames = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String formatExpenseDay(DateTime date) => '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
String formatExpenseTime(DateTime date) => '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String formatExpenseRs(num amount) => 'Rs. ${amount.toStringAsFixed(0)}';
String formatExpenseNumber(num value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toString();
