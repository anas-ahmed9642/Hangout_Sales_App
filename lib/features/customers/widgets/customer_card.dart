import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../delivery_areas/models/delivery_area.dart';
import '../../delivery_areas/providers/delivery_areas_provider.dart';
import '../../orders/models/order.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import '../providers/customer_orders_provider.dart';
import 'last_order_preview.dart';

/// One row in the Customers list (plan 8.11):
///
///   Ahmed Raza          03001234567
///   Sector 11B · last order 3 days ago
///
/// The area segment names the default address's area, resolved
/// through [deliveryAreasProvider] (all areas, so a deactivated area
/// still names a saved address — the `_findArea` precedent). It is
/// omitted when the customer has no address, the address has no
/// area, or the areas have not loaded. In the win-back slice
/// ([showOrderCount]) the row also carries the derived non-cancelled
/// order count once that customer's orders have loaded.
///
/// Tap is wired by the caller: the detail screen (and its route) is
/// Phase 8, so the list screen passes no onTap yet and the row is
/// display-only apart from its archive/restore menu.
class CustomerCard extends ConsumerWidget {
  final Customer customer;
  final bool showOrderCount;
  final VoidCallback? onTap;
  final VoidCallback onToggleArchived;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onToggleArchived,
    this.showOrderCount = false,
    this.onTap,
  });

  CustomerAddress? get _defaultAddress {
    final addresses = customer.addresses;
    if (addresses.isEmpty) return null;
    for (final address in addresses) {
      if (address.id == customer.defaultAddressId) return address;
    }
    return addresses.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    String? areaName;
    final areaId = _defaultAddress?.areaId;
    if (areaId != null) {
      final areas = ref.watch(deliveryAreasProvider).valueOrNull ??
          const <DeliveryArea>[];
      for (final area in areas) {
        if (area.id == areaId) {
          areaName = area.name;
          break;
        }
      }
    }

    final segments = <String>[];
    if (areaName != null) {
      segments.add(areaName);
    }
    final lastOrderAt = customer.lastOrderAt;
    segments.add(
      lastOrderAt == null
          ? 'No orders yet'
          : 'last order ${relativeTimeAgo(lastOrderAt)}',
    );
    if (showOrderCount) {
      final orders =
          ref.watch(customerOrdersProvider(customer.phone)).valueOrNull;
      if (orders != null) {
        final count = orders
            .where((order) => order.status != OrderStatus.cancelled)
            .length;
        segments.add('$count ${count == 1 ? 'order' : 'orders'}');
      }
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('customer_card_${customer.phone}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name ?? 'Unnamed customer',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  customer.archived ? Colors.black54 : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          customer.phone,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      segments.join(' · '),
                      style: textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (customer.mergedInto != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Merged into ${customer.mergedInto}',
                        style: textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // A merged-away customer gets no menu: restoring it
              // would resurrect a merged identity into the active
              // list. Merge lands in Phase 12; the guard lands now.
              if (customer.mergedInto == null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Customer actions',
                  onSelected: (value) {
                    if (value == 'toggleArchived') {
                      onToggleArchived();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'toggleArchived',
                      child: Text(customer.archived ? 'Restore' : 'Archive'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
