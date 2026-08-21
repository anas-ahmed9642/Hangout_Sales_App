class Flavor {
  final String id;
  final String name;
  final double? priceExtra;

  const Flavor({
    required this.id,
    required this.name,
    this.priceExtra,
  });
}