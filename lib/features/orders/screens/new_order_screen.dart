import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hangout_sales_app/features/orders/screens/order_history_screen.dart';
import '../../../core/services/business_day_service.dart';
import '../../../shared/widgets/hangout_app_bar.dart';
import '../providers/order_draft_provider.dart';
import '../widgets/address_decision_sheet.dart';
import '../widgets/additional_items_section.dart';
import '../widgets/customer_form.dart';
import '../widgets/delivery_picker.dart';
import '../widgets/order_category_selector.dart';
import '../widgets/order_entries_section.dart';
import '../widgets/order_summary.dart';
import '../widgets/payment_status_selector.dart';
import '../../../core/constants/app_routes.dart';
import 'package:go_router/go_router.dart';

class NewOrderScreen extends ConsumerWidget {
  const NewOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the validation state to enable/disable the checkout button
    final canConfirm = ref.watch(
      orderDraftProvider.select(
        (draft) => ref.read(orderDraftProvider.notifier).canConfirm,
      ),
    );

    return Scaffold(
      appBar: HangoutAppBar(
        title: 'New Order',
        showBackButton: true,
        actions: [
          // --- NEW HISTORY BUTTON ---
          IconButton(
            tooltip: 'Order History',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          // --- EXISTING DISCARD BUTTON ---
          IconButton(
            tooltip: 'Discard Order',
            icon: const Icon(Icons.delete_outline, color: Color(0xFFD4AF37)),
            onPressed: () {
              _confirmDiscard(context, ref);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // REFINEMENT: Added extra bottom padding (48) for breathing room
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              OrderCategorySelector(),
              SizedBox(height: 24),
              OrderEntriesSection(),
              SizedBox(height: 24),
              AdditionalItemsSection(),
              SizedBox(height: 24),
              CustomerForm(),
              SizedBox(height: 24),
              PaymentStatusSelector(),
              SizedBox(height: 24),
              DeliveryPicker(),
              SizedBox(height: 24),
              OrderSummary(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            // The button will be greyed out if canComplete is false
            onPressed: canConfirm ? () => _submitOrder(context, ref) : null,
            child: const Text(
              'Confirm Order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
Future<void> _confirmDiscard(
  BuildContext context,
  WidgetRef ref,
) async {
  final shouldDiscard = await showDialog<bool>(
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
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Discard order?'),
            ),
          ],
        ),
        content: const Text(
          'All current order information will be cleared. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Keep Order'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Discard'),
          ),
        ],
      );
    },
  );

  if (shouldDiscard != true || !context.mounted) {
    return;
  }

  ref.read(orderDraftProvider.notifier).clearDraft();

  context.go(AppRoutes.dashboard);
}
 
  Future<void> _submitOrder(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(orderDraftProvider.notifier);

    if (await notifier.addressDecisionNeeded() != null) {
      if (!context.mounted) return;
      final proceed = await showAddressDecisionSheet(context);
      if (!proceed || !context.mounted) return;
    }

    // We explicitly pass this temporary string so we don't hide the missing UI logic.
    // The repository transaction will intercept this and swap it for the real number!
    const temporaryOrderNumber = 'PENDING-INTEGRATION';
    // Normalize the timestamp before saving it to Firebase!
    final temporaryBusinessDate = const BusinessDayService().businessDate(
      DateTime.now(),
    );
    if (!context.mounted) {
      return;
    }
    try {
      // 1. Show a loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 2. Trigger the save chain (UI -> Notifier -> Repository)
      await notifier.saveOrder(
        orderNumber: temporaryOrderNumber,
        businessDate: temporaryBusinessDate,
      );

      // 3. Pop the loading spinner
      if (context.mounted) Navigator.of(context).pop();

      // 4. Clear the cart so they can take the next customer's order
      notifier.clearDraft();

      // 5. Show a success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
