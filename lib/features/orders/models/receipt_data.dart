import '../models/order.dart';
import '../models/pizza_size.dart';

class ReceiptItemData {
  final String title;
  final String? detail;
  final int quantity;
  final double amount;

  const ReceiptItemData({
    required this.title,
    this.detail,
    required this.quantity,
    required this.amount,
  });
}

class ReceiptAdditionalItemData {
  final String title;
  final int quantity;

  const ReceiptAdditionalItemData({
    required this.title,
    required this.quantity,
  });
}

class ReceiptData {
  final String storeName;
  final String orderNumber;
  final DateTime createdAt;

  final String customerName;
  final String? customerPhone;
  final String? customerAddress;

  final List<ReceiptItemData> items;
  final List<ReceiptAdditionalItemData> additionalItems;

  final double pizzaSubtotal;
  final double additionalDrinksTotal;
  final double additionalDipSauceTotal;
  final double deliveryCharge;
  final double total;

  final String fulfillmentStatus;
  final String paymentStatus;

  const ReceiptData({
    required this.storeName,
    required this.orderNumber,
    required this.createdAt,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.items,
    required this.additionalItems,
    required this.pizzaSubtotal,
    required this.additionalDrinksTotal,
    required this.additionalDipSauceTotal,
    required this.deliveryCharge,
    required this.total,
    required this.fulfillmentStatus,
    required this.paymentStatus,
  });

  factory ReceiptData.fromOrder(Order order) {
    final receiptItems = <ReceiptItemData>[];

    var itemIndex = 0;

    for (final deal in order.deals) {
      final dealPizzaCount = deal.pizzaSizes.length;

      final detailLines = <String>[];

      for (var pizzaIndex = 0;
          pizzaIndex < dealPizzaCount;
          pizzaIndex++) {
        if (itemIndex >= order.items.length) {
          break;
        }

        final item = order.items[itemIndex];

        detailLines.add(
          '${_pizzaSizeLabel(item.size)} - ${item.flavorName}',
        );

        if (item.toppings != null && item.toppings!.isNotEmpty) {
          detailLines.add(
            '  + ${item.toppings!.map((topping) => topping.toppingName).join(', ')}',
          );
        }

        itemIndex++;
      }

      receiptItems.add(
        ReceiptItemData(
          title: deal.name,
          detail: detailLines.isEmpty
              ? null
              : detailLines.join('\n'),
          quantity: 1,
          amount: deal.price,
        ),
      );
    }

    while (itemIndex < order.items.length) {
      final item = order.items[itemIndex];

      final detailParts = <String>[
        '${_pizzaSizeLabel(item.size)} - ${item.flavorName}',
      ];

      if (item.toppings != null && item.toppings!.isNotEmpty) {
        detailParts.add(
          '+ ${item.toppings!.map((topping) => topping.toppingName).join(', ')}',
        );
      }

      receiptItems.add(
        ReceiptItemData(
          title: 'Pizza',
          detail: detailParts.join('\n'),
          quantity: item.quantity,
          amount: item.unitPrice * item.quantity,
        ),
      );

      itemIndex++;
    }

    final pizzaSubtotal = order.deals.fold<double>(
          0,
          (total, deal) => total + deal.price,
        ) +
        order.items.fold<double>(
          0,
          (total, item) =>
              total + (item.unitPrice * item.quantity),
        );

    final additionalDipSauceTotal =
      order.additionalDipSauceCount * 30.0;

    final additionalDrinksTotal =
        order.total -
        pizzaSubtotal -
        additionalDipSauceTotal -
        order.deliveryCharge;

    final additionalItems = order.additionalDrinks.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => ReceiptAdditionalItemData(
            title: _drinkLabel(entry.key),
            quantity: entry.value,
          ),
        )
        .toList();

    if (order.additionalDipSauceCount > 0) {
      additionalItems.add(
        ReceiptAdditionalItemData(
          title: 'Dip Sauce',
          quantity: order.additionalDipSauceCount,
        ),
      );
    }

    return ReceiptData(
      storeName: 'HANGOUT PIZZA CLASSIC',
      orderNumber: order.orderNumber,
      createdAt: order.createdAt,
      customerName:
          order.customerName?.trim().isNotEmpty == true
              ? order.customerName!.trim()
              : 'Walk-in Customer',
      customerPhone: order.customerPhone,
      customerAddress: order.customerAddress,
      items: List.unmodifiable(receiptItems),
      additionalItems: List.unmodifiable(additionalItems),
      pizzaSubtotal: pizzaSubtotal,
      additionalDrinksTotal:
          additionalDrinksTotal < 0
              ? 0
              : additionalDrinksTotal,
      additionalDipSauceTotal:
          additionalDipSauceTotal,
      deliveryCharge: order.deliveryCharge,
      total: order.total,
      fulfillmentStatus:
          _fulfillmentLabel(order.status),
      paymentStatus:
          _paymentLabel(order.paymentStatus),
    );
  }

  static String _pizzaSizeLabel(PizzaSize size) {
    switch (size) {
      case PizzaSize.small:
        return 'Small';
      case PizzaSize.regular:
        return 'Regular';
      case PizzaSize.large:
        return 'Large';
    }
  }

  static String _drinkLabel(String drinkId) {
    switch (drinkId) {
      case 'drink_345ml':
        return '345ml Drink';
      case 'drink_1ltr':
        return '1L Drink';
      case 'drink_1.5ltr':
        return '1.5L Drink';
      default:
        return drinkId;
    }
  }

  static String _fulfillmentLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  static String _paymentLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.unpaid:
        return 'Unpaid';
    }
  }
}