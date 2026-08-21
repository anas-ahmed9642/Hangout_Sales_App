import 'pizza_size.dart';
class Deal {
  final String id;
  final String name;
  final double price;
  final List<PizzaSize> pizzaSizes;
  final int dipSauceCount;
  final String? drinkSize;

  const Deal({
    required this.id,
    required this.name,
    required this.price,
    required this.pizzaSizes,
    required this.dipSauceCount,
    this.drinkSize,
  });
}