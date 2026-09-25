import 'package:hangout_sales_app/features/orders/models/order.dart';

import 'order_draft_entry.dart';

class OrderDraft {
  final List<OrderDraftEntry> entries;
  final Map<String, int> additionalDrinks;
  final int additionalDipSauceCount;

  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;

  final double deliveryCharge;

  final PaymentStatus paymentStatus;

  const OrderDraft({
    this.entries = const [],
    this.additionalDrinks = const {},
    this.additionalDipSauceCount = 0,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.deliveryCharge = 0,
    this.paymentStatus = PaymentStatus.unpaid,
  });

  OrderDraft copyWith({
    List<OrderDraftEntry>? entries,
    Map<String, int>? additionalDrinks,
    int? additionalDipSauceCount,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? deliveryCharge,
    PaymentStatus? paymentStatus,
  }) {
    return OrderDraft(
      entries: entries ?? this.entries,
      additionalDrinks: additionalDrinks ?? this.additionalDrinks,
      additionalDipSauceCount:
          additionalDipSauceCount ?? this.additionalDipSauceCount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}