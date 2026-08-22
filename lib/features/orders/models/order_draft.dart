import 'order_draft_entry.dart';

class OrderDraft {
  final List<OrderDraftEntry> entries;

  final double deliveryCharge;

  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;
  final Map<String, int> additionalDrinks;

final int additionalDipSauceCount;

  const OrderDraft({
    this.entries = const [],
    this.additionalDrinks = const {},
    this.additionalDipSauceCount = 0,
    this.deliveryCharge = 0,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
  });

  OrderDraft copyWith({
  List<OrderDraftEntry>? entries,
  Map<String, int>? additionalDrinks,
  int? additionalDipSauceCount,
  double? deliveryCharge,
  String? customerName,
  String? customerPhone,
  String? customerAddress,
}) {
  return OrderDraft(
    entries: entries ?? this.entries,
    additionalDrinks: additionalDrinks ?? this.additionalDrinks,
  additionalDipSauceCount:
      additionalDipSauceCount ?? this.additionalDipSauceCount,
    deliveryCharge: deliveryCharge ?? this.deliveryCharge,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    customerAddress: customerAddress ?? this.customerAddress,
  );
}
}