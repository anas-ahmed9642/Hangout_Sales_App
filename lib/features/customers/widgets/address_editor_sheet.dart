import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/map_link_helper.dart';
import '../../delivery_areas/providers/delivery_areas_provider.dart';
import '../../orders/widgets/delivery_area_sheet.dart';
import '../models/customer_address.dart';

/// What the address editor returns: the address as edited, and
/// whether it should become the customer's default.
class AddressEditorResult {
  final CustomerAddress address;
  final bool makeDefault;

  const AddressEditorResult({
    required this.address,
    required this.makeDefault,
  });
}

/// Opens the address editor sheet (plan 8.12, F22): label, address
/// text, delivery area (the same searchable sheet New Order uses),
/// a validated location link, and "Make default".
///
/// [initial] is null when adding. [isDefault] marks [initial] as the
/// current default — its Make-default switch is locked on, because a
/// default can only be replaced by another address, never unset.
/// [isFirstAddress] locks the switch on too: a customer's first
/// saved address becomes the default. Returns null when dismissed.
Future<AddressEditorResult?> showAddressEditorSheet(
  BuildContext context, {
  CustomerAddress? initial,
  bool isDefault = false,
  bool isFirstAddress = false,
}) {
  return showModalBottomSheet<AddressEditorResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _AddressEditorSheet(
      initial: initial,
      isDefault: isDefault,
      isFirstAddress: isFirstAddress,
    ),
  );
}

class _AddressEditorSheet extends ConsumerStatefulWidget {
  final CustomerAddress? initial;
  final bool isDefault;
  final bool isFirstAddress;

  const _AddressEditorSheet({
    required this.initial,
    required this.isDefault,
    required this.isFirstAddress,
  });

  @override
  ConsumerState<_AddressEditorSheet> createState() =>
      _AddressEditorSheetState();
}

class _AddressEditorSheetState extends ConsumerState<_AddressEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _textController;
  late final TextEditingController _mapLinkController;
  String? _areaId;
  late bool _makeDefault;
  bool _triedSave = false;

  bool get _makeDefaultLocked => widget.isDefault || widget.isFirstAddress;

  @override
  void initState() {
    super.initState();
    _labelController =
        TextEditingController(text: widget.initial?.label ?? '');
    _textController = TextEditingController(text: widget.initial?.text ?? '');
    _mapLinkController =
        TextEditingController(text: widget.initial?.mapLink ?? '');
    _areaId = widget.initial?.areaId;
    _makeDefault = widget.isDefault || widget.isFirstAddress;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _textController.dispose();
    _mapLinkController.dispose();
    super.dispose();
  }

  /// Same validation the CustomerAddress constructor applies; shown
  /// inline so an invalid link never reaches the repository (the
  /// customer_form.dart map-link precedent).
  String? _mapLinkError(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }
    return MapLinkHelper.parse(raw) == null
        ? 'Not a recognized Google Maps link or coordinates.'
        : null;
  }

  void _save() {
    final text = _textController.text.trim();
    final mapLink = _mapLinkController.text.trim();
    if (text.isEmpty || _mapLinkError(mapLink) != null) {
      setState(() => _triedSave = true);
      return;
    }

    final label = _labelController.text.trim();
    final linkOrNull = mapLink.isEmpty ? null : mapLink;
    final initial = widget.initial;
    final address = initial == null
        ? CustomerAddress.create(
            label: label.isEmpty ? null : label,
            text: text,
            mapLink: linkOrNull,
            areaId: _areaId,
          )
        : initial.copyWith(
            label: label.isEmpty ? null : label,
            text: text,
            mapLink: linkOrNull,
            areaId: _areaId,
          );

    Navigator.of(context).pop(
      AddressEditorResult(address: address, makeDefault: _makeDefault),
    );
  }

  @override
  Widget build(BuildContext context) {
    // All areas (including inactive), so a saved address keeps
    // naming its area — the customer_card.dart precedent.
    final areas = ref.watch(deliveryAreasProvider).valueOrNull;
    String? areaName;
    if (_areaId != null && areas != null) {
      for (final area in areas) {
        if (area.id == _areaId) {
          areaName = area.name;
          break;
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? 'Add address' : 'Edit address',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('address_label_field'),
                controller: _labelController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  hintText: 'Home',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('address_text_field'),
                controller: _textController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: const OutlineInputBorder(),
                  errorText: _triedSave &&
                          _textController.text.trim().isEmpty
                      ? 'Address text is required.'
                      : null,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                key: const Key('address_area_field'),
                onTap: () => showDeliveryAreaSheet(
                  context,
                  onAreaSelected: (area) =>
                      setState(() => _areaId = area?.id),
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Delivery area (optional)',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(areaName ?? 'Not listed / other'),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('address_map_link_field'),
                controller: _mapLinkController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Location link (optional)',
                  border: const OutlineInputBorder(),
                  errorText: _mapLinkError(_mapLinkController.text),
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
              SwitchListTile(
                key: const Key('address_make_default_switch'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Make default'),
                value: _makeDefault,
                onChanged: _makeDefaultLocked
                    ? null
                    : (value) => setState(() => _makeDefault = value),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('address_editor_save'),
                  onPressed: _save,
                  child: const Text('Save address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
