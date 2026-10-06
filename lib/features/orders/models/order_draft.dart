import 'package:hangout_sales_app/features/orders/models/order.dart';

import 'order_draft_entry.dart';

/// What to do when the order's address differs from the customer's saved
/// address. Chosen in the "address changed" sheet (Phase 5); stored on
/// the draft from Phase 4 so the decision travels with the order.
enum AddressDecision {
  useForThisOrderOnly,
  updateSavedAddress,
  saveAsNewAddress,
}

class OrderDraft {
  final List<OrderDraftEntry> entries;
  final Map<String, int> additionalDrinks;
  final int additionalDipSauceCount;

  final String? customerName;
  final String? customerPhone;
  final String? customerAddress;

  final double deliveryCharge;

  final PaymentStatus paymentStatus;

  /// Normalized phone of the autofill-matched customer, if any.
  final String? matchedCustomerPhone;

  /// Saved address currently applied to this order, if any.
  final String? selectedAddressId;

  /// Location link for this order (autofilled or typed).
  final String? customerMapLink;

  /// Delivery area for this order; null = unlisted/other.
  final String? deliveryAreaId;

  /// Snapshot of the area name (areas can be renamed later).
  final String? deliveryAreaName;

  /// Editable per-order copy of the customer's delivery notes.
  final String? deliveryNotes;

  /// Whether a new customer will be saved with this order (Phase 5).
  /// The switch UI lands in Phase 5; the default is ON.
  final bool saveCustomer;

  /// Phase 5 "address changed" decision; null until the sheet answers.
  final AddressDecision? addressDecision;

  /// Label for the "save as new address" decision (Phase 5 sheet input).
  final String? newAddressLabel;

  /// Draft field keys currently holding autofilled values. Only these may
  /// be replaced when the phone changes; typed values are never
  /// overwritten. Keys: 'name', 'address', 'mapLink', 'area',
  /// 'deliveryNotes'.
  final Set<String> autofilledFields;

  const OrderDraft({
    this.entries = const [],
    this.additionalDrinks = const {},
    this.additionalDipSauceCount = 0,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.deliveryCharge = 0,
    this.paymentStatus = PaymentStatus.unpaid,
    this.matchedCustomerPhone,
    this.selectedAddressId,
    this.customerMapLink,
    this.deliveryAreaId,
    this.deliveryAreaName,
    this.deliveryNotes,
    this.saveCustomer = true,
    this.addressDecision,
    this.newAddressLabel,
    this.autofilledFields = const {},
  });

  OrderDraft copyWith({
    List<OrderDraftEntry>? entries,
    Map<String, int>? additionalDrinks,
    int? additionalDipSauceCount,
    String? customerName,
    bool clearCustomerName = false,
    String? customerPhone,
    bool clearCustomerPhone = false,
    String? customerAddress,
    bool clearCustomerAddress = false,
    double? deliveryCharge,
    PaymentStatus? paymentStatus,
    String? matchedCustomerPhone,
    bool clearMatchedCustomerPhone = false,
    String? selectedAddressId,
    bool clearSelectedAddressId = false,
    String? customerMapLink,
    bool clearCustomerMapLink = false,
    String? deliveryAreaId,
    bool clearDeliveryAreaId = false,
    String? deliveryAreaName,
    bool clearDeliveryAreaName = false,
    String? deliveryNotes,
    bool clearDeliveryNotes = false,
    bool? saveCustomer,
    AddressDecision? addressDecision,
    bool clearAddressDecision = false,
    String? newAddressLabel,
    bool clearNewAddressLabel = false,
    Set<String>? autofilledFields,
  }) {
    return OrderDraft(
      entries: entries ?? this.entries,
      additionalDrinks: additionalDrinks ?? this.additionalDrinks,
      additionalDipSauceCount:
          additionalDipSauceCount ?? this.additionalDipSauceCount,
      customerName:
          clearCustomerName ? null : customerName ?? this.customerName,
      customerPhone:
          clearCustomerPhone ? null : customerPhone ?? this.customerPhone,
      customerAddress: clearCustomerAddress
          ? null
          : customerAddress ?? this.customerAddress,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      matchedCustomerPhone: clearMatchedCustomerPhone
          ? null
          : matchedCustomerPhone ?? this.matchedCustomerPhone,
      selectedAddressId: clearSelectedAddressId
          ? null
          : selectedAddressId ?? this.selectedAddressId,
      customerMapLink: clearCustomerMapLink
          ? null
          : customerMapLink ?? this.customerMapLink,
      deliveryAreaId: clearDeliveryAreaId
          ? null
          : deliveryAreaId ?? this.deliveryAreaId,
      deliveryAreaName: clearDeliveryAreaName
          ? null
          : deliveryAreaName ?? this.deliveryAreaName,
      deliveryNotes:
          clearDeliveryNotes ? null : deliveryNotes ?? this.deliveryNotes,
      saveCustomer: saveCustomer ?? this.saveCustomer,
      addressDecision: clearAddressDecision
          ? null
          : addressDecision ?? this.addressDecision,
      newAddressLabel: clearNewAddressLabel
          ? null
          : newAddressLabel ?? this.newAddressLabel,
      autofilledFields: autofilledFields ?? this.autofilledFields,
    );
  }
}