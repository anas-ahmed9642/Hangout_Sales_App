import 'pizza_size.dart';
import 'topping_selection.dart';

class OrderItem {
  final String flavorId;
  final String flavorName;
  final double? flavorPriceExtra;

  final PizzaSize size;

  final List<ToppingSelection>? toppings;

  final int quantity;

  final double unitPrice;

  const OrderItem({
    required this.flavorId,
    required this.flavorName,
    this.flavorPriceExtra,
    required this.size,
    this.toppings,
    required this.quantity,
    required this.unitPrice,
  });
}