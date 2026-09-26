import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_data.dart';
import '../providers/order_draft_provider.dart';

class DeliveryPicker extends ConsumerWidget {
  const DeliveryPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftProvider);
    final notifier = ref.read(orderDraftProvider.notifier);

    final options = [
      const _DeliveryOption(
        label: 'Pickup',
        charge: MenuData.pickupCharge,
      ),
      ...MenuData.deliveryCharges.map(
        (charge) => _DeliveryOption(
          label: 'Delivery — Rs. ${charge.toStringAsFixed(0)}',
          charge: charge,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Row(
          children: [
            const Icon(Icons.moped_outlined),
            const SizedBox(width: 8),
            Text(
              'Delivery',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<double>(
          initialValue: draft.deliveryCharge,
          decoration: const InputDecoration(
            labelText: 'Delivery Charge',
            border: OutlineInputBorder(),
          ),
          items: options.map((option) {
            return DropdownMenuItem<double>(
              value: option.charge,
              child: Text(option.label),
            );
          }).toList(),
          onChanged: (charge) {
            if (charge == null) {
              return;
            }

            notifier.setDeliveryCharge(charge);
          },
        ),
      ],
    );
  }
}

class _DeliveryOption {
  final String label;
  final double charge;

  const _DeliveryOption({
    required this.label,
    required this.charge,
  });
}