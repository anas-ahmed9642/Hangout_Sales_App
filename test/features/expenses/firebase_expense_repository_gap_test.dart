import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/chicken_purchase_line.dart';
import 'package:hangout_sales_app/features/expenses/models/expense.dart';
import 'package:hangout_sales_app/features/expenses/models/expense_category.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_expense_repository.dart';


Expense makeExpense({
  String id = 'exp-1',
  String title = 'Gas cylinder',
  ExpenseCategory category = ExpenseCategory.gas,
  double amount = 4500,
  String? notes,
  DateTime? businessDate,
  bool voided = false,
  double? pricePerKg,
  List<ChickenPurchaseLine>? chickenLines,
}) {
  final day = businessDate ?? DateTime(2026, 9, 28);
  return Expense(
    id: id,
    title: title,
    category: category,
    amount: amount,
    notes: notes,
    date: DateTime(day.year, day.month, day.day, 18, 30),
    businessDate: day,
    voided: voided,
    pricePerKg: pricePerKg,
    chickenLines: chickenLines,
  );
}

void main() {
  late FakeFirebaseFirestore fake;
  late FirebaseExpenseRepository repository;

  setUp(() {
    fake = FakeFirebaseFirestore();
    repository = FirebaseExpenseRepository(firestore: fake);
  });

  Future<Map<String, dynamic>> rawExpense(String id) async {
    final snapshot = await fake.collection('expenses').doc(id).get();
    return snapshot.data()!;
  }

  Future<List<Map<String, dynamic>>> rawHistory(String id) async {
    final snapshot = await fake
        .collection('expenses')
        .doc(id)
        .collection('history')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }


  group('createExpense / getExpense', () {
    test('writes under the caller-supplied id and nowhere else', () async {
      await repository.createExpense(makeExpense(id: 'custom-id'));

      final all = await fake.collection('expenses').get();

      expect(all.docs.map((doc) => doc.id), ['custom-id']);
    });

    test('getExpense returns null for an unknown id', () async {
      expect(await repository.getExpense('missing'), isNull);
    });

  });

  group('streamExpenses', () {
    test('a time-of-day on the requested date still resolves to the whole day',
        () async {
      await repository.createExpense(
        makeExpense(id: 'a', businessDate: DateTime(2026, 9, 28)),
      );

      final expenses = await repository
          .streamExpenses(DateTime(2026, 9, 28, 14, 30))
          .first;

      expect(expenses.map((expense) => expense.id), ['a']);
    });

    test('a stream drops an expense once it is voided', () async {
      await repository.createExpense(makeExpense(id: 'a'));

      final before =
          await repository.streamExpenses(DateTime(2026, 9, 28)).first;
      expect(before.map((expense) => expense.id), ['a']);

      await repository.voidExpense('a', changeReason: 'Entered twice');

      final after =
          await repository.streamExpenses(DateTime(2026, 9, 28)).first;
      expect(after, isEmpty);
    });

  });

  group('getExpensesByDateRange', () {
    test('a time-of-day on either bound is normalized to midnight', () async {
      await repository.createExpense(
        makeExpense(id: 'd27', businessDate: DateTime(2026, 9, 27)),
      );
      await repository.createExpense(
        makeExpense(id: 'd28', businessDate: DateTime(2026, 9, 28)),
      );
      await repository.createExpense(
        makeExpense(id: 'd29', businessDate: DateTime(2026, 9, 29)),
      );

      final result = await repository.getExpensesByDateRange(
        DateTime(2026, 9, 27, 13),
        DateTime(2026, 9, 29, 9),
      );

      expect(result.map((e) => e.id).toSet(), {'d27', 'd28'});
    });

    test('spans a month boundary', () async {
      await repository.createExpense(
        makeExpense(id: 'sep30', businessDate: DateTime(2026, 9, 30)),
      );
      await repository.createExpense(
        makeExpense(id: 'oct1', businessDate: DateTime(2026, 10, 1)),
      );
      await repository.createExpense(
        makeExpense(id: 'oct2', businessDate: DateTime(2026, 10, 2)),
      );

      final result = await repository.getExpensesByDateRange(
        DateTime(2026, 9, 30),
        DateTime(2026, 10, 2),
      );

      expect(result.map((e) => e.id).toSet(), {'sep30', 'oct1'});
    });

    test('an empty half-open range returns nothing', () async {
      await repository.createExpense(makeExpense(id: 'a'));

      final result = await repository.getExpensesByDateRange(
        DateTime(2026, 9, 28),
        DateTime(2026, 9, 28),
      );

      expect(result, isEmpty);
    });

  });

  group('getTotalExpensesByDateRange', () {
    test('is zero when the range holds no expenses', () async {
      final total = await repository.getTotalExpensesByDateRange(
        DateTime(2026, 9, 28),
        DateTime(2026, 9, 29),
      );

      expect(total, 0);
    });

    test('only counts expenses inside the range', () async {
      await repository.createExpense(
        makeExpense(id: 'in', amount: 1000, businessDate: DateTime(2026, 9, 28)),
      );
      await repository.createExpense(
        makeExpense(id: 'out', amount: 5000, businessDate: DateTime(2026, 9, 29)),
      );

      final total = await repository.getTotalExpensesByDateRange(
        DateTime(2026, 9, 28),
        DateTime(2026, 9, 29),
      );

      expect(total, 1000);
    });

    test('drops immediately after an expense is voided', () async {
      await repository.createExpense(makeExpense(id: 'a', amount: 4000));
      await repository.createExpense(makeExpense(id: 'b', amount: 2000));
      final start = DateTime(2026, 9, 28);
      final end = DateTime(2026, 9, 29);
      expect(await repository.getTotalExpensesByDateRange(start, end), 6000);

      await repository.voidExpense('a', changeReason: 'Wrong entry');

      expect(await repository.getTotalExpensesByDateRange(start, end), 2000);
    });

  });

  group('updateExpense', () {
    test('a second real edit takes editCount to two', () async {
      await repository.createExpense(makeExpense());

      await repository.updateExpense(
        'exp-1',
        {'title': 'Gas refill'},
        changeReason: 'Renamed',
      );
      await repository.updateExpense(
        'exp-1',
        {'amount': 5000.0},
        changeReason: 'Repriced',
      );

      expect((await rawExpense('exp-1'))['editCount'], 2);
      expect(await rawHistory('exp-1'), hasLength(2));
    });

    test('list values are deep-compared: identical lines write nothing, '
        'a changed line writes one row', () async {
      await repository.createExpense(
        makeExpense(
          id: 'chk-1',
          category: ExpenseCategory.chicken,
          amount: 2000,
          pricePerKg: 1000,
          chickenLines: const [
            ChickenPurchaseLine(chickenType: 'Malai Boti', quantityKg: 2),
          ],
        ),
      );

      await repository.updateExpense(
        'chk-1',
        {
          'chickenLines': [
            {'chickenType': 'Malai Boti', 'quantityKg': 2},
          ],
        },
        changeReason: 'Re-saved without changes',
      );
      expect(await rawHistory('chk-1'), isEmpty);
      expect((await rawExpense('chk-1'))['editCount'], 0);

      await repository.updateExpense(
        'chk-1',
        {
          'chickenLines': [
            {'chickenType': 'Malai Boti', 'quantityKg': 3},
          ],
          'amount': 3000.0,
        },
        changeReason: 'Extra kilo arrived',
      );

      final history = await rawHistory('chk-1');
      expect(history.map((row) => row['field']),
          unorderedEquals(['chickenLines', 'amount']));
      final restored = await repository.getExpense('chk-1');
      expect(restored!.chickenLines!.single.quantityKg, 3);
      expect(restored.amount, 3000);
      expect(restored.editCount, 1);
    });

    test('an empty change map is rejected', () async {
      await repository.createExpense(makeExpense());

      await expectLater(
        repository.updateExpense('exp-1', {}, changeReason: 'Why not'),
        throwsArgumentError,
      );
    });

    test('an unknown expense id is rejected', () async {
      await expectLater(
        repository.updateExpense(
          'missing',
          {'title': 'Anything'},
          changeReason: 'Testing',
        ),
        throwsStateError,
      );
    });

    test('a voided expense cannot be edited and stays untouched', () async {
      await repository.createExpense(makeExpense(voided: true));

      await expectLater(
        repository.updateExpense(
          'exp-1',
          {'title': 'Sneaky edit'},
          changeReason: 'Should be refused',
        ),
        throwsStateError,
      );

      expect((await rawExpense('exp-1'))['title'], 'Gas cylinder');
      expect(await rawHistory('exp-1'), isEmpty);
    });

  });

  group('voidExpense', () {
    test('a voided expense leaves every operational read', () async {
      await repository.createExpense(makeExpense(id: 'keep', amount: 1000));
      await repository.createExpense(makeExpense(id: 'drop', amount: 2000));

      await repository.voidExpense('drop', changeReason: 'Duplicate');

      final day = DateTime(2026, 9, 28);
      final nextDay = DateTime(2026, 9, 29);
      expect(
        (await repository.streamExpenses(day).first).map((e) => e.id),
        ['keep'],
      );
      expect(
        (await repository.getExpensesByDateRange(day, nextDay))
            .map((e) => e.id),
        ['keep'],
      );
      expect(await repository.getTotalExpensesByDateRange(day, nextDay), 1000);
    });

    test('a blank reason is rejected and the expense stays live', () async {
      await repository.createExpense(makeExpense());

      await expectLater(
        repository.voidExpense('exp-1', changeReason: '  '),
        throwsArgumentError,
      );

      expect((await repository.getExpense('exp-1'))!.voided, isFalse);
      expect(await rawHistory('exp-1'), isEmpty);
    });

    test('an unknown expense id is rejected', () async {
      await expectLater(
        repository.voidExpense('missing', changeReason: 'Testing'),
        throwsStateError,
      );
    });

  });

  group('getExpenseHistory', () {
    test('is empty for an expense that was never edited', () async {
      await repository.createExpense(makeExpense());

      expect(await repository.getExpenseHistory('exp-1'), isEmpty);
    });

    test('never mixes in another expense\'s history', () async {
      await repository.createExpense(makeExpense(id: 'one'));
      await repository.createExpense(makeExpense(id: 'two'));
      await repository.updateExpense(
        'one',
        {'title': 'Renamed one'},
        changeReason: 'Only one changed',
      );

      expect(await repository.getExpenseHistory('one'), hasLength(1));
      expect(await repository.getExpenseHistory('two'), isEmpty);
    });

  });
}
