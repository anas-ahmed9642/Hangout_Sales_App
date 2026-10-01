import '../../../core/utils/phone_normalizer.dart';
import 'customer_address.dart';

/// A customer of the shop.
///
/// The phone number IS the identity: it is immutable after creation and
/// doubles as the Firestore document id ([id] == [phone]). Changing a
/// number is a merge (F23), never an edit.
///
/// Per the module principle "the customer is a convenience, the order is
/// the record": orders keep their own copies of name/phone/address, so
/// editing, archiving or merging a customer never rewrites history.
class Customer {
  /// Always equal to [phone] — the Firestore document id.
  String get id => phone;

  /// Normalized mobile `03xxxxxxxxx`; immutable after creation.
  final String phone;

  /// Trimmed; max 60 chars; null when unknown.
  final String? name;

  /// Saved addresses (F22). The list exists from day one; it may be empty
  /// (e.g. a customer created from an order that had no address).
  final List<CustomerAddress> addresses;

  /// Must reference an entry in [addresses] when set.
  final String? defaultAddressId;

  /// Delivery instructions, max 200 chars; shown on pick, optionally printed.
  final String? deliveryNotes;

  /// Internal notes, max 300 chars; never printed.
  final String? notes;

  /// Archive instead of delete (F25).
  final bool archived;

  /// Phone of the surviving customer; set only by a merge (F23).
  final String? mergedInto;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// `createdAt` of the newest order created for this customer.
  /// Not adjusted when that order is later cancelled (accepted).
  final DateTime? lastOrderAt;

  static const _sentinel = Object();

  Customer({
    required this.phone,
    String? name,
    List<CustomerAddress>? addresses,
    this.defaultAddressId,
    String? deliveryNotes,
    String? notes,
    this.archived = false,
    this.mergedInto,
    required this.createdAt,
    required this.updatedAt,
    this.lastOrderAt,
  })  : name = _emptyToNull(name),
        addresses = List.unmodifiable(addresses ?? const []),
        deliveryNotes = _emptyToNull(deliveryNotes),
        notes = _emptyToNull(notes) {
    if (PhoneNormalizer.normalize(phone) != phone) {
      throw ArgumentError.value(
        phone,
        'phone',
        'Must be a normalized Pakistani mobile number (03xxxxxxxxx).',
      );
    }
    if (name != null && name.trim().length > 60) {
      throw ArgumentError('Customer name must be at most 60 characters.');
    }
    if (defaultAddressId != null &&
        !this.addresses.any((a) => a.id == defaultAddressId)) {
      throw ArgumentError(
        'defaultAddressId must reference an entry in addresses.',
      );
    }
    if (deliveryNotes != null && deliveryNotes.trim().length > 200) {
      throw ArgumentError('Delivery notes must be at most 200 characters.');
    }
    if (notes != null && notes.trim().length > 300) {
      throw ArgumentError('Notes must be at most 300 characters.');
    }
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Note: [phone] is intentionally absent — it is immutable after creation.
  Customer copyWith({
    Object? name = _sentinel,
    List<CustomerAddress>? addresses,
    Object? defaultAddressId = _sentinel,
    Object? deliveryNotes = _sentinel,
    Object? notes = _sentinel,
    bool? archived,
    Object? mergedInto = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? lastOrderAt = _sentinel,
  }) {
    return Customer(
      phone: phone,
      name: name == _sentinel ? this.name : name as String?,
      addresses: addresses ?? this.addresses,
      defaultAddressId: defaultAddressId == _sentinel
          ? this.defaultAddressId
          : defaultAddressId as String?,
      deliveryNotes: deliveryNotes == _sentinel
          ? this.deliveryNotes
          : deliveryNotes as String?,
      notes: notes == _sentinel ? this.notes : notes as String?,
      archived: archived ?? this.archived,
      mergedInto:
          mergedInto == _sentinel ? this.mergedInto : mergedInto as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOrderAt: lastOrderAt == _sentinel
          ? this.lastOrderAt
          : lastOrderAt as DateTime?,
    );
  }
}