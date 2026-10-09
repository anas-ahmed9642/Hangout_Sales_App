import 'package:flutter/material.dart';

import '../models/customer_stats.dart';

/// Stats block on Customer Detail (plan 8.12, F19):
///
///   12 orders · Rs. 27600 · avg Rs. 2300
///   Favorite: Fajita · Rs. 1850 unpaid (1 order)
///
/// Figures come from `customerStatsProvider` (cancelled orders are
/// excluded there, per plan 8.8). Money formatting follows the app —
/// `Rs. ` plus a whole-rupee figure, no thousands separators (order
/// screens, customer_unpaid_banner.dart). The unpaid segment appears
/// only when something is owed; the Favorite segment only when the
/// customer has ordered items.
class CustomerStatsCard extends StatelessWidget {
  final CustomerStats stats;

  const CustomerStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (stats.orderCount == 0) {
      return Text(
        'No orders yet',
        key: const Key('customer_stats_empty'),
        style: textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final orderWord = stats.orderCount == 1 ? 'order' : 'orders';
    final summary = '${stats.orderCount} $orderWord · '
        'Rs. ${stats.totalSpent.toStringAsFixed(0)} · '
        'avg Rs. ${stats.averageOrderValue.toStringAsFixed(0)}';

    final detailSegments = <String>[];
    if (stats.favoriteFlavor != null) {
      detailSegments.add('Favorite: ${stats.favoriteFlavor}');
    }
    if (stats.unpaidOrderCount > 0) {
      final unpaidWord = stats.unpaidOrderCount == 1 ? 'order' : 'orders';
      detailSegments.add(
        'Rs. ${stats.unpaidAmount.toStringAsFixed(0)} unpaid '
        '(${stats.unpaidOrderCount} $unpaidWord)',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summary, style: textTheme.bodyLarge),
        if (detailSegments.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            detailSegments.join(' · '),
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
