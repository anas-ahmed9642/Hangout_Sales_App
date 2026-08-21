import 'deal.dart';
import 'pizza_size.dart';
import 'topping_selection.dart';

class OrderDraftEntry {
  final String id;

  final Deal? deal;
  final PizzaSize? standalonePizzaSize;

  final List<String?> flavorIds;
  final List<List<ToppingSelection>> toppings;

  const OrderDraftEntry({
    required this.id,
    this.deal,
    this.standalonePizzaSize,
    this.flavorIds = const [],
    this.toppings = const [],
  });
OrderDraftEntry copyWith({
  Deal? deal,
  PizzaSize? standalonePizzaSize,
  List<String?>? flavorIds,
  List<List<ToppingSelection>>? toppings,
}) {
  return OrderDraftEntry(
    id: id,
    deal: deal ?? this.deal,
    standalonePizzaSize:
        standalonePizzaSize ?? this.standalonePizzaSize,
    flavorIds: flavorIds ?? this.flavorIds,
    toppings: toppings ?? this.toppings,
  );
}

}
