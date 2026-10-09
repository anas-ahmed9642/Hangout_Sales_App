import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/customer.dart';
import '../providers/customer_merge_provider.dart';
import '../providers/customer_orders_provider.dart';
import '../providers/customer_search_provider.dart';
import '../providers/customers_provider.dart';
import '../repositories/customer_merge_repository.dart';
import '../services/customer_merge_service.dart';

String? _normalizeOrNull(String? raw) {
  if (raw == null) return null;
  return PhoneNormalizer.normalize(raw);
}

String _label(Customer customer) => customer.name ?? customer.phone;

String _plural(int count, String noun) =>
    count == 1 ? '1 $noun' : '$count ${noun}s';

String _friendlyError(Object error) {
  var raw = error.toString();
  for (final prefix in const [
    'Exception: ',
    'Bad state: ',
    'Invalid argument(s): ',
  ]) {
    if (raw.startsWith(prefix)) {
      raw = raw.substring(prefix.length);
      break;
    }
  }
  return raw;
}

/// Merge review screen (plan Phase 12). SOURCE is the duplicate (its
/// orders move and it is archived), TARGET is the customer to keep.
/// Either phone may be missing and chosen on the screen. A reason is
/// required before the merge can run.
class CustomerMergeScreen extends ConsumerStatefulWidget {
  /// The duplicate (archived after the merge).
  final String? initialSourcePhone;

  /// The customer to keep (receives the orders).
  final String? initialTargetPhone;

  const CustomerMergeScreen({
    super.key,
    this.initialSourcePhone,
    this.initialTargetPhone,
  });

  @override
  ConsumerState<CustomerMergeScreen> createState() =>
      _CustomerMergeScreenState();
}

class _CustomerMergeScreenState extends ConsumerState<CustomerMergeScreen> {
  final TextEditingController _reasonController = TextEditingController();

  String? _sourcePhone;
  String? _targetPhone;
  bool _merging = false;
  int _ordersMoved = 0;

  @override
  void initState() {
    super.initState();
    _sourcePhone = _normalizeOrNull(widget.initialSourcePhone);
    _targetPhone = _normalizeOrNull(widget.initialTargetPhone);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _choose({required bool isSource}) async {
    final excluded = <String>{
      if (isSource && _targetPhone != null) _targetPhone!,
      if (!isSource && _sourcePhone != null) _sourcePhone!,
    };

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _CustomerPickerSheet(excludedPhones: excluded),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isSource) {
        _sourcePhone = picked;
      } else {
        _targetPhone = picked;
      }
    });
  }

  void _swap() {
    setState(() {
      final previousSource = _sourcePhone;
      _sourcePhone = _targetPhone;
      _targetPhone = previousSource;
    });
  }

  Future<void> _confirmAndMerge({
    required Customer source,
    required Customer target,
  }) async {
    final orderCount =
        ref.read(customerOrdersProvider(source.phone)).valueOrNull?.length;
    final orderText = orderCount == null
        ? 'the orders'
        : _plural(orderCount, 'order');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Merge customers?'),
        content: Text(
          'Move $orderText from ${_label(source)} to ${_label(target)} and '
          'archive ${_label(source)}?',
        ),
        actions: [
          TextButton(
            key: const Key('merge_dialog_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('merge_dialog_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _merging = true;
      _ordersMoved = 0;
    });

    final CustomerMergeResult result;
    try {
      result = await ref.read(customerMergeRepositoryProvider).mergeCustomers(
            sourcePhone: source.phone,
            targetPhone: target.phone,
            reason: _reasonController.text,
            onProgress: (moved) {
              if (mounted) {
                setState(() => _ordersMoved = moved);
              }
            },
          );
    } catch (error) {
      if (!mounted) return;

      setState(() => _merging = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            content: Text(
              'Merge failed: ${_friendlyError(error)}. You can run the merge '
              'again; orders already moved are skipped.',
            ),
          ),
        );
      return;
    }

    if (!mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            result.alreadyMerged
                ? '${_label(source)} was already merged into '
                    '${_label(target)}.'
                : 'Merged ${_label(source)} into ${_label(target)}. '
                    '${_plural(result.ordersMoved, 'order')} moved.',
          ),
        ),
      );

    context.pushReplacement(AppRoutes.customerDetailPath(target.phone));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourcePhone = _sourcePhone;
    final targetPhone = _targetPhone;

    final Customer? source = sourcePhone == null
        ? null
        : ref.watch(customerStreamByPhoneProvider(sourcePhone)).valueOrNull;
    final Customer? target = targetPhone == null
        ? null
        : ref.watch(customerStreamByPhoneProvider(targetPhone)).valueOrNull;
    final sourceOrders = sourcePhone == null
        ? null
        : ref.watch(customerOrdersProvider(sourcePhone)).valueOrNull;

    final String? blocker = (source != null && target != null)
        ? customerMergeBlocker(source: source, target: target)
        : null;

    return Scaffold(
      appBar: const HangoutAppBar(
        title: 'Merge customers',
        showBackButton: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Orders move to the customer you keep. The duplicate is '
            'archived and marked as merged.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _MergeSideCard(
            key: const Key('merge_source_card'),
            title: 'Duplicate (archived after the merge)',
            phone: sourcePhone,
            customer: source,
            orderCount: sourceOrders?.length,
            enabled: !_merging,
            onChange: () => _choose(isSource: true),
          ),
          if (sourcePhone != null && targetPhone != null)
            Center(
              child: IconButton(
                key: const Key('merge_swap_button'),
                tooltip: 'Swap direction',
                icon: const Icon(Icons.swap_vert),
                onPressed: _merging ? null : _swap,
              ),
            )
          else
            const SizedBox(height: 8),
          _MergeSideCard(
            key: const Key('merge_target_card'),
            title: 'Keep (receives the orders)',
            phone: targetPhone,
            customer: target,
            orderCount: null,
            enabled: !_merging,
            onChange: () => _choose(isSource: false),
          ),
          const SizedBox(height: 16),
          if (blocker != null)
            _BlockerCard(key: const Key('merge_blocker'), message: blocker)
          else if (source != null && target != null)
            _MergePreviewCard(
              key: const Key('merge_preview_card'),
              source: source,
              target: target,
              orderCount: sourceOrders?.length,
            ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('merge_reason_field'),
            controller: _reasonController,
            enabled: !_merging,
            maxLength: customerMergeReasonMaxLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Reason for merge',
              hintText: 'e.g. Same person, new number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _reasonController,
            builder: (context, value, _) {
              final readySource = source;
              final readyTarget = target;
              VoidCallback? onPressed;
              if (!_merging &&
                  value.text.trim().isNotEmpty &&
                  readySource != null &&
                  readyTarget != null &&
                  blocker == null) {
                onPressed = () => _confirmAndMerge(
                      source: readySource,
                      target: readyTarget,
                    );
              }
              return FilledButton.icon(
                key: const Key('merge_confirm_button'),
                onPressed: onPressed,
                icon: const Icon(Icons.merge_type),
                label: const Text('Merge customers'),
              );
            },
          ),
          if (_merging)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text('Moving orders... $_ordersMoved moved'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MergeSideCard extends StatelessWidget {
  const _MergeSideCard({
    super.key,
    required this.title,
    required this.phone,
    required this.customer,
    required this.orderCount,
    required this.enabled,
    required this.onChange,
  });

  final String title;
  final String? phone;
  final Customer? customer;
  final int? orderCount;
  final bool enabled;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shownPhone = phone;
    final shownCustomer = customer;
    final count = orderCount;

    final String headline;
    String? detail;
    if (shownPhone == null) {
      headline = 'No customer selected';
    } else if (shownCustomer == null) {
      headline = shownPhone;
      detail = 'Customer not found';
    } else {
      headline = shownCustomer.name ?? 'Unnamed customer';
      detail = count == null
          ? shownCustomer.phone
          : '${shownCustomer.phone} - ${_plural(count, 'order')}';
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(headline, style: theme.textTheme.titleMedium),
                  if (detail != null) Text(detail),
                ],
              ),
            ),
            TextButton(
              onPressed: enabled ? onChange : null,
              child: Text(shownPhone == null ? 'Choose' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockerCard extends StatelessWidget {
  const _BlockerCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.block, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MergePreviewCard extends StatelessWidget {
  const _MergePreviewCard({
    super.key,
    required this.source,
    required this.target,
    required this.orderCount,
  });

  final Customer source;
  final Customer target;
  final int? orderCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = planCustomerMerge(source: source, target: target);
    final count = orderCount;

    final lines = <String>[
      count == null
          ? 'Counting orders...'
          : '${_plural(count, 'order')} will move to ${_label(target)}.',
    ];

    if (plan.addressesToAdd.isEmpty) {
      lines.add('No new addresses to add.');
    } else {
      lines.add(
        '${_plural(plan.addressesToAdd.length, 'address')} will be added:',
      );
      for (final address in plan.addressesToAdd) {
        lines.add('- ${address.label}: ${address.text}');
      }
    }

    if (plan.notesChanged) {
      lines.add(
        plan.notesTruncated
            ? 'Internal notes will be appended, shortened to fit 300 '
                'characters. The full text stays on the archived customer.'
            : 'Internal notes will be appended.',
      );
    } else if (plan.notesTruncated) {
      lines.add(
        'Internal notes do not fit and stay on the archived customer.',
      );
    }

    if (plan.deliveryNotesChanged) {
      lines.add(
        plan.deliveryNotesTruncated
            ? 'Delivery notes will be appended, shortened to fit 200 '
                'characters. The full text stays on the archived customer.'
            : 'Delivery notes will be appended.',
      );
    } else if (plan.deliveryNotesTruncated) {
      lines.add(
        'Delivery notes do not fit and stay on the archived customer.',
      );
    }

    lines.add(
      '${_label(source)} will be archived and marked '
      '"Merged into ${target.phone}".',
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What will happen', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends ConsumerStatefulWidget {
  const _CustomerPickerSheet({required this.excludedPhones});

  final Set<String> excludedPhones;

  @override
  ConsumerState<_CustomerPickerSheet> createState() =>
      _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends ConsumerState<_CustomerPickerSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersStreamProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                key: const Key('merge_picker_search'),
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search name or number',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: customersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_friendlyError(error)),
                  ),
                ),
                data: (customers) {
                  final eligible = customers
                      .where(
                        (customer) =>
                            customer.mergedInto == null &&
                            !widget.excludedPhones.contains(customer.phone),
                      )
                      .toList();
                  final results = filterAndSortCustomers(
                    eligible,
                    query: _query,
                    filter: CustomerFilter.all,
                    sort: CustomerSort.nameAsc,
                    now: DateTime.now(),
                  );

                  if (results.isEmpty) {
                    return const Center(child: Text('No customers found'));
                  }

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final customer = results[index];
                      return ListTile(
                        key: Key('merge_pick_${customer.phone}'),
                        title: Text(customer.name ?? 'Unnamed customer'),
                        subtitle: Text(customer.phone),
                        onTap: () =>
                            Navigator.of(context).pop(customer.phone),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
