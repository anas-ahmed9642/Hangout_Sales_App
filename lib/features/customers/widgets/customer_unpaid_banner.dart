import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customer_unpaid_provider.dart';

/// Warning banner shown when a picked customer has unpaid orders
/// (plan 8.9, F6): `Rs. 1850 unpaid across 1 order`.
///
/// Informational only — never blocks saving. Hidden while loading, on
/// error, and when nothing is unpaid. Visual language mirrors the
/// delivery-notes banner in customer_form.dart.
class CustomerUnpaidBanner extends ConsumerWidget {
  final String phone;

  const CustomerUnpaidBanner({super.key, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(customerUnpaidProvider(phone));

    if (!summary.hasUnpaid) {
      return const SizedBox.shrink();
    }

    final orderWord = summary.count == 1 ? 'order' : 'orders';

    // Self-spacing: 8px top margin when visible; SizedBox.shrink (no
    // margin) when hidden, so no phantom gap for order-less customers.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 18,
            color: Colors.amber.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rs. ${summary.amount.toStringAsFixed(0)} unpaid across '
              '${summary.count} $orderWord',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}