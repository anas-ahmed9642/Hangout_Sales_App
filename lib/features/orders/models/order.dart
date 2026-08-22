import 'order_item.dart';
import 'deal.dart';

enum OrderStatus {
  pending,
  completed,
  cancelled,
}

class Order {
  final String id;
  final String orderNumber;

  final DateTime createdAt;
  final DateTime businessDate;

  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;

  final List<OrderItem> items;
  final List<Deal> deals;

  final Map<String, int> additionalDrinks;
  final int additionalDipSauceCount;

  final double deliveryCharge;
  final double total;

  final OrderStatus status;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.businessDate,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.deals,
    required this.additionalDrinks,
    required this.additionalDipSauceCount,
    required this.deliveryCharge,
    required this.total,
    required this.status,
  });
}