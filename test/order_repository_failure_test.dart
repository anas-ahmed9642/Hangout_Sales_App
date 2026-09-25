import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

class _FailingOrderRepository implements OrderRepository {
  final Object failure;

  _FailingOrderRepository(this.failure);

  @override
  Future<void> createOrder(Order order) async {
    throw failure;
  }

  @override
  Future<Order?> getOrder(String orderId) async {
    throw failure;
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(
    String orderId,
  ) async {
    throw failure;
  }

  @override
  Future<List<Order>> searchOrdersByPhone(
    String phoneNumber,
  ) async {
    throw failure;
  }

  @override
  Stream<List<Order>> streamOrders(
    DateTime businessDate,
  ) {
    return Stream<List<Order>>.error(failure);
  }

  @override
  Stream<List<Order>> streamUnpaidOrders() => Stream.value(const []);

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {
    throw failure;
  }
}

void main() {
  final testOrder = Order(
    id: 'failure-test-order',
    orderNumber: 'ORD-FAIL',
    createdAt: DateTime(2026, 9, 15, 19, 0),
    businessDate: DateTime(2026, 9, 15),
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: 500,
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
  );

  group('OrderRepository failure propagation', () {
    test('createOrder propagates repository failure', () async {
      final repository = _FailingOrderRepository(
        StateError('Network unavailable'),
      );

      await expectLater(
        repository.createOrder(testOrder),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Network unavailable',
          ),
        ),
      );
    });

    test('getOrder propagates repository failure', () async {
      final repository = _FailingOrderRepository(
        StateError('Read failed'),
      );

      await expectLater(
        repository.getOrder(testOrder.id),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Read failed',
          ),
        ),
      );
    });

    test('updateOrder propagates repository failure', () async {
      final repository = _FailingOrderRepository(
        StateError('Update failed'),
      );

      await expectLater(
        repository.updateOrder(
          testOrder.id,
          {
            'paymentStatus': PaymentStatus.paid.name,
          },
          changeReason: 'Payment received',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Update failed',
          ),
        ),
      );
    });

    test('getOrderHistory propagates repository failure', () async {
      final repository = _FailingOrderRepository(
        StateError('History unavailable'),
      );

      await expectLater(
        repository.getOrderHistory(testOrder.id),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'History unavailable',
          ),
        ),
      );
    });

    test('searchOrdersByPhone propagates repository failure', () async {
      final repository = _FailingOrderRepository(
        StateError('Search unavailable'),
      );

      await expectLater(
        repository.searchOrdersByPhone('03001234567'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Search unavailable',
          ),
        ),
      );
    });

    test('streamOrders exposes stream failure', () async {
      final repository = _FailingOrderRepository(
        StateError('Stream disconnected'),
      );

      await expectLater(
        repository.streamOrders(
          DateTime(2026, 9, 15),
        ),
        emitsError(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Stream disconnected',
          ),
        ),
      );
    });
  });
}