import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hangout_sales_app/core/utils/map_link_helper.dart';
import 'package:hangout_sales_app/core/utils/phone_normalizer.dart';
import 'package:hangout_sales_app/features/customers/providers/customers_provider.dart';
import 'package:hangout_sales_app/features/customers/services/contact_launcher.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_areas_provider.dart';

import '../providers/order_draft_provider.dart';

class CustomerForm extends ConsumerStatefulWidget {
  const CustomerForm({super.key});

  @override
  ConsumerState<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<CustomerForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _mapLinkController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if there is already data in the draft when the screen loads
    final draft = ref.read(orderDraftProvider);
    _nameController = TextEditingController(text: draft.customerName ?? '');
    _phoneController = TextEditingController(text: draft.customerPhone ?? '');
    _addressController =
        TextEditingController(text: draft.customerAddress ?? '');
    _mapLinkController =
        TextEditingController(text: draft.customerMapLink ?? '');
    _notesController =
        TextEditingController(text: draft.deliveryNotes ?? '');
  }

  @override
  void dispose() {
    // Prevent memory leaks!
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _mapLinkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// One-way sync: draft -> controllers. User typing flows controller ->
  /// draft via onChanged, so when this fires with a different value the
  /// change came from autofill, a chip selection or discard. Setting
  /// .text programmatically does not trigger onChanged, so there is no
  /// loop and no fight with the listener (Finding 3).
  void _sync(TextEditingController controller, String? value) {
    final text = value ?? '';
    if (controller.text != text) {
      controller.text = text;
    }
  }

  bool _isValidMapLink(String? link) {
    return link != null &&
        link.trim().isNotEmpty &&
        MapLinkHelper.parse(link) != null;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(orderDraftProvider.notifier);
    final draft = ref.watch(orderDraftProvider);

    // Extended magic listener: autofill, chip selection and Discard Order
    // all flow through the draft, and the controllers follow it.
    ref.listen(orderDraftProvider, (previous, next) {
      _sync(_nameController, next.customerName);
      _sync(_phoneController, next.customerPhone);
      _sync(_addressController, next.customerAddress);
      _sync(_mapLinkController, next.customerMapLink);
      _sync(_notesController, next.deliveryNotes);
    });

    final phoneText = draft.customerPhone ?? '';
    final matchedPhone = draft.matchedCustomerPhone;

    final areas = ref.watch(deliveryAreasProvider).valueOrNull ?? const [];
    final areaNames = {for (final area in areas) area.id: area.name};

    final matchedCustomer = matchedPhone == null
        ? null
        : ref.watch(customerByPhoneProvider(matchedPhone)).valueOrNull;

    final showChips = matchedCustomer != null &&
        matchedCustomer.addresses.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline),
            const SizedBox(width: 8),
            Text(
              'Customer Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.onCustomerPhoneChanged,
        ),
        _phoneHint(phoneText, matchedPhone),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setCustomerName,
        ),
        if (showChips) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final address in matchedCustomer.addresses)
                ChoiceChip(
                  label: Text(
                    address.areaId == null ||
                            areaNames[address.areaId] == null
                        ? address.label
                        : '${address.label} · ${areaNames[address.areaId]}',
                  ),
                  selected: draft.selectedAddressId == address.id,
                  onSelected: (_) =>
                      notifier.selectCustomerAddress(address.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _addressController,
                keyboardType: TextInputType.streetAddress,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                onChanged: notifier.setCustomerAddress,
              ),
            ),
            if (_isValidMapLink(draft.customerMapLink)) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton(
                  tooltip: 'Open in Maps',
                  icon: const Icon(Icons.map_outlined),
                  onPressed: () => ContactLauncher().openMap(
                    context,
                    draft.customerMapLink!,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mapLinkController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Location link',
            border: const OutlineInputBorder(),
            errorText: _mapLinkError(_mapLinkController.text),
          ),
          onChanged: notifier.setCustomerMapLink,
        ),
        if (matchedCustomer?.deliveryNotes != null) ...[
          const SizedBox(height: 12),
          _notesBanner(matchedCustomer!.deliveryNotes!),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Delivery notes (this order)',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setDeliveryNotes,
        ),
      ],
    );
  }

  /// Hint under the phone field, derived from draft state (plan 8.1):
  /// invalid -> guidance; valid but unknown -> "New customer" (the
  /// interactive switch lands in Phase 5); matched -> no hint.
  Widget _phoneHint(String phoneText, String? matchedPhone) {
    if (phoneText.isEmpty || matchedPhone != null) {
      return const SizedBox.shrink();
    }

    final valid = PhoneNormalizer.normalize(phoneText) != null;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        valid ? 'New customer — will be saved' : 'Enter a valid mobile number',
        style: TextStyle(
          fontSize: 12,
          color: valid ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      ),
    );
  }

  /// Inline, non-blocking message for a bad map link (plan Phase 4
  /// checkpoint: it must not block saving the order).
  String? _mapLinkError(String text) {
    if (text.trim().isEmpty) {
      return null;
    }
    return MapLinkHelper.parse(text) == null
        ? 'Not a recognized Google Maps link or coordinates.'
        : null;
  }

  /// The customer's saved delivery notes, read-only (plan 8.1). The
  /// editable per-order copy lives in the notes field below it.
  Widget _notesBanner(String notes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 18,
            color: Colors.amber.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notes,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}