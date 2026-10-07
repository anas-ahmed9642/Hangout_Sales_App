import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hangout_sales_app/features/delivery_areas/models/delivery_area.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_areas_provider.dart';


/// Opens the searchable delivery-area bottom sheet (plan 8.3).
Future<void> showDeliveryAreaSheet(
  BuildContext context, {
  required void Function(DeliveryArea?) onAreaSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _DeliveryAreaSheet(onAreaSelected: onAreaSelected),
  );
}

/// Search normalization (plan 6.4): lowercase, strip non-alphanumerics,
/// then a "contains" test. '5c1', '5C/1' and 'sector 5c/1' all match
/// 'Sector 5C/1'.
String _searchKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

class _DeliveryAreaSheet extends ConsumerStatefulWidget {
  final void Function(DeliveryArea?) onAreaSelected;

  const _DeliveryAreaSheet({required this.onAreaSelected});

  @override
  ConsumerState<_DeliveryAreaSheet> createState() =>
      _DeliveryAreaSheetState();
}

class _DeliveryAreaSheetState extends ConsumerState<_DeliveryAreaSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(activeDeliveryAreasProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery area',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search areas',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: areasAsync.when(
                data: (areas) => _buildList(areas),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load areas: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<DeliveryArea> areas) {
    final query = _searchKey(_query);
    final filtered = query.isEmpty
        ? areas
        : areas
            .where((area) => _searchKey(area.name).contains(query))
            .toList();

    return ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          leading: const Icon(Icons.location_off_outlined),
          title: const Text('Not listed / other'),
          subtitle: const Text('Set the charge manually'),
          onTap: () {
            // Unlisted: clear the area, keep the charge as-is (plan 8.3).
            widget.onAreaSelected(null);
            Navigator.pop(context);
          },
        ),
        const Divider(),
        if (filtered.isEmpty)
          const ListTile(
            title: Text('No areas match your search.'),
          )
        else
          for (final area in filtered)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(area.name),
              trailing: Text(
                'Rs. ${area.defaultCharge.toStringAsFixed(0)}',
              ),
              onTap: () {
                widget.onAreaSelected(area);
                Navigator.pop(context);
              },
            ),
      ],
    );
  }
}
