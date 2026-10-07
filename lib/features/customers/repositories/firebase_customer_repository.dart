import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/phone_normalizer.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import 'customer_document_mapper.dart';
import 'customer_repository.dart';

/// Firestore implementation of [CustomerRepository].
///
/// Document mapping lives in `customer_document_mapper.dart`, shared with
/// the order-creation transaction (plan 8.6). The document id is the
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

    return customerFromDocument(snapshot);
  }

  @override
  Stream<List<Customer>> streamCustomers({bool includeArchived = false}) {
    return _customersCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(customerFromDocument)
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

    await doc.set(customerToMap(customer));
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
    final validated = customerFromDocument(snapshot).copyWith(
      addresses: addresses,
      defaultAddressId: defaultAddressId,
    );

    await doc.update({
      'addresses': validated.addresses.map(customerAddressToMap).toList(),
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

}
