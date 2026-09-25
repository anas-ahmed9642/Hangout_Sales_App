import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_data.dart';
import '../providers/order_draft_provider.dart';

class AdditionalItemsSection extends ConsumerWidget {
  const AdditionalItemsSection({super.key});

  static const List<_DrinkOption> _drinkOptions = [
    _DrinkOption(
      id: 'drink_345ml',
      label: '345ml Drink',
    ),
    _DrinkOption(
      id: 'drink_1ltr',
      label: '1L Drink',
    ),
    _DrinkOption(
      id: 'drink_1.5ltr',
      label: '1.5L Drink',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftProvider);
    final notifier = ref.read(orderDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Items',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),

        Text(
          'Drinks',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        ..._drinkOptions.map(
          (option) {
            final quantity = draft.additionalDrinks[option.id] ?? 0;
            final price = MenuData.drinkPrices[option.id] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(option.label),
                subtitle: Text(
                  'Rs. ${price.toStringAsFixed(0)} each',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Remove drink',
                      onPressed: quantity > 0
                          ? () {
                              notifier.removeAdditionalDrink(option.id);
                            }
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add drink',
                      onPressed: () {
                        notifier.addAdditionalDrink(option.id);
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        Text(
          'Dip Sauce',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        Card(
          child: ListTile(
            title: const Text('Additional Dip Sauce'),
            subtitle: Text(
              'Rs. ${MenuData.dipSaucePrice.toStringAsFixed(0)} each',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Remove dip sauce',
                  onPressed: draft.additionalDipSauceCount > 0
                      ? () {
                          notifier.setAdditionalDipSauceCount(
                            draft.additionalDipSauceCount - 1,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '${draft.additionalDipSauceCount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  tooltip: 'Add dip sauce',
                  onPressed: () {
                    notifier.setAdditionalDipSauceCount(
                      draft.additionalDipSauceCount + 1,
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DrinkOption {
  final String id;
  final String label;

  const _DrinkOption({
    required this.id,
    required this.label,
  });
}