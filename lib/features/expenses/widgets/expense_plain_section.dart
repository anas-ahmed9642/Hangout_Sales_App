import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/expense_draft_provider.dart';

/// Entry form for [ExpenseEntryShape.plain]: title + amount + notes.
///
/// Uncontrolled text fields writing straight into the draft notifier.
/// The parent keys this section by category, so switching categories
/// always rebuilds it with fresh, empty fields.
class ExpensePlainSection extends ConsumerWidget {
  const ExpensePlainSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(expenseDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expense Details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('expense_title_field'),
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Morning purchase',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setTitle,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('expense_amount_field'),
          decoration: const InputDecoration(
            labelText: 'Amount (Rs.)',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) =>
              notifier.setAmount(double.tryParse(value) ?? 0),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('expense_notes_field'),
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: notifier.setNotes,
        ),
      ],
    );
  }
}
