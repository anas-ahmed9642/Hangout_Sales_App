import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hangout_sales_app/features/orders/models/deal.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/topping_selection.dart';

import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/menu_data.dart';
import '../models/order.dart';
import '../models/order_draft_entry.dart';
import '../models/pizza_size.dart';
import '../providers/order_edit_provider.dart';
import '../providers/order_repository_provider.dart';
import '../widgets/delivery_area_sheet.dart';

class EditOrderScreen extends ConsumerStatefulWidget {
  final Order order;

  const EditOrderScreen({super.key, required this.order});

  @override
  ConsumerState<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends ConsumerState<EditOrderScreen> {
  bool _isSaving = false;

  Future<void> _save() async {
    final notifier = ref.read(orderEditProvider(widget.order).notifier);

    if (!notifier.canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notifier.validationErrors.join(' '))),
      );
      return;
    }

    final reason = await _requestChangeReason();

    if (!mounted || reason == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final editedOrder = notifier.buildEditedOrder();

      final repository = ref.read(orderRepositoryProvider);

      await repository.updateOrder(widget.order.id, {
        'customerName': editedOrder.customerName,
        'customerPhone': editedOrder.customerPhone,
        'customerAddress': editedOrder.customerAddress,
        'deliveryAreaId': editedOrder.deliveryAreaId,
        'deliveryAreaName': editedOrder.deliveryAreaName,
        'deliveryNotes': editedOrder.deliveryNotes,
        'items': editedOrder.items.map(_orderItemToMap).toList(),
        'deals': editedOrder.deals.map(_dealToMap).toList(),
        'additionalDrinks': editedOrder.additionalDrinks,
        'additionalDipSauceCount': editedOrder.additionalDipSauceCount,
        'deliveryCharge': editedOrder.deliveryCharge,
        'total': editedOrder.total,
      }, changeReason: reason);

      if (!mounted) {
        return;
      }

      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded),
                SizedBox(width: 12),
                Expanded(child: Text('Order updated successfully.')),
              ],
            ),
          ),
        );

      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Order update failed: $error\n$stackTrace');
      // ...rest of your existing catch block unchanged
      if (!mounted) {
        return;
      }

      HapticFeedback.heavyImpact();

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            content: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unable to update order: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Future<String?> _requestChangeReason() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reason for edit'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Why is this order being changed?',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reason = controller.text.trim();

                if (reason.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(reason);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Map<String, dynamic> _toppingToMap(ToppingSelection topping) {
    return {
      'toppingId': topping.toppingId,
      'toppingName': topping.toppingName,
      'priceAtOrderTime': topping.priceAtOrderTime,
    };
  }

 Map<String, dynamic> _orderItemToMap(OrderItem item) {
  return {
    'flavorId': item.flavorId,
    'flavorName': item.flavorName,
    'flavorPriceExtra': item.flavorPriceExtra,
    'size': item.size.name,
    'toppings': item.toppings?.map(_toppingToMap).toList(),
    'quantity': item.quantity,
    'unitPrice': item.unitPrice,
  };
}

Map<String, dynamic> _dealToMap(Deal deal) {
  return {
    'id': deal.id,
    'name': deal.name,
    'price': deal.price,
    'pizzaSizes': deal.pizzaSizes.map((size) => size.name).toList(),
    'dipSauceCount': deal.dipSauceCount,
    'drinkSize': deal.drinkSize,
  };
}

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(orderEditProvider(widget.order));

    final notifier = ref.read(orderEditProvider(widget.order).notifier);

    return Scaffold(
      appBar: const HangoutAppBar(title: 'Edit Order', showBackButton: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EditHeader(order: widget.order),
              const SizedBox(height: 20),

              _EditItemsSection(entries: draft.entries, notifier: notifier),

              const SizedBox(height: 24),

              _AdditionalItemsEditor(draft: draft, notifier: notifier),

              const SizedBox(height: 24),

              _CustomerEditor(draft: draft, notifier: notifier),

              const SizedBox(height: 24),

              _DeliveryEditor(
                charge: draft.deliveryCharge,
                onChanged: notifier.setDeliveryCharge,
                areaName: draft.deliveryAreaName,
                onAreaTap: () => showDeliveryAreaSheet(
                  context,
                  onAreaSelected: (area) => notifier.setDeliveryArea(
                    areaId: area?.id,
                    areaName: area?.name,
                    defaultCharge: area?.defaultCharge,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _EditSummary(
                total: notifier.total,
                pizzaSubtotal: notifier.pizzaSubtotal,
                drinksTotal: notifier.additionalDrinksTotal,
                dipTotal: notifier.additionalDipSauceTotal,
                delivery: draft.deliveryCharge,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _isSaving || !notifier.canSave ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? 'Saving…' : 'Save Changes'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditHeader extends StatelessWidget {
  final Order order;

  const _EditHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              size: 30,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editing ${order.orderNumber}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Changes will be recorded in order history.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItemsSection extends StatelessWidget {
  final List<OrderDraftEntry> entries;
  final OrderEditNotifier notifier;

  const _EditItemsSection({required this.entries, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...entries.map(
          (entry) => _EditEntryCard(entry: entry, notifier: notifier),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showAddItemMenu(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Item'),
        ),
      ],
    );
  }

  void _showAddItemMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Add to Order',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...MenuData.deals.map(
                (deal) => ListTile(
                  leading: const Icon(Icons.local_offer_outlined),
                  title: Text(deal.name),
                  subtitle: Text('Rs. ${deal.price.toStringAsFixed(0)}'),
                  onTap: () {
                    notifier.addDeal(deal);
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              ...PizzaSize.values.map(
                (size) => ListTile(
                  leading: const Icon(Icons.local_pizza_outlined),
                  title: Text('${_sizeLabel(size)} Pizza'),
                  subtitle: Text(
                    'Rs. ${(MenuData.pizzaPrices[size] ?? 0).toStringAsFixed(0)}',
                  ),
                  onTap: () {
                    notifier.addStandalonePizza(size);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _sizeLabel(PizzaSize size) {
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

class _EditEntryCard extends StatelessWidget {
  final OrderDraftEntry entry;
  final OrderEditNotifier notifier;

  const _EditEntryCard({required this.entry, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final isDeal = entry.deal != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isDeal
                        ? entry.deal!.name
                        : '${_sizeLabel(entry.standalonePizzaSize!)} Pizza',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: () {
                    notifier.removeEntry(entry.id);
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...List.generate(entry.flavorIds.length, (pizzaIndex) {
              final selected = entry.flavorIds[pizzaIndex];

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pizza ${pizzaIndex + 1}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selected,
                      decoration: const InputDecoration(
                        labelText: 'Flavor',
                        border: OutlineInputBorder(),
                      ),
                      items: MenuData.flavors
                          .map(
                            (flavor) => DropdownMenuItem<String>(
                              value: flavor.id,
                              child: Text(flavor.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        notifier.setFlavor(entry.id, pizzaIndex, value);
                      },
                    ),
                    const SizedBox(height: 8),
                    _ToppingsEditor(
                      entry: entry,
                      pizzaIndex: pizzaIndex,
                      notifier: notifier,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _sizeLabel(PizzaSize size) {
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

class _ToppingsEditor extends StatelessWidget {
  final OrderDraftEntry entry;
  final int pizzaIndex;
  final OrderEditNotifier notifier;

  const _ToppingsEditor({
    required this.entry,
    required this.pizzaIndex,
    required this.notifier,
  });

  static const options = [
    ('cheese', 'Extra Cheese'),
    ('meat', 'Extra Meat'),
    ('veggie', 'Extra Veggie'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = entry.toppings[pizzaIndex];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.any((item) => item.toppingId == option.$1);

        return FilterChip(
          label: Text(option.$2),
          selected: isSelected,
          onSelected: (value) {
            if (value) {
              notifier.addTopping(entry.id, pizzaIndex, option.$1, option.$2);
            } else {
              notifier.removeTopping(entry.id, pizzaIndex, option.$1);
            }
          },
        );
      }).toList(),
    );
  }
}

class _AdditionalItemsEditor extends StatelessWidget {
  final dynamic draft;
  final OrderEditNotifier notifier;

  const _AdditionalItemsEditor({required this.draft, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...MenuData.drinkPrices.entries.map((drink) {
              final quantity = draft.additionalDrinks[drink.key] ?? 0;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_drinkLabel(drink.key)),
                subtitle: Text('Rs. ${drink.value.toStringAsFixed(0)} each'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: quantity == 0
                          ? null
                          : () {
                              notifier.removeAdditionalDrink(drink.key);
                            },
                      icon: const Icon(Icons.remove_rounded),
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {
                        notifier.addAdditionalDrink(drink.key);
                      },
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Additional Dip Sauce'),
              subtitle: Text(
                'Rs. ${MenuData.dipSaucePrice.toStringAsFixed(0)} each',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: draft.additionalDipSauceCount == 0
                        ? null
                        : () {
                            notifier.setAdditionalDipSauceCount(
                              draft.additionalDipSauceCount - 1,
                            );
                          },
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Text(
                    '${draft.additionalDipSauceCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      notifier.setAdditionalDipSauceCount(
                        draft.additionalDipSauceCount + 1,
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _drinkLabel(String id) {
    switch (id) {
      case 'drink_345ml':
        return '345ml Drink';
      case 'drink_1ltr':
        return '1L Drink';
      case 'drink_1.5ltr':
        return '1.5L Drink';
      default:
        return id;
    }
  }
}

class _CustomerEditor extends StatelessWidget {
  final dynamic draft;
  final OrderEditNotifier notifier;

  const _CustomerEditor({required this.draft, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: draft.customerName ?? '',
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setCustomerName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: draft.customerPhone ?? '',
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setCustomerPhone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: draft.customerAddress ?? '',
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setCustomerAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: draft.deliveryNotes ?? '',
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Delivery notes',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setDeliveryNotes,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryEditor extends StatelessWidget {
  final double charge;
  final ValueChanged<double> onChanged;
  final String? areaName;
  final VoidCallback onAreaTap;

  const _DeliveryEditor({
    required this.charge,
    required this.onChanged,
    required this.areaName,
    required this.onAreaTap,
  });

  @override
  Widget build(BuildContext context) {
    final options = [MenuData.pickupCharge, ...MenuData.deliveryCharges];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (charge != MenuData.pickupCharge) ...[
              TextFormField(
                key: ValueKey(areaName),
                readOnly: true,
                initialValue: areaName,
                decoration: const InputDecoration(
                  labelText: 'Delivery area (optional)',
                  hintText: 'Select area',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                onTap: onAreaTap,
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<double>(
              key: ValueKey(charge),
              initialValue: options.contains(charge) ? charge : null,
              decoration: const InputDecoration(
                labelText: 'Delivery Charge',
                border: OutlineInputBorder(),
              ),
              items: options.map((value) {
                final label = value == MenuData.pickupCharge
                    ? 'Pickup'
                    : 'Delivery — Rs. ${value.toStringAsFixed(0)}';
                return DropdownMenuItem<double>(
                  value: value,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSummary extends StatelessWidget {
  final double total;
  final double pizzaSubtotal;
  final double drinksTotal;
  final double dipTotal;
  final double delivery;

  const _EditSummary({
    required this.total,
    required this.pizzaSubtotal,
    required this.drinksTotal,
    required this.dipTotal,
    required this.delivery,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _row(context, 'Pizza subtotal', pizzaSubtotal),
            _row(context, 'Additional drinks', drinksTotal),
            _row(context, 'Additional dip sauce', dipTotal),
            _row(context, 'Delivery', delivery),
            const Divider(height: 28),
            _row(context, 'Updated Total', total, total: true),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    double value, {
    bool total = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: total
                  ? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : null,
            ),
          ),
          Text(
            'Rs. ${value.toStringAsFixed(0)}',
            style: total
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
