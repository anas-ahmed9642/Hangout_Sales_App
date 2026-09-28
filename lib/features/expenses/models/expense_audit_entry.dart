class ExpenseAuditEntry {
  final String field;
  final Object? oldValue;
  final Object? newValue;
  final String changeReason;
  final DateTime? timestamp;
  const ExpenseAuditEntry({required this.field, this.oldValue, this.newValue, required this.changeReason, this.timestamp});
}
