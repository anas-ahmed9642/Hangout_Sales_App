import '../models/order.dart';

abstract class OrderRepository {
  /// Phase 4: Save a newly created order.
  Future<void> createOrder(Order order);

  // ---------------------------------------------------------------------------
  // Future Contract Methods (Phase 8 & 9)
  // ---------------------------------------------------------------------------
  // Future<Order?> getOrder(String orderId);
  // Stream<List<Order>> streamOrders(DateTime businessDate);
  // Future<List<Order>> searchOrders(String query);
}