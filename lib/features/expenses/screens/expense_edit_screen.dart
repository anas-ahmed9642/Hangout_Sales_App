import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/chicken_purchase_line.dart';
import '../models/expense.dart';
import '../models/expense_category_display.dart';
import '../models/expense_draft.dart';
import '../models/expense_edit_input.dart';
import '../models/expense_line_item.dart';
import '../providers/expense_actions_provider.dart';
import '../providers/expense_detail_provider.dart';
import '../widgets/expense_formatters.dart';
import '../widgets/expense_reason_dialog.dart';

/// Phase 10 — edit one saved expense (route `/expenses/detail/:id/edit`).
///
/// Only the narrow set of fields described by [ExpenseEditInput] can be
/// edited. The form keeps its own local controllers (stable keys, so
/// typing never loses focus — the Phase 7 lesson) and re-derives an
/// [ExpenseEditInput] on every rebuild. Validation, the change map and
/// the recomputed total all come from the pure functions in
/// expense_actions_provider.dart; this screen holds no business logic.
///
/// Save asks for a reason, calls [ExpenseActions.saveEdit], then pops
/// with `true`; the detail screen refreshes on that result.
class ExpenseEditScreen extends ConsumerWidget {
  final String expenseId;

  const ExpenseEditScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncExpense = ref.watch(expenseDetailProvider(expenseId));

    return Scaffold(
      appBar: const HangoutAppBar(title: 'Edit Expense'),
      body: asyncExpense.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _EditMessage(
          icon: Icons.error_outline,
          title: "Couldn't load expense",
          message: error.toString(),
          onRetry: () => ref.invalidate(expenseDetailProvider(expenseId)),
        ),
        data: (expense) {
          if (expense == null) {
            return const _EditMessage(
              icon: Icons.search_off,
              title: 'Expense not found',
              message: 'This expense no longer exists.',
            );
          }
          if (expense.voided) {
            return const _EditMessage(
              icon: Icons.block,
              title: 'Voided expenses cannot be edited.',
              message: 'Voided expenses are historical records.',
            );
          }
          return _ExpenseEditForm(key: ValueKey(expense.id), expense: expense);
        },
      ),
    );
  }
}

class _ExpenseEditForm extends ConsumerStatefulWidget {
  final Expense expense;

  const _ExpenseEditForm({super.key, required this.expense});

  @override
  ConsumerState<_ExpenseEditForm> createState() => _ExpenseEditFormState();
}

class _ExpenseEditFormState extends ConsumerState<_ExpenseEditForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _workerController;
  late final TextEditingController _amountController;
  late final TextEditingController _priceController;
  late final List<TextEditingController> _chickenControllers;
  late final List<TextEditingController> _itemControllers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense.title);
    _notesController = TextEditingController(text: expense.notes ?? '');
    _workerController = TextEditingController(text: expense.workerName ?? '');
    _amountController =
        TextEditingController(text: formatExpenseNumber(expense.amount));
    _priceController = TextEditingController(
      text: expense.pricePerKg == null
          ? ''
          : formatExpenseNumber(expense.pricePerKg!),
    );
    _chickenControllers = [
      for (final line
          in expense.chickenLines ?? const <ChickenPurchaseLine>[])
        TextEditingController(text: '${line.quantityKg}'),
    ];
    _itemControllers = [
      for (final item in expense.lineItems ?? const <ExpenseLineItem>[])
        TextEditingController(text: formatExpenseNumber(item.price)),
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _workerController.dispose();
    _amountController.dispose();
    _priceController.dispose();
    for (final controller in _chickenControllers) {
      controller.dispose();
    }
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  ExpenseEditInput _input() {
    return ExpenseEditInput(
      title: _titleController.text,
      notes: _notesController.text,
      workerName: _workerController.text,
      amount: double.tryParse(_amountController.text.trim()) ?? 0,
      pricePerKg: double.tryParse(_priceController.text.trim()) ?? 0,
      chickenQuantities: [
        for (final controller in _chickenControllers)
          int.tryParse(controller.text.trim()) ?? 0,
      ],
      lineItemPrices: [
        for (final controller in _itemControllers)
          double.tryParse(controller.text.trim()) ?? 0,
      ],
    );
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) {
      return;
    }

    final reason = await showExpenseReasonDialog(
      context,
      title: 'Save changes?',
      message: 'Every changed field is recorded in the change history '
          'together with your reason.',
      confirmLabel: 'Save Changes',
    );
    if (reason == null || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saved = await ref.read(expenseActionsProvider).saveEdit(
            original: widget.expense,
            input: _input(),
            changeReason: reason,
          );
      if (!mounted) {
        return;
      }
      context.pop(saved);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save changes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _numberField({
    required String fieldKey,
    required TextEditingController controller,
    required String label,
    required bool decimal,
  }) {
    return TextField(
      key: Key(fieldKey),
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      onChanged: (_) => setState(() {}),
    );
  }

  List<Widget> _shapeFields() {
    final expense = widget.expense;

    switch (expense.category.entryShape) {
      case ExpenseEntryShape.plain:
        return [
          _numberField(
            fieldKey: 'edit_amount_field',
            controller: _amountController,
            label: 'Amount (Rs.)',
            decimal: true,
          ),
          const SizedBox(height: 12),
        ];
      case ExpenseEntryShape.wages:
        return [
          TextField(
            key: const Key('edit_worker_field'),
            controller: _workerController,
            decoration: const InputDecoration(
              labelText: 'Worker name',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _numberField(
            fieldKey: 'edit_amount_field',
            controller: _amountController,
            label: 'Amount (Rs.)',
            decimal: true,
          ),
          const SizedBox(height: 12),
        ];
      case ExpenseEntryShape.chicken:
        return [
          _numberField(
            fieldKey: 'edit_price_per_kg_field',
            controller: _priceController,
            label: 'Price per kg (Rs.)',
            decimal: true,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _chickenControllers.length; i++) ...[
            _numberField(
              fieldKey: 'edit_chicken_kg_$i',
              controller: _chickenControllers[i],
              label: '${expense.chickenLines![i].chickenType} (kg)',
              decimal: false,
            ),
            const SizedBox(height: 12),
          ],
        ];
      case ExpenseEntryShape.catalogItems:
        return [
          for (var i = 0; i < _itemControllers.length; i++) ...[
            _numberField(
              fieldKey: 'edit_item_price_$i',
              controller: _itemControllers[i],
              label: '${expense.lineItems![i].itemName} (Rs.)',
              decimal: true,
            ),
            const SizedBox(height: 12),
          ],
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final input = _input();
    final errors = validateExpenseEdit(expense, input);
    final changes = errors.isEmpty
        ? buildExpenseChanges(expense, input)
        : const <String, dynamic>{};
    final canSave = errors.isEmpty && changes.isNotEmpty && !_isSaving;
    final total = computeEditedAmount(expense, input);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Details', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('edit_title_field'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                ..._shapeFields(),
                TextField(
                  key: const Key('edit_notes_field'),
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: textTheme.titleMedium),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatExpenseRs(total),
                              key: const Key('edit_total_text'),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (total != expense.amount)
                              Text(
                                'was ${formatExpenseRs(expense.amount)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lock_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Category (${expense.category.displayName}), '
                          'business date '
                          '(${formatExpenseDay(expense.businessDate)}) and '
                          'which items were bought cannot be edited. To '
                          'change those, void this expense and add a new '
                          'one.',
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final message in errors)
                    Text(
                      message,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                ] else if (changes.isEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'No changes yet.',
                    key: const Key('edit_no_changes_hint'),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('save_edit_button'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                ),
                onPressed: canSave ? _onSavePressed : null,
                child: Text(
                  _isSaving ? 'Saving…' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _EditMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
