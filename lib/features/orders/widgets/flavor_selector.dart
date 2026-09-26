import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/menu_data.dart';
import '../models/order_draft_entry.dart';
import '../providers/order_draft_provider.dart';

class FlavorSelector extends ConsumerWidget {
  final OrderDraftEntry entry;

  const FlavorSelector({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(orderDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        entry.flavorIds.length,
        (pizzaIndex) {
          final selectedFlavorId = entry.flavorIds[pizzaIndex];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: selectedFlavorId,
              decoration: InputDecoration(
                labelText: 'Pizza ${pizzaIndex + 1} Flavor',
                border: const OutlineInputBorder(),
              ),
              items: MenuData.flavors.map((flavor) {
                return DropdownMenuItem<String>(
                  value: flavor.id,
                  child: Text(flavor.name),
                );
              }).toList(),
              onChanged: (flavorId) {
                if (flavorId == null) {
                  return;
                }

                notifier.setFlavor(
                  entry.id,
                  pizzaIndex,
                  flavorId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
