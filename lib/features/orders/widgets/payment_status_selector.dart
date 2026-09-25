import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../providers/order_draft_provider.dart';

class PaymentStatusSelector extends ConsumerWidget {
  const PaymentStatusSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentStatus = ref.watch(
      orderDraftProvider.select((draft) => draft.paymentStatus),
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPaid = paymentStatus == PaymentStatus.paid;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.payments_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                'Was payment received for this order?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _PaymentSegmentedControl(
              isPaid: isPaid,
              onChanged: (status) {
                HapticFeedback.selectionClick();
                ref
                    .read(orderDraftProvider.notifier)
                    .setPaymentStatus(status);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSegmentedControl extends StatelessWidget {
  final bool isPaid;
  final ValueChanged<PaymentStatus> onChanged;

  const _PaymentSegmentedControl({
    required this.isPaid,
    required this.onChanged,
  });

  // Semantic colors, deliberately independent of the app's theme.primary —
  // paid/unpaid is state a cashier should be able to read at a glance.
  // Swap these for colorScheme-driven values if you'd rather it follow theme.
  static const _paidColor = Color(0xFF1FA35C);
  static const _unpaidColor = Color(0xFFE0862E);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = (constraints.maxWidth - 8) / 2;

        return Container(
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(4),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                alignment:
                    isPaid ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: segmentWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: isPaid ? _paidColor : _unpaidColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isPaid ? _paidColor : _unpaidColor)
                            .withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: _SegmentLabel(
                        icon: Icons.check_circle_rounded,
                        label: 'Paid',
                        selected: isPaid,
                        onTap: () => onChanged(PaymentStatus.paid),
                      ),
                    ),
                    Expanded(
                      child: _SegmentLabel(
                        icon: Icons.schedule_rounded,
                        label: 'Unpaid',
                        selected: !isPaid,
                        onTap: () => onChanged(PaymentStatus.unpaid),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentLabel({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = selected
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox.expand(
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.0 : 0.9,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(icon, size: 18, color: textColor),
                  ),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}