import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';

/// Firestore document mapping for customers, shared by
/// FirebaseCustomerRepository and the order-creation transaction in
/// FirebaseOrderRepository (plan 8.6). One definition, no duplication.
///
/// The document id is the normalized phone; the stored phone field is
/// only for console readability.
Map<String, dynamic> customerToMap(Customer customer) {
  return {
    'phone': customer.phone,
    'name': customer.name,
    'addresses': customer.addresses.map(customerAddressToMap).toList(),
    'defaultAddressId': customer.defaultAddressId,
    'deliveryNotes': customer.deliveryNotes,
    'notes': customer.notes,
    'archived': customer.archived,
    'mergedInto': customer.mergedInto,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'lastOrderAt': customer.lastOrderAt == null
        ? null
        : Timestamp.fromDate(customer.lastOrderAt!),
  };
}

/// Update mapping: preserves the existing createdAt; updatedAt still
/// becomes a server timestamp. Used for in-transaction customer touches.
Map<String, dynamic> customerUpdateMap(Customer customer) {
  return {
    ...customerToMap(customer),
    'createdAt': Timestamp.fromDate(customer.createdAt),
  };
}

Map<String, dynamic> customerAddressToMap(CustomerAddress address) {
  return {
    'id': address.id,
    'label': address.label,
    'text': address.text,
    'mapLink': address.mapLink,
    'areaId': address.areaId,
  };
}

Customer customerFromDocument(
  DocumentSnapshot<Map<String, dynamic>> document,
) {
  final data = document.data() ?? {};
  return Customer(
    // The document id IS the identity (plan 5.1); the stored field is
    // only for console readability.
    phone: document.id,
    name: data['name'] as String?,
    addresses: (data['addresses'] as List<dynamic>? ?? [])
        .map((entry) => customerAddressFromMap(entry as Map<String, dynamic>))
        .toList(),
    defaultAddressId: data['defaultAddressId'] as String?,
    deliveryNotes: data['deliveryNotes'] as String?,
    notes: data['notes'] as String?,
    archived: data['archived'] as bool? ?? false,
    mergedInto: data['mergedInto'] as String?,
    createdAt: _readDateTime(data['createdAt']),
    updatedAt: _readDateTime(data['updatedAt']),
    lastOrderAt: _readNullableDateTime(data['lastOrderAt']),
  );
}

CustomerAddress customerAddressFromMap(Map<String, dynamic> map) {
  return CustomerAddress(
    id: map['id'] as String? ?? '',
    label: map['label'] as String?,
    text: map['text'] as String? ?? '',
    mapLink: map['mapLink'] as String?,
    areaId: map['areaId'] as String?,
  );
}

DateTime _readDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _readNullableDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}
