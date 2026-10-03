import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/phone_normalizer.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import 'customer_repository.dart';

/// Firestore implementation of [CustomerRepository].
///
/// Document mapping is inline (no toJson/fromJson on the models),
/// mirroring FirebaseDeliveryAreaRepository. The document id is the
/// normalized phone; the repository owns createdAt/updatedAt via server
/// timestamps, exactly like the delivery-area repository does.
class FirebaseCustomerRepository implements CustomerRepository {
  final FirebaseFirestore _firestore;

  FirebaseCustomerRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customersCollection =>
      _firestore.collection('customers');

  /// Doc ids are normalized phones. normalize() is idempotent and never
  /// throws; an un-normalizable input falls through as-is and simply
  /// matches nothing, so lookups safely return null.
  String _docId(String phone) => PhoneNormalizer.normalize(phone) ?? phone;

  Future<void> _requireCustomer(
    DocumentReference<Map<String, dynamic>> doc,
    String id,
  ) async {
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      throw StateError('Customer $id does not exist.');
    }
  }

  @override
  Future<Customer?> getByPhone(String phone) async {
    final snapshot =
        await _customersCollection.doc(_docId(phone)).get();

    if (!snapshot.exists) {
      return null;
    }

    return _customerFromDocument(snapshot);
  }

  @override
  Stream<List<Customer>> streamCustomers({bool includeArchived = false}) {
    return _customersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(_customerFromDocument)
          .where((customer) => includeArchived || !customer.archived)
          .toList();
    });
  }

  @override
  Future<void> createCustomer(Customer customer) async {
    final doc = _customersCollection.doc(customer.phone);

    if ((await doc.get()).exists) {
      throw StateError(
        'Customer ${customer.phone} already exists.',
      );
    }

    await doc.set(_customerToMap(customer));
  }

  @override
  Future<void> updateProfile(
    String phone, {
    String? name,
    String? notes,
    String? deliveryNotes,
  }) async {
    final id = _docId(phone);
    final doc = _customersCollection.doc(id);

    await _requireCustomer(doc, id);

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) {
      updates['name'] = _cleaned(name, 60, 'Customer name');
    }
    if (deliveryNotes != null) {
      updates['deliveryNotes'] = _cleaned(deliveryNotes, 200, 'Delivery notes');
    }
    if (notes != null) {
      updates['notes'] = _cleaned(notes, 300, 'Notes');
    }

    await doc.update(updates);
  }

  @override
  Future<void> saveAddresses(
    String phone,
    List<CustomerAddress> addresses,
    String? defaultAddressId,
  ) async {
    final id = _docId(phone);
    final doc = _customersCollection.doc(id);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      throw StateError('Customer $id does not exist.');
    }

    // The Customer constructor validates integrity: defaultAddressId must
    // reference an entry in addresses (ArgumentError otherwise).
    final validated = _customerFromDocument(snapshot).copyWith(
      addresses: addresses,
      defaultAddressId: defaultAddressId,
    );

    await doc.update({
      'addresses': validated.addresses.map(_addressToMap).toList(),
      'defaultAddressId': validated.defaultAddressId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setArchived(String phone, bool archived) async {
    final id = _docId(phone);
    final doc = _customersCollection.doc(id);

    await _requireCustomer(doc, id);

    await doc.update({
      'archived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mirrors the Customer constructor: trims, blank becomes null (so ''
  /// clears the field), over-limit throws with the model's message.
  String? _cleaned(String value, int maxLength, String fieldLabel) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.length > maxLength) {
      throw ArgumentError(
        '$fieldLabel must be at most $maxLength characters.',
      );
    }

    return trimmed;
  }

  Map<String, dynamic> _customerToMap(Customer customer) {
    return {
      'phone': customer.phone,
      'name': customer.name,
      'addresses': customer.addresses.map(_addressToMap).toList(),
      'defaultAddressId': customer.defaultAddressId,
      'deliveryNotes': customer.deliveryNotes,
      'notes': customer.notes,
      'archived': customer.archived,
      'mergedInto': customer.mergedInto,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastOrderAt': customer.lastOrderAt,
    };
  }

  Map<String, dynamic> _addressToMap(CustomerAddress address) {
    return {
      'id': address.id,
      'label': address.label,
      'text': address.text,
      'mapLink': address.mapLink,
      'areaId': address.areaId,
    };
  }

  Customer _customerFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return Customer(
      // The document id IS the identity (plan 5.1); the stored field is
      // only for console readability.
      phone: document.id,
      name: data['name'] as String?,
      addresses: (data['addresses'] as List<dynamic>? ?? [])
          .map((entry) => _addressFromMap(entry as Map<String, dynamic>))
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

  CustomerAddress _addressFromMap(Map<String, dynamic> map) {
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
}