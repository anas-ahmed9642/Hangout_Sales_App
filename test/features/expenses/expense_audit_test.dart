import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_expense_repository.dart';

void main() {
  group('buildExpenseHistoryEntries', () {
    test('emits one entry per actually-changed field', () {
      final entries = buildExpenseHistoryEntries(
        currentData: {'title': 'Old title', 'amount': 100.0, 'notes': 'unchanged'},
        changes: {'title': 'New title', 'amount': 100.0},
        changeReason: '  corrected title  ', timestamp: DateTime(2026, 9, 23, 12, 0),
      );
      expect(entries, hasLength(1));
      final entry = entries.first;
      expect(entry['field'], 'title'); expect(entry['oldValue'], 'Old title'); expect(entry['newValue'], 'New title');
      expect(entry['changeReason'], 'corrected title'); expect(entry['timestamp'], isA<Timestamp>());
    });

    test('deep-compares list values so identical lines write no history', () {
      final entries = buildExpenseHistoryEntries(
        currentData: {'lineItems': [{'itemName': 'Cola Next 1ltr', 'price': 250.0}]},
        changes: {'lineItems': [{'itemName': 'Cola Next 1ltr', 'price': 250.0}]},
        changeReason: 'no-op save', timestamp: DateTime(2026, 9, 23),
      );
      expect(entries, isEmpty);
    });

    test('detects a real change inside a list value', () {
      final entries = buildExpenseHistoryEntries(
        currentData: {'lineItems': [{'itemName': 'Cola Next 1ltr', 'price': 250.0}]},
        changes: {'lineItems': [{'itemName': 'Cola Next 1ltr', 'price': 300.0}]},
        changeReason: 'price corrected', timestamp: DateTime(2026, 9, 23),
      );
      expect(entries, hasLength(1)); expect(entries.first['field'], 'lineItems');
      expect(entries.first['oldValue'], [{'itemName': 'Cola Next 1ltr', 'price': 250.0}]);
      expect(entries.first['newValue'], [{'itemName': 'Cola Next 1ltr', 'price': 300.0}]);
    });

    test('returns no entries when nothing changed', () {
      final entries = buildExpenseHistoryEntries(
        currentData: {'title': 'Same', 'amount': 50.0}, changes: {'title': 'Same', 'amount': 50.0},
        changeReason: 'no-op save', timestamp: DateTime(2026, 9, 23),
      );
      expect(entries, isEmpty);
    });
  });
}
