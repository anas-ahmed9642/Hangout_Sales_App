import 'order_item.dart';
import 'deal.dart';

enum OrderStatus {
  pending,
  completed,
  cancelled,
}

enum PaymentStatus {
  unpaid,
  paid,
}

class Order {
  final String id;
  final String orderNumber;

  final DateTime createdAt;
  final DateTime businessDate;

  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;

  /// Delivery area id; null = unlisted/other (plan 8.3).
  final String? deliveryAreaId;

  /// Snapshot of the area name; area renames must not rewrite history.
  final String? deliveryAreaName;

  /// Per-order delivery notes snapshot; reprints are historical.
  final String? deliveryNotes;

  final List<OrderItem> items;
  final List<Deal> deals;

  final Map<String, int> additionalDrinks;
  final int additionalDipSauceCount;

  final double deliveryCharge;
  final double total;

  /// Describes the fulfillment/lifecycle state of the order.
  final OrderStatus status;

  /// Describes whether the customer has paid.
  final PaymentStatus paymentStatus;
  final int editCount;
  const Order({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.businessDate,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.deliveryAreaId,
    this.deliveryAreaName,
    this.deliveryNotes,
    required this.items,
    required this.deals,
    required this.additionalDrinks,
    required this.additionalDipSauceCount,
    required this.deliveryCharge,
    required this.total,
    required this.status,
    required this.paymentStatus,
    this.editCount = 0,
  });
}
