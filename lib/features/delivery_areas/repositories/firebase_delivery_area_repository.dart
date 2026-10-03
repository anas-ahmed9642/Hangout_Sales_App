import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hangout_sales_app/features/orders/models/menu_data.dart';

import '../models/delivery_area.dart';
import '../seed/verified_delivery_area_seed.dart';
import 'delivery_area_repository.dart';

class FirebaseDeliveryAreaRepository implements DeliveryAreaRepository {
  final FirebaseFirestore _firestore;

  FirebaseDeliveryAreaRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _areasCollection =>
      _firestore.collection('deliveryAreas');

  void _validateCharge(double defaultCharge) {
    if (!MenuData.deliveryCharges.contains(defaultCharge)) {
      throw ArgumentError(
        'Default charge Rs. ${defaultCharge.toStringAsFixed(0)} '
        'is not a valid delivery charge.',
      );
    }
  }

  Future<void> _validateUniqueName(
    String name, {
    String? excludeId,
  }) async {
    final normalized = name.trim().toLowerCase();
    final snapshot = await _areasCollection.get();

    for (final document in snapshot.docs) {
      if (excludeId != null && document.id == excludeId) {
        continue;
      }

      final existing =
          (document.data()['name'] as String? ?? '').trim().toLowerCase();

      if (existing == normalized) {
        throw StateError(
          'An area named "${name.trim()}" already exists.',
        );
      }
    }
  }

  Future<void> _requireArea(String areaId) async {
    final snapshot = await _areasCollection.doc(areaId).get();

    if (!snapshot.exists) {
      throw StateError(
        'Delivery area $areaId does not exist.',
      );
    }
  }

  @override
  Stream<List<DeliveryArea>> streamAreas({bool activeOnly = false}) {
    return _areasCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(_deliveryAreaFromDocument)
          .where((area) => !activeOnly || area.active)
          .toList();
    });
  }

  @override
  Future<String> createArea({
    required String name,
    required double defaultCharge,
  }) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError('Area name is required.');
    }

    _validateCharge(defaultCharge);
    await _validateUniqueName(normalizedName);

    final document = _areasCollection.doc();

    await document.set({
      'name': normalizedName,
      'defaultCharge': defaultCharge,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  @override
  Future<void> updateArea(
    String areaId, {
    required String name,
    required double defaultCharge,
  }) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError('Area name is required.');
    }

    _validateCharge(defaultCharge);
    await _requireArea(areaId);
    await _validateUniqueName(normalizedName, excludeId: areaId);

    await _areasCollection.doc(areaId).update({
      'name': normalizedName,
      'defaultCharge': defaultCharge,
    });
  }

  @override
  Future<void> setAreaActive(
    String areaId,
    bool active,
  ) async {
    await _requireArea(areaId);

    await _areasCollection.doc(areaId).update({
      'active': active,
    });
  }

  @override
  Future<int> seedVerifiedAreas() async {
    final existingSnapshot = await _areasCollection.get();

    final existingKeys = existingSnapshot.docs.map((document) {
      return (document.data()['name'] as String? ?? '')
          .trim()
          .toLowerCase();
    }).toSet();

    final missingItems = verifiedDeliveryAreaSeed.where((item) {
      return !existingKeys.contains(item.name.trim().toLowerCase());
    }).toList();

    if (missingItems.isEmpty) {
      return 0;
    }

    final batch = _firestore.batch();

    for (final item in missingItems) {
      final document = _areasCollection.doc();

      batch.set(document, {
        'name': item.name,
        'defaultCharge': item.defaultCharge,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    return missingItems.length;
  }

  DeliveryArea _deliveryAreaFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return DeliveryArea(
      id: document.id,
      name: data['name'] as String? ?? '',
      defaultCharge: (data['defaultCharge'] as num?)?.toDouble() ?? 0,
      active: data['active'] as bool? ?? false,
      createdAt: _readCreatedAt(data['createdAt']),
    );
  }

  DateTime _readCreatedAt(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}