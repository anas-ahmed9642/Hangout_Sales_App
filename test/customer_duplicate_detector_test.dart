import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/customers/models/customer_duplicate_candidate.dart';
import 'package:hangout_sales_app/features/customers/services/customer_duplicate_detector.dart';

final _t = DateTime(2026, 10, 2);

Customer _customer(
  String phone, {
  String? name,
  List<CustomerAddress> addresses = const [],
  bool archived = false,
  String? mergedInto,
  DateTime? lastOrderAt,
}) {
  return Customer(
    phone: phone,
    name: name,
    addresses: addresses,
    archived: archived,
    mergedInto: mergedInto,
    createdAt: _t,
    updatedAt: _t,
    lastOrderAt: lastOrderAt,
  );
}

CustomerAddress _address(String id, String text, {String? mapLink}) {
  return CustomerAddress(id: id, text: text, mapLink: mapLink);
}

void main() {
  group('duplicatePairKey', () {
    test('is independent of the order of the phones', () {
      expect(
        duplicatePairKey('03002222222', '03001111111'),
        duplicatePairKey('03001111111', '03002222222'),
      );
      expect(
        duplicatePairKey('03002222222', '03001111111'),
        '03001111111_03002222222',
      );
    });
  });

  group('findDuplicateCandidates', () {
    test('flags the same name, ignoring case and inner spacing', () {
      final result = findDuplicateCandidates([
        _customer('03002222222', name: 'ahmed   raza'),
        _customer('03001111111', name: 'Ahmed Raza'),
      ]);

      expect(result, hasLength(1));
      expect(result.single.first.phone, '03001111111');
      expect(result.single.second.phone, '03002222222');
      expect(result.single.reasons, {DuplicateReason.sameName});
    });

    test('unnamed customers never match each other by name', () {
      final result = findDuplicateCandidates([
        _customer('03001111111'),
        _customer('03002222222'),
      ]);

      expect(result, isEmpty);
    });

    test('flags the same address text, ignoring case and spacing', () {
      final result = findDuplicateCandidates([
        _customer(
          '03001111111',
          name: 'Ahmed',
          addresses: [_address('a', 'House 14, Street 3')],
        ),
        _customer(
          '03002222222',
          name: 'Sara',
          addresses: [_address('b', 'house 14,   street 3')],
        ),
      ]);

      expect(result, hasLength(1));
      expect(result.single.reasons, {DuplicateReason.sameAddress});
    });

    test('flags an identical map link', () {
      final result = findDuplicateCandidates([
        _customer(
          '03001111111',
          name: 'Ahmed',
          addresses: [
            _address('a', 'House 1', mapLink: 'https://maps.app.goo.gl/AbC123'),
          ],
        ),
        _customer(
          '03002222222',
          name: 'Sara',
          addresses: [
            _address('b', 'House 2', mapLink: 'https://maps.app.goo.gl/AbC123'),
          ],
        ),
      ]);

      expect(result, hasLength(1));
      expect(result.single.reasons, {DuplicateReason.sameMapLink});
    });

    test('map links that differ only in case are different places', () {
      final result = findDuplicateCandidates([
        _customer(
          '03001111111',
          name: 'Ahmed',
          addresses: [
            _address('a', 'House 1', mapLink: 'https://maps.app.goo.gl/AbC123'),
          ],
        ),
        _customer(
          '03002222222',
          name: 'Sara',
          addresses: [
            _address('b', 'House 2', mapLink: 'https://maps.app.goo.gl/abc123'),
          ],
        ),
      ]);

      expect(result, isEmpty);
    });

    test('combines reasons and lists multi-reason pairs first', () {
      final result = findDuplicateCandidates([
        _customer(
          '03003333333',
          name: 'Sara',
          addresses: [_address('c', 'House 1')],
        ),
        _customer(
          '03001111111',
          name: 'Ahmed',
          addresses: [_address('a', 'House 1')],
        ),
        _customer(
          '03002222222',
          name: 'Ahmed',
          addresses: [_address('b', 'House 1')],
        ),
      ]);

      expect(
        result.map((candidate) => candidate.pairKey).toList(),
        [
          '03001111111_03002222222',
          '03001111111_03003333333',
          '03002222222_03003333333',
        ],
      );
      expect(
        result.first.reasons,
        {DuplicateReason.sameName, DuplicateReason.sameAddress},
      );
    });

    test('ignores archived and merged customers', () {
      final result = findDuplicateCandidates([
        _customer('03001111111', name: 'Ahmed'),
        _customer('03002222222', name: 'Ahmed', archived: true),
        _customer(
          '03003333333',
          name: 'Ahmed',
          archived: true,
          mergedInto: '03001111111',
        ),
      ]);

      expect(result, isEmpty);
    });

    test('three customers with one name make three pairs', () {
      final result = findDuplicateCandidates([
        _customer('03001111111', name: 'Ahmed'),
        _customer('03002222222', name: 'Ahmed'),
        _customer('03003333333', name: 'Ahmed'),
      ]);

      expect(result, hasLength(3));
    });

    test('dismissed pairs are left out, other pairs stay', () {
      final result = findDuplicateCandidates(
        [
          _customer('03001111111', name: 'Ahmed'),
          _customer('03002222222', name: 'Ahmed'),
          _customer('03003333333', name: 'Ahmed'),
        ],
        dismissedPairKeys: {duplicatePairKey('03002222222', '03001111111')},
      );

      expect(result, hasLength(2));
      expect(
        result.map((candidate) => candidate.pairKey),
        isNot(contains('03001111111_03002222222')),
      );
    });

    test('no customers means no candidates', () {
      expect(findDuplicateCandidates(const []), isEmpty);
    });
  });

  group('CustomerDuplicateCandidate suggestions', () {
    test('suggests the more recently active customer as the target', () {
      final older = _customer(
        '03001111111',
        name: 'Ahmed',
        lastOrderAt: DateTime(2026, 9, 1),
      );
      final newer = _customer(
        '03002222222',
        name: 'Ahmed',
        lastOrderAt: DateTime(2026, 9, 20),
      );
      final candidate = CustomerDuplicateCandidate(
        first: older,
        second: newer,
        reasons: {DuplicateReason.sameName},
      );

      expect(candidate.suggestedTarget.phone, '03002222222');
      expect(candidate.suggestedSource.phone, '03001111111');
    });

    test('falls back to the first customer on ties and missing dates', () {
      final candidate = CustomerDuplicateCandidate(
        first: _customer('03001111111', name: 'Ahmed'),
        second: _customer('03002222222', name: 'Ahmed'),
        reasons: {DuplicateReason.sameName},
      );

      expect(candidate.suggestedTarget.phone, '03001111111');
      expect(candidate.suggestedSource.phone, '03002222222');
    });
  });
}
