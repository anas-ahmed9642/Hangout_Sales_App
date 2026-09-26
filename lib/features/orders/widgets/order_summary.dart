import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_draft_entry.dart';
import '../models/pizza_size.dart';
import '../providers/order_draft_provider.dart';

class OrderSummary extends ConsumerWidget {
  const OrderSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftProvider);
    final notifier = ref.read(orderDraftProvider.notifier);

    // Grab validation state for the bottom of the summary
    final validationErrors = notifier.validationErrors;
    final canConfirm = notifier.canConfirm;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // --- UPGRADED EMPTY STATE ---
            if (draft.entries.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_basket_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
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
              )
            else
              ...draft.entries.map(
                (entry) => _SummaryEntryRow(
                  entry: entry,
                  price: notifier.entryTotal(entry),
                ),
              ),

            if (draft.entries.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
            ],

            _SummaryRow(
              label: 'Pizza subtotal',
              value: notifier.pizzaSubtotal,
            ),
            _SummaryRow(
              label: 'Additional drinks',
              value: notifier.additionalDrinksTotal,
            ),
            _SummaryRow(
              label: 'Additional dip sauce',
              value: notifier.additionalDipSauceTotal,
            ),
            _SummaryRow(
              label: 'Delivery',
              value: draft.deliveryCharge,
            ),

            const Divider(),

            _SummaryRow(
              label: 'Total',
              // Note: using notifier.grandTotal here just in case draft.total isn't exposed in your model
              value: notifier.grandTotal, 
              isTotal: true,
            ),
            
            const SizedBox(height: 20),

            // --- RESTORED VALIDATION LOGIC ---
            if (canConfirm)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order is ready for confirmation.',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              )
            else ...[
              Text(
                'Order needs attention',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              const SizedBox(height: 8),
              ...validationErrors.map(
                (error) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- UPGRADED ERROR ICON ---
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      // ---------------------------
                      Expanded(
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
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

class _SummaryEntryRow extends StatelessWidget {
  final OrderDraftEntry entry;
  final double price;

  const _SummaryEntryRow({
    required this.entry,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final title = _entryTitle(entry);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _EntryTypeBadge(
                      isDeal: entry.deal != null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Rs. ${price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _entryTitle(OrderDraftEntry entry) {
    if (entry.deal != null) {
      return entry.deal!.name;
    }

    final size = entry.standalonePizzaSize;

    if (size == null) {
      return 'Pizza';
    }

    return '${_pizzaSizeLabel(size)} Pizza';
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

class _EntryTypeBadge extends StatelessWidget {
  final bool isDeal;

  const _EntryTypeBadge({
    required this.isDeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Text(
        isDeal ? 'DEAL' : 'PIZZA',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: isTotal
                  ? Theme.of(context).textTheme.titleMedium
                  : null,
            ),
          ),
          Text(
            'Rs. ${value.toStringAsFixed(0)}',
            style: isTotal
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}