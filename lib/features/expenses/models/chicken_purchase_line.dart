/// The three chicken types the shop purchases, in display order.
const chickenTypes = <String>[
  'Malai Boti',
  'Chicken Tikka',
  'Chicken Fajita',
];

class ChickenPurchaseLine {
  final String chickenType;
  final int quantityKg;

  const ChickenPurchaseLine({
    required this.chickenType,
    required this.quantityKg,
  });
}