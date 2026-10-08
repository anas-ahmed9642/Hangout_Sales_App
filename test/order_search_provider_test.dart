import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/customers/models/customer_upsert.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/providers/order_search_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

class _MockSearchRepository implements OrderRepository {
  @override
  Future<List<Order>> searchOrdersByPhone(String phoneNumber) async {
    if (phoneNumber == '03472960010') {
      return [
        Order(
          id: 'test-1',
          orderNumber: 'ORD-TEST',
          createdAt: DateTime.now(),
          businessDate: DateTime.now(),
          items: const [],
          deals: const [],
          additionalDrinks: const {},
          additionalDipSauceCount: 0,
          deliveryCharge: 0,
          total: 1500,
          status: OrderStatus.completed,
          paymentStatus: PaymentStatus.paid,
          customerPhone: '03472960010',
        )
      ];
    }
    return [];
  }

  @override
  Future<void> createOrder(
    Order order, {
    CustomerUpsert? customerUpsert,
  }) async {}

  @override
  Future<Order?> getOrder(String orderId) async => null;

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) => Stream.value([]);

  @override
  Stream<List<Order>> streamUnpaidOrders() => Stream.value(const []);

  @override
  Stream<List<Order>> streamOrdersByCustomerPhone(String phone) =>
      throw UnimplementedError();

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async {
    return const [];
  }
}

void main() {
  test('orderSearchProvider returns empty list when query is empty', () async {
    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(_MockSearchRepository()),
      ],
    );
    addTearDown(container.dispose);

    // Initial state is empty string
    final result = await container.read(orderSearchProvider.future);
    expect(result, isEmpty); // No Firebase read performed!
  });

  test('orderSearchProvider returns orders when query matches', () async {
    final container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(_MockSearchRepository()),
      ],
    );
    addTearDown(container.dispose);

    // Simulate cashier typing a phone number
    container.read(orderSearchQueryProvider.notifier).state = '03472960010';

    final result = await container.read(orderSearchProvider.future);
    expect(result, hasLength(1));
    expect(result.first.customerPhone, '03472960010');
  });
}