import 'customer.dart';

/// Why two customers were flagged as a possible duplicate (plan Phase 12).
enum DuplicateReason { sameName, sameAddress, sameMapLink }

/// Order-independent key for a pair of customer phones: the two phones
/// sorted ascending and joined with an underscore. Used to remember
/// dismissed pairs.
String duplicatePairKey(String phoneA, String phoneB) {
  return phoneA.compareTo(phoneB) <= 0
      ? '${phoneA}_$phoneB'
      : '${phoneB}_$phoneA';
}

/// A suggested duplicate pair. Suggestions only: nothing is ever merged
/// automatically.
class CustomerDuplicateCandidate {
  /// The customer with the smaller phone.
  final Customer first;

  /// The customer with the larger phone.
  final Customer second;

  final Set<DuplicateReason> reasons;

  CustomerDuplicateCandidate({
    required this.first,
    required this.second,
    required Set<DuplicateReason> reasons,
  }) : reasons = Set<DuplicateReason>.of(reasons);

  String get pairKey => duplicatePairKey(first.phone, second.phone);

  /// The customer to keep by default: the more recently active one.
  /// Ties and missing dates fall back to [first]. The merge screen lets
  /// the user swap the direction.
  Customer get suggestedTarget {
    final firstLast = first.lastOrderAt;
    final secondLast = second.lastOrderAt;
    if (secondLast != null &&
        (firstLast == null || secondLast.isAfter(firstLast))) {
      return second;
    }
    return first;
  }

  /// The customer suggested as the duplicate (archived after the merge).
  Customer get suggestedSource =>
      identical(suggestedTarget, first) ? second : first;
}
