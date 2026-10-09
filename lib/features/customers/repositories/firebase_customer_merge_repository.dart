import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/phone_normalizer.dart';
import '../models/customer_duplicate_candidate.dart';
import '../services/customer_merge_service.dart';
import 'customer_document_mapper.dart';
import 'customer_merge_repository.dart';

/// Firestore implementation of [CustomerMergeRepository].
///
/// Firestore is resolved lazily so constructing this repository never
/// touches FirebaseFirestore.instance (widget tests build screens
/// without Firebase initialised).
///
/// Each moved order costs two writes in one batch (the order update and
/// its history entry), so the default of 200 orders per batch stays well
/// under Firestore's 500-write limit.
class FirebaseCustomerMergeRepository implements CustomerMergeRepository {
  static const int defaultOrdersPerBatch = 200;
  static const int maxOrdersPerBatch = 250;

  final FirebaseFirestore? _firestoreOverride;
  final int _ordersPerBatch;

  FirebaseCustomerMergeRepository({
    FirebaseFirestore? firestore,
    int ordersPerBatch = defaultOrdersPerBatch,
  })  : _firestoreOverride = firestore,
        _ordersPerBatch = ordersPerBatch {
    if (ordersPerBatch < 1 || ordersPerBatch > maxOrdersPerBatch) {
      throw ArgumentError.value(
        ordersPerBatch,
        'ordersPerBatch',
        'Must be between 1 and $maxOrdersPerBatch (two writes per order, '
            'Firestore allows 500 writes per batch).',
      );
    }
  }

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customers =>
      _firestore.collection('customers');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  /// NOT metadata/counters: createOrder overwrites that doc wholesale.
  DocumentReference<Map<String, dynamic>> get _dismissalsDoc =>
      _firestore.collection('metadata').doc('customerDuplicateDismissals');

  @override
  Future<CustomerMergeResult> mergeCustomers({
    required String sourcePhone,
    required String targetPhone,
    required String reason,
    void Function(int ordersMoved)? onProgress,
  }) async {
    final source = PhoneNormalizer.normalize(sourcePhone);
    final target = PhoneNormalizer.normalize(targetPhone);
    if (source == null || target == null) {
      throw ArgumentError('Both customers need a valid mobile number.');
    }
    if (source == target) {
      throw ArgumentError('Choose two different customers.');
    }

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw ArgumentError('A merge reason is required.');
    }
    if (trimmedReason.length > customerMergeReasonMaxLength) {
      throw ArgumentError(
        'The merge reason must be at most '
        '$customerMergeReasonMaxLength characters.',
      );
    }

    final sourceRef = _customers.doc(source);
    final targetRef = _customers.doc(target);

    final sourceSnapshot = await sourceRef.get();
    final targetSnapshot = await targetRef.get();
    if (!sourceSnapshot.exists) {
      throw StateError('Customer $source does not exist.');
    }
    if (!targetSnapshot.exists) {
      throw StateError('Customer $target does not exist.');
    }

    final sourceCustomer = customerFromDocument(sourceSnapshot);
    final targetCustomer = customerFromDocument(targetSnapshot);

    if (sourceCustomer.mergedInto == target) {
      return const CustomerMergeResult(
        ordersMoved: 0,
        addressesAdded: 0,
        alreadyMerged: true,
      );
    }

    final blocker = customerMergeBlocker(
      source: sourceCustomer,
      target: targetCustomer,
    );
    if (blocker != null) {
      throw StateError(blocker);
    }

    // Step 1: move the orders, chunk by chunk. A moved order no longer
    // matches the query, so a re-run after an interruption simply
    // continues with what is left. The order update and its history
    // entry share one batch, so an order is never moved without its
    // audit entry. editCount is deliberately NOT touched.
    var ordersMoved = 0;
    while (true) {
      final chunk = await _orders
          .where('customerPhone', isEqualTo: source)
          .limit(_ordersPerBatch)
          .get();
      if (chunk.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();
      final timestamp = Timestamp.now();
      for (final doc in chunk.docs) {
        batch.update(doc.reference, {'customerPhone': target});
        batch.set(doc.reference.collection('history').doc(), {
          'field': 'customerPhone',
          'oldValue': source,
          'newValue': target,
          'changeReason': 'Customer merge: $trimmedReason',
          'source': 'customerMerge',
          'timestamp': timestamp,
        });
      }
      await batch.commit();

      ordersMoved += chunk.docs.length;
      onProgress?.call(ordersMoved);
    }

    // Step 2 (LAST, atomic): profile union on TARGET and archive SOURCE.
    // Finalising last means an interrupted merge leaves both customers
    // active and consistent, and the merge can simply be run again.
    var addressesAdded = 0;
    var finishedByAnotherRun = false;

    await _firestore.runTransaction((transaction) async {
      final freshSource = await transaction.get(sourceRef);
      final freshTarget = await transaction.get(targetRef);
      if (!freshSource.exists || !freshTarget.exists) {
        throw StateError('A customer no longer exists.');
      }

      final currentSource = customerFromDocument(freshSource);
      final currentTarget = customerFromDocument(freshTarget);

      if (currentSource.mergedInto == target) {
        finishedByAnotherRun = true;
        return;
      }

      final currentBlocker = customerMergeBlocker(
        source: currentSource,
        target: currentTarget,
      );
      if (currentBlocker != null) {
        throw StateError(currentBlocker);
      }

      final plan = planCustomerMerge(
        source: currentSource,
        target: currentTarget,
      );
      addressesAdded = plan.addressesToAdd.length;

      transaction.update(targetRef, {
        'addresses': plan.addresses.map(customerAddressToMap).toList(),
        'defaultAddressId': plan.defaultAddressId,
        'notes': plan.notes,
        'deliveryNotes': plan.deliveryNotes,
        'lastOrderAt': plan.lastOrderAt == null
            ? null
            : Timestamp.fromDate(plan.lastOrderAt!),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(sourceRef, {
        'archived': true,
        'mergedInto': target,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return CustomerMergeResult(
      ordersMoved: ordersMoved,
      addressesAdded: finishedByAnotherRun ? 0 : addressesAdded,
      alreadyMerged: finishedByAnotherRun,
    );
  }

  @override
  Stream<Set<String>> streamDismissedPairs() async* {
    yield* _dismissalsDoc.snapshots().map((snapshot) {
      final pairs = snapshot.data()?['pairs'];
      if (pairs is List) {
        return pairs.whereType<String>().toSet();
      }
      return <String>{};
    });
  }

  @override
  Future<void> dismissPair(String phoneA, String phoneB) async {
    final a = PhoneNormalizer.normalize(phoneA);
    final b = PhoneNormalizer.normalize(phoneB);
    if (a == null || b == null) {
      throw ArgumentError('Both customers need a valid mobile number.');
    }
    if (a == b) {
      throw ArgumentError('Choose two different customers.');
    }

    await _dismissalsDoc.set({
      'pairs': FieldValue.arrayUnion([duplicatePairKey(a, b)]),
    }, SetOptions(merge: true));
  }
}
