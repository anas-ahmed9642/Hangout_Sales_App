import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/core/services/business_day_service.dart';
import 'package:hangout_sales_app/features/customers/services/customer_insights.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';

// Every function under test is pure and synchronous: it reads only
// the list (and map) handed to it and returns a value. There are no
// streams, providers or futures, so each assertion below observes
// the returned value directly — no awaiting and no timing window in
// which a pass could be vacuous.

const _businessDays = BusinessDayService();

const _phoneA = '03001111111';
const _phoneB = '03002222222';
const _phoneC = '03003333333';
const _phoneD = '03004444444';
const _phoneE = '03005555555';

/// October 2026, [day] at [hour] (default 20:00 — after the 05:00
/// business-day cutoff, so the business date is the same calendar day).
DateTime _at(int day, [int hour = 20]) => DateTime(2026, 10, day, hour);

Order _order({
  required String id,
  required DateTime createdAt,
  required double total,
  String? phone,
  String? name,
  DateTime? businessDate,
  OrderStatus status = OrderStatus.completed,
  PaymentStatus paymentStatus = PaymentStatus.paid,
}) {
  return Order(
    id: id,
    orderNumber: 'ORD-$id',
    createdAt: createdAt,
    businessDate: businessDate ?? _businessDays.businessDate(createdAt),
    customerName: name,
    customerPhone: phone,
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: total,
    status: status,
    paymentStatus: paymentStatus,
  );
}

void main() {
  group('topCustomers', () {
    test('empty input -> empty list', () {
      expect(topCustomers(const <Order>[]), isEmpty);
    });

    test('ranks by spend, highest first (default metric)', () {
      final orders = [
        _order(id: '1', phone: _phoneA, createdAt: _at(1), total: 1000),
        _order(id: '2', phone: _phoneA, createdAt: _at(2), total: 500),
        _order(id: '3', phone: _phoneB, createdAt: _at(3), total: 2000),
        _order(id: '4', phone: _phoneC, createdAt: _at(4), total: 800),
      ];

      final result = topCustomers(orders);

      expect(
        result.map((c) => c.phone).toList(),
        [_phoneB, _phoneA, _phoneC],
      );
      expect(result[0].totalSpent, 2000);
      expect(result[0].orderCount, 1);
      expect(result[1].totalSpent, 1500);
      expect(result[1].orderCount, 2);
      expect(result[2].totalSpent, 800);
    });

    test('ranks by order count; spend breaks the tie', () {
      final orders = [
        _order(id: '1', phone: _phoneA, createdAt: _at(1), total: 1000),
        _order(id: '2', phone: _phoneA, createdAt: _at(2), total: 500),
        _order(id: '3', phone: _phoneB, createdAt: _at(3), total: 2000),
        _order(id: '4', phone: _phoneC, createdAt: _at(4), total: 800),
      ];

      final result = topCustomers(orders, by: TopCustomerMetric.orderCount);

      expect(
        result.map((c) => c.phone).toList(),
        [_phoneA, _phoneB, _phoneC],
      );
    });

    test('spend tie breaks by order count (not by phone)', () {
      final orders = [
        // X has the LARGER phone but more orders -> must come first.
        _order(id: '1', phone: '03009999999', createdAt: _at(1), total: 500),
        _order(id: '2', phone: '03009999999', createdAt: _at(2), total: 500),
        _order(id: '3', phone: '03001111111', createdAt: _at(3), total: 1000),
      ];

      final result = topCustomers(orders);

      expect(
        result.map((c) => c.phone).toList(),
        ['03009999999', '03001111111'],
      );
    });

    test('order-count tie breaks by spend (not by phone)', () {
      final orders = [
        _order(id: '1', phone: '03001111111', createdAt: _at(1), total: 900),
        _order(id: '2', phone: '03009999999', createdAt: _at(2), total: 1100),
      ];

      final result = topCustomers(orders, by: TopCustomerMetric.orderCount);

      expect(
        result.map((c) => c.phone).toList(),
        ['03009999999', '03001111111'],
      );
    });

    test('tie on both metrics breaks by most recent order (not by phone)',
        () {
      final orders = [
        _order(id: '1', phone: _phoneA, createdAt: _at(2), total: 1000),
        _order(id: '2', phone: _phoneB, createdAt: _at(5), total: 1000),
      ];

      final bySpend = topCustomers(orders);
      final byCount = topCustomers(orders, by: TopCustomerMetric.orderCount);

      expect(bySpend.map((c) => c.phone).toList(), [_phoneB, _phoneA]);
      expect(byCount.map((c) => c.phone).toList(), [_phoneB, _phoneA]);
    });

    test('full tie breaks by phone ascending', () {
      final orders = [
        _order(id: '1', phone: '03007777777', createdAt: _at(3), total: 1000),
        _order(id: '2', phone: '03006666666', createdAt: _at(3), total: 1000),
      ];

      final result = topCustomers(orders);

      expect(
        result.map((c) => c.phone).toList(),
        ['03006666666', '03007777777'],
      );
    });

    test('cancelled orders are excluded; cancelled-only customers vanish',
        () {
      final orders = [
        _order(id: '1', phone: _phoneA, createdAt: _at(1), total: 1000),
        _order(
          id: '2',
          phone: _phoneA,
          createdAt: _at(2),
          total: 5000,
          status: OrderStatus.cancelled,
        ),
        _order(
          id: '3',
          phone: _phoneD,
          createdAt: _at(3),
          total: 9000,
          status: OrderStatus.cancelled,
        ),
      ];

      final result = topCustomers(orders);

      expect(result.length, 1);
      expect(result.single.phone, _phoneA);
      expect(result.single.totalSpent, 1000);
      expect(result.single.orderCount, 1);
    });

    test('pending and unpaid orders still count toward spend', () {
      final orders = [
        _order(
          id: '1',
          phone: _phoneA,
          createdAt: _at(1),
          total: 700,
          status: OrderStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        ),
        _order(id: '2', phone: _phoneA, createdAt: _at(2), total: 300),
      ];

      final result = topCustomers(orders);

      expect(result.single.orderCount, 2);
      expect(result.single.totalSpent, 1000);
    });

    test('walk-ins and invalid numbers are never ranked', () {
      final orders = [
        _order(id: '1', phone: null, createdAt: _at(1), total: 9000),
        _order(id: '2', phone: '', createdAt: _at(1), total: 9000),
        _order(id: '3', phone: '   ', createdAt: _at(1), total: 9000),
        _order(id: '4', phone: 'abc', createdAt: _at(1), total: 9000),
        _order(id: '5', phone: '0211234567', createdAt: _at(1), total: 9000),
        _order(id: '6', phone: '12345', createdAt: _at(1), total: 9000),
        _order(id: '7', phone: _phoneA, createdAt: _at(2), total: 100),
      ];

      final result = topCustomers(orders);

      expect(result.length, 1);
      expect(result.single.phone, _phoneA);
      expect(result.single.totalSpent, 100);
    });

    test('different phone formats merge into one normalized customer', () {
      final orders = [
        _order(id: '1', phone: '0300-1111111', createdAt: _at(1), total: 100),
        _order(
          id: '2',
          phone: '+92 300 1111111',
          createdAt: _at(2),
          total: 200,
        ),
        _order(id: '3', phone: '03001111111', createdAt: _at(3), total: 300),
      ];

      final result = topCustomers(orders);

      expect(result.length, 1);
      expect(result.single.phone, _phoneA);
      expect(result.single.orderCount, 3);
      expect(result.single.totalSpent, 600);
    });

    test('limit truncates; oversize limit returns everyone', () {
      final orders = [
        _order(id: '1', phone: _phoneA, createdAt: _at(1), total: 300),
        _order(id: '2', phone: _phoneB, createdAt: _at(2), total: 200),
        _order(id: '3', phone: _phoneC, createdAt: _at(3), total: 100),
      ];

      expect(
        topCustomers(orders, limit: 2).map((c) => c.phone).toList(),
        [_phoneA, _phoneB],
      );
      expect(topCustomers(orders, limit: 1).single.phone, _phoneA);
      expect(topCustomers(orders, limit: 50).length, 3);
    });

    test('limit zero returns an empty list', () {
      final orders = [
        _order(id: '1', phone: _phoneA, createdAt: _at(1), total: 300),
      ];

      expect(topCustomers(orders, limit: 0), isEmpty);
    });

    test('negative limit throws ArgumentError', () {
      final orders = [
        _order(id: '1', phone: _phoneA, createdAt: _at(1), total: 300),
      ];

      expect(
        () => topCustomers(orders, limit: -1),
        throwsArgumentError,
      );
    });

    test('name comes from the newest non-blank name, trimmed', () {
      final orders = [
        _order(
          id: '3',
          phone: _phoneA,
          name: '  New Name  ',
          createdAt: _at(3),
          total: 100,
        ),
        _order(
          id: '1',
          phone: _phoneA,
          name: 'Old Name',
          createdAt: _at(1),
          total: 100,
        ),
        _order(
          id: '5',
          phone: _phoneA,
          name: '   ',
          createdAt: _at(5),
          total: 100,
        ),
      ];

      expect(topCustomers(orders).single.name, 'New Name');
    });

    test('name is null when no order carries one', () {
      final orders = [
        _order(id: '1', phone: _phoneA, createdAt: _at(1), total: 100),
        _order(id: '2', phone: _phoneA, name: '', createdAt: _at(2), total: 1),
      ];

      expect(topCustomers(orders).single.name, isNull);
    });

    test('lastOrderAt is the newest createdAt regardless of list order', () {
      final orders = [
        _order(id: '5', phone: _phoneA, createdAt: _at(5), total: 100),
        _order(id: '1', phone: _phoneA, createdAt: _at(1), total: 100),
        _order(id: '3', phone: _phoneA, createdAt: _at(3), total: 100),
      ];

      expect(topCustomers(orders).single.lastOrderAt, _at(5));
    });

    test('does not mutate the input list', () {
      final orders = [
        _order(id: '1', phone: _phoneB, createdAt: _at(1), total: 100),
        _order(id: '2', phone: _phoneA, createdAt: _at(2), total: 900),
      ];
      final snapshot = List<Order>.of(orders);

      topCustomers(orders);

      expect(orders, snapshot);
    });
  });

  group('firstOrderBusinessDateByPhone', () {
    test('empty input -> empty map', () {
      expect(firstOrderBusinessDateByPhone(const <Order>[]), isEmpty);
    });

    test('earliest business date per normalized phone, across formats', () {
      final orders = [
        _order(id: '1', phone: '0300-1111111', createdAt: _at(3), total: 100),
        _order(id: '2', phone: '03001111111', createdAt: _at(1), total: 100),
        _order(
          id: '3',
          phone: '+92 300 1111111',
          createdAt: _at(2),
          total: 100,
        ),
        _order(id: '4', phone: _phoneB, createdAt: _at(5), total: 100),
      ];

      final result = firstOrderBusinessDateByPhone(orders);

      expect(result, {
        _phoneA: DateTime(2026, 10, 1),
        _phoneB: DateTime(2026, 10, 5),
      });
    });

    test('cancelled orders and walk-ins are skipped', () {
      final orders = [
        _order(
          id: '1',
          phone: _phoneA,
          createdAt: _at(1),
          total: 100,
          status: OrderStatus.cancelled,
        ),
        _order(id: '2', phone: _phoneA, createdAt: _at(3), total: 100),
        _order(
          id: '3',
          phone: _phoneD,
          createdAt: _at(2),
          total: 100,
          status: OrderStatus.cancelled,
        ),
        _order(id: '4', phone: null, createdAt: _at(1), total: 100),
        _order(id: '5', phone: 'abc', createdAt: _at(1), total: 100),
      ];

      final result = firstOrderBusinessDateByPhone(orders);

      expect(result, {_phoneA: DateTime(2026, 10, 3)});
    });

    test('uses the business date: a 02:00 order belongs to the day before',
        () {
      final orders = [
        _order(
          id: '1',
          phone: _phoneA,
          createdAt: DateTime(2026, 10, 6, 2, 0),
          total: 100,
        ),
      ];

      final result = firstOrderBusinessDateByPhone(orders);

      expect(result, {_phoneA: DateTime(2026, 10, 5)});
    });

    test('values are date-only even when businessDate carries a time', () {
      final orders = [
        _order(
          id: '1',
          phone: _phoneA,
          createdAt: _at(5),
          businessDate: DateTime(2026, 10, 5, 20, 30),
          total: 100,
        ),
      ];

      final result = firstOrderBusinessDateByPhone(orders);

      expect(result[_phoneA], DateTime(2026, 10, 5));
    });

    test('does not mutate the input list', () {
      final orders = [
        _order(id: '1', phone: _phoneA, createdAt: _at(2), total: 100),
        _order(id: '2', phone: _phoneA, createdAt: _at(1), total: 100),
      ];
      final snapshot = List<Order>.of(orders);

      firstOrderBusinessDateByPhone(orders);

      expect(orders, snapshot);
    });
  });

  group('newVsReturning', () {
    test('empty period -> all zeros', () {
      final result =
          newVsReturning(const <Order>[], const <String, DateTime>{});

      expect(result.newCustomerCount, 0);
      expect(result.returningCustomerCount, 0);
      expect(result.newCustomerOrderCount, 0);
      expect(result.returningCustomerOrderCount, 0);
      expect(result.walkInOrderCount, 0);
      expect(result.newCustomerRevenue, 0);
      expect(result.returningCustomerRevenue, 0);
      expect(result.walkInRevenue, 0);
      expect(result.identifiedCustomerCount, 0);
      expect(result.totalOrderCount, 0);
      expect(result.totalRevenue, 0);
      expect(NewVsReturning.empty.totalOrderCount, 0);
    });

    test('hand-built period: new, returning, walk-ins, cancelled', () {
      final history = [
        // A ordered before the period -> returning inside it.
        _order(id: 'a0', phone: _phoneA, createdAt: _at(1), total: 800),
        // E ordered before the period and NOT inside it -> not reported.
        _order(id: 'e0', phone: _phoneE, createdAt: _at(2), total: 600),
      ];
      final inPeriod = [
        _order(id: 'a1', phone: _phoneA, createdAt: _at(5), total: 1000),
        _order(id: 'a2', phone: _phoneA, createdAt: _at(6), total: 500),
        _order(id: 'b1', phone: _phoneB, createdAt: _at(5), total: 700),
        _order(id: 'b2', phone: _phoneB, createdAt: _at(7), total: 300),
        _order(id: 'c1', phone: _phoneC, createdAt: _at(6), total: 400),
        _order(id: 'w1', phone: null, createdAt: _at(5), total: 250),
        _order(id: 'w2', phone: 'abc', createdAt: _at(6), total: 150),
        _order(
          id: 'x1',
          phone: _phoneD,
          createdAt: _at(5),
          total: 999,
          status: OrderStatus.cancelled,
        ),
      ];

      final firstMap =
          firstOrderBusinessDateByPhone([...history, ...inPeriod]);
      final result = newVsReturning(inPeriod, firstMap);

      expect(result.newCustomerCount, 2); // B, C
      expect(result.returningCustomerCount, 1); // A
      expect(result.newCustomerOrderCount, 3); // b1, b2, c1
      expect(result.returningCustomerOrderCount, 2); // a1, a2
      expect(result.walkInOrderCount, 2);
      expect(result.newCustomerRevenue, 1400);
      expect(result.returningCustomerRevenue, 1500);
      expect(result.walkInRevenue, 400);
      expect(result.identifiedCustomerCount, 3);
      expect(result.totalOrderCount, 7);
      expect(result.totalRevenue, 3300);
    });

    test('result does not depend on the order of ordersInPeriod', () {
      final inPeriod = [
        _order(id: 'a1', phone: _phoneA, createdAt: _at(6), total: 500),
        _order(id: 'a0', phone: _phoneA, createdAt: _at(5), total: 1000),
        _order(id: 'b1', phone: _phoneB, createdAt: _at(7), total: 300),
        _order(id: 'b0', phone: _phoneB, createdAt: _at(5), total: 700),
      ];
      final history = [
        _order(id: 'h', phone: _phoneA, createdAt: _at(1), total: 100),
      ];
      final firstMap =
          firstOrderBusinessDateByPhone([...history, ...inPeriod]);

      final forward = newVsReturning(inPeriod, firstMap);
      final backward = newVsReturning(inPeriod.reversed.toList(), firstMap);

      expect(backward.newCustomerCount, forward.newCustomerCount);
      expect(backward.returningCustomerCount, forward.returningCustomerCount);
      expect(backward.newCustomerCount, 1);
      expect(backward.returningCustomerCount, 1);
      expect(backward.newCustomerRevenue, forward.newCustomerRevenue);
      expect(
        backward.returningCustomerRevenue,
        forward.returningCustomerRevenue,
      );
    });

    test('first order on the same day as the in-period order is new, even '
        'with different times of day', () {
      final orders = [
        _order(
          id: '1',
          phone: _phoneA,
          createdAt: _at(5, 9),
          businessDate: DateTime(2026, 10, 5, 9),
          total: 100,
        ),
        _order(
          id: '2',
          phone: _phoneA,
          createdAt: _at(5, 20),
          businessDate: DateTime(2026, 10, 5, 20),
          total: 200,
        ),
      ];

      final result =
          newVsReturning(orders, firstOrderBusinessDateByPhone(orders));

      expect(result.newCustomerCount, 1);
      expect(result.returningCustomerCount, 0);
      expect(result.newCustomerOrderCount, 2);
      expect(result.newCustomerRevenue, 300);
    });

    test('earlier orders that were all cancelled do not make a customer '
        'returning', () {
      final all = [
        _order(
          id: '1',
          phone: _phoneA,
          createdAt: _at(1),
          total: 100,
          status: OrderStatus.cancelled,
        ),
        _order(id: '2', phone: _phoneA, createdAt: _at(5), total: 200),
      ];
      final inPeriod = [all[1]];

      final result =
          newVsReturning(inPeriod, firstOrderBusinessDateByPhone(all));

      expect(result.newCustomerCount, 1);
      expect(result.returningCustomerCount, 0);
    });

    test('a customer missing from the map is treated as new', () {
      final inPeriod = [
        _order(id: '1', phone: _phoneA, createdAt: _at(5), total: 100),
      ];

      final result = newVsReturning(inPeriod, const <String, DateTime>{});

      expect(result.newCustomerCount, 1);
      expect(result.returningCustomerCount, 0);
    });

    test('a first-order date after the in-period orders is treated as new',
        () {
      final inPeriod = [
        _order(id: '1', phone: _phoneA, createdAt: _at(5), total: 100),
      ];

      final result =
          newVsReturning(inPeriod, {_phoneA: DateTime(2026, 10, 9)});

      expect(result.newCustomerCount, 1);
      expect(result.returningCustomerCount, 0);
    });

    test('raw phone formats in the period merge into one returning customer',
        () {
      final inPeriod = [
        _order(id: '1', phone: '0300-1111111', createdAt: _at(5), total: 100),
        _order(
          id: '2',
          phone: '+92 300 1111111',
          createdAt: _at(6),
          total: 200,
        ),
      ];

      final result =
          newVsReturning(inPeriod, {_phoneA: DateTime(2026, 10, 1)});

      expect(result.returningCustomerCount, 1);
      expect(result.newCustomerCount, 0);
      expect(result.returningCustomerOrderCount, 2);
      expect(result.returningCustomerRevenue, 300);
    });

    test('raw-format map keys still match their customer (defensive)', () {
      final inPeriod = [
        _order(id: '1', phone: _phoneA, createdAt: _at(5), total: 100),
      ];

      // The documented contract is normalized keys, but a caller that
      // hands over a raw-format key must not flip a returning
      // customer to "new".
      final result = newVsReturning(inPeriod, {
        '+92 300 1111111': DateTime(2026, 10, 1),
      });

      expect(result.returningCustomerCount, 1);
      expect(result.newCustomerCount, 0);
    });

    test('duplicate map keys for one customer: the earliest date wins', () {
      final inPeriod = [
        _order(id: '1', phone: _phoneA, createdAt: _at(10), total: 100),
      ];

      final result = newVsReturning(inPeriod, {
        '0300-1111111': DateTime(2026, 10, 10),
        '+923001111111': DateTime(2026, 10, 1),
      });

      // Earliest global first (Oct 1) predates the in-period order.
      expect(result.returningCustomerCount, 1);
      expect(result.newCustomerCount, 0);
    });

    test('cancelled-only period is reported as empty', () {
      final inPeriod = [
        _order(
          id: '1',
          phone: _phoneA,
          createdAt: _at(5),
          total: 100,
          status: OrderStatus.cancelled,
        ),
        _order(
          id: '2',
          phone: null,
          createdAt: _at(5),
          total: 100,
          status: OrderStatus.cancelled,
        ),
      ];

      final result = newVsReturning(inPeriod, const <String, DateTime>{});

      expect(result.identifiedCustomerCount, 0);
      expect(result.walkInOrderCount, 0);
      expect(result.totalOrderCount, 0);
      expect(result.totalRevenue, 0);
    });

    test('walk-ins only: counted separately, no customers', () {
      final inPeriod = [
        _order(id: '1', phone: null, createdAt: _at(5), total: 100),
        _order(id: '2', phone: '', createdAt: _at(5), total: 50),
        _order(id: '3', phone: '0211234567', createdAt: _at(6), total: 25),
      ];

      final result = newVsReturning(inPeriod, const <String, DateTime>{});

      expect(result.identifiedCustomerCount, 0);
      expect(result.walkInOrderCount, 3);
      expect(result.walkInRevenue, 175);
      expect(result.totalOrderCount, 3);
    });

    test('pending and unpaid orders are counted', () {
      final inPeriod = [
        _order(
          id: '1',
          phone: _phoneA,
          createdAt: _at(5),
          total: 100,
          status: OrderStatus.pending,
          paymentStatus: PaymentStatus.unpaid,
        ),
      ];

      final result = newVsReturning(inPeriod, const <String, DateTime>{});

      expect(result.newCustomerCount, 1);
      expect(result.newCustomerRevenue, 100);
    });

    test('does not mutate its inputs', () {
      final inPeriod = [
        _order(id: '1', phone: _phoneA, createdAt: _at(5), total: 100),
        _order(id: '2', phone: _phoneB, createdAt: _at(6), total: 200),
      ];
      final snapshot = List<Order>.of(inPeriod);
      final firstMap = <String, DateTime>{_phoneA: DateTime(2026, 10, 1)};
      final mapSnapshot = Map<String, DateTime>.of(firstMap);

      newVsReturning(inPeriod, firstMap);

      expect(inPeriod, snapshot);
      expect(firstMap, mapSnapshot);
    });
  });
}
