import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_data.dart';
import '../models/order_draft_entry.dart';
import '../models/pizza_size.dart';
import '../providers/order_draft_provider.dart';

// We must import the editors so the cashier can actually use them!
import 'flavor_selector.dart';
import 'topping_selector.dart';

class OrderEntriesSection extends ConsumerWidget {
  const OrderEntriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftProvider);
    final notifier = ref.read(orderDraftProvider.notifier);
if (draft.entries.isEmpty) {
      return Card( // Note: 'const' removed here
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_basket_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No items added yet.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Order',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...draft.entries.map(
          (entry) => _OrderEntryCard(
            entry: entry,
            onRemove: () {
              notifier.removeEntry(entry.id);
            },
          ),
        ),
      ],
    );
  }
}

class _OrderEntryCard extends StatelessWidget {
  final OrderDraftEntry entry;
  final VoidCallback onRemove;

  const _OrderEntryCard({
    required this.entry,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDeal = entry.deal != null;

    final title = isDeal
        ? entry.deal!.name
        : '${_pizzaSizeLabel(entry.standalonePizzaSize!)} Pizza';

    final basePrice = isDeal
        ? entry.deal!.price
        : MenuData.pizzaPrices[entry.standalonePizzaSize!] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- YOUR CUSTOM HEADER ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EntryTypeBadge(
                  label: isDeal ? 'DEAL' : 'PIZZA',
                  icon: isDeal
                      ? Icons.local_offer_outlined
                      : Icons.local_pizza_outlined,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Base price: Rs. ${basePrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- YOUR CUSTOM READ-ONLY SUMMARY ---
            ...List.generate(
              entry.flavorIds.length,
              (pizzaIndex) {
                final size = isDeal
                    ? entry.deal!.pizzaSizes[pizzaIndex]
                    : entry.standalonePizzaSize!;

                final flavorId = entry.flavorIds[pizzaIndex];

                final flavor = flavorId == null
                    ? 'Flavor not selected'
                    : MenuData.flavors
                        .firstWhere(
                          (item) => item.id == flavorId,
                        )
                        .name;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pizza ${pizzaIndex + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_pizzaSizeLabel(size)} • $flavor',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            if (entry.toppings.any((list) => list.isNotEmpty)) ...[
              const SizedBox(height: 6),
              ...List.generate(
                entry.toppings.length,
                (pizzaIndex) {
                  final toppings = entry.toppings[pizzaIndex];

                  if (toppings.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Pizza ${pizzaIndex + 1}: '
                      '${toppings.map((topping) => topping.toppingName).join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ],

            const Divider(height: 32),

            // --- THE MISSING EDITORS ---
            Text(
              'Customize',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),

            FlavorSelector(
              entry: entry,
            ),

            const SizedBox(height: 8),

            ...List.generate(
              entry.toppings.length,
              (pizzaIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ToppingSelector(
                    entry: entry,
                    pizzaIndex: pizzaIndex,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
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
}

// Your custom badge remains untouched!
class _EntryTypeBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _EntryTypeBadge({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}