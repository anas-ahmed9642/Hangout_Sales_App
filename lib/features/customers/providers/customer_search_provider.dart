import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../orders/models/order.dart';
import '../models/customer.dart';
import 'customer_orders_provider.dart';
import 'customers_provider.dart';

/// Which slice of the customer list is on screen (plan 8.11).
enum CustomerFilter { all, winBack, archived }

/// List ordering for the All / Archived slices (plan 8.11): most
/// recent order first (the default), or name A-Z. The win-back slice
/// ignores this and always orders by order count (plan 8.11).
enum CustomerSort { recentFirst, nameAsc }

/// Search text as typed. Kept separate from the filter so typing
/// never re-queries Firestore — filtering is in memory over the
/// already-streamed list (expense-history precedent).
final customerSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final customerFilterProvider =
    StateProvider.autoDispose<CustomerFilter>((ref) => CustomerFilter.all);

final customerSortProvider =
    StateProvider.autoDispose<CustomerSort>((ref) => CustomerSort.recentFirst);

String _nameKey(Customer customer) =>
    (customer.name ?? customer.phone).toLowerCase();

/// Total, deterministic order: display name (the phone for unnamed
/// customers), then the unique phone. List.sort is not stable, so
/// every comparator in this file ends here.
int _compareNameThenPhone(Customer a, Customer b) {
  final byName = _nameKey(a).compareTo(_nameKey(b));
  if (byName != 0) return byName;
  return a.phone.compareTo(b.phone);
}

/// Name A-Z ordering: named customers alphabetically, unnamed
/// customers last (they display as "Unnamed customer"), phone breaks
/// ties. Deliberately different from [_compareNameThenPhone], which
/// keys unnamed customers by phone.
int _compareNameAsc(Customer a, Customer b) {
  final aName = a.name?.toLowerCase();
  final bName = b.name?.toLowerCase();
  if (aName == null && bName == null) return a.phone.compareTo(b.phone);
  if (aName == null) return 1;
  if (bName == null) return -1;
  final byName = aName.compareTo(bName);
  return byName != 0 ? byName : a.phone.compareTo(b.phone);
}

int _compareRecentFirst(Customer a, Customer b) {
  final aLast = a.lastOrderAt;
  final bLast = b.lastOrderAt;
  if (aLast == null && bLast == null) return _compareNameThenPhone(a, b);
  if (aLast == null) return 1;
  if (bLast == null) return -1;
  final byRecent = bLast.compareTo(aLast);
  return byRecent != 0 ? byRecent : _compareNameThenPhone(a, b);
}

/// Pure in-memory filtering and ordering of the streamed customer
/// list (plan 8.11, F11/F20/F25). No providers, no Firestore — the
/// unit tests drive this directly with a fixed [now].
///
/// Query: case-insensitive "contains" on the name, and "contains" on
/// the phone after stripping non-digits from the query (so `0300`,
/// `1234` and `0300-1234` all match the stored normalized phone).
/// Partial numbers are not valid phones, so PhoneNormalizer is never
/// applied to the query.
///
/// Slices: All = non-archived; Archived = archived only; Win-back =
/// non-archived with a [Customer.lastOrderAt] strictly older than
/// 30 days before [now] (a customer who never ordered is not a
/// win-back candidate, and exactly-30-days is not "older than 30").
///
/// Ordering: win-back sorts by [orderCounts] descending (a phone
/// missing from the map counts as 0), then longest-inactive first,
/// then name/phone. Other slices use [sort]. Counts are derived by
/// the caller — never stored on the customer (plan Section 4).
List<Customer> filterAndSortCustomers(
  List<Customer> customers, {
  required String query,
  required CustomerFilter filter,
  required CustomerSort sort,
  required DateTime now,
  Map<String, int> orderCounts = const {},
}) {
  final trimmed = query.trim();
  final nameQuery = trimmed.toLowerCase();
  final digitQuery = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  final cutoff = now.subtract(const Duration(days: 30));

  bool matchesQuery(Customer customer) {
    if (trimmed.isEmpty) return true;
    final name = customer.name;
    if (name != null && name.toLowerCase().contains(nameQuery)) {
      return true;
    }
    return digitQuery.isNotEmpty && customer.phone.contains(digitQuery);
  }

  bool inSlice(Customer customer) {
    if (filter == CustomerFilter.archived) return customer.archived;
    if (customer.archived) return false;
    if (filter == CustomerFilter.winBack) {
      final lastOrderAt = customer.lastOrderAt;
      return lastOrderAt != null && lastOrderAt.isBefore(cutoff);
    }
    return true;
  }

  final visible =
      customers.where((c) => inSlice(c) && matchesQuery(c)).toList();

  if (filter == CustomerFilter.winBack) {
    visible.sort((a, b) {
      final byCount =
          (orderCounts[b.phone] ?? 0).compareTo(orderCounts[a.phone] ?? 0);
      if (byCount != 0) return byCount;
      // Win-back membership guarantees a non-null lastOrderAt.
      final byInactive = a.lastOrderAt!.compareTo(b.lastOrderAt!);
      if (byInactive != 0) return byInactive;
      return _compareNameThenPhone(a, b);
    });
  } else if (sort == CustomerSort.nameAsc) {
    visible.sort(_compareNameAsc);
  } else {
    visible.sort(_compareRecentFirst);
  }
  return visible;
}

/// The visible, ordered customers for the list screen.
///
/// Derives from [allCustomersStreamProvider] (the screen's single
/// Firestore subscription) so typing and slice switches never
/// re-query. While the stream is loading or in error this yields an
/// empty list — the screen renders those states from the stream
/// itself, never from here.
///
/// Win-back order counts are derived only for the win-back
/// candidates (plan: "counts derived for visible rows"): each
/// candidate's orders are watched through the existing
/// [customerOrdersProvider] and counted with cancelled orders
/// excluded, the module-wide rule. A candidate whose orders are
/// still loading counts as 0 until they arrive, then this rebuilds.
final customerSearchResultsProvider =
    Provider.autoDispose<List<Customer>>((ref) {
  final customers =
      ref.watch(allCustomersStreamProvider).valueOrNull ?? const <Customer>[];
  final query = ref.watch(customerSearchQueryProvider);
  final filter = ref.watch(customerFilterProvider);
  final sort = ref.watch(customerSortProvider);
  final now = DateTime.now();

  var orderCounts = const <String, int>{};
  if (filter == CustomerFilter.winBack) {
    final candidates = filterAndSortCustomers(
      customers,
      query: query,
      filter: filter,
      sort: sort,
      now: now,
    );
    final counts = <String, int>{};
    for (final customer in candidates) {
      final orders =
          ref.watch(customerOrdersProvider(customer.phone)).valueOrNull;
      if (orders != null) {
        counts[customer.phone] = orders
            .where((order) => order.status != OrderStatus.cancelled)
            .length;
      }
    }
    orderCounts = counts;
  }

  return filterAndSortCustomers(
    customers,
    query: query,
    filter: filter,
    sort: sort,
    now: now,
    orderCounts: orderCounts,
  );
});
