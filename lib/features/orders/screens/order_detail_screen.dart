import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:hangout_sales_app/features/orders/models/deal.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/screens/edit_order_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // for HapticFeedback
import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/order.dart';
import '../services/order_receipt_service.dart';
import '../providers/order_edit_history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/order_repository_provider.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../services/tcp_printer_transport.dart';
import '../services/thermal_printer_transport.dart'; // for BluetoothThermalPrinterTransport

class OrderDetailScreen extends ConsumerWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedCreatedAt = DateFormat(
      'dd MMM yyyy · hh:mm a',
    ).format(order.createdAt);

    final formattedBusinessDate = DateFormat(
      'dd MMM yyyy',
    ).format(order.businessDate);

    final displayName = order.customerName?.trim().isNotEmpty == true
        ? order.customerName!.trim()
        : 'Walk-in Customer';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
     appBar: HangoutAppBar(
  title: 'Order Details',
  showBackButton: true,
  actions: [
    if (order.status == OrderStatus.pending) ...[
      IconButton(
        tooltip: 'Edit Order',
        icon: const Icon(Icons.edit_outlined),
        onPressed: () async {
          final updated = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => EditOrderScreen(order: order),
            ),
          );

          if (!context.mounted || updated != true) {
            return;
          }

          Navigator.of(context).pop(true);
        },
      ),
      IconButton(
        tooltip: 'Cancel Order',
        icon: const Icon(Icons.cancel_outlined),
        onPressed: () {
          _confirmCancellation(context, ref, order);
        },
      ),
    ],
    _ReprintButton(order: order),
  ],
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderHeader(order: order, formattedCreatedAt: formattedCreatedAt),

            const SizedBox(height: 16),
            if (order.paymentStatus == PaymentStatus.unpaid)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                ), // just vertical spacing

                child: _MarkAsPaidButton(order: order, ref: ref),
              ),
            const SizedBox(height: 16),
            if (order.status == OrderStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _CompleteOrderButton(order: order),
              ),

            const SizedBox(height: 16),

            _OrderInformationSection(
              formattedCreatedAt: formattedCreatedAt,
              formattedBusinessDate: formattedBusinessDate,
            ),

            const SizedBox(height: 16),

            _CustomerInformationSection(
              displayName: displayName,
              phone: order.customerPhone,
              address: order.customerAddress,
            ),

            const SizedBox(height: 16),

            _OrderItemsSection(order: order),

            const SizedBox(height: 16),

            _AdditionalItemsSection(order: order),

            const SizedBox(height: 16),

            _PaymentSummarySection(order: order),

            const SizedBox(height: 16),

            _OrderActivitySection(orderId: order.id),
          ],
        ),
      ),
    );
  }
  Future<void> _confirmCancellation(
  BuildContext context,
  WidgetRef ref,
  Order order,
) async {
  if (order.status != OrderStatus.pending) {
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colorScheme = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.error,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Cancel this order?'),
            ),
          ],
        ),
        content: const Text(
          'This will mark the order as cancelled. '
          'The order will remain in history, but its content can no longer be edited.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Keep Order'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel Order'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  try {
    final repository = ref.read(orderRepositoryProvider);

    await repository.updateOrder(
      order.id,
      {
        'status': OrderStatus.cancelled.name,
      },
      changeReason: 'Order cancelled',
    );

    if (!context.mounted) {
      return;
    }

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              Theme.of(context).colorScheme.inverseSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(
                Icons.cancel_rounded,
                color:
                    Theme.of(context).colorScheme.inversePrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order ${order.orderNumber} cancelled.',
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onInverseSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  } catch (error, stackTrace) {
    debugPrint(
      'Order cancellation failed: $error\n$stackTrace',
    );

    if (!context.mounted) {
      return;
    }

    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              Theme.of(context).colorScheme.errorContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color:
                    Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unable to cancel order: $error',
                  style: TextStyle(
                    color:
                        Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
}

// ─────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────

class _OrderHeader extends StatelessWidget {
  final Order order;
  final String formattedCreatedAt;

  const _OrderHeader({required this.order, required this.formattedCreatedAt});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      'Rs. ${order.total.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  formattedCreatedAt,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusBadge(status: order.status),
                _PaymentStatusBadge(paymentStatus: order.paymentStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      OrderStatus.pending => (
        'Pending',
        Colors.orange,
        Icons.hourglass_top_rounded,
      ),
      OrderStatus.completed => (
        'Completed',
        Colors.green,
        Icons.check_circle_rounded,
      ),
      OrderStatus.cancelled => ('Cancelled', Colors.red, Icons.cancel_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final PaymentStatus paymentStatus;

  const _PaymentStatusBadge({required this.paymentStatus});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (paymentStatus) {
      PaymentStatus.paid => ('Paid', Colors.green, Icons.check_circle_rounded),
      PaymentStatus.unpaid => (
        'Unpaid',
        Colors.red,
        Icons
            .money_off_csred_rounded, // swap for whatever icon your list screen uses
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────
// Order Information
// ─────────────────────────────────────────────────────────────────────────

class _OrderInformationSection extends StatelessWidget {
  final String formattedCreatedAt;
  final String formattedBusinessDate;

  const _OrderInformationSection({
    required this.formattedCreatedAt,
    required this.formattedBusinessDate,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Order Information',
      icon: Icons.info_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'Created', value: formattedCreatedAt),
          const SizedBox(height: 10),
          _DetailRow(label: 'Business Date', value: formattedBusinessDate),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Customer
// ─────────────────────────────────────────────────────────────────────────

class _CustomerInformationSection extends StatelessWidget {
  final String displayName;
  final String? phone;
  final String? address;

  const _CustomerInformationSection({
    required this.displayName,
    required this.phone,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Customer',
      icon: Icons.person_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: 'Name', value: displayName),
          if (phone?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _DetailRow(label: 'Phone', value: phone!.trim()),
          ],
          if (address?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _DetailRow(label: 'Address', value: address!.trim()),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Order Items (pizzas, numbered + deals with detail line)
// ─────────────────────────────────────────────────────────────────────────

class _OrderItemsSection extends StatelessWidget {
  final Order order;

  const _OrderItemsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Order Items',
      icon: Icons.receipt_long_rounded,
      child: order.deals.isEmpty && order.items.isEmpty
          ? Text(
              'No order items recorded.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.deals.map((deal) => _DealRow(deal: deal)),
                if (order.deals.isNotEmpty && order.items.isNotEmpty)
                  const Divider(height: 28),
                ...order.items.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == order.items.length - 1 ? 0 : 14,
                    ),
                    child: _OrderItemRow(index: entry.key, item: entry.value),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DealRow extends StatelessWidget {
  final Deal deal;

  const _DealRow({required this.deal});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final detailParts = <String>[
      '${deal.pizzaSizes.length} pizza${deal.pizzaSizes.length == 1 ? '' : 's'}',
      if (deal.drinkSize != null) _drinkLabel(deal.drinkSize!),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_offer_rounded,
            color: colorScheme.secondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detailParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rs. ${deal.price.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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

class _OrderItemRow extends StatelessWidget {
  final int index;
  final OrderItem item;

  const _OrderItemRow({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_pizzaSizeLabel(item.size)} Pizza · ${item.flavorName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    'Rs. ${item.unitPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (item.toppings != null && item.toppings!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.toppings!
                      .map(
                        (topping) => Chip(
                          label: Text(
                            topping.toppingName,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
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

// ─────────────────────────────────────────────────────────────────────────
// Additional Items
// ─────────────────────────────────────────────────────────────────────────

class _AdditionalItemsSection extends StatelessWidget {
  final Order order;

  const _AdditionalItemsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final drinks = order.additionalDrinks.entries.toList();

    if (drinks.isEmpty && order.additionalDipSauceCount == 0) {
      return const SizedBox.shrink();
    }

    return _DetailCard(
      title: 'Additional Items',
      icon: Icons.local_drink_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...drinks.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DetailRow(
                label: _drinkLabel(entry.key),
                value: 'x${entry.value}',
              ),
            ),
          ),
          if (order.additionalDipSauceCount > 0)
            _DetailRow(
              label: 'Dip Sauce',
              value: 'x${order.additionalDipSauceCount}',
            ),
        ],
      ),
    );
  }
  // Top-level, outside any class — visible to every class in this file

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

// ─────────────────────────────────────────────────────────────────────────
// Payment Summary
// ─────────────────────────────────────────────────────────────────────────

class _PaymentSummarySection extends StatelessWidget {
  final Order order;

  const _PaymentSummarySection({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DetailCard(
      title: 'Order Summary',
      icon: Icons.summarize_outlined,
      child: Column(
        children: [
          _DetailRow(
            label: 'Delivery',
            value: 'Rs. ${order.deliveryCharge.toStringAsFixed(0)}',
          ),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Grand Total',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Rs. ${order.total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared building blocks
// ─────────────────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────
// Reprint action
// ─────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────
// Reprint action (Integrated & Styled)
// ─────────────────────────────────────────────────────────────────────────

class _ReprintButton extends StatefulWidget {
  final Order order;

  const _ReprintButton({required this.order});

  @override
  State<_ReprintButton> createState() => _ReprintButtonState();
}

class _ReprintButtonState extends State<_ReprintButton> {
  bool _isPrinting = false;

  Future<void> _handleReprint() async {
    if (_isPrinting) return;

    HapticFeedback.lightImpact();
    setState(() => _isPrinting = true);

    // Initialize the real service
    final receiptService = OrderReceiptService(
      transport: const BluetoothThermalPrinterTransport(),
    );
    try {
      // The actual network/Bluetooth call to the printer
      await receiptService.reprint(widget.order);

      if (!mounted) return;
      setState(() => _isPrinting = false);

      // Elegant Success Notification
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
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Receipt reprint sent to printer.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPrinting = false);
      HapticFeedback.heavyImpact(); // Distinct physical feedback for errors

      // Elegant Error Notification
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
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unable to print: $error',
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: 'Reprint Receipt',
        onPressed: _handleReprint,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: _isPrinting
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(Icons.print_outlined, key: ValueKey('icon')),
        ),
      ),
    );
  }
}

class _MarkAsPaidButton extends StatefulWidget {
  final Order order;
  final WidgetRef ref;

  const _MarkAsPaidButton({required this.order, required this.ref});

  @override
  State<_MarkAsPaidButton> createState() => _MarkAsPaidButtonState();
}

class _MarkAsPaidButtonState extends State<_MarkAsPaidButton> {
  bool _isUpdating = false;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _isPaid = widget.order.paymentStatus == PaymentStatus.paid;
  }

  Future<void> _confirmMarkAsPaid() async {
    if (_isUpdating || _isPaid) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Mark this order as paid?'),
          content: const Text(
            'This confirms that payment has been received for this order.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Confirm'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _markAsPaid();
  }

  Future<void> _markAsPaid() async {
    if (_isUpdating || _isPaid) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isUpdating = true;
    });

    try {
      final repository = widget.ref.read(orderRepositoryProvider);

      await repository.updateOrder(widget.order.id, {
        'paymentStatus': PaymentStatus.paid.name,
      }, changeReason: 'Marked as paid');

      if (!mounted) return;

      setState(() {
        _isUpdating = false;
        _isPaid = true;
      });

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
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment marked as paid.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isUpdating = false;
      });

      HapticFeedback.heavyImpact();

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
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unable to update payment: $error',
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

  @override
  Widget build(BuildContext context) {
    if (_isPaid) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton.icon(
      onPressed: _isUpdating ? null : _confirmMarkAsPaid,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _isUpdating
            ? const SizedBox(
                key: ValueKey('payment-loading'),
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : const Icon(
                Icons.payments_outlined,
                key: ValueKey('payment-icon'),
              ),
      ),
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          _isUpdating ? 'Updating…' : 'Mark as Paid',
          key: ValueKey(_isUpdating),
        ),
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _OrderActivitySection extends ConsumerWidget {
  final String orderId;

  const _OrderActivitySection({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(orderEditHistoryProvider(orderId));

    return historyAsync.when(
      loading: () => const _ActivityLoading(),
      error: (error, stackTrace) => _ActivityError(
        onRetry: () {
          ref.invalidate(orderEditHistoryProvider(orderId));
        },
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }

        return _OrderActivityCard(entries: entries);
      },
    );
  }
}

class _OrderActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> entries;

  const _OrderActivityCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Order Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...List.generate(entries.length, (index) {
              final entry = entries[index];

              return _ActivityEntry(
                entry: entry,
                isLast: index == entries.length - 1,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ActivityEntry extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isLast;

  const _ActivityEntry({required this.entry, required this.isLast});

  String _formatField(String field) {
    switch (field) {
      case 'paymentStatus':
        return 'Payment Status';
      case 'status':
        return 'Fulfillment Status';
      case 'deliveryCharge':
        return 'Delivery Charge';
      case 'customerName':
        return 'Customer Name';
      case 'customerPhone':
        return 'Customer Phone';
      case 'customerAddress':
        return 'Customer Address';
      case 'total':
        return 'Total';
      default:
        return field;
    }
  }

  String _formatValue(String field, dynamic value) {
    if (value == null) {
      return '—';
    }

    switch (field) {
      case 'items':
        return _formatItems(value);
      case 'deals':
        return _formatDeals(value);
      case 'additionalDrinks':
        return _formatDrinks(value);
      case 'deliveryCharge':
      case 'total':
        return 'Rs. ${(value as num).toStringAsFixed(0)}';
      case 'paid':
      case 'unpaid':
      case 'pending':
      case 'completed':
      case 'cancelled':
        return _capitalize(value.toString());
      default:
        switch (value.toString()) {
          case 'paid':
            return 'Paid';
          case 'unpaid':
            return 'Unpaid';
          case 'pending':
            return 'Pending';
          case 'completed':
            return 'Completed';
          case 'cancelled':
            return 'Cancelled';
          default:
            return value.toString();
        }
    }
  }

  String _formatItems(dynamic value) {
    if (value is! List || value.isEmpty) return 'No items';
    return value
        .map((raw) {
          final item = raw as Map<String, dynamic>;
          final name = item['flavorName'] ?? item['flavorId'] ?? 'Item';
          final size = (item['size'] ?? '').toString();
          final qty = item['quantity'] ?? 1;
          final sizeLabel = size.isNotEmpty ? ' (${_capitalize(size)})' : '';
          return '$name$sizeLabel ×$qty';
        })
        .join(', ');
  }

  String _formatDeals(dynamic value) {
    if (value is! List || value.isEmpty) return 'No deals';
    return value
        .map((raw) {
          final deal = raw as Map<String, dynamic>;
          return (deal['name'] ?? deal['id'] ?? 'Deal').toString();
        })
        .join(', ');
  }

  String _formatDrinks(dynamic value) {
    if (value is! Map || value.isEmpty) return 'None';
    return value.entries
        .map((e) => '${_drinkLabel(e.key.toString())} ×${e.value}')
        .join(', ');
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  String _formatTimestamp(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is Timestamp) {
      return DateFormat(
        'dd MMM yyyy · hh:mm a',
      ).format(value.toDate().toLocal());
    }
    if (value is DateTime) {
      return DateFormat('dd MMM yyyy · hh:mm a').format(value.toLocal());
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final field = entry['field']?.toString() ?? 'Unknown field';
    final oldValue = entry['oldValue'];
    final newValue = entry['newValue'];
    final reason = entry['changeReason']?.toString() ?? 'No reason provided';

    final timestamp = entry['timestamp'];

    final timeText = _formatTimestamp(timestamp);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 70,
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatField(field),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatValue(field, oldValue)}  →  ${_formatValue(field, newValue)}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  reason,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (timeText.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    timeText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ActivityError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ActivityError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 24),
      child: ListTile(
        leading: Icon(
          Icons.error_outline_rounded,
          color: theme.colorScheme.error,
        ),
        title: const Text('Unable to load order activity'),
        trailing: IconButton(
          tooltip: 'Retry',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: onRetry,
        ),
      ),
    );
  }
}

class _CompleteOrderButton extends ConsumerStatefulWidget {
  final Order order;

  const _CompleteOrderButton({required this.order});

  @override
  ConsumerState<_CompleteOrderButton> createState() =>
      _CompleteOrderButtonState();
}

class _CompleteOrderButtonState extends ConsumerState<_CompleteOrderButton> {
  bool _isCompleting = false;
  bool _isCompleted = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.order.status != OrderStatus.pending;
  }

  Future<void> _confirmCompletion() async {
    if (_isCompleting || _isCompleted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Complete this order?'),
          content: const Text(
            'This confirms that the customer has received the order.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Complete'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _completeOrder();
  }

  Future<void> _completeOrder() async {
    if (_isCompleting || _isCompleted) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });

    try {
      final repository = ref.read(orderRepositoryProvider);

      await repository.updateOrder(widget.order.id, {
        'status': OrderStatus.completed.name,
      }, changeReason: 'Order completed');

      if (!mounted) return;

      HapticFeedback.lightImpact();

      // 1. Fire the SnackBar BEFORE updating the state
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
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Order ${widget.order.orderNumber} completed.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      // 2. Trigger the exit animation
      setState(() {
        _isCompleting = false;
        _isCompleted = true;
        _isExiting = true;
      });
    } catch (e) {
      if (!mounted) return;

      HapticFeedback.heavyImpact();

      // Fire error SnackBar before state change
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
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Could not complete the order. Please try again.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      setState(() {
        _isCompleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted && !_isExiting) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInCubic,
      tween: Tween<double>(begin: 0, end: _isExiting ? 1 : 0),
      // 3. Clean up the widget tree when the animation finishes
      onEnd: () {
        if (_isExiting) {
          setState(() {
            _isExiting = false;
          });
        }
      },
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            MediaQuery.sizeOf(context).width * 0.85 * value,
            -8 * value,
          ),
          child: Opacity(opacity: 1 - value, child: child),
        );
      },
      child: FilledButton.icon(
        onPressed: _isCompleting ? null : _confirmCompletion,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isCompleting
              ? const SizedBox(
                  key: ValueKey('completion-loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Icon(
                  Icons.check_circle_outline_rounded,
                  key: ValueKey('completion-icon'),
                ),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _isCompleting ? 'Completing…' : 'Complete Order',
            key: ValueKey(_isCompleting),
          ),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
