import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../shared/widgets/hangout_app_bar.dart';
import '../../delivery_areas/models/delivery_area.dart';
import '../../delivery_areas/providers/delivery_areas_provider.dart';
import '../../orders/screens/order_detail_screen.dart';
import '../../orders/widgets/order_history_item.dart';
import '../models/customer.dart';
import '../models/customer_address.dart';
import '../providers/customer_orders_provider.dart';
import '../providers/customer_repository_provider.dart';
import '../providers/customer_stats_provider.dart';
import '../providers/customers_provider.dart';
import '../services/customer_address_ops.dart';
import '../widgets/address_editor_sheet.dart';
import '../widgets/contact_actions_row.dart';
import '../widgets/customer_stats_card.dart';
import '../widgets/map_link_button.dart';

/// Customer Detail (plan 8.12, Phase 8): everything about one
/// customer in one place — profile, contact actions (F3), saved
/// addresses (F22), notes, derived stats (F19) and order history,
/// with archive / restore in the app-bar menu (F25).
///
/// The customer loads LIVE from [customerStreamByPhoneProvider]:
/// profile edits, address changes and archive/restore reflect the
/// moment the repository write lands, with no manual invalidation.
/// Every write goes through the existing CustomerRepository methods
/// — this phase changes no interface.
class CustomerDetailScreen extends ConsumerWidget {
  /// The customer's phone — its id. The route and the list screen
  /// pass it normalized; build() normalizes defensively regardless.
  final String phone;

  const CustomerDetailScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The route passes the normalized phone (list screen, reload);
    // normalize defensively anyway so a hand-typed URL still finds
    // the customer (repository lookups normalize the same way).
    final normalizedPhone = PhoneNormalizer.normalize(phone) ?? phone;
    final customerAsync =
        ref.watch(customerStreamByPhoneProvider(normalizedPhone));
    final customer = customerAsync.valueOrNull;

    return Scaffold(
      appBar: HangoutAppBar(
        title: customer == null
            ? 'Customer'
            : customer.name ?? 'Unnamed customer',
        showBackButton: true,
        actions: [
          if (customer != null && customer.mergedInto == null)
            PopupMenuButton<String>(
              key: const Key('customer_detail_menu'),
              tooltip: 'Customer actions',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'toggleArchived') {
                  _toggleArchived(context, ref, customer);
                } else if (value == 'merge') {
                  context.push(
                    AppRoutes.customerMergePath(sourcePhone: customer.phone),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'toggleArchived',
                  child: Text(customer.archived ? 'Restore' : 'Archive'),
                ),
                if (!customer.archived)
                  const PopupMenuItem<String>(
                    key: Key('customer_detail_merge_item'),
                    value: 'merge',
                    child: Text('Merge into another customer'),
                  ),
              ],
            ),
        ],
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _CustomerDetailError(
          message: _friendlyErrorMessage(error),
          onRetry: () => ref.invalidate(
            customerStreamByPhoneProvider(normalizedPhone),
          ),
        ),
        data: (loaded) {
          if (loaded == null) {
            return const _CustomerNotFound();
          }
          return _CustomerDetailBody(customer: loaded);
        },
      ),
    );
  }
}

enum _ProfileField { name, deliveryNotes, notes }

String _friendlyErrorMessage(Object error) {
  final raw = error.toString();
  if (raw.startsWith('Exception: ')) {
    return raw.substring('Exception: '.length);
  }
  if (raw.startsWith('Bad state: ')) {
    return raw.substring('Bad state: '.length);
  }
  return raw;
}

void _showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        content: Text(message),
      ),
    );
}

Future<void> _toggleArchived(
  BuildContext context,
  WidgetRef ref,
  Customer customer,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(customerRepositoryProvider)
        .setArchived(customer.phone, !customer.archived);

    if (!context.mounted) return;

    final label = customer.name ?? customer.phone;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            customer.archived ? '$label restored.' : '$label archived.',
          ),
        ),
      );
  } catch (error) {
    if (!context.mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          content: Text('Unable to update customer: $error'),
        ),
      );
  }
}

/// One profile-edit dialog for name / delivery notes / internal
/// notes (plan Phase 8: "profile edit via small dialogs"). Saving an
/// empty field clears it — the repository contract (null leaves a
/// field unchanged, '' clears it), surfaced here by always passing
/// the edited field. Over-limit input is capped by maxLength and
/// also guarded by the repository's own validation.
Future<void> _editProfile(
  BuildContext context,
  WidgetRef ref,
  Customer customer,
  _ProfileField field,
) async {
  final (title, label, initial, maxLength, success) = switch (field) {
    _ProfileField.name => (
        'Edit name',
        'Name',
        customer.name ?? '',
        60,
        'Name updated.'
      ),
    _ProfileField.deliveryNotes => (
        'Edit delivery notes',
        'Delivery notes',
        customer.deliveryNotes ?? '',
        200,
        'Delivery notes updated.'
      ),
    _ProfileField.notes => (
        'Edit internal notes',
        'Internal notes',
        customer.notes ?? '',
        300,
        'Internal notes updated.'
      ),
  };

  final saved = await showDialog<String>(
    context: context,
    builder: (dialogContext) => _TextEditDialog(
      title: title,
      label: label,
      initial: initial,
      maxLength: maxLength,
    ),
  );

  // Dismissed, or nothing actually changed: save nothing.
  if (saved == null || saved.trim() == initial || !context.mounted) {
    return;
  }

  try {
    final repository = ref.read(customerRepositoryProvider);
    switch (field) {
      case _ProfileField.name:
        await repository.updateProfile(customer.phone, name: saved);
      case _ProfileField.deliveryNotes:
        await repository.updateProfile(
          customer.phone,
          deliveryNotes: saved,
        );
      case _ProfileField.notes:
        await repository.updateProfile(customer.phone, notes: saved);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(success),
        ),
      );
  } catch (error) {
    if (!context.mounted) return;
    _showErrorSnack(context, 'Unable to update customer: $error');
  }
}

/// Saves one address-list transition (customer_address_ops.dart)
/// and confirms it with a snackbar; failures keep the screen as-is
/// and surface the error.
Future<void> _saveAddresses(
  BuildContext context,
  WidgetRef ref,
  Customer customer,
  AddressListUpdate update,
  String success,
) async {
  try {
    await ref.read(customerRepositoryProvider).saveAddresses(
          customer.phone,
          update.addresses,
          update.defaultAddressId,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(success),
        ),
      );
  } catch (error) {
    if (!context.mounted) return;
    _showErrorSnack(context, 'Unable to update addresses: $error');
  }
}

/// Add / edit one address through the editor sheet (plan 8.12, F22).
/// The default rules live in customer_address_ops.dart.
Future<void> _openAddressEditor(
  BuildContext context,
  WidgetRef ref,
  Customer customer, {
  CustomerAddress? initial,
}) async {
  final result = await showAddressEditorSheet(
    context,
    initial: initial,
    isDefault:
        initial != null && initial.id == effectiveDefaultAddressId(customer),
    isFirstAddress: customer.addresses.isEmpty,
  );

  if (result == null || !context.mounted) return;

  if (initial == null) {
    await _saveAddresses(
      context,
      ref,
      customer,
      addAddress(customer, result.address, makeDefault: result.makeDefault),
      'Address added.',
    );
  } else {
    await _saveAddresses(
      context,
      ref,
      customer,
      replaceAddress(
        customer,
        result.address,
        makeDefault: result.makeDefault,
      ),
      'Address updated.',
    );
  }
}

/// Remove one address after confirmation. Removing the default
/// promotes the first remaining address; removing the last leaves a
/// valid customer with no addresses (plan 8.12).
Future<void> _removeAddress(
  BuildContext context,
  WidgetRef ref,
  Customer customer,
  CustomerAddress address,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Remove this address?'),
      content: Text(address.text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  await _saveAddresses(
    context,
    ref,
    customer,
    removeAddress(customer, address.id),
    'Address removed.',
  );
}

Future<void> _makeDefault(
  BuildContext context,
  WidgetRef ref,
  Customer customer,
  CustomerAddress address,
) {
  return _saveAddresses(
    context,
    ref,
    customer,
    setDefaultAddress(customer, address.id),
    'Default address updated.',
  );
}

class _CustomerDetailBody extends ConsumerWidget {
  final Customer customer;

  const _CustomerDetailBody({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final areas = ref.watch(deliveryAreasProvider).valueOrNull ??
        const <DeliveryArea>[];

    String? areaNameFor(CustomerAddress address) {
      if (address.areaId == null) return null;
      for (final area in areas) {
        if (area.id == address.areaId) return area.name;
      }
      return null;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                customer.name ?? 'Unnamed customer',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              key: const Key('edit_name_button'),
              tooltip: 'Edit name',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  _editProfile(context, ref, customer, _ProfileField.name),
            ),
          ],
        ),
        Text(customer.phone, style: textTheme.bodyLarge),
        const SizedBox(height: 8),
        ContactActionsRow(phone: customer.phone),
        if (customer.archived) ...[
          const SizedBox(height: 12),
          const _InfoNote(
            icon: Icons.archive_outlined,
            text: 'This customer is archived.',
          ),
        ],
        if (customer.mergedInto != null) ...[
          const SizedBox(height: 12),
          _InfoNote(
            icon: Icons.merge_type_outlined,
            text: 'Merged into ${customer.mergedInto}',
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: _SectionTitle('Addresses')),
            IconButton(
              key: const Key('add_address_button'),
              tooltip: 'Add address',
              icon: const Icon(Icons.add),
              onPressed: () => _openAddressEditor(context, ref, customer),
            ),
          ],
        ),
        if (customer.addresses.isEmpty)
          Text(
            'No saved addresses',
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final address in customer.addresses)
            _AddressRow(
              isDefault: address.id == effectiveDefaultAddressId(customer),
              address: address,
              areaName: areaNameFor(address),
              onEdit: () => _openAddressEditor(
                context,
                ref,
                customer,
                initial: address,
              ),
              onRemove: () => _removeAddress(context, ref, customer, address),
              onMakeDefault: () =>
                  _makeDefault(context, ref, customer, address),
            ),
        const SizedBox(height: 16),
        _NotesRow(
          label: 'Delivery notes',
          value: customer.deliveryNotes,
          editKey: const Key('edit_delivery_notes_button'),
          onEdit: () => _editProfile(
            context,
            ref,
            customer,
            _ProfileField.deliveryNotes,
          ),
        ),
        const SizedBox(height: 12),
        _NotesRow(
          label: 'Internal notes',
          value: customer.notes,
          editKey: const Key('edit_notes_button'),
          onEdit: () =>
              _editProfile(context, ref, customer, _ProfileField.notes),
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Stats'),
        const SizedBox(height: 8),
        _StatsSection(phone: customer.phone),
        const SizedBox(height: 24),
        const _SectionTitle('Order history'),
        const SizedBox(height: 8),
        _HistorySection(phone: customer.phone),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// One saved address: star when it is the default, label · area,
/// the address text, and its map / make-default / edit / remove
/// actions. The map button self-hides when the address has no valid
/// link (File 4).
class _AddressRow extends StatelessWidget {
  final bool isDefault;
  final CustomerAddress address;
  final String? areaName;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onMakeDefault;

  const _AddressRow({
    required this.isDefault,
    required this.address,
    required this.areaName,
    required this.onEdit,
    required this.onRemove,
    required this.onMakeDefault,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: ValueKey('address_${address.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isDefault) ...[
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Color(0xFFD4AF37),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        areaName == null
                            ? address.label
                            : '${address.label} · $areaName',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(address.text, style: textTheme.bodyMedium),
              ],
            ),
          ),
          MapLinkButton(mapLink: address.mapLink),
          if (!isDefault)
            IconButton(
              key: ValueKey('make_default_${address.id}'),
              tooltip: 'Make default',
              icon: const Icon(Icons.star_border),
              onPressed: onMakeDefault,
            ),
          IconButton(
            key: ValueKey('edit_address_${address.id}'),
            tooltip: 'Edit address',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            key: ValueKey('remove_address_${address.id}'),
            tooltip: 'Remove address',
            icon: const Icon(Icons.delete_outline),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _NotesRow extends StatelessWidget {
  final String label;
  final String? value;
  final Key editKey;
  final VoidCallback onEdit;

  const _NotesRow({
    required this.label,
    required this.value,
    required this.editKey,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value ?? 'Not set',
                style: textTheme.bodyMedium?.copyWith(
                  color: value == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: editKey,
          tooltip: 'Edit $label',
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
      ],
    );
  }
}

/// The small profile-edit dialog (name / delivery notes / internal
/// notes). Owns and disposes its text controller.
class _TextEditDialog extends StatefulWidget {
  final String title;
  final String label;
  final String initial;
  final int maxLength;

  const _TextEditDialog({
    required this.title,
    required this.label,
    required this.initial,
    required this.maxLength,
  });

  @override
  State<_TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<_TextEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('profile_edit_field'),
        controller: _controller,
        maxLength: widget.maxLength,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Stats block: renders [CustomerStatsCard] only once the orders
/// have actually loaded, so a loading customer never flashes a
/// false "No orders yet"; failures get a retry that re-subscribes
/// the orders stream.
class _StatsSection extends ConsumerWidget {
  final String phone;

  const _StatsSection({required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider(phone));

    return ordersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _OrdersRetry(
        message: 'Could not load stats.',
        onRetry: () => ref.invalidate(customerOrdersProvider(phone)),
      ),
      data: (_) => CustomerStatsCard(
        stats: ref.watch(customerStatsProvider(phone)),
      ),
    );
  }
}

/// Order history: the first [_initialCount] orders, then a
/// "Show all" button — an unbounded Column of history items inside
/// the page ListView would build every row of a long history at
/// once. Tapping a row pushes Order Detail with the order object
/// (order_history_screen.dart precedent).
class _HistorySection extends ConsumerStatefulWidget {
  final String phone;

  const _HistorySection({required this.phone});

  @override
  ConsumerState<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends ConsumerState<_HistorySection> {
  static const int _initialCount = 20;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(customerOrdersProvider(widget.phone));

    return ordersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _OrdersRetry(
        message: 'Could not load order history.',
        onRetry: () =>
            ref.invalidate(customerOrdersProvider(widget.phone)),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Text(
            'No orders yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }

        final visible =
            _showAll ? orders : orders.take(_initialCount).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final order in visible)
              OrderHistoryItem(
                key: ValueKey('customer_order_${order.id}'),
                order: order,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          OrderDetailScreen(order: order),
                    ),
                  );
                },
              ),
            if (!_showAll && orders.length > _initialCount)
              TextButton(
                key: const Key('show_all_orders_button'),
                onPressed: () => setState(() => _showAll = true),
                child: Text('Show all ${orders.length} orders'),
              ),
          ],
        );
      },
    );
  }
}

class _OrdersRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OrdersRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      ],
    );
  }
}

class _CustomerNotFound extends StatelessWidget {
  const _CustomerNotFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Customer not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'This customer may have been removed.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CustomerDetailError({
    required this.message,
    required this.onRetry,
  });

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
              "Couldn't load customer",
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
