import '../models/customer.dart';
import '../models/customer_duplicate_candidate.dart';

String _collapse(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

String _foldCase(String value) => _collapse(value).toLowerCase();

/// Pure duplicate detection (plan Phase 12). No Firebase, no providers.
///
/// Only ACTIVE customers (not archived, not merged) are considered. Two
/// customers are flagged when they share ANY of:
/// - the same name (case-insensitive, whitespace collapsed),
/// - the same address text (case-insensitive, whitespace collapsed),
/// - the same map link (whitespace collapsed, case-SENSITIVE: short-link
///   codes are case-sensitive, so differing case means a different place).
///
/// Unnamed customers never match each other by name. Pairs whose
/// [duplicatePairKey] is in [dismissedPairKeys] are left out.
///
/// Result order is deterministic: pairs with more reasons first, then by
/// the first phone, then the second phone.
List<CustomerDuplicateCandidate> findDuplicateCandidates(
  List<Customer> customers, {
  Set<String> dismissedPairKeys = const <String>{},
}) {
  final active = customers
      .where((customer) => !customer.archived && customer.mergedInto == null)
      .toList();

  final reasonsByPair = <String, Set<DuplicateReason>>{};
  final membersByPair = <String, List<Customer>>{};

  void flag(
    Iterable<String> Function(Customer customer) keysOf,
    DuplicateReason reason,
  ) {
    final groups = <String, List<Customer>>{};
    for (final customer in active) {
      for (final key in keysOf(customer).toSet()) {
        if (key.isEmpty) continue;
        groups.putIfAbsent(key, () => <Customer>[]).add(customer);
      }
    }
    for (final group in groups.values) {
      if (group.length < 2) continue;
      for (var i = 0; i < group.length; i++) {
        for (var j = i + 1; j < group.length; j++) {
          final a = group[i];
          final b = group[j];
          final pairKey = duplicatePairKey(a.phone, b.phone);
          reasonsByPair
              .putIfAbsent(pairKey, () => <DuplicateReason>{})
              .add(reason);
          membersByPair.putIfAbsent(
            pairKey,
            () => a.phone.compareTo(b.phone) <= 0
                ? <Customer>[a, b]
                : <Customer>[b, a],
          );
        }
      }
    }
  }

  flag((customer) => [_foldCase(customer.name ?? '')],
      DuplicateReason.sameName);
  flag(
    (customer) => customer.addresses.map((address) => _foldCase(address.text)),
    DuplicateReason.sameAddress,
  );
  flag(
    (customer) =>
        customer.addresses.map((address) => _collapse(address.mapLink ?? '')),
    DuplicateReason.sameMapLink,
  );

  final result = <CustomerDuplicateCandidate>[];
  for (final entry in membersByPair.entries) {
    if (dismissedPairKeys.contains(entry.key)) continue;
    result.add(
      CustomerDuplicateCandidate(
        first: entry.value[0],
        second: entry.value[1],
        reasons: reasonsByPair[entry.key]!,
      ),
    );
  }

  result.sort((a, b) {
    final byReasons = b.reasons.length.compareTo(a.reasons.length);
    if (byReasons != 0) return byReasons;
    final byFirst = a.first.phone.compareTo(b.first.phone);
    if (byFirst != 0) return byFirst;
    return a.second.phone.compareTo(b.second.phone);
  });

  return result;
}
