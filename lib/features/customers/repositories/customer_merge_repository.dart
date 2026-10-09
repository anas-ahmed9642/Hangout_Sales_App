/// Longest allowed merge reason (it is written into every moved order's
/// history entry).
const int customerMergeReasonMaxLength = 100;

/// Outcome of [CustomerMergeRepository.mergeCustomers].
class CustomerMergeResult {
  /// Orders re-pointed from SOURCE to TARGET by THIS call (a resumed
  /// merge only counts the orders it moved itself).
  final int ordersMoved;

  /// Addresses taken over from SOURCE by THIS call.
  final int addressesAdded;

  /// True when SOURCE was already merged into TARGET; nothing was done.
  final bool alreadyMerged;

  const CustomerMergeResult({
    required this.ordersMoved,
    required this.addressesAdded,
    this.alreadyMerged = false,
  });
}

/// Data-layer contract for duplicate handling (plan Phase 12).
///
/// Deliberately separate from CustomerRepository and OrderRepository:
/// the merge is the ONE place allowed to re-point orders regardless of
/// their status (it bypasses the completed/cancelled content lock of
/// OrderRepository.updateOrder), and it is audited per order.
abstract class CustomerMergeRepository {
  /// Merges SOURCE (the duplicate) into TARGET (the customer to keep).
  ///
  /// Moves every SOURCE order to TARGET in chunked batches, writing one
  /// audited history entry per order WITHOUT touching editCount. Then,
  /// as the LAST step and in one transaction, unions addresses, appends
  /// notes, sets TARGET.lastOrderAt and archives SOURCE with
  /// mergedInto = TARGET. Safe to re-run after an interruption: orders
  /// already moved no longer match SOURCE and are skipped.
  ///
  /// [onProgress] receives the running count of orders moved by this call.
  ///
  /// Throws [ArgumentError] for invalid input (bad phone, same phone,
  /// empty or over-long reason) and [StateError] when a customer is
  /// missing or the merge is not allowed.
  Future<CustomerMergeResult> mergeCustomers({
    required String sourcePhone,
    required String targetPhone,
    required String reason,
    void Function(int ordersMoved)? onProgress,
  });

  /// Pair keys (see duplicatePairKey) the user dismissed as "not a
  /// duplicate".
  Stream<Set<String>> streamDismissedPairs();

  /// Remembers that the two customers are not duplicates of each other.
  /// Order of the phones does not matter.
  Future<void> dismissPair(String phoneA, String phoneB);
}
