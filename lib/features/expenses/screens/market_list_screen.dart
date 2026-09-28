import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/business_day_service.dart';
import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/market_list.dart';
import '../providers/market_list_draft_provider.dart';
import '../services/market_list_print_service.dart';
import '../widgets/expense_formatters.dart';

/// One progressive-disclosure screen for the whole market-list lifecycle:
/// add catalog items -> enter estimates -> print -> hand cash to the worker
/// -> reconcile actual prices -> confirm.
///
/// Sections unlock in order; the confirm button enables only when every
/// item has a price > 0 and the handover switch is on. The screen computes
/// the business date ONCE at confirm-press and passes it into the
/// notifier, which never computes it.
class MarketListScreen extends ConsumerStatefulWidget {
  const MarketListScreen({super.key});

  @override
  ConsumerState<MarketListScreen> createState() => _MarketListScreenState();
}

class _MarketListScreenState extends ConsumerState<MarketListScreen> {
  final _priceControllers = <int, TextEditingController>{};
  bool _resumeDismissed = false;

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _priceController(int index, double price) {
    final existing = _priceControllers[index];
    final text = price == 0 ? '' : price.toStringAsFixed(0);
    if (existing == null) {
      final controller = TextEditingController(text: text);
      _priceControllers[index] = controller;
      return controller;
    }
    if (existing.text != text && !existing.selection.isValid) {
      existing.text = text;
    }
    return existing;
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(marketListDraftProvider);
    final notifier = ref.read(marketListDraftProvider.notifier);
    final catalogAsync = ref.watch(marketListCatalogProvider);
    final persistedAsync = ref.watch(persistedMarketListDraftProvider);
    final canConfirm = notifier.validationErrors.isEmpty && !notifier.isBusy;

    return Scaffold(
      appBar: const HangoutAppBar(title: 'Market List'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ResumeCard(
            persistedAsync: persistedAsync,
            dismissed: _resumeDismissed,
            onResume: (persisted) {
              notifier.loadDraft(persisted);
              setState(() => _resumeDismissed = true);
            },
            onDismiss: () => setState(() => _resumeDismissed = true),
          ),
          _SectionCard(
            title: '1. Add items',
            child: catalogAsync.when(
              data: (items) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in items)
                    ActionChip(
                      key: Key('catalog_chip_${item.id}'),
                      label: Text(item.name),
                      onPressed: () => notifier.addItem(item.name),
                    ),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text('Catalog failed: $error'),
            ),
          ),
          _SectionCard(
            title: '2. Estimates',
            trailing: Text(
              formatExpenseRs(notifier.estimateTotal),
              key: const Key('estimate_total'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            child: draft.items.isEmpty
                ? const Text('No items yet — add some from the catalog.')
                : Column(
                    children: [
                      for (var i = 0; i < draft.items.length; i++)
                        _ItemRow(
                          key: Key('market_list_item_$i'),
                          index: i,
                          item: draft.items[i],
                          priceController: _priceController(
                            i,
                            draft.items[i].price,
                          ),
                          onPriceChanged: (value) {
                            final price = double.tryParse(value) ?? 0;
                            notifier.updateItemPrice(i, price);
                          },
                          onPriceSubmitted: (_) => notifier.commitPrices(),
                          onRemove: () => notifier.removeItem(i),
                        ),
                    ],
                  ),
          ),
          _SectionCard(
            title: '3. Print & hand over',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  key: const Key('print_list_button'),
                  onPressed: notifier.isBusy || draft.items.isEmpty
                      ? null
                      : () => _onPrintPressed(notifier),
                  icon: const Icon(Icons.print),
                  label: const Text('Print list'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('handover_switch'),
                  title: const Text('Cash handed to worker'),
                  value: draft.handedToWorker,
                  onChanged: (handed) => notifier.setHandedToWorker(handed),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: '4. Reconcile & confirm',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'After shopping, update each line with the ACTUAL price, '
                  'then confirm. Confirming creates the Market Bills expense '
                  'and locks this list.',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('confirm_list_button'),
                  onPressed: canConfirm
                      ? () => _onConfirmPressed(notifier)
                      : null,
                  child: Text(
                    'Confirm — ${formatExpenseRs(notifier.estimateTotal)}',
                  ),
                ),
                if (!canConfirm && draft.items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      notifier.validationErrors.first,
                      key: const Key('confirm_hint'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPrintPressed(MarketListDraftNotifier notifier) async {
    try {
      await notifier.printList(MarketListPrintService());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market list sent to printer.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print failed: $e')),
      );
    }
  }

  Future<void> _onConfirmPressed(
    MarketListDraftNotifier notifier,
  ) async {
    // Business date computed ONCE: displayed here and saved by the
    // transaction. Never recomputed inside the notifier.
    final businessDate = BusinessDayService().businessDate(DateTime.now());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('confirm_market_list_dialog'),
        title: const Text('Confirm market list?'),
        content: Text(
          'This creates a Market Bills expense of '
          '${formatExpenseRs(notifier.estimateTotal)} for business day '
          '${formatExpenseDay(businessDate)}. The list will be locked.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel_confirm_button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_confirm_button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await notifier.confirm(businessDate);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Market list confirmed.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Confirm failed: $e')),
      );
    }
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.persistedAsync,
    required this.dismissed,
    required this.onResume,
    required this.onDismiss,
  });

  final AsyncValue<MarketList?> persistedAsync;
  final bool dismissed;
  final void Function(MarketList persisted) onResume;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (dismissed) return const SizedBox.shrink();
    return persistedAsync.when(
      data: (persisted) {
        if (persisted == null) return const SizedBox.shrink();
        return Card(
          key: const Key('resume_draft_card'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Resume previous list (${persisted.items.length} items, '
                    '${formatExpenseRs(persisted.total)})?',
                  ),
                ),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Start new'),
                ),
                FilledButton(
                  onPressed: () => onResume(persisted),
                  child: const Text('Resume'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.index,
    required this.item,
    required this.priceController,
    required this.onPriceChanged,
    required this.onPriceSubmitted,
    required this.onRemove,
  });

  final int index;
  final MarketListItem item;
  final TextEditingController priceController;
  final void Function(String value) onPriceChanged;
  final void Function(String value) onPriceSubmitted;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.itemName),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              key: Key('price_field_$index'),
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: onPriceChanged,
              onSubmitted: onPriceSubmitted,
            ),
          ),
          IconButton(
            key: Key('remove_item_$index'),
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
