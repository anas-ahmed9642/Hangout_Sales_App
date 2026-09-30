import 'package:cloud_firestore/cloud_firestore.dart';
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
    return (await fake.collection('expenses').doc(id).get()).data()!;
  }

  Future<List<Map<String, dynamic>>> rawHistory(String id) async {
    final snapshot = await fake
        .collection('expenses')
        .doc(id)
        .collection('history')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  test('round-trips a chicken expense', () async {
    await repository.createExpense(makeExpense(
      id: 'chk-1',
      category: ExpenseCategory.chicken,
      amount: 6000,
      pricePerKg: 1000,
      chickenLines: const [
        ChickenPurchaseLine(chickenType: 'Malai Boti', quantityKg: 2),
        ChickenPurchaseLine(chickenType: 'Chicken Fajita', quantityKg: 3),
        ChickenPurchaseLine(chickenType: 'Chicken Tikka', quantityKg: 1),
      ],
    ));
    final restored = await repository.getExpense('chk-1');
    expect(restored, isNotNull);
    expect(restored!.amount, 6000);
    expect(restored.chickenLines, hasLength(3));
    expect(restored.editCount, 0);
  });

  test('streams only the requested live business day', () async {
    await repository.createExpense(makeExpense(id: 'a'));
    await repository.createExpense(makeExpense(id: 'b', voided: true));
    await repository.createExpense(makeExpense(
      id: 'c',
      businessDate: DateTime(2026, 9, 27),
    ));
    final result = await repository.streamExpenses(DateTime(2026, 9, 28)).first;
    expect(result.map((expense) => expense.id), ['a']);
  });

  test('date ranges are inclusive-exclusive and exclude voided rows',
      () async {
    for (final day in [27, 28, 29]) {
      await repository.createExpense(makeExpense(
        id: 'd$day',
        businessDate: DateTime(2026, 9, day),
        voided: day == 28,
      ));
    }
    final result = await repository.getExpensesByDateRange(
      DateTime(2026, 9, 27, 13),
      DateTime(2026, 9, 29, 9),
    );
    expect(result.map((expense) => expense.id), ['d27']);
  });

  test('totals ignore voided expenses', () async {
    await repository.createExpense(makeExpense(id: 'a', amount: 4500));
    await repository.createExpense(makeExpense(
      id: 'b',
      amount: 1500,
      voided: true,
    ));
    expect(
      await repository.getTotalExpensesByDateRange(
        DateTime(2026, 9, 28),
        DateTime(2026, 9, 29),
      ),
      4500,
    );
  });

  test('updates changed fields and writes audit rows', () async {
    await repository.createExpense(makeExpense());
    await repository.updateExpense(
      'exp-1',
      {'title': 'Gas refill', 'amount': 4800.0},
      changeReason: '  Price went up  ',
    );
    final data = await rawExpense('exp-1');
    expect(data['title'], 'Gas refill');
    expect(data['amount'], 4800);
    expect(data['editCount'], 1);
    final history = await rawHistory('exp-1');
    expect(history, hasLength(2));
    expect(history.every((row) => row['changeReason'] == 'Price went up'),
        isTrue);
    expect(history.every((row) => row['timestamp'] is Timestamp), isTrue);
  });

  test('unchanged fields write no history', () async {
    await repository.createExpense(makeExpense());
    await repository.updateExpense(
      'exp-1',
      {'title': 'Gas cylinder'},
      changeReason: 'No change',
    );
    expect((await rawExpense('exp-1'))['editCount'], 0);
    expect(await rawHistory('exp-1'), isEmpty);
  });

  test('blank update reasons are rejected', () async {
    await repository.createExpense(makeExpense());
    await expectLater(
      repository.updateExpense(
        'exp-1',
        {'title': 'Gas refill'},
        changeReason: ' ',
      ),
      throwsArgumentError,
    );
  });

  test('voiding keeps the document and writes one audit row', () async {
    await repository.createExpense(makeExpense());
    await repository.voidExpense('exp-1', changeReason: '  Duplicate  ');
    final restored = await repository.getExpense('exp-1');
    expect(restored!.voided, isTrue);
    final history = await rawHistory('exp-1');
    expect(history.single['field'], 'voided');
    expect(history.single['oldValue'], false);
    expect(history.single['newValue'], true);
    expect(history.single['changeReason'], 'Duplicate');
  });

  test('voiding twice is rejected', () async {
    await repository.createExpense(makeExpense());
    await repository.voidExpense('exp-1', changeReason: 'First');
    await expectLater(
      repository.voidExpense('exp-1', changeReason: 'Second'),
      throwsStateError,
    );
    expect(await rawHistory('exp-1'), hasLength(1));
  });

  test('history rows include ids and are newest first', () async {
    await repository.createExpense(makeExpense());
    final history = fake.collection('expenses').doc('exp-1').collection('history');
    await history.doc('older').set({
      'field': 'title',
      'oldValue': 'A',
      'newValue': 'B',
      'changeReason': 'first',
      'timestamp': Timestamp.fromDate(DateTime(2026, 9, 28, 10)),
    });
    await history.doc('newer').set({
      'field': 'amount',
      'oldValue': 100,
      'newValue': 200,
      'changeReason': 'second',
      'timestamp': Timestamp.fromDate(DateTime(2026, 9, 28, 12)),
    });
    final rows = await repository.getExpenseHistory('exp-1');
    expect(rows.map((row) => row['id']), ['newer', 'older']);
  });
}
