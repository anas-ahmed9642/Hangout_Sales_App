import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_repository.dart';
import '../models/order_item.dart';
import '../models/topping_selection.dart';
import '../models/deal.dart';
import '../models/order.dart' as order_model;

Map<String, dynamic> _orderToMap(order_model.Order order) {
  return {
    'id': order.id,
    'orderNumber': order.orderNumber,
    'createdAt': Timestamp.fromDate(order.createdAt),
    'businessDate': Timestamp.fromDate(order.businessDate),
    'customerName': order.customerName,
    'customerPhone': order.customerPhone,
    'customerAddress': order.customerAddress,
    'items': order.items.map(_orderItemToMap).toList(),
    'deals': order.deals.map(_dealToMap).toList(),
    'deliveryCharge': order.deliveryCharge,
    'total': order.total,
    'status': order.status.name,
  };
}

Map<String, dynamic> _orderItemToMap(OrderItem item) {
  return {
    'flavorId': item.flavorId,
    'flavorName': item.flavorName,
    'flavorPriceExtra': item.flavorPriceExtra,
    'size': item.size.name,
    'toppings': item.toppings?.map(_toppingToMap).toList(),
    'quantity': item.quantity,
    'unitPrice': item.unitPrice,
  };
}

Map<String, dynamic> _toppingToMap(ToppingSelection topping) {
  return {
    'toppingId': topping.toppingId,
    'toppingName': topping.toppingName,
    'priceAtOrderTime': topping.priceAtOrderTime,
  };
}

Map<String, dynamic> _dealToMap(Deal deal) {
  return {
    'id': deal.id,
    'name': deal.name,
    'price': deal.price,
    'pizzaSizes': deal.pizzaSizes.map((size) => size.name).toList(),
    'dipSauceCount': deal.dipSauceCount,
    'drinkSize': deal.drinkSize,
  };
}

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirebaseOrderRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  @override
  Future<void> createOrder(order_model.Order order) async {
    await _ordersCollection
        .doc(order.id)
        .set(_orderToMap(order));
  }
}