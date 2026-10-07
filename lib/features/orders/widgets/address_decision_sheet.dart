import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_draft.dart';
import '../providers/order_draft_provider.dart';

/// Shows the "address changed" sheet (plan 8.4) when the order's address
/// differs from the matched customer's saved address.
///
/// Returns true when the order should be saved, false when the cashier
/// cancelled. The chosen decision is written to the draft before
/// returning true, so saveOrder picks it up via buildCustomerUpsert.
/// The default selection is "Use for this order only" so a rushed
/// cashier never silently changes saved data.
Future<bool> showAddressDecisionSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _AddressDecisionSheet(),
  ).then((value) => value ?? false);
}

class _AddressDecisionSheet extends ConsumerStatefulWidget {
  const _AddressDecisionSheet();

  @override
  ConsumerState<_AddressDecisionSheet> createState() =>
      _AddressDecisionSheetState();
}

class _AddressDecisionSheetState
    extends ConsumerState<_AddressDecisionSheet> {
  AddressDecision _decision = AddressDecision.useForThisOrderOnly;
  final _labelController = TextEditingController();

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: bottomInset + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address changed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('This address differs from the saved one.'),
            const SizedBox(height: 12),
            RadioGroup<AddressDecision>(
              groupValue: _decision,
              onChanged: _select,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<AddressDecision>(
                    title: const Text('Use for this order only'),
                    value: AddressDecision.useForThisOrderOnly,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<AddressDecision>(
                    title: const Text('Update the saved address'),
                    value: AddressDecision.updateSavedAddress,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<AddressDecision>(
                    title: const Text('Save as a new address'),
                    value: AddressDecision.saveAsNewAddress,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (_decision == AddressDecision.saveAsNewAddress) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _labelController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'Home',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save order'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _select(AddressDecision? value) {
    if (value == null) {
      return;
    }
    setState(() => _decision = value);
  }

  void _save() {
    final notifier = ref.read(orderDraftProvider.notifier);
    notifier.setAddressDecision(_decision);
    notifier.setNewAddressLabel(
      _decision == AddressDecision.saveAsNewAddress
          ? _labelController.text
          : null,
    );
    Navigator.of(context).pop(true);
  }
}
