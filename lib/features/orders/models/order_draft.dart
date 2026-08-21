import 'order_draft_entry.dart';

class OrderDraft {
  final List<OrderDraftEntry> entries;

  final double deliveryCharge;

  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;

  const OrderDraft({
    this.entries = const [],
    this.deliveryCharge = 0,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
  });

  OrderDraft copyWith({
  List<OrderDraftEntry>? entries,
  double? deliveryCharge,
  String? customerName,
  String? customerPhone,
  String? customerAddress,
}) {
  return OrderDraft(
    entries: entries ?? this.entries,
    deliveryCharge: deliveryCharge ?? this.deliveryCharge,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    customerAddress: customerAddress ?? this.customerAddress,
  );
}
}