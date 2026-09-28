import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/chicken_purchase_line.dart';
import '../models/expense.dart';
import '../models/expense_draft.dart';
import '../models/expense_category_display.dart';
import '../models/expense_line_item.dart';
import '../providers/expense_actions_provider.dart';
import '../providers/expense_detail_provider.dart';
import '../providers/expense_history_provider.dart';
import '../widgets/expense_audit_trail.dart';
import '../widgets/expense_formatters.dart';
import '../widgets/expense_reason_dialog.dart';

/// Phase 10 — read-only detail for one saved expense (route
/// `/expenses/detail/:id`), with Edit and Void actions.
///
/// Reads through [expenseDetailProvider], which does not filter voided
/// records, so a just-voided expense stays visible here with its audit
/// reason. Voided expenses show a banner and no actions. Edit pushes the
/// edit route and refreshes when it returns `true`; void asks for a
/// reason, calls [ExpenseActions], then refreshes in place. Every
/// mutation also invalidates [expenseHistoricalListProvider] so the
/// history screen underneath reloads.
class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  bool _isBusy = false;

  void _refreshAll() {
    ref.invalidate(expenseDetailProvider(widget.expenseId));
    ref.invalidate(expenseAuditTrailProvider(widget.expenseId));
    ref.invalidate(expenseHistoricalListProvider);
  }

  Future<void> _onEditPressed() async {
    final saved = await context.push<bool>(
      AppRoutes.expenseEditPath(widget.expenseId),
    );
    if (!mounted || saved != true) {
      return;
    }
    _refreshAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense updated.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _onVoidPressed(Expense expense) async {
    if (_isBusy) {
      return;
    }

    final reason = await showExpenseReasonDialog(
      context,
      title: 'Void this expense?',
      message: 'It stays on record for auditing but is removed from all '
          'totals and can no longer be edited. This cannot be undone.',
      confirmLabel: 'Void Expense',
      destructive: true,
    );
    if (reason == null || !mounted) {
      return;
    }

    setState(() => _isBusy = true);
    try {
      await ref.read(expenseActionsProvider).voidExpense(
            expense: expense,
            changeReason: reason,
          );
      if (!mounted) {
        return;
      }
      _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense voided.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to void expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncExpense = ref.watch(expenseDetailProvider(widget.expenseId));
    final expense = asyncExpense.valueOrNull;

    return Scaffold(
      appBar: const HangoutAppBar(title: 'Expense Detail'),
      body: asyncExpense.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _DetailError(
          message: _friendlyErrorMessage(error),
          onRetry: _refreshAll,
        ),
        data: (loaded) {
          if (loaded == null) {
            return const _DetailNotFound();
          }
          return _DetailBody(expense: loaded);
        },
      ),
      bottomNavigationBar: expense == null || expense.voided
          ? null
          : _ActionBar(
              busy: _isBusy,
              onEdit: _onEditPressed,
              onVoid: () => _onVoidPressed(expense),
            ),
    );
  }
}

String _friendlyErrorMessage(Object error) {
  final raw = error.toString();
  return raw.startsWith('Exception: ')
      ? raw.substring('Exception: '.length)
      : raw;
}

class _DetailBody extends StatelessWidget {
  final Expense expense;

  const _DetailBody({required this.expense});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final notes = expense.notes?.trim() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (expense.voided) const _VoidedBanner(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  key: const Key('expense_detail_title'),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CategoryTag(label: expense.category.displayName),
                    Text(
                      formatExpenseRs(expense.amount),
                      key: const Key('expense_detail_amount'),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Business date',
                  value: formatExpenseDay(expense.businessDate),
                ),
                _InfoRow(
                  label: 'Saved',
                  value: '${formatExpenseDay(expense.date)}'
                      ' • ${formatExpenseTime(expense.date)}',
                ),
                if (expense.editCount > 0)
                  _InfoRow(label: 'Edits', value: '${expense.editCount}'),
                ..._shapeRows(context, expense),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Notes',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(notes),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _AuditSection(expenseId: expense.id),
      ],
    );
  }
}

/// The shape-specific rows (worker, chicken lines, catalog items).
List<Widget> _shapeRows(BuildContext context, Expense expense) {
  final headingStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      );

  switch (expense.category.entryShape) {
    case ExpenseEntryShape.plain:
      return const [];
    case ExpenseEntryShape.wages:
      return [
        _InfoRow(label: 'Worker', value: expense.workerName ?? '—'),
      ];
    case ExpenseEntryShape.chicken:
      final pricePerKg = expense.pricePerKg ?? 0;
      return [
        _InfoRow(label: 'Price per kg', value: formatExpenseRs(pricePerKg)),
        const SizedBox(height: 8),
        Text('Chicken lines', style: headingStyle),
        for (final line
            in expense.chickenLines ?? const <ChickenPurchaseLine>[])
          _InfoRow(
            label: line.chickenType,
            value: '${line.quantityKg} kg'
                ' • ${formatExpenseRs(line.quantityKg * pricePerKg)}',
          ),
      ];
    case ExpenseEntryShape.catalogItems:
      return [
        const SizedBox(height: 8),
        Text('Items', style: headingStyle),
        for (final item in expense.lineItems ?? const <ExpenseLineItem>[])
          _InfoRow(label: item.itemName, value: formatExpenseRs(item.price)),
      ];
  }
}

class _AuditSection extends ConsumerWidget {
  final String expenseId;

  const _AuditSection({required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTrail = ref.watch(expenseAuditTrailProvider(expenseId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Change History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        asyncTrail.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Row(
            children: [
              const Expanded(
                child: Text(
                  "Couldn't load change history.",
                  key: Key('audit_trail_error'),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(expenseAuditTrailProvider(expenseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (entries) => ExpenseAuditTrail(entries: entries),
        ),
      ],
    );
  }
}

class _VoidedBanner extends StatelessWidget {
  const _VoidedBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('expense_detail_voided_banner'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.block, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Voided — this expense is excluded from all totals and can '
              'no longer be edited.',
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onVoid;

  const _ActionBar({
    required this.busy,
    required this.onEdit,
    required this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('expense_detail_void_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: errorColor,
                  side: BorderSide(color: errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: busy ? null : onVoid,
                icon: const Icon(Icons.block),
                label: Text(busy ? 'Voiding…' : 'Void'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const Key('expense_detail_edit_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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

class _CategoryTag extends StatelessWidget {
  final String label;

  const _CategoryTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B4E12),
            ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              "Couldn't load expense",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailNotFound extends StatelessWidget {
  const _DetailNotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Expense not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'This expense no longer exists.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
