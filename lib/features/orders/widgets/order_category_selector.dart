import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/deal.dart';
import '../models/menu_data.dart';
import '../models/pizza_size.dart';
import '../providers/order_draft_provider.dart';

class OrderCategorySelector extends ConsumerWidget {
  const OrderCategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(orderDraftProvider.notifier);

    final standardDeals = MenuData.deals
        .where((deal) => !deal.id.startsWith('party_'))
        .toList();

    final partyDeals = MenuData.deals
        .where((deal) => deal.id.startsWith('party_'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add to Order',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),

        _DealGroup(
          title: 'Standard Deals',
          deals: standardDeals,
          onDealSelected: notifier.addDeal,
        ),

        const SizedBox(height: 24),

        _DealGroup(
          title: 'Party Deals',
          deals: partyDeals,
          onDealSelected: notifier.addDeal,
        ),

        const SizedBox(height: 24),

        Text(
          'Standalone Pizza',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PizzaSize.values.map((size) {
            return OutlinedButton(
              onPressed: () {
                notifier.addStandalonePizza(size);
              },
              child: Text(_pizzaSizeLabel(size)),
            );
          }).toList(),
        ),
      ],
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

class _DealGroup extends StatelessWidget {
  final String title;
  final List<Deal> deals;
  final ValueChanged<Deal> onDealSelected;

  const _DealGroup({
    required this.title,
    required this.deals,
    required this.onDealSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 700 ? 3 : 2;
            const spacing = 12.0;

            final cardWidth =
                (constraints.maxWidth - ((columns - 1) * spacing)) /
                    columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: deals.map((deal) {
                return SizedBox(
                  width: cardWidth,
                  child: _DealCard(
                    deal: deal,
                    onTap: () => onDealSelected(deal),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

  class _DealCard extends StatelessWidget {
    final Deal deal;
    final VoidCallback onTap;

    const _DealCard({
      required this.deal,
      required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),

                Text(
                  'Rs. ${deal.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 10),

                Text(
                  _pizzaDescription(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                if (deal.dipSauceCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${deal.dipSauceCount} dip sauce'
                    '${deal.dipSauceCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],

                if (deal.drinkSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _drinkLabel(deal.drinkSize!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    String _pizzaDescription() {
      final counts = <PizzaSize, int>{};

      for (final size in deal.pizzaSizes) {
        counts[size] = (counts[size] ?? 0) + 1;
      }

      final parts = <String>[];

      for (final size in PizzaSize.values) {
        final count = counts[size] ?? 0;

        if (count == 0) {
          continue;
        }

        final label = _pizzaSizeLabel(size);

        parts.add(
          '$count × $label',
        );
      }

      return parts.join(' • ');
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

    String _drinkLabel(String drinkId) {
      switch (drinkId) {
        case 'drink_345ml':
          return '345ml drink';
        case 'drink_1ltr':
          return '1L drink';
        case 'drink_1.5ltr':
          return '1.5L drink';
        default:
          return drinkId;
      }
    }
  }