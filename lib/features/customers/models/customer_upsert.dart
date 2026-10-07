import 'package:hangout_sales_app/features/customers/models/customer_address.dart';
import 'package:hangout_sales_app/features/orders/models/order_draft.dart';

/// Carries everything createOrder needs to create or touch the customer
/// for an order, inside the same Firestore transaction (plan 8.6).
///
/// The phone is always the normalized 03xxxxxxxxx form; a null upsert
/// (see OrderDraftNotifier.buildCustomerUpsert) means "no customer
/// write" — the order saves on its own.
class CustomerUpsert {
  /// Normalized phone; doubles as the customer document id.
  final String phone;

  /// The "New customer — will be saved" switch (plan 8.5). Only matters
  /// when the customer does not exist yet.
  final bool createIfMissing;

  /// Trimmed; null when the order had no name.
  final String? name;

  /// Trimmed; null when the order had no delivery notes. Only used when
  /// creating a new customer — an existing customer's notes are never
  /// touched from the order flow (Locked Decision 6).
  final String? deliveryNotes;

  /// The address as placed on this order (text, link, area). Null when
  /// the order had no address text. Used for new-customer creation and
  /// for the updateSaved / saveAsNew address decisions.
  final CustomerAddress? address;

  /// The "address changed" sheet's answer (plan 8.4). Null when the sheet
  /// never showed. Only matters for an existing customer.
  final AddressDecision? addressDecision;

  /// For [AddressDecision.updateSavedAddress]: the saved address id to
  /// update. Falls back to save-as-new when the id is unknown.
  final String? addressIdToUpdate;

  /// For [AddressDecision.saveAsNewAddress]: the label typed in the
  /// sheet. Blank becomes "Home" via [CustomerAddress].
  final String? newAddressLabel;

  const CustomerUpsert({
    required this.phone,
    required this.createIfMissing,
    this.name,
    this.deliveryNotes,
    this.address,
    this.addressDecision,
    this.addressIdToUpdate,
    this.newAddressLabel,
  });
}
