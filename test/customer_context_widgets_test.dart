import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/customers/widgets/customer_unpaid_banner.dart';
import 'package:hangout_sales_app/features/customers/widgets/last_order_preview.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

import 'helpers/test_container.dart';

final _t = DateTime(2026, 10, 7);

Order _order({
  required String id,
  required double total,
  List<OrderItem> items = const [],
  DateTime? createdAt,
  PaymentStatus paymentStatus = PaymentStatus.unpaid,
  OrderStatus status = OrderStatus.pending,
}) {
  final at = createdAt ?? _t;
  return Order(
    id: id,
    orderNumber: 'ORD-$id',
    createdAt: at,
    businessDate: at,
    items: items,
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: total,
    status: status,
    paymentStatus: paymentStatus,
  );
}

OrderItem _pizza(String flavorId, String flavorName, PizzaSize size) {
  return OrderItem(
    flavorId: flavorId,
    flavorName: flavorName,
    size: size,
    quantity: 1,
    unitPrice: 700,
  );
}

class _FakeOrderRepository implements OrderRepository {
  final Map<String, Stream<List<Order>>> streams;

  _FakeOrderRepository(this.streams);

  @override
  Stream<List<Order>> streamOrdersByCustomerPhone(String phone) {
    return streams[phone] ?? Stream.value(const []);
  }

  @override
  Future<void> createOrder(Order order, {CustomerUpsert? customerUpsert}) =>
      throw UnimplementedError();

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) =>
      throw UnimplementedError();

  @override
  Future<List<Order>> searchOrdersByPhone(String phoneNumber) =>
      throw UnimplementedError();

  @override
  Future<Order?> getOrder(String orderId) => throw UnimplementedError();

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) =>
      throw UnimplementedError();

  @override
  Stream<List<Order>> streamUnpaidOrders() => throw UnimplementedError();
}

ProviderContainer _container(Map<String, Stream<List<Order>>> streams) {
  return createTestContainer(overrides: [
    orderRepositoryProvider.overrideWithValue(_FakeOrderRepository(streams)),
  ]);
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container,
  Widget body,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(body: body),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  group('relativeTimeAgo', () {
    final now = DateTime(2026, 10, 7, 12);

    test('just now', () {
      expect(
        relativeTimeAgo(now.subtract(const Duration(seconds: 30)), now: now),
        'just now',
      );
    });

    test('minutes', () {
      expect(
        relativeTimeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5 min ago',
      );
    });

    test('one hour', () {
      expect(
        relativeTimeAgo(now.subtract(const Duration(hours: 1)), now: now),
        '1 hour ago',
      );
    });

    test('hours', () {
      expect(
        relativeTimeAgo(now.subtract(const Duration(hours: 3)), now: now),
        '3 hours ago',
      );
    });

    test('yesterday', () {
      expect(
        relativeTimeAgo(now.subtract(const Duration(hours: 30)), now: now),
        'Yesterday',
      );
    });

    test('days', () {
      expect(
        relativeTimeAgo(DateTime(2026, 9, 25, 12), now: now),
        '12 days ago',
      );
    });

    test('older than 30 days', () {
      expect(
        relativeTimeAgo(DateTime(2026, 8, 1), now: now),
        '1 Aug 2026',
      );
    });
  });

  group('CustomerUnpaidBanner', () {
    testWidgets('shows amount and count; hides when nothing is unpaid',
        (tester) async {
      final container = _container({
        '03001234567': Stream.value([
          _order(id: 'a', total: 1000),
          _order(id: 'b', total: 850),
          _order(id: 'c', total: 500, paymentStatus: PaymentStatus.paid),
        ]),
        '03009998888': Stream.value([
          _order(id: 'd', total: 500, paymentStatus: PaymentStatus.paid),
        ]),
      });

      await _pump(
        tester,
        container,
        const Column(
          children: [
            CustomerUnpaidBanner(phone: '03001234567'),
            CustomerUnpaidBanner(phone: '03009998888'),
          ],
        ),
      );

      expect(find.text('Rs. 1850 unpaid across 2 orders'), findsOneWidget);
      // The second customer's banner hides: exactly one banner on screen.
      expect(find.textContaining('unpaid across'), findsOneWidget);
    });

    testWidgets('singular order wording', (tester) async {
      final container = _container({
        '03001234567': Stream.value([
          _order(id: 'a', total: 1850),
        ]),
      });

      await _pump(
        tester,
        container,
        const CustomerUnpaidBanner(phone: '03001234567'),
      );

      expect(find.text('Rs. 1850 unpaid across 1 order'), findsOneWidget);
    });
  });

  group('LastOrderPreview', () {
    testWidgets('shows one muted line; Reorder rebuilds the draft',
        (tester) async {
      final createdAt = DateTime.now().subtract(
        const Duration(days: 12, hours: 2),
      );
      final order = _order(
        id: 'o1',
        total: 1400,
        createdAt: createdAt,
        paymentStatus: PaymentStatus.paid,
        items: [
          _pizza('chicken_fajita', 'Chicken Fajita', PizzaSize.large),
          _pizza('chicken_fajita', 'Chicken Fajita', PizzaSize.large),
        ],
      );
      final container = _container({
        '03001234567': Stream.value([order]),
      });

      await _pump(
        tester,
        container,
        const LastOrderPreview(phone: '03001234567'),
      );

      final expected = 'Last order ${relativeTimeAgo(createdAt)}'
          ' · 2 Large Chicken Fajita · Rs. 1400';
      expect(find.text(expected), findsOneWidget);
      expect(find.text('Reorder'), findsOneWidget);

      await tester.tap(find.text('Reorder'));
      await tester.pump();

      final entries = container.read(orderDraftProvider).entries;
      expect(entries.length, 2);
      expect(entries[0].standalonePizzaSize, PizzaSize.large);
      expect(entries[0].flavorIds, ['chicken_fajita']);
    });

    testWidgets('hides when the customer has no orders', (tester) async {
      final container = _container(const {});

      await _pump(
        tester,
        container,
        const LastOrderPreview(phone: '03009998888'),
      );

      expect(find.text('Reorder'), findsNothing);
      expect(find.textContaining('Last order'), findsNothing);
    });

    testWidgets('skips the cancelled order for the preview', (tester) async {
      final cancelledAt = DateTime.now().subtract(const Duration(days: 1));
      final olderAt = DateTime.now().subtract(const Duration(days: 5));
      final container = _container({
        '03001234567': Stream.value([
          _order(
            id: 'new',
            total: 999,
            createdAt: cancelledAt,
            status: OrderStatus.cancelled,
            items: [
              _pizza('spicy_bbq', 'Spicy BBQ', PizzaSize.small),
            ],
          ),
          _order(
            id: 'old',
            total: 700,
            createdAt: olderAt,
            items: [
              _pizza('chicken_fajita', 'Chicken Fajita', PizzaSize.large),
            ],
          ),
        ]),
      });

      await _pump(
        tester,
        container,
        const LastOrderPreview(phone: '03001234567'),
      );

      final expected = 'Last order ${relativeTimeAgo(olderAt)}'
          ' · Large Chicken Fajita · Rs. 700';
      expect(find.text(expected), findsOneWidget);
    });
  });
}