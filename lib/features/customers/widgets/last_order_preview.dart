import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../orders/models/order.dart';
import '../../orders/models/pizza_size.dart';
import '../../orders/providers/order_draft_provider.dart';
import '../providers/last_order_provider.dart';
import '../services/reorder_mapper.dart';

/// "12 days ago", "Yesterday", "3 hours ago".
///
/// Thresholds (test-pinned): under 1 minute -> just now; under 60
/// minutes -> N min ago; under 24 hours -> N hour(s) ago; under 48
/// hours -> Yesterday; under 30 days -> N day(s) ago; older ->
/// d MMM yyyy.
String relativeTimeAgo(DateTime when, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(when);

  if (diff.inMinutes < 1) {
    return 'just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    final hours = diff.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  }
  if (diff.inHours < 48) {
    return 'Yesterday';
  }
  if (diff.inDays < 30) {
    final days = diff.inDays;
    return '$days ${days == 1 ? 'day' : 'days'} ago';
  }
  return DateFormat('d MMM yyyy').format(when);
}

String _pizzaSizeLabel(PizzaSize size) {
  switch (size) {
    case PizzaSize.small:
      return 'Small';
    case PizzaSize.regular:
      return 'Regular';
    case PizzaSize.large:
      return 'Large';
  }
}

/// One muted line: `Last order 12 days ago · 2 Large Fajita · Rs. 2300`.
/// Deals are listed first (grouped by id), then standalone pizzas grouped
/// by size+flavor; only the first segment shows, with a +N more suffix.
String _previewLine(Order order) {
  final segments = <String>[];

  final dealCounts = <String, int>{};
  final dealNames = <String, String>{};
  for (final deal in order.deals) {
    dealCounts[deal.id] = (dealCounts[deal.id] ?? 0) + 1;
    dealNames[deal.id] = deal.name;
  }
  for (final id in dealCounts.keys) {
    final count = dealCounts[id]!;
    segments.add(count == 1 ? dealNames[id]! : '${dealNames[id]} x$count');
  }

  // order.items holds deal pizzas too (flattened by buildOrder), so the
  // first N items belong to the deals and are skipped positionally —
  // the same rule mapOrderToDraft uses.
  var dealItemCount = 0;
  for (final deal in order.deals) {
    dealItemCount += deal.pizzaSizes.length;
  }

  final pizzaCounts = <String, int>{};
  final pizzaLabels = <String, String>{};
  for (final item in order.items.skip(dealItemCount)) {
    final key = '${item.size.name}|${item.flavorName}';
    pizzaCounts[key] = (pizzaCounts[key] ?? 0) + 1;
    pizzaLabels[key] = '${_pizzaSizeLabel(item.size)} ${item.flavorName}';
  }
  for (final key in pizzaCounts.keys) {
    final count = pizzaCounts[key]!;
    segments.add(
      count == 1 ? pizzaLabels[key]! : '$count ${pizzaLabels[key]}',
    );
  }

  final itemPart = segments.isEmpty
      ? ''
      : ' · ${segments.first}${segments.length > 1 ? ' +${segments.length - 1} more' : ''}';

  return 'Last order ${relativeTimeAgo(order.createdAt)}$itemPart'
      ' · Rs. ${order.total.toStringAsFixed(0)}';
}

/// Last-order preview with a Reorder button (plan 8.10, F7/F8).
///
/// One muted line under the customer name; hidden when the customer has
/// no (non-cancelled) orders. Reorder rebuilds the draft's item fields at
/// current menu prices via [mapOrderToDraft] + `applyReorder` — customer
/// fields and the chosen delivery charge are never touched.
class LastOrderPreview extends ConsumerWidget {
  final String phone;

  const LastOrderPreview({super.key, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastOrder = ref.watch(lastOrderProvider(phone));

    if (lastOrder == null) {
      return const SizedBox.shrink();
    }

    // Self-spacing: 8px top margin when visible; nothing when hidden.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _previewLine(lastOrder),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _reorder(context, ref, lastOrder),
            child: const Text('Reorder'),
          ),
        ],
      ),
    );
  }

  void _reorder(BuildContext context, WidgetRef ref, Order order) {
    final result = mapOrderToDraft(order);
    ref.read(orderDraftProvider.notifier).applyReorder(result);

    if (result.skippedCount > 0 && context.mounted) {
      final itemWord = result.skippedCount == 1 ? 'item' : 'items';
      final verb = result.skippedCount == 1 ? 'is' : 'are';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              '${result.skippedCount} $itemWord from the last order $verb '
              'no longer on the menu.',
            ),
          ),
        );
    }
  }
}