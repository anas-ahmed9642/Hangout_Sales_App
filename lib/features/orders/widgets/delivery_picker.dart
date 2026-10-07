import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_data.dart';
import '../providers/order_draft_provider.dart';
import 'delivery_area_sheet.dart';

class DeliveryPicker extends ConsumerWidget {
  const DeliveryPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(orderDraftProvider);
    final notifier = ref.read(orderDraftProvider.notifier);

    final isPickup = draft.deliveryCharge == MenuData.pickupCharge;

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
        // Optional area field (plan 8.3). Hidden for Pickup; the notifier
        // clears the area when the charge becomes Pickup.
        if (!isPickup) ...[
          TextFormField(
            key: ValueKey(draft.deliveryAreaId),
            readOnly: true,
            initialValue: draft.deliveryAreaName,
            decoration: const InputDecoration(
              labelText: 'Delivery area (optional)',
              hintText: 'Select area',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            onTap: () => showDeliveryAreaSheet(
              context,
              onAreaSelected: (area) => notifier.setDeliveryArea(
                areaId: area?.id,
                areaName: area?.name,
                defaultCharge: area?.defaultCharge,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<double>(
          // Finding 4: initialValue is read once, so without this key a
          // charge set programmatically (autofill, area selection) would
          // not be reflected in the dropdown.
          key: ValueKey(draft.deliveryCharge),
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
