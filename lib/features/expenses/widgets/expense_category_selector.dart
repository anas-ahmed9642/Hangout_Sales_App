import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_category.dart';
import '../models/expense_category_display.dart';
import '../providers/expense_draft_provider.dart';

/// Picks the expense category. One tap = [ExpenseDraftNotifier.setCategory],
/// which restarts the draft so stale shape-specific inputs never leak across.
///
/// For catalog-backed categories the catalog stream is pointed at the same
/// category explicitly — no hidden listeners.
class ExpenseCategorySelector extends ConsumerWidget {
  const ExpenseCategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      expenseDraftProvider.select((draft) => draft.category),
    );
    final notifier = ref.read(expenseDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Category',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseCategory.values.map((category) {
            return ChoiceChip(
              label: Text(category.displayName),
              selected: selected == category,
              onSelected: (_) {
                notifier.setCategory(category);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
