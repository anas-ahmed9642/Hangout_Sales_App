import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/expense_draft_provider.dart';

/// Live total + validation errors for the current draft.
///
/// Watches through the same select-notifier pattern NewOrderScreen uses
/// for its confirm button, so the card rebuilds on every draft change.
class ExpenseSummary extends ConsumerWidget {
  const ExpenseSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      expenseDraftProvider.select(
        (draft) => ref.read(expenseDraftProvider.notifier).computedAmount,
      ),
    );
    final errors = ref.watch(
      expenseDraftProvider.select(
        (draft) => ref.read(expenseDraftProvider.notifier).validationErrors,
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Rs. ${total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...errors.map(
                (error) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
