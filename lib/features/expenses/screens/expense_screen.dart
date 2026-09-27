import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/business_day_service.dart';
import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/expense_category_display.dart';
import '../models/expense_draft.dart';
import '../providers/expense_draft_provider.dart';
import '../widgets/expense_catalog_section.dart';
import '../widgets/expense_category_selector.dart';
import '../widgets/expense_chicken_section.dart';
import '../widgets/expense_plain_section.dart';
import '../widgets/expense_summary.dart';
import '../widgets/expense_wages_section.dart';

/// The Add-Expense screen (route `/expenses`, reached from the dashboard's
/// "Add Expense" button).
///
/// Architecture mirrors [NewOrderScreen]: the screen holds no form state.
/// Every input writes into [expenseDraftProvider]; the shape section is
/// switched on the draft's [ExpenseEntryShape]; the save button follows
/// the notifier's [canConfirm].
class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  /// True while a confirmed save is in flight. Guards against double
  /// writes (e.g. Save → Confirm → back button → Save → Confirm again
  /// while the first write is still running).
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final canConfirm = ref.watch(
      expenseDraftProvider.select(
        (draft) => ref.read(expenseDraftProvider.notifier).canConfirm,
      ),
    );
    final shape = ref.watch(
      expenseDraftProvider.select((draft) => draft.entryShape),
    );
    final category = ref.watch(
      expenseDraftProvider.select((draft) => draft.category),
    );

    return Scaffold(
      appBar: HangoutAppBar(
        title: 'New Expense',
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: 'Discard Expense',
            icon: const Icon(
              Icons.delete_outline,
              color: Color(0xFFD4AF37),
            ),
            onPressed: () => _confirmDiscard(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExpenseCategorySelector(),
              const SizedBox(height: 24),
              // Keyed by category: switching categories inside the same
              // shape (e.g. Utilities -> Gas) rebuilds the section with
              // fresh, empty fields instead of showing stale text.
              _ShapeSection(key: ValueKey(category), shape: shape),
              const SizedBox(height: 24),
              const ExpenseSummary(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(
            key: const Key('save_expense_button'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: canConfirm && !_isSaving
                ? () => _onSavePressed()
                : null,
            child: const Text(
              'Save Expense',
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
                child: Text('Discard expense?'),
              ),
            ],
          ),
          content: const Text(
            'All current expense information will be cleared. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Keep Expense'),
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

    ref.read(expenseDraftProvider.notifier).clearDraft();

    context.go(AppRoutes.dashboard);
  }

  /// Entry point for the Save button. Computes the business date ONCE,
  /// shows it in the confirmation dialog, and passes that same value
  /// into [_saveExpense] so the displayed and saved dates can never
  /// disagree around the 5:00 AM cutoff.
  Future<void> _onSavePressed() async {
    final notifier = ref.read(expenseDraftProvider.notifier);
    final businessDate =
        const BusinessDayService().businessDate(DateTime.now());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final draft = ref.read(expenseDraftProvider);
        return AlertDialog(
          key: const Key('save_confirmation_dialog'),
          title: const Text('Confirm Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(label: 'Title', value: draft.title),
              _SummaryRow(
                label: 'Category',
                value: draft.category?.displayName ?? '—',
              ),
              _SummaryRow(
                label: 'Amount',
                value: 'Rs. ${notifier.computedAmount.toStringAsFixed(0)}',
              ),
              _SummaryRow(
                label: 'Business date',
                value: _formatDate(businessDate),
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('cancel_save_button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm_save_button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm & Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _saveExpense(businessDate: businessDate);
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _saveExpense({required DateTime businessDate}) async {
    if (_isSaving) {
      return;
    }
    setState(() => _isSaving = true);

    final notifier = ref.read(expenseDraftProvider.notifier);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );

      await notifier.saveExpense(businessDate: businessDate);

      if (mounted) Navigator.of(context).pop();

      notifier.clearDraft();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      // Draft is deliberately NOT cleared here: the user keeps everything
      // they entered and can retry after fixing the problem.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Renders exactly one entry section for the current [shape].
/// Null shape (no category picked yet) shows a prompt.
class _ShapeSection extends StatelessWidget {
  final ExpenseEntryShape? shape;

  const _ShapeSection({super.key, required this.shape});

  @override
  Widget build(BuildContext context) {
    switch (shape) {
      case ExpenseEntryShape.plain:
        return const ExpensePlainSection();
      case ExpenseEntryShape.chicken:
        return const ExpenseChickenSection();
      case ExpenseEntryShape.catalogItems:
        return const ExpenseCatalogSection();
      case ExpenseEntryShape.wages:
        return const ExpenseWagesSection();
      case null:
        return const Text('Select a category above to start.');
    }
  }
}

/// One label/value row inside the save-confirmation dialog.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
