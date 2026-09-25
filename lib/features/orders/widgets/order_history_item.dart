import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';

class OrderHistoryItem extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderHistoryItem({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customerName =
        order.customerName?.trim().isNotEmpty == true
            ? order.customerName!.trim()
            : 'Walk-in Customer';

    final formattedDate =
        DateFormat('dd MMM yyyy · hh:mm a').format(order.createdAt);

    final itemCount = order.items.length;
    final itemSummary =
        '$itemCount item${itemCount == 1 ? '' : 's'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rs. ${order.total.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$formattedDate · $itemSummary',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _OrderStatusBadge(status: order.status),
                    // Only rendered when unpaid — a paid order's card
                    // looks exactly as it did before this change.
                    // Payment status is a safety net for cashiers who
                    // aren't in the "Unpaid Only" filter, not a
                    // replacement for it.
                    if (order.paymentStatus == PaymentStatus.unpaid) ...[
                      const SizedBox(width: 6),
                      const _UnpaidBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      OrderStatus.pending => 'Pending',
      OrderStatus.completed => 'Completed',
      OrderStatus.cancelled => 'Cancelled',
    };

    final icon = switch (status) {
      OrderStatus.pending => Icons.pending_outlined,
      OrderStatus.completed => Icons.check_circle_outline,
      OrderStatus.cancelled => Icons.cancel_outlined,
    };

    final color = switch (status) {
      OrderStatus.pending => Colors.orange.shade700,
      OrderStatus.completed => Colors.green.shade700,
      OrderStatus.cancelled => Theme.of(context).colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _UnpaidBadge extends StatelessWidget {
  const _UnpaidBadge();

  // Deliberately NOT orange — OrderStatus.pending already owns that
  // color above. A pending + unpaid order needs two badges a cashier
  // can tell apart at a glance, not two orange pills that blend
  // together.
  static const _color = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.money_off_rounded, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            'Unpaid',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}