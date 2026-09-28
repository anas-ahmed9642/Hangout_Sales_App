
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/chicken_purchase_line.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_edit_input.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_line_item.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_actions_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_detail_provider.dart';
import 'package:hangout_sales_app/features/expenses/providers/expense_repository_provider.dart';
import 'package:hangout_sales_app/features/expenses/repositories/expense_repository.dart';
import 'package:hangout_sales_app/features/expenses/widgets/expense_audit_trail.dart';

import '../../helpers/test_container.dart';

class _UpdateCall {
  final String id;
  final Map<String, dynamic> changes;
  final String reason;

  _UpdateCall(this.id, this.changes, this.reason);
}

class _VoidCall {
  final String id;
  final String reason;

  _VoidCall(this.id, this.reason);
}

class _RecordingRepository implements ExpenseRepository {
  final List<_UpdateCall> updateCalls = [];
  final List<_VoidCall> voidCalls = [];
  final List<Map<String, dynamic>> historyRows;

  _RecordingRepository({this.historyRows = const []});

  @override
  Future<void> updateExpense(
    String expenseId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {
    updateCalls.add(_UpdateCall(expenseId, changes, changeReason));
  }

  @override
  Future<void> voidExpense(
    String expenseId, {
    required String changeReason,
  }) async {
    voidCalls.add(_VoidCall(expenseId, changeReason));
  }

  @override
  Future<List<Map<String, dynamic>>> getExpenseHistory(String expenseId) async {
    return historyRows;
  }

  @override
  Future<void> createExpense(Expense expense) => throw UnimplementedError();
  @override
  Stream<List<Expense>> streamExpenses(DateTime businessDate) =>
      throw UnimplementedError();
  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      throw UnimplementedError();
  @override
  Future<double> getTotalExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) =>
      throw UnimplementedError();
  @override
  Future<Expense?> getExpense(String expenseId) => throw UnimplementedError();
}

Expense _expense({
  required String id,
  required String title,
  required ExpenseCategory category,
  required double amount,
  String? notes,
  String? workerName,
  double? pricePerKg,
  List<ChickenPurchaseLine>? chickenLines,
  List<ExpenseLineItem>? lineItems,
  bool voided = false,
}) {
  return Expense(
    id: id,
    title: title,
    category: category,
    amount: amount,
    notes: notes,
    date: DateTime(2026, 9, 28, 10),
    businessDate: DateTime(2026, 9, 28),
    voided: voided,
    workerName: workerName,
    pricePerKg: pricePerKg,
    chickenLines: chickenLines,
    lineItems: lineItems,
  );
}

Expense _plain({bool voided = false}) => _expense(
      id: 'plain1',
      title: 'Gas cylinder',
      category: ExpenseCategory.gas,
      amount: 4500,
      notes: 'Gas refill',
      voided: voided,
    );

Expense _wages() => _expense(
      id: 'wage1',
      title: 'Weekly wage',
      category: ExpenseCategory.workersWages,
      amount: 12000,
      workerName: 'Bilal',
    );

Expense _chicken() => _expense(
      id: 'chk1',
      title: 'Morning chicken',
      category: ExpenseCategory.chicken,
      amount: 7500,
      pricePerKg: 500,
      chickenLines: const [
        ChickenPurchaseLine(chickenType: 'Malai Boti', quantityKg: 10),
        ChickenPurchaseLine(chickenType: 'Chicken Tikka', quantityKg: 5),
      ],
    );

Expense _catalog() => _expense(
      id: 'cat1',
      title: 'Market run',
      category: ExpenseCategory.marketBills,
      amount: 500,
      lineItems: const [
        ExpenseLineItem(itemName: 'Onion', price: 200),
        ExpenseLineItem(itemName: 'Tomato', price: 300),
      ],
    );

void main() {
  group('buildExpenseChanges', () {
    test('returns no changes when nothing was edited (every shape)', () {
      for (final expense in [_plain(), _wages(), _chicken(), _catalog()]) {
        expect(
          buildExpenseChanges(expense, ExpenseEditInput.fromExpense(expense)),
          isEmpty,
          reason: expense.id,
        );
      }
    });

    test('plain: only the edited title is included; input is trimmed', () {
      final changes = buildExpenseChanges(
        _plain(),
        const ExpenseEditInput(
          title: '  Gas cylinder (large)  ',
          notes: 'Gas refill',
          amount: 4500,
        ),
      );
      expect(changes, {'title': 'Gas cylinder (large)'});
    });

    test('plain: clearing notes writes null', () {
      final changes = buildExpenseChanges(
        _plain(),
        const ExpenseEditInput(title: 'Gas cylinder', notes: '', amount: 4500),
      );
      expect(changes, {'notes': null});
    });

    test('plain: amount change', () {
      final changes = buildExpenseChanges(
        _plain(),
        const ExpenseEditInput(
          title: 'Gas cylinder',
          notes: 'Gas refill',
          amount: 5000,
        ),
      );
      expect(changes, {'amount': 5000.0});
    });

    test('wages: worker name and amount', () {
      final changes = buildExpenseChanges(
        _wages(),
        const ExpenseEditInput(
          title: 'Weekly wage',
          workerName: 'Imran',
          amount: 13000,
        ),
      );
      expect(changes, {'workerName': 'Imran', 'amount': 13000.0});
    });

    test('chicken: a quantity change rewrites lines and recomputes amount',
        () {
      final changes = buildExpenseChanges(
        _chicken(),
        const ExpenseEditInput(
          title: 'Morning chicken',
          pricePerKg: 500,
          chickenQuantities: [12, 5],
        ),
      );
      expect(changes, {
        'chickenLines': [
          {'chickenType': 'Malai Boti', 'quantityKg': 12},
          {'chickenType': 'Chicken Tikka', 'quantityKg': 5},
        ],
        'amount': 8500.0,
      });
    });

    test('chicken: a price change recomputes amount without touching lines',
        () {
      final changes = buildExpenseChanges(
        _chicken(),
        const ExpenseEditInput(
          title: 'Morning chicken',
          pricePerKg: 520,
          chickenQuantities: [10, 5],
        ),
      );
      expect(changes, {'pricePerKg': 520.0, 'amount': 7800.0});
    });

    test('catalog: a price change rewrites items and recomputes amount', () {
      final changes = buildExpenseChanges(
        _catalog(),
        const ExpenseEditInput(
          title: 'Market run',
          lineItemPrices: [200, 350],
        ),
      );
      expect(changes, {
        'lineItems': [
          {'itemName': 'Onion', 'price': 200.0},
          {'itemName': 'Tomato', 'price': 350.0},
        ],
        'amount': 550.0,
      });
    });

    test('throws StateError for invalid input', () {
      expect(
        () => buildExpenseChanges(
          _plain(),
          const ExpenseEditInput(title: '   ', amount: 4500),
        ),
        throwsStateError,
      );
    });
  });

  group('validateExpenseEdit', () {
    test('requires a title', () {
      final errors = validateExpenseEdit(
        _plain(),
        const ExpenseEditInput(title: ' ', amount: 4500),
      );
      expect(errors, contains('Title is required.'));
    });

    test('plain needs a positive amount', () {
      final errors = validateExpenseEdit(
        _plain(),
        const ExpenseEditInput(title: 'Gas', amount: 0),
      );
      expect(errors, contains('Amount must be greater than zero.'));
    });

    test('wages needs a worker name', () {
      final errors = validateExpenseEdit(
        _wages(),
        const ExpenseEditInput(title: 'Wage', workerName: ' ', amount: 100),
      );
      expect(errors, contains('Worker name is required.'));
    });

    test('chicken needs positive kg and price', () {
      final errors = validateExpenseEdit(
        _chicken(),
        const ExpenseEditInput(
          title: 'Chicken',
          pricePerKg: 0,
          chickenQuantities: [0, 5],
        ),
      );
      expect(errors, contains('Chicken quantity must be greater than zero.'));
      expect(errors, contains('Price per kg must be greater than zero.'));
    });

    test('chicken quantities must match the saved lines', () {
      final errors = validateExpenseEdit(
        _chicken(),
        const ExpenseEditInput(
          title: 'Chicken',
          pricePerKg: 500,
          chickenQuantities: [10],
        ),
      );
      expect(errors, contains('Chicken quantities do not match the saved lines.'));
    });

    test('a chicken expense without lines cannot be edited', () {
      final broken = _expense(
        id: 'chk2',
        title: 'Broken',
        category: ExpenseCategory.chicken,
        amount: 100,
        pricePerKg: 100,
      );
      final errors = validateExpenseEdit(
        broken,
        const ExpenseEditInput(title: 'Broken', pricePerKg: 100),
      );
      expect(errors, contains('This expense has no chicken lines to edit.'));
    });

    test('catalog needs positive prices', () {
      final errors = validateExpenseEdit(
        _catalog(),
        const ExpenseEditInput(title: 'Run', lineItemPrices: [200, 0]),
      );
      expect(errors, contains('Item price must be greater than zero.'));
    });
  });

  group('ExpenseActions', () {
    test('saveEdit writes only changed fields with the trimmed reason',
        () async {
      final repo = _RecordingRepository();
      final actions = ExpenseActions(repo);

      final wrote = await actions.saveEdit(
        original: _plain(),
        input: const ExpenseEditInput(
          title: 'Gas cylinder',
          notes: 'Gas refill',
          amount: 5000,
        ),
        changeReason: '  Price was wrong  ',
      );

      expect(wrote, isTrue);
      expect(repo.updateCalls, hasLength(1));
      expect(repo.updateCalls.single.id, 'plain1');
      expect(repo.updateCalls.single.changes, {'amount': 5000.0});
      expect(repo.updateCalls.single.reason, 'Price was wrong');
    });

    test('saveEdit with no changes returns false and writes nothing',
        () async {
      final repo = _RecordingRepository();
      final expense = _plain();

      final wrote = await ExpenseActions(repo).saveEdit(
        original: expense,
        input: ExpenseEditInput.fromExpense(expense),
        changeReason: 'No-op',
      );

      expect(wrote, isFalse);
      expect(repo.updateCalls, isEmpty);
    });

    test('saveEdit requires a reason', () async {
      final repo = _RecordingRepository();
      final expense = _plain();

      await expectLater(
        ExpenseActions(repo).saveEdit(
          original: expense,
          input: const ExpenseEditInput(
            title: 'Changed',
            notes: 'Gas refill',
            amount: 4500,
          ),
          changeReason: '   ',
        ),
        throwsArgumentError,
      );
      expect(repo.updateCalls, isEmpty);
    });

    test('saveEdit refuses a voided expense', () async {
      final repo = _RecordingRepository();

      await expectLater(
        ExpenseActions(repo).saveEdit(
          original: _plain(voided: true),
          input: const ExpenseEditInput(title: 'Changed', amount: 4500),
          changeReason: 'Trying anyway',
        ),
        throwsStateError,
      );
      expect(repo.updateCalls, isEmpty);
    });

    test('voidExpense trims and forwards the reason', () async {
      final repo = _RecordingRepository();

      await ExpenseActions(repo).voidExpense(
        expense: _plain(),
        changeReason: '  Entered twice  ',
      );

      expect(repo.voidCalls, hasLength(1));
      expect(repo.voidCalls.single.id, 'plain1');
      expect(repo.voidCalls.single.reason, 'Entered twice');
    });

    test('voidExpense requires a reason and refuses an already-voided one',
        () async {
      final repo = _RecordingRepository();
      final actions = ExpenseActions(repo);

      await expectLater(
        actions.voidExpense(expense: _plain(), changeReason: ' '),
        throwsArgumentError,
      );
      await expectLater(
        actions.voidExpense(
          expense: _plain(voided: true),
          changeReason: 'Again',
        ),
        throwsStateError,
      );
      expect(repo.voidCalls, isEmpty);
    });

    test('expenseActionsProvider uses the overridden repository', () async {
      final repo = _RecordingRepository();
      final container = createTestContainer(
        overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
      );

      await container.read(expenseActionsProvider).voidExpense(
            expense: _plain(),
            changeReason: 'Duplicate',
          );

      expect(repo.voidCalls.single.reason, 'Duplicate');
    });
  });

  group('audit trail', () {
    test('expenseAuditEntryFromMap converts a Firestore timestamp', () {
      final entry = expenseAuditEntryFromMap({
        'id': 'h1',
        'field': 'amount',
        'oldValue': 7000.0,
        'newValue': 7500.0,
        'changeReason': 'Wrong price',
        'timestamp': Timestamp.fromDate(DateTime(2026, 9, 28, 11, 30)),
      });

      expect(entry.field, 'amount');
      expect(entry.oldValue, 7000.0);
      expect(entry.newValue, 7500.0);
      expect(entry.changeReason, 'Wrong price');
      expect(entry.timestamp, DateTime(2026, 9, 28, 11, 30));
    });

    test('expenseAuditEntryFromMap tolerates missing fields', () {
      final entry = expenseAuditEntryFromMap({'field': 'notes'});

      expect(entry.field, 'notes');
      expect(entry.changeReason, '');
      expect(entry.timestamp, isNull);
    });

    test('expenseAuditTrailProvider maps repository rows', () async {
      final repo = _RecordingRepository(
        historyRows: [
          {
            'id': 'h1',
            'field': 'voided',
            'oldValue': false,
            'newValue': true,
            'changeReason': 'Entered twice',
            'timestamp': Timestamp.fromDate(DateTime(2026, 9, 28, 12)),
          },
        ],
      );
      final container = createTestContainer(
        overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
      );
      container.listen(
        expenseAuditTrailProvider('e1'),
        (previous, next) {},
      );

      final entries =
          await container.read(expenseAuditTrailProvider('e1').future);

      expect(entries, hasLength(1));
      expect(entries.single.field, 'voided');
      expect(entries.single.changeReason, 'Entered twice');
    });

    test('field labels', () {
      expect(expenseAuditFieldLabel('workerName'), 'Worker');
      expect(expenseAuditFieldLabel('voided'), 'Status');
      expect(expenseAuditFieldLabel('somethingNew'), 'somethingNew');
    });

    test('value formatting', () {
      expect(formatExpenseAuditValue('amount', 7500.0), 'Rs. 7500');
      expect(formatExpenseAuditValue('amount', 12.5), 'Rs. 12.5');
      expect(formatExpenseAuditValue('voided', true), 'Voided');
      expect(formatExpenseAuditValue('voided', false), 'Active');
      expect(formatExpenseAuditValue('notes', null), '—');
      expect(formatExpenseAuditValue('title', 'Old title'), 'Old title');
      expect(
        formatExpenseAuditValue('chickenLines', [
          {'chickenType': 'Malai Boti', 'quantityKg': 12},
        ]),
        '12 kg Malai Boti',
      );
      expect(
        formatExpenseAuditValue('lineItems', [
          {'itemName': 'Onion', 'price': 200.0},
        ]),
        'Onion (Rs. 200)',
      );
    });
  });
}