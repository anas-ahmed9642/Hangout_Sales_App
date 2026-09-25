import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/order_draft_provider.dart';

// 1. Upgraded to a ConsumerStatefulWidget
class CustomerForm extends ConsumerStatefulWidget {
  const CustomerForm({super.key});

  @override
  ConsumerState<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<CustomerForm> {
  // 2. Created controllers for all three fields
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if there is already data in the draft when the screen loads
    final draft = ref.read(orderDraftProvider);
    _nameController = TextEditingController(text: draft.customerName ?? '');
    _phoneController = TextEditingController(text: draft.customerPhone ?? '');
    _addressController = TextEditingController(text: draft.customerAddress ?? '');
  }

  @override
  void dispose() {
    // Prevent memory leaks!
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(orderDraftProvider.notifier);

    // 3. The magic listener: if the state gets cleared (Discard Order), clear the text boxes!
    ref.listen(orderDraftProvider, (previous, next) {
      if (next.customerName == null || next.customerName!.isEmpty) {
        if (_nameController.text.isNotEmpty) _nameController.clear();
      }
      if (next.customerPhone == null || next.customerPhone!.isEmpty) {
        if (_phoneController.text.isNotEmpty) _phoneController.clear();
      }
      if (next.customerAddress == null || next.customerAddress!.isEmpty) {
        if (_addressController.text.isNotEmpty) _addressController.clear();
      }
    });

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
          controller: _nameController, // Replaced initialValue with controller
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setCustomerName,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController, // Replaced initialValue with controller
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setCustomerPhone,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController, // Replaced initialValue with controller
          keyboardType: TextInputType.streetAddress,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setCustomerAddress,
        ),
      ],
    );
  }
}