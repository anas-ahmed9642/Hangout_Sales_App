import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/expense_draft_provider.dart';

/// Entry form for [ExpenseEntryShape.wages]: title, worker name,
/// amount, notes.
class ExpenseWagesSection extends ConsumerWidget {
  const ExpenseWagesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(expenseDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Worker Wages',
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
          key: const Key('expense_worker_name_field'),
          decoration: const InputDecoration(
            labelText: 'Worker name',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setWorkerName,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('expense_amount_field'),
          decoration: const InputDecoration(
            labelText: 'Amount (Rs.)',
            border: OutlineInputBorder(),
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
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
