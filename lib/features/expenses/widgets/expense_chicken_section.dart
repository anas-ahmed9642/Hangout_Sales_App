import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chicken_purchase_line.dart';
import '../providers/expense_draft_provider.dart';

/// Entry form for [ExpenseEntryShape.chicken]: title, price per kg,
/// and a dynamic list of chicken lines (type + kg).
///
/// Only the small "new line" row keeps local controllers; everything
/// committed lives in the draft.
class ExpenseChickenSection extends ConsumerStatefulWidget {
  const ExpenseChickenSection({super.key});

  @override
  ConsumerState<ExpenseChickenSection> createState() =>
      _ExpenseChickenSectionState();
}

class _ExpenseChickenSectionState
    extends ConsumerState<ExpenseChickenSection> {
  String _selectedType = chickenTypes.first;
  final _kgController = TextEditingController();

  @override
  void dispose() {
    _kgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(expenseDraftProvider.notifier);
    final draft = ref.watch(expenseDraftProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chicken Purchase',
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
          key: const Key('expense_price_per_kg_field'),
          decoration: const InputDecoration(
            labelText: 'Price per kg (Rs.)',
            border: OutlineInputBorder(),
          ),
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) =>
              notifier.setPricePerKg(double.tryParse(value) ?? 0),
        ),
        const SizedBox(height: 16),
        Text(
          'Chicken lines',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...draft.chickenLines.asMap().entries.map((entry) {
          final index = entry.key;
          final line = entry.value;
          final lineTotal = line.quantityKg * draft.pricePerKg;

          return Card(
            child: ListTile(
              title: Text(line.chickenType),
              subtitle: Text('${line.quantityKg} kg'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rs. ${lineTotal.toStringAsFixed(0)}'),
                  IconButton(
                    key: Key('remove_chicken_line_$index'),
                    tooltip: 'Remove line',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notifier.removeChickenLine(index),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                key: const Key('chicken_type_field'),
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Chicken type',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in chickenTypes)
                    DropdownMenuItem(value: type, child: Text(type)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('chicken_kg_field'),
                controller: _kgController,
                decoration: const InputDecoration(
                  labelText: 'Kg',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              key: const Key('add_chicken_line_button'),
              onPressed: () {
                final kg = int.tryParse(_kgController.text.trim()) ?? 0;
                if (kg <= 0) {
                  return;
                }
                notifier.addChickenLine(
                  chickenType: _selectedType,
                  quantityKg: kg,
                );
                _kgController.clear();
              },
              child: const Text('Add'),
            ),
          ],
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
