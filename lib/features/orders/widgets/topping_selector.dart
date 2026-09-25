import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_draft_entry.dart';
import '../providers/order_draft_provider.dart';

class ToppingSelector extends ConsumerWidget {
  final OrderDraftEntry entry;
  final int pizzaIndex;

  const ToppingSelector({
    super.key,
    required this.entry,
    required this.pizzaIndex,
  });

  static const List<_ToppingOption> _options = [
    _ToppingOption(
      id: 'cheese',
      name: 'Extra Cheese',
    ),
    _ToppingOption(
      id: 'meat',
      name: 'Extra Meat',
    ),
    _ToppingOption(
      id: 'veggie',
      name: 'Extra Veggie',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(orderDraftProvider.notifier);

    if (pizzaIndex < 0 || pizzaIndex >= entry.toppings.length) {
      return const SizedBox.shrink();
    }

    final selectedToppings = entry.toppings[pizzaIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Toppings',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((option) {
            final isSelected = selectedToppings.any(
              (topping) => topping.toppingId == option.id,
            );

            return FilterChip(
              label: Text(option.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  notifier.addTopping(
                    entry.id,
                    pizzaIndex,
                    option.id,
                    option.name,
                  );
                } else {
                  notifier.removeTopping(
                    entry.id,
                    pizzaIndex,
                    option.id,
                  );
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ToppingOption {
  final String id;
  final String name;

  const _ToppingOption({
    required this.id,
    required this.name,
  });
}