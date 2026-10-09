import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import 'customer_repository_provider.dart';

/// All customers, archived excluded by default. No sorting here —
/// presentation order belongs to the list screen (Phase 7).
final customersStreamProvider =
    StreamProvider.autoDispose<List<Customer>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);

  return repository.streamCustomers();
});

/// Every customer, archived included. The Phase 7 list screen
/// partitions the archived flag in memory (All / Win-back / Archived
/// slices), which the archived-excluded [customersStreamProvider]
/// cannot serve. This is the list screen's single Firestore
/// subscription; the search results provider derives from it instead
/// of reading the repository again.
final allCustomersStreamProvider =
    StreamProvider.autoDispose<List<Customer>>((ref) {
  final repository = ref.watch(customerRepositoryProvider);

  return repository.streamCustomers(includeArchived: true);
});

/// One-shot customer lookup by phone, keyed by the phone as typed.
/// The repository normalizes defensively, so '+92 300 ...' and
/// '0300-...' resolve to the same customer. Watched (not
/// read-then-forgotten) by the Phase 4 autofill field, so autoDispose
/// is safe here.
final customerByPhoneProvider =
    FutureProvider.autoDispose.family<Customer?, String>((ref, phone) {
  final repository = ref.watch(customerRepositoryProvider);

  return repository.getByPhone(phone);
});

/// One customer by phone, LIVE (Phase 8). Derives from
/// [allCustomersStreamProvider] — the repository's only customer
/// stream — so profile edits, address changes and archive/restore
/// appear on Customer Detail the moment they land, with no manual
/// invalidation. Keyed by the NORMALIZED phone; the list screen and
/// the route both pass it already normalized. Emits null when no
/// customer has that phone.
final customerStreamByPhoneProvider =
    StreamProvider.autoDispose.family<Customer?, String>((ref, phone) async* {
  final customers = await ref.watch(allCustomersStreamProvider.future);
  for (final customer in customers) {
    if (customer.phone == phone) {
      yield customer;
      return;
    }
  }
  yield null;
});