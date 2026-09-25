import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'order_repository.dart';
import '../models/order_item.dart';
import '../models/topping_selection.dart';
import '../models/deal.dart';
import '../models/order.dart' as order_model;
import '../models/pizza_size.dart';
import 'package:collection/collection.dart';

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
    'additionalDrinks': order.additionalDrinks,
    'additionalDipSauceCount': order.additionalDipSauceCount,
    'deliveryCharge': order.deliveryCharge,
    'total': order.total,
    'status': order.status.name,
    'paymentStatus': order.paymentStatus.name,
    'editCount': order.editCount,
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

order_model.Order _orderFromMap(Map<String, dynamic> data) {
  return order_model.Order(
    id: data['id'] as String,
    orderNumber: data['orderNumber'] as String,
    createdAt: (data['createdAt'] as Timestamp).toDate(),
    businessDate: (data['businessDate'] as Timestamp).toDate(),
    customerName: data['customerName'] as String?,
    customerPhone: data['customerPhone'] as String?,
    customerAddress: data['customerAddress'] as String?,
    items: (data['items'] as List<dynamic>)
        .map(
          (item) => _orderItemFromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    deals: (data['deals'] as List<dynamic>)
        .map((deal) => _dealFromMap(Map<String, dynamic>.from(deal as Map)))
        .toList(),
    additionalDrinks: Map<String, int>.from(data['additionalDrinks'] as Map),
    additionalDipSauceCount: (data['additionalDipSauceCount'] as num).toInt(),
    deliveryCharge: (data['deliveryCharge'] as num).toDouble(),
    total: (data['total'] as num).toDouble(),
    status: order_model.OrderStatus.values.firstWhere(
      (status) => status.name == data['status'],
    ),
    paymentStatus: order_model.PaymentStatus.values.firstWhere(
      (paymentStatus) => paymentStatus.name == data['paymentStatus'],
      orElse: () => order_model.PaymentStatus.unpaid,
    ),
    editCount: (data['editCount'] as num?)?.toInt() ?? 0,
  );
}

OrderItem _orderItemFromMap(Map<String, dynamic> data) {
  return OrderItem(
    flavorId: data['flavorId'] as String,
    flavorName: data['flavorName'] as String,
    flavorPriceExtra: (data['flavorPriceExtra'] as num?)?.toDouble(),
    size: PizzaSize.values.firstWhere((e) => e.name == data['size']),
    toppings: (data['toppings'] as List<dynamic>?)
        ?.map(
          (topping) =>
              _toppingFromMap(Map<String, dynamic>.from(topping as Map)),
        )
        .toList(),
    quantity: (data['quantity'] as num).toInt(),
    unitPrice: (data['unitPrice'] as num).toDouble(),
  );
}

ToppingSelection _toppingFromMap(Map<String, dynamic> data) {
  return ToppingSelection(
    toppingId: data['toppingId'] as String,
    toppingName: data['toppingName'] as String,
    priceAtOrderTime: (data['priceAtOrderTime'] as num).toDouble(),
  );
}

Deal _dealFromMap(Map<String, dynamic> data) {
  return Deal(
    id: data['id'] as String,
    name: data['name'] as String,
    price: (data['price'] as num).toDouble(),
    pizzaSizes: (data['pizzaSizes'] as List<dynamic>)
        .map(
          (e) =>
              PizzaSize.values.firstWhere((size) => size.name == e as String),
        )
        .toList(),
    dipSauceCount: (data['dipSauceCount'] as num).toInt(),
    drinkSize: data['drinkSize'] as String?,
  );
}

class FirebaseOrderRepository implements OrderRepository {
  final FirebaseFirestore _firestore;

  FirebaseOrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCollection =>
      _firestore.collection('orders');

  @override
  Future<void> createOrder(order_model.Order order) async {
    // Define references for the transaction
    final counterRef = _firestore.collection('metadata').doc('counters');
    final orderRef = _ordersCollection.doc(order.id);

    // Execute the atomic transaction
    await _firestore.runTransaction((transaction) async {
      // 1. Lock and read the current counter
      final counterSnapshot = await transaction.get(counterRef);

      int currentNumber = 0;
      if (counterSnapshot.exists) {
        currentNumber = counterSnapshot.data()?['order_count'] ?? 0;
      }

      // 2. Increment the sequence
      final nextSequence = currentNumber + 1;

      // 3. Format the new order number (e.g., ORD-0001)
      final formattedNumber = 'ORD-${nextSequence.toString().padLeft(4, '0')}';

      // 4. Convert the Dart object to a Map and overwrite the UI's placeholder
      final orderMap = _orderToMap(order);
      orderMap['orderNumber'] = formattedNumber;

      // 5. Write both documents to the database at the exact same time
      transaction.set(counterRef, {'order_count': nextSequence});
      transaction.set(orderRef, orderMap);
    });
  }

  @override
  Stream<List<order_model.Order>> streamOrders(DateTime businessDate) {
    // 1. Calculate the absolute start and end of the requested business day
    final startOfDay = Timestamp.fromDate(
      DateTime(businessDate.year, businessDate.month, businessDate.day),
    );
    final endOfDay = Timestamp.fromDate(
      DateTime(businessDate.year, businessDate.month, businessDate.day + 1),
    );

    // 2. Use a range query instead of an exact match
    return _ordersCollection
        .where('businessDate', isGreaterThanOrEqualTo: startOfDay)
        .where('businessDate', isLessThan: endOfDay)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => _orderFromMap(doc.data())).toList();
        });
  }
  @override
Stream<List<order_model.Order>> streamUnpaidOrders() {
  return _ordersCollection
      .where(
        'paymentStatus',
        isEqualTo: order_model.PaymentStatus.unpaid.name,
      )
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => _orderFromMap(doc.data()))
            .where(
              (order) => order.status != order_model.OrderStatus.cancelled,
            )
            .toList();
      });
}

  @override
  Future<List<order_model.Order>> searchOrdersByPhone(
    String phoneNumber,
  ) async {
    final snapshot = await _ordersCollection
        .where('customerPhone', isEqualTo: phoneNumber)
        .get();

    return snapshot.docs.map((doc) => _orderFromMap(doc.data())).toList();
  }

  @override
  Future<order_model.Order?> getOrder(String orderId) async {
    final snapshot = await _ordersCollection.doc(orderId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();

    if (data == null) {
      return null;
    }

    return _orderFromMap(data);
  }

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {
    if (changes.isEmpty) {
      throw ArgumentError('Cannot update an order with no changes.');
    }

    if (changeReason.trim().isEmpty) {
      throw ArgumentError('A change reason is required.');
    }

    // Fields that represent order content — editing these after an
    // order is completed or cancelled is disallowed, since the order
    // record should be immutable at that point aside from status/
    // payment-state transitions.
    const contentFields = <String>{
      'customerName',
      'customerPhone',
      'customerAddress',
      'items',
      'deals',
      'additionalDrinks',
      'additionalDipSauceCount',
      'deliveryCharge',
      'total',
    };

    final isContentEdit = changes.keys.any(contentFields.contains);

    final orderRef = _ordersCollection.doc(orderId);
    final historyCollection = orderRef.collection('history');

    await _firestore.runTransaction((transaction) async {
      // Read the current order before making any changes.
      // (Transactions require all reads before any writes —
      // this single read covers every field we need old values for.)
      final orderSnapshot = await transaction.get(orderRef);

      if (!orderSnapshot.exists) {
        throw StateError('Order $orderId does not exist.');
      }

      final currentData = orderSnapshot.data();

      if (currentData == null) {
        throw StateError('Order $orderId contains no data.');
      }

      final currentStatus = currentData['status'] as String?;

      if (isContentEdit &&
          (currentStatus == OrderStatus.completed.name ||
              currentStatus == OrderStatus.cancelled.name)) {
        throw StateError('Completed or cancelled orders cannot be edited.');
      }

      const deepEq = DeepCollectionEquality();

final currentEditCount =
    (currentData['editCount'] as num?)?.toInt() ?? 0;

final changedEntries = changes.entries.where((entry) {
  final oldValue = currentData[entry.key];
  final newValue = entry.value;

  return !deepEq.equals(oldValue, newValue);
}).toList();

final hasContentEdit = changedEntries.any(
  (entry) => contentFields.contains(entry.key),
);

final updateData = <String, dynamic>{
  ...changes,
};

if (hasContentEdit) {
  updateData['editCount'] = currentEditCount + 1;
}

// Update the actual order document.
transaction.update(orderRef, updateData);

      // One history document per changed field — not one bundled
      // entry — so "every change ever made to field X" is directly
      // queryable against the subcollection later without unpacking
      // arrays/maps inside a single document.
      final timestamp = Timestamp.now();
      

      for (final entry in changedEntries) {
  final oldValue = currentData[entry.key];
  final newValue = entry.value;

  if (kDebugMode) {
    debugPrint(
      '${entry.key}: old=$oldValue (${oldValue.runtimeType}) '
      'new=$newValue (${newValue.runtimeType}) '
      'equal=${deepEq.equals(oldValue, newValue)}',
    );
  }

  final historyRef = historyCollection.doc();

  transaction.set(historyRef, {
    'field': entry.key,
    'oldValue': oldValue,
    'newValue': newValue,
    'changeReason': changeReason.trim(),
    'timestamp': timestamp,
  });
}
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async {
    final snapshot = await _ordersCollection
        .doc(orderId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}
