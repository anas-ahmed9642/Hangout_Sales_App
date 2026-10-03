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