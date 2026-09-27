import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog_item.dart';
import '../models/expense_line_item.dart';
import '../providers/catalog_provider.dart';
import '../providers/expense_draft_provider.dart';

/// Entry form for [ExpenseEntryShape.catalogItems]: pick catalog items by
/// name, then type each line's price.
///
/// Catalog items carry no price in the data model, so the picker only
/// supplies the name (snapshot as plain text, per the Phase 6 contract)
/// and the price is entered per line.
class ExpenseCatalogSection extends ConsumerWidget {
  const ExpenseCatalogSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(expenseDraftProvider.notifier);
    final draft = ref.watch(expenseDraftProvider);
    // The draft is the source of truth for which category's items to show.
    // This section only builds for the catalogItems shape, so the category
    // is always non-null here.
    final catalogAsync = ref.watch(catalogItemsProvider(draft.category!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Market Items',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('expense_title_field'),
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Morning purchase',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setTitle,
        ),
        const SizedBox(height: 16),
        Text(
          'Pick from catalog',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        catalogAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Text(
                'No catalog items in this category yet.',
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return ActionChip(
                  label: Text(_itemLabel(item)),
                  onPressed: () => notifier.addLineItem(
                    itemName: _itemLabel(item),
                    price: 0,
                  ),
                );
              }).toList(),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('Could not load catalog: $error'),
        ),
        const SizedBox(height: 16),
        Text(
          'Added items',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (draft.lineItems.isEmpty)
          const Text('Nothing added yet — tap an item above.'),
        ...draft.lineItems.asMap().entries.map((entry) {
          return _CatalogLineRow(
            // Index key: updateLineItem replaces the line instance on every
            // keystroke, so identity keys recreate the row and kill focus.
            // didUpdateWidget resyncs the price field when a deletion above
            // slides a different line into this position.
            key: ValueKey('added_${entry.key}'),
            line: entry.value,
            index: entry.key,
          );
        }),
        const SizedBox(height: 12),
        TextField(
          key: const Key('expense_notes_field'),
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: notifier.setNotes,
        ),
      ],
    );
  }

  String _itemLabel(CatalogItem item) {
    final size = item.size?.trim() ?? '';
    if (size.isEmpty) return item.name;
    final name = item.name.trim();
    // Names often already contain the size ("Coke 1ltr") — don't repeat it.
    if (name.toLowerCase().endsWith(size.toLowerCase())) return name;
    return '$name • $size';
  }
}

/// One added catalog line: name, editable price, remove button.
///
/// Holds its own price controller so typing never fights the provider
/// rebuilds. Keyed by line identity (see parent).
class _CatalogLineRow extends ConsumerStatefulWidget {
  final ExpenseLineItem line;
  final int index;

  const _CatalogLineRow({
    super.key,
    required this.line,
    required this.index,
  });

  @override
  ConsumerState<_CatalogLineRow> createState() => _CatalogLineRowState();
}

class _CatalogLineRowState extends ConsumerState<_CatalogLineRow> {
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: _priceText);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CatalogLineRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.line.itemName != oldWidget.line.itemName) {
      _priceController.text = _priceText;
    }
  }

  String get _priceText =>
      widget.line.price == 0 ? '' : widget.line.price.toStringAsFixed(0);

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(expenseDraftProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(widget.line.itemName),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: Key('line_price_field_${widget.index}'),
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Rs.',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) => notifier.updateLineItem(
                  widget.index,
                  itemName: widget.line.itemName,
                  price: double.tryParse(value) ?? 0,
                ),
              ),
            ),
            IconButton(
              key: Key('remove_line_item_${widget.index}'),
              tooltip: 'Remove item',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => notifier.removeLineItem(widget.index),
            ),
          ],
        ),
      ),
    );
  }
}
