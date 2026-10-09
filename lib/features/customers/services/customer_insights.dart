import '../../../core/utils/phone_normalizer.dart';
import '../../orders/models/order.dart';

/// Pure customer-insight calculations for the Reports module
/// (plan features F17 top customers and F18 new vs returning).
///
/// No Firebase, no providers, no UI: every function takes plain
/// `List<Order>` / `Map` inputs and returns plain result objects,
/// so Reports can call them directly and tests need no fakes.
///
/// Public signatures (stable contract for Reports):
///
///     List<TopCustomer> topCustomers(
///       List<Order> orders, {
///       TopCustomerMetric by = TopCustomerMetric.spend,
///       int limit = 10,
///     })
///
///     Map<String, DateTime> firstOrderBusinessDateByPhone(
///       List<Order> orders,
///     )
///
///     NewVsReturning newVsReturning(
///       List<Order> ordersInPeriod,
///       Map<String, DateTime> firstOrderDateByPhone,
///     )
///
/// Module-wide rules applied by every function here:
/// * Cancelled orders are excluded (the module-wide rule for derived
///   figures: customer_unpaid_provider.dart, last_order_provider.dart).
///   Pending and unpaid orders DO count: spend and order counts do not
///   depend on payment status.
/// * A customer is identified by the NORMALIZED phone
///   (`PhoneNormalizer.normalize`). Older orders stored in raw formats
///   (`0300-1234567`, `+92 300 1234567`, ...) therefore merge into one
///   customer.
/// * An order whose phone is null, blank or not a valid mobile number
///   is a WALK-IN: it can never be ranked or classified as new or
///   returning, and is reported separately.
/// * Business dates are compared DATE-ONLY (year/month/day), so the
///   5 a.m. business-day cutoff already baked into `Order.businessDate`
///   is respected and time-of-day never changes a classification.
/// * Inputs are never mutated.

/// What [topCustomers] ranks by.
enum TopCustomerMetric {
  /// Sum of `Order.total` over the customer's non-cancelled orders.
  spend,

  /// Count of the customer's non-cancelled orders.
  orderCount,
}

/// One ranked customer returned by [topCustomers].
class TopCustomer {
  /// Normalized phone (`03xxxxxxxxx`) — the customer's identity.
  final String phone;

  /// Name from the customer's most recent order that has a non-blank
  /// name (trimmed); null when no order carries a name.
  final String? name;

  /// Count of non-cancelled orders.
  final int orderCount;

  /// Sum of `total` over non-cancelled orders.
  final double totalSpent;

  /// `createdAt` of the customer's newest non-cancelled order.
  final DateTime lastOrderAt;

  const TopCustomer({
    required this.phone,
    this.name,
    required this.orderCount,
    required this.totalSpent,
    required this.lastOrderAt,
  });
}

/// Result of [newVsReturning].
///
/// Invariants (for any input):
/// * [identifiedCustomerCount] = [newCustomerCount]
///   + [returningCustomerCount]
/// * [totalOrderCount] = [newCustomerOrderCount]
///   + [returningCustomerOrderCount] + [walkInOrderCount]
/// * every figure excludes cancelled orders.
class NewVsReturning {
  /// Distinct customers whose first-ever order falls in the period.
  final int newCustomerCount;

  /// Distinct customers who ordered in the period but had ordered before.
  final int returningCustomerCount;

  /// In-period orders placed by new customers.
  final int newCustomerOrderCount;

  /// In-period orders placed by returning customers.
  final int returningCustomerOrderCount;

  /// In-period orders with no valid phone (walk-ins).
  final int walkInOrderCount;

  /// Sum of `total` of in-period orders placed by new customers.
  final double newCustomerRevenue;

  /// Sum of `total` of in-period orders placed by returning customers.
  final double returningCustomerRevenue;

  /// Sum of `total` of in-period walk-in orders.
  final double walkInRevenue;

  const NewVsReturning({
    this.newCustomerCount = 0,
    this.returningCustomerCount = 0,
    this.newCustomerOrderCount = 0,
    this.returningCustomerOrderCount = 0,
    this.walkInOrderCount = 0,
    this.newCustomerRevenue = 0,
    this.returningCustomerRevenue = 0,
    this.walkInRevenue = 0,
  });

  /// No orders in the period.
  static const empty = NewVsReturning();

  /// Distinct customers (new + returning) who ordered in the period.
  int get identifiedCustomerCount => newCustomerCount + returningCustomerCount;

  /// All counted in-period orders, walk-ins included.
  int get totalOrderCount =>
      newCustomerOrderCount + returningCustomerOrderCount + walkInOrderCount;

  /// All counted in-period revenue, walk-ins included.
  double get totalRevenue =>
      newCustomerRevenue + returningCustomerRevenue + walkInRevenue;
}

/// Ranks customers by [by], highest first, and returns at most [limit].
///
/// * Cancelled orders and walk-in orders (null / blank / invalid phone)
///   are ignored.
/// * Ranking is fully deterministic. Ties on the primary metric break
///   by the other metric (descending), then by the most recent
///   `lastOrderAt` (newest first), then by phone ascending.
/// * `limit: 0` returns an empty list; a `limit` larger than the number
///   of customers returns all of them. A negative limit is a caller
///   bug and throws an [ArgumentError] rather than silently looking
///   like "no customers".
/// * The returned list is a fresh list; [orders] is not modified.
List<TopCustomer> topCustomers(
  List<Order> orders, {
  TopCustomerMetric by = TopCustomerMetric.spend,
  int limit = 10,
}) {
  if (limit < 0) {
    throw ArgumentError.value(limit, 'limit', 'Must not be negative.');
  }
  if (limit == 0) {
    return <TopCustomer>[];
  }

  final groups = <String, _CustomerAccumulator>{};
  for (final order in orders) {
    if (!_isCounted(order)) {
      continue;
    }
    final phone = _identify(order);
    if (phone == null) {
      continue;
    }
    groups.putIfAbsent(phone, () => _CustomerAccumulator(phone)).add(order);
  }

  final ranked = groups.values
      .map((accumulator) => accumulator.toTopCustomer())
      .toList();
  ranked.sort((a, b) => _compareTopCustomers(a, b, by));

  if (ranked.length <= limit) {
    return ranked;
  }
  return ranked.sublist(0, limit);
}

/// Builds the `firstOrderDateByPhone` map that [newVsReturning] needs:
/// normalized phone -> date-only BUSINESS date of that customer's
/// earliest non-cancelled order.
///
/// Pass the customer's FULL order history (not just one period) —
/// "first order" only means something against everything that came
/// before. Cancelled orders and walk-in orders are skipped, so a
/// customer whose earlier orders were all cancelled is dated from
/// their first real order.
Map<String, DateTime> firstOrderBusinessDateByPhone(List<Order> orders) {
  final result = <String, DateTime>{};
  for (final order in orders) {
    if (!_isCounted(order)) {
      continue;
    }
    final phone = _identify(order);
    if (phone == null) {
      continue;
    }
    final date = _dateOnly(order.businessDate);
    final existing = result[phone];
    if (existing == null || date.isBefore(existing)) {
      result[phone] = date;
    }
  }
  return result;
}

/// Splits one period's orders into new customers, returning customers
/// and walk-ins.
///
/// * [ordersInPeriod] must contain ALL of the period's orders (it is
///   what makes "earliest order in the period" meaningful). Cancelled
///   orders are ignored.
/// * [firstOrderDateByPhone] should be keyed by NORMALIZED phone (use
///   [firstOrderBusinessDateByPhone], which guarantees that). Keys are
///   re-normalized defensively before lookup, so a raw-format key
///   (`0300-1234567`, `+923001234567`) still matches its customer;
///   when two keys normalize to the same phone the earliest date
///   wins. Values are compared date-only.
/// * A customer is NEW when their all-time first order date is NOT
///   before the earliest business date of their in-period orders —
///   i.e. their first-ever order falls inside the period. Otherwise
///   they are RETURNING.
/// * A customer with no entry in [firstOrderDateByPhone] is treated
///   as NEW: there is no evidence of an earlier order.
/// * Orders with a null / blank / invalid phone are walk-ins, counted
///   separately and never classified.
NewVsReturning newVsReturning(
  List<Order> ordersInPeriod,
  Map<String, DateTime> firstOrderDateByPhone,
) {
  final globalFirst = _normalizedFirstDates(firstOrderDateByPhone);
  final earliestInPeriod = <String, DateTime>{};
  final orderCounts = <String, int>{};
  final revenues = <String, double>{};
  var walkInOrderCount = 0;
  var walkInRevenue = 0.0;

  for (final order in ordersInPeriod) {
    if (!_isCounted(order)) {
      continue;
    }
    final phone = _identify(order);
    if (phone == null) {
      walkInOrderCount++;
      walkInRevenue += order.total;
      continue;
    }
    final date = _dateOnly(order.businessDate);
    final earliest = earliestInPeriod[phone];
    if (earliest == null || date.isBefore(earliest)) {
      earliestInPeriod[phone] = date;
    }
    orderCounts[phone] = (orderCounts[phone] ?? 0) + 1;
    revenues[phone] = (revenues[phone] ?? 0) + order.total;
  }

  var newCustomerCount = 0;
  var returningCustomerCount = 0;
  var newCustomerOrderCount = 0;
  var returningCustomerOrderCount = 0;
  var newCustomerRevenue = 0.0;
  var returningCustomerRevenue = 0.0;

  for (final entry in earliestInPeriod.entries) {
    final phone = entry.key;
    final firstEver = globalFirst[phone];
    final isNew = firstEver == null || !firstEver.isBefore(entry.value);
    final orders = orderCounts[phone] ?? 0;
    final revenue = revenues[phone] ?? 0.0;
    if (isNew) {
      newCustomerCount++;
      newCustomerOrderCount += orders;
      newCustomerRevenue += revenue;
    } else {
      returningCustomerCount++;
      returningCustomerOrderCount += orders;
      returningCustomerRevenue += revenue;
    }
  }

  return NewVsReturning(
    newCustomerCount: newCustomerCount,
    returningCustomerCount: returningCustomerCount,
    newCustomerOrderCount: newCustomerOrderCount,
    returningCustomerOrderCount: returningCustomerOrderCount,
    walkInOrderCount: walkInOrderCount,
    newCustomerRevenue: newCustomerRevenue,
    returningCustomerRevenue: returningCustomerRevenue,
    walkInRevenue: walkInRevenue,
  );
}

/// Normalizes the keys of a first-order map: raw-format keys are
/// folded onto the normalized phone, invalid keys are dropped, and
/// when several keys identify the same customer the earliest
/// (date-only) value wins.
Map<String, DateTime> _normalizedFirstDates(
  Map<String, DateTime> firstOrderDateByPhone,
) {
  final result = <String, DateTime>{};
  for (final entry in firstOrderDateByPhone.entries) {
    final phone = PhoneNormalizer.normalize(entry.key);
    if (phone == null) {
      continue;
    }
    final date = _dateOnly(entry.value);
    final existing = result[phone];
    if (existing == null || date.isBefore(existing)) {
      result[phone] = date;
    }
  }
  return result;
}

/// Orders that count toward any insight: everything except cancelled.
bool _isCounted(Order order) => order.status != OrderStatus.cancelled;

/// The normalized phone of [order], or null for a walk-in (null, blank
/// or invalid number).
String? _identify(Order order) {
  final raw = order.customerPhone;
  if (raw == null) {
    return null;
  }
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  return PhoneNormalizer.normalize(text);
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

int _compareTopCustomers(
  TopCustomer a,
  TopCustomer b,
  TopCustomerMetric by,
) {
  final bySpend = by == TopCustomerMetric.spend;

  final primary = bySpend
      ? b.totalSpent.compareTo(a.totalSpent)
      : b.orderCount.compareTo(a.orderCount);
  if (primary != 0) {
    return primary;
  }

  final secondary = bySpend
      ? b.orderCount.compareTo(a.orderCount)
      : b.totalSpent.compareTo(a.totalSpent);
  if (secondary != 0) {
    return secondary;
  }

  final recent = b.lastOrderAt.compareTo(a.lastOrderAt);
  if (recent != 0) {
    return recent;
  }

  return a.phone.compareTo(b.phone);
}

/// Running totals for one customer inside [topCustomers].
class _CustomerAccumulator {
  final String phone;
  int orderCount = 0;
  double totalSpent = 0;
  DateTime? lastOrderAt;
  String? name;
  DateTime? _nameOrderAt;

  _CustomerAccumulator(this.phone);

  void add(Order order) {
    orderCount++;
    totalSpent += order.total;

    final last = lastOrderAt;
    if (last == null || order.createdAt.isAfter(last)) {
      lastOrderAt = order.createdAt;
    }

    final candidate = order.customerName?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      final seen = _nameOrderAt;
      if (seen == null || order.createdAt.isAfter(seen)) {
        name = candidate;
        _nameOrderAt = order.createdAt;
      }
    }
  }

  TopCustomer toTopCustomer() {
    return TopCustomer(
      phone: phone,
      name: name,
      orderCount: orderCount,
      totalSpent: totalSpent,
      lastOrderAt: lastOrderAt!,
    );
  }
}
