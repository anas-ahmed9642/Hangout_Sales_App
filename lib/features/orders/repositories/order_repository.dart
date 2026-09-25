import '../models/order.dart';

abstract class OrderRepository {
  /// Phase 4 / 7: Save a newly created order.
  Future<void> createOrder(Order order);

  /// Phase 8: Stream orders belonging to a business date.
  Stream<List<Order>> streamOrders(DateTime businessDate);

  /// Phase 8: Search historical orders by customer phone number.
  Future<List<Order>> searchOrdersByPhone(String phoneNumber);

  /// Phase 8/9: Retrieve one specific saved order when direct lookup is needed.
  Future<Order?> getOrder(String orderId);

  /// Phase 10: Update an already-saved order and record why it changed.
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  });
  
  Future<List<Map<String, dynamic>>> getOrderHistory(
  String orderId,
);
Stream<List<Order>> streamUnpaidOrders();
}
