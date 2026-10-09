import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_duplicate_candidate.dart';
import '../repositories/customer_merge_repository.dart';
import '../repositories/firebase_customer_merge_repository.dart';
import '../services/customer_duplicate_detector.dart';
import 'customers_provider.dart';

/// The single merge/dismissal repository (plan Phase 12). Widget tests
/// override this with a fake, like customerRepositoryProvider.
final customerMergeRepositoryProvider =
    Provider<CustomerMergeRepository>((ref) {
  return FirebaseCustomerMergeRepository();
});

/// Pair keys the user dismissed as "not a duplicate".
final dismissedDuplicatePairsProvider =
    StreamProvider.autoDispose<Set<String>>((ref) {
  final repository = ref.watch(customerMergeRepositoryProvider);

  return repository.streamDismissedPairs();
});

/// Possible duplicate pairs, derived in memory from the customer stream
/// (the list screen's single customer subscription) minus dismissed
/// pairs. While either source is loading or in error this is EMPTY: a
/// suggestion must never flash and disappear, and a failing dismissal
/// read must never break the Customers screen.
final duplicateCandidatesProvider =
    Provider.autoDispose<List<CustomerDuplicateCandidate>>((ref) {
  final customers = ref.watch(allCustomersStreamProvider).valueOrNull;
  final dismissed = ref.watch(dismissedDuplicatePairsProvider).valueOrNull;

  if (customers == null || dismissed == null) {
    return const <CustomerDuplicateCandidate>[];
  }

  return findDuplicateCandidates(customers, dismissedPairKeys: dismissed);
});
