import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/models/customer_duplicate_candidate.dart';
import 'package:hangout_sales_app/features/customers/repositories/customer_merge_repository.dart';
import 'package:hangout_sales_app/features/customers/repositories/firebase_customer_merge_repository.dart';
import 'package:hangout_sales_app/features/customers/repositories/firebase_customer_repository.dart';
import 'package:hangout_sales_app/features/customers/services/customer_merge_service.dart';

const _source = '03001111111';
const _target = '03002222222';
const _other = '03003333333';

final _created = DateTime(2026, 9, 1);

CustomerAddress _address(String id, String text, {String? label}) {
  return CustomerAddress(id: id, label: label, text: text);
}

Customer _customer(
  String phone, {
  String? name,
  List<CustomerAddress> addresses = const [],
  String? defaultAddressId,
  String? deliveryNotes,
  String? notes,
  bool archived = false,
  String? mergedInto,
  DateTime? lastOrderAt,
}) {
  return Customer(
    phone: phone,
    name: name,
    addresses: addresses,
    defaultAddressId: defaultAddressId,
    deliveryNotes: deliveryNotes,
    notes: notes,
    archived: archived,
    mergedInto: mergedInto,
    createdAt: _created,
    updatedAt: _created,
    lastOrderAt: lastOrderAt,
  );
}

Future<void> _seedOrder(
  FakeFirebaseFirestore firestore,
  String id,
  String phone, {
  String status = 'completed',
  int editCount = 0,
}) {
  return firestore.collection('orders').doc(id).set({
    'id': id,
    'customerPhone': phone,
    'status': status,
    'editCount': editCount,
    'total': 1000.0,
  });
}

Future<List<String>> _orderIdsFor(
  FakeFirebaseFirestore firestore,
  String phone,
) async {
  final snapshot = await firestore
      .collection('orders')
      .where('customerPhone', isEqualTo: phone)
      .get();
  final ids = snapshot.docs.map((doc) => doc.id).toList()..sort();
  return ids;
}

Future<int> _historyCount(FakeFirebaseFirestore firestore, String id) async {
  final snapshot =
      await firestore.collection('orders').doc(id).collection('history').get();
  return snapshot.docs.length;
}

void main() {
  group('planCustomerMerge', () {
    test('adds only addresses whose text is new and keeps the default', () {
      final plan = planCustomerMerge(
        source: _customer(
          _source,
          addresses: [
            _address('s1', 'house 14,  street 3'),
            _address('s2', 'Shop 9, Market'),
          ],
        ),
        target: _customer(
          _target,
          addresses: [
            _address('t1', 'House 14, Street 3'),
            _address('t2', 'Office Tower'),
          ],
          defaultAddressId: 't1',
        ),
      );

      expect(plan.addressesToAdd, hasLength(1));
      expect(plan.addressesToAdd.single.text, 'Shop 9, Market');
      expect(plan.addresses, hasLength(3));
      expect(plan.defaultAddressId, 't1');
    });

    test('gives a colliding address id a fresh id', () {
      final plan = planCustomerMerge(
        source: _customer(_source, addresses: [_address('same', 'Shop 9')]),
        target: _customer(_target, addresses: [_address('same', 'House 14')]),
      );

      expect(plan.addressesToAdd, hasLength(1));
      expect(plan.addressesToAdd.single.id, isNot('same'));
      final ids = plan.addresses.map((address) => address.id).toSet();
      expect(ids, hasLength(2));
    });

    test('adopts the source default when the target has no addresses', () {
      final plan = planCustomerMerge(
        source: _customer(
          _source,
          addresses: [_address('s1', 'House 1'), _address('s2', 'House 2')],
          defaultAddressId: 's2',
        ),
        target: _customer(_target),
      );

      expect(plan.addresses, hasLength(2));
      expect(plan.defaultAddressId, 's2');
    });

    test('no addresses on either side leaves no default', () {
      final plan = planCustomerMerge(
        source: _customer(_source),
        target: _customer(_target),
      );

      expect(plan.addresses, isEmpty);
      expect(plan.defaultAddressId, isNull);
    });

    test('appends internal notes with a newline', () {
      final plan = planCustomerMerge(
        source: _customer(_source, notes: 'Likes extra dip'),
        target: _customer(_target, notes: 'Pays by card'),
      );

      expect(plan.notes, 'Pays by card\nLikes extra dip');
      expect(plan.notesChanged, isTrue);
      expect(plan.notesTruncated, isFalse);
    });

    test('copies source notes when the target has none', () {
      final plan = planCustomerMerge(
        source: _customer(_source, notes: 'Likes extra dip'),
        target: _customer(_target),
      );

      expect(plan.notes, 'Likes extra dip');
      expect(plan.notesChanged, isTrue);
    });

    test('does not repeat a note the target already contains', () {
      final plan = planCustomerMerge(
        source: _customer(_source, notes: 'pays by card'),
        target: _customer(_target, notes: 'Pays by card, always'),
      );

      expect(plan.notes, 'Pays by card, always');
      expect(plan.notesChanged, isFalse);
    });

    test('shortens appended notes without touching the existing text', () {
      final existing = 'x' * 295;
      final plan = planCustomerMerge(
        source: _customer(_source, notes: 'abcdefghij'),
        target: _customer(_target, notes: existing),
      );

      expect(plan.notes!.length, 300);
      expect(plan.notes!.startsWith(existing), isTrue);
      expect(plan.notes!.endsWith('\u2026'), isTrue);
      expect(plan.notesChanged, isTrue);
      expect(plan.notesTruncated, isTrue);
      // The result must be a valid customer value.
      expect(
        () => _customer(_target, notes: plan.notes),
        returnsNormally,
      );
    });

    test('leaves the target notes alone when there is no room', () {
      final existing = 'x' * 300;
      final plan = planCustomerMerge(
        source: _customer(_source, notes: 'abc'),
        target: _customer(_target, notes: existing),
      );

      expect(plan.notes, existing);
      expect(plan.notesChanged, isFalse);
      expect(plan.notesTruncated, isTrue);
    });

    test('joins delivery notes with a semicolon', () {
      final plan = planCustomerMerge(
        source: _customer(_source, deliveryNotes: 'Call on arrival'),
        target: _customer(_target, deliveryNotes: 'Gate is blue'),
      );

      expect(plan.deliveryNotes, 'Gate is blue; Call on arrival');
      expect(plan.deliveryNotesChanged, isTrue);
    });

    test('keeps the newer lastOrderAt', () {
      final sourceNewer = planCustomerMerge(
        source: _customer(_source, lastOrderAt: DateTime(2026, 9, 20)),
        target: _customer(_target, lastOrderAt: DateTime(2026, 9, 10)),
      );
      final targetNewer = planCustomerMerge(
        source: _customer(_source, lastOrderAt: DateTime(2026, 9, 1)),
        target: _customer(_target, lastOrderAt: DateTime(2026, 9, 10)),
      );
      final targetNull = planCustomerMerge(
        source: _customer(_source, lastOrderAt: DateTime(2026, 9, 1)),
        target: _customer(_target),
      );
      final bothNull = planCustomerMerge(
        source: _customer(_source),
        target: _customer(_target),
      );

      expect(sourceNewer.lastOrderAt, DateTime(2026, 9, 20));
      expect(targetNewer.lastOrderAt, DateTime(2026, 9, 10));
      expect(targetNull.lastOrderAt, DateTime(2026, 9, 1));
      expect(bothNull.lastOrderAt, isNull);
    });
  });

  group('customerMergeBlocker', () {
    test('allows two active customers', () {
      expect(
        customerMergeBlocker(
          source: _customer(_source),
          target: _customer(_target),
        ),
        isNull,
      );
    });

    test('blocks the same customer, merged sources and bad targets', () {
      expect(
        customerMergeBlocker(
          source: _customer(_source),
          target: _customer(_source),
        ),
        isNotNull,
      );
      expect(
        customerMergeBlocker(
          source: _customer(_source, archived: true, mergedInto: _other),
          target: _customer(_target),
        ),
        contains('already merged'),
      );
      expect(
        customerMergeBlocker(
          source: _customer(_source),
          target: _customer(_target, archived: true, mergedInto: _other),
        ),
        contains('cannot receive'),
      );
      expect(
        customerMergeBlocker(
          source: _customer(_source),
          target: _customer(_target, archived: true),
        ),
        contains('archived'),
      );
    });
  });

  group('FirebaseCustomerMergeRepository.mergeCustomers', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseCustomerRepository customers;
    late FirebaseCustomerMergeRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      customers = FirebaseCustomerRepository(firestore: firestore);
      repository = FirebaseCustomerMergeRepository(
        firestore: firestore,
        ordersPerBatch: 2,
      );
    });

    Future<void> seedPair() async {
      await customers.createCustomer(
        _customer(
          _source,
          name: 'Ahmed',
          addresses: [_address('s1', 'Shop 9, Market', label: 'Shop')],
          defaultAddressId: 's1',
          notes: 'Pays late',
          lastOrderAt: DateTime(2026, 9, 20),
        ),
      );
      await customers.createCustomer(
        _customer(
          _target,
          name: 'Ahmed Raza',
          addresses: [_address('t1', 'House 14, Street 3')],
          defaultAddressId: 't1',
          lastOrderAt: DateTime(2026, 9, 10),
        ),
      );
    }

    test('moves every order, audits each one and leaves editCount alone',
        () async {
      await seedPair();
      await _seedOrder(firestore, 'o1', _source, editCount: 3);
      await _seedOrder(firestore, 'o2', _source, status: 'cancelled');
      await _seedOrder(firestore, 'o3', _source, status: 'pending');
      await _seedOrder(firestore, 'o4', _source);
      await _seedOrder(firestore, 'o5', _source);
      await _seedOrder(firestore, 'o6', _target);
      await _seedOrder(firestore, 'o7', _other);

      final result = await repository.mergeCustomers(
        sourcePhone: _source,
        targetPhone: _target,
        reason: 'Same person',
      );

      expect(result.ordersMoved, 5);
      expect(result.addressesAdded, 1);
      expect(result.alreadyMerged, isFalse);

      expect(await _orderIdsFor(firestore, _source), isEmpty);
      expect(
        await _orderIdsFor(firestore, _target),
        ['o1', 'o2', 'o3', 'o4', 'o5', 'o6'],
      );
      expect(await _orderIdsFor(firestore, _other), ['o7']);

      for (final id in ['o1', 'o2', 'o3', 'o4', 'o5']) {
        final history = await firestore
            .collection('orders')
            .doc(id)
            .collection('history')
            .get();
        expect(history.docs, hasLength(1), reason: 'history for $id');
        final entry = history.docs.single.data();
        expect(entry['field'], 'customerPhone');
        expect(entry['oldValue'], _source);
        expect(entry['newValue'], _target);
        expect(entry['changeReason'], 'Customer merge: Same person');
        expect(entry['source'], 'customerMerge');
        expect(entry['timestamp'], isNotNull);
      }
      expect(await _historyCount(firestore, 'o6'), 0);
      expect(await _historyCount(firestore, 'o7'), 0);

      final o1 = (await firestore.collection('orders').doc('o1').get()).data()!;
      expect(o1['editCount'], 3);
      expect(o1['status'], 'completed');
      final o2 = (await firestore.collection('orders').doc('o2').get()).data()!;
      expect(o2['status'], 'cancelled');
    });

    test('finalises both customers: union, notes, lastOrderAt, archive',
        () async {
      await seedPair();
      await _seedOrder(firestore, 'o1', _source);

      await repository.mergeCustomers(
        sourcePhone: _source,
        targetPhone: _target,
        reason: 'Same person',
      );

      final source = (await customers.getByPhone(_source))!;
      expect(source.archived, isTrue);
      expect(source.mergedInto, _target);
      expect(source.name, 'Ahmed');
      expect(source.addresses, hasLength(1));
      expect(source.notes, 'Pays late');

      final target = (await customers.getByPhone(_target))!;
      expect(target.archived, isFalse);
      expect(target.mergedInto, isNull);
      expect(target.name, 'Ahmed Raza');
      expect(
        target.addresses.map((address) => address.text).toList(),
        ['House 14, Street 3', 'Shop 9, Market'],
      );
      expect(target.defaultAddressId, 't1');
      expect(target.notes, 'Pays late');
      expect(
        target.lastOrderAt!.isAtSameMomentAs(DateTime(2026, 9, 20)),
        isTrue,
      );
    });

    test('a merge killed halfway can be re-run without duplicates', () async {
      await seedPair();
      for (final id in ['o1', 'o2', 'o3', 'o4', 'o5']) {
        await _seedOrder(firestore, id, _source);
      }

      await expectLater(
        repository.mergeCustomers(
          sourcePhone: _source,
          targetPhone: _target,
          reason: 'Same person',
          onProgress: (moved) {
            if (moved == 2) {
              throw StateError('simulated crash');
            }
          },
        ),
        throwsA(isA<StateError>()),
      );

      // Interrupted: two orders moved, three left, nothing finalised.
      expect(await _orderIdsFor(firestore, _target), hasLength(2));
      expect(await _orderIdsFor(firestore, _source), hasLength(3));
      final midSource = (await customers.getByPhone(_source))!;
      expect(midSource.archived, isFalse);
      expect(midSource.mergedInto, isNull);
      expect((await customers.getByPhone(_target))!.notes, isNull);

      final result = await repository.mergeCustomers(
        sourcePhone: _source,
        targetPhone: _target,
        reason: 'Same person',
      );

      expect(result.ordersMoved, 3);
      expect(result.alreadyMerged, isFalse);
      expect(await _orderIdsFor(firestore, _source), isEmpty);
      expect(await _orderIdsFor(firestore, _target), hasLength(5));
      for (final id in ['o1', 'o2', 'o3', 'o4', 'o5']) {
        expect(await _historyCount(firestore, id), 1, reason: 'history $id');
      }

      final source = (await customers.getByPhone(_source))!;
      expect(source.archived, isTrue);
      expect(source.mergedInto, _target);
      final target = (await customers.getByPhone(_target))!;
      expect(target.notes, 'Pays late');
      expect(target.addresses, hasLength(2));
    });

    test('running a finished merge again does nothing', () async {
      await seedPair();
      await _seedOrder(firestore, 'o1', _source);

      await repository.mergeCustomers(
        sourcePhone: _source,
        targetPhone: _target,
        reason: 'Same person',
      );
      final again = await repository.mergeCustomers(
        sourcePhone: _source,
        targetPhone: _target,
        reason: 'Same person',
      );

      expect(again.alreadyMerged, isTrue);
      expect(again.ordersMoved, 0);
      expect(await _historyCount(firestore, 'o1'), 1);
      expect((await customers.getByPhone(_target))!.addresses, hasLength(2));
    });

    test('accepts phones in any format', () async {
      await seedPair();
      await _seedOrder(firestore, 'o1', _source);

      final result = await repository.mergeCustomers(
        sourcePhone: '+92 300 1111111',
        targetPhone: '0300-2222222',
        reason: 'Same person',
      );

      expect(result.ordersMoved, 1);
      expect(await _orderIdsFor(firestore, _target), ['o1']);
    });

    test('rejects invalid input before touching anything', () async {
      await seedPair();
      await _seedOrder(firestore, 'o1', _source);

      Future<void> merge({
        String source = _source,
        String target = _target,
        String reason = 'Same person',
      }) {
        return repository.mergeCustomers(
          sourcePhone: source,
          targetPhone: target,
          reason: reason,
        );
      }

      await expectLater(merge(target: _source), throwsA(isA<ArgumentError>()));
      await expectLater(merge(source: 'abc'), throwsA(isA<ArgumentError>()));
      await expectLater(merge(reason: '   '), throwsA(isA<ArgumentError>()));
      await expectLater(
        merge(reason: 'x' * (customerMergeReasonMaxLength + 1)),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        merge(target: _other),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        merge(source: _other),
        throwsA(isA<StateError>()),
      );

      expect(await _orderIdsFor(firestore, _source), ['o1']);
      expect(await _historyCount(firestore, 'o1'), 0);
    });

    test('refuses an archived target and moves nothing', () async {
      await seedPair();
      await customers.setArchived(_target, true);
      await _seedOrder(firestore, 'o1', _source);

      await expectLater(
        repository.mergeCustomers(
          sourcePhone: _source,
          targetPhone: _target,
          reason: 'Same person',
        ),
        throwsA(isA<StateError>()),
      );

      expect(await _orderIdsFor(firestore, _source), ['o1']);
    });

    test('refuses a source that was merged into someone else', () async {
      await seedPair();
      await customers.createCustomer(_customer(_other, name: 'Third'));
      await repository.mergeCustomers(
        sourcePhone: _source,
        targetPhone: _other,
        reason: 'First merge',
      );

      await expectLater(
        repository.mergeCustomers(
          sourcePhone: _source,
          targetPhone: _target,
          reason: 'Second merge',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects an out-of-range batch size', () {
      expect(
        () => FirebaseCustomerMergeRepository(
          firestore: firestore,
          ordersPerBatch: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => FirebaseCustomerMergeRepository(
          firestore: firestore,
          ordersPerBatch:
              FirebaseCustomerMergeRepository.maxOrdersPerBatch + 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('FirebaseCustomerMergeRepository dismissals', () {
    late FakeFirebaseFirestore firestore;
    late FirebaseCustomerMergeRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirebaseCustomerMergeRepository(firestore: firestore);
    });

    test('starts with no dismissed pairs', () async {
      expect(await repository.streamDismissedPairs().first, isEmpty);
    });

    test('dismissing stores the pair regardless of phone order', () async {
      await repository.dismissPair(_target, _source);
      await repository.dismissPair(_source, _target);
      await repository.dismissPair(_source, _other);

      final pairs = await repository.streamDismissedPairs().first;

      expect(pairs, {
        duplicatePairKey(_source, _target),
        duplicatePairKey(_source, _other),
      });
    });

    test('lives in its own metadata doc, never in the order counter',
        () async {
      await repository.dismissPair(_source, _target);

      final counters =
          await firestore.collection('metadata').doc('counters').get();
      expect(counters.exists, isFalse);
    });

    test('rejects invalid pairs', () async {
      await expectLater(
        repository.dismissPair(_source, _source),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        repository.dismissPair('abc', _target),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
