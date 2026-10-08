import '../../customers/models/customer_upsert.dart';
import '../models/order.dart';

abstract class OrderRepository {
  /// Phase 4 / 7: Save a newly created order.
  ///
  /// Phase 5: when [customerUpsert] is non-null, the customer is created
  /// or touched inside the same Firestore transaction (plan 8.6).
  Future<void> createOrder(Order order, {CustomerUpsert? customerUpsert});

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

  /// Phase 6: Stream one customer's orders, newest first.
  ///
  /// Single query: customerPhone == phone ordered by createdAt descending
  /// (composite index in firestore.indexes.json). Feeds
  /// customerOrdersProvider; the unpaid summary and the last-order
  /// preview derive from it client-side.
  Stream<List<Order>> streamOrdersByCustomerPhone(String phone);
}
