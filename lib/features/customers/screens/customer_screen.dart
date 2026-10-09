import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/customer.dart';
import '../providers/customer_merge_provider.dart';
import '../providers/customer_repository_provider.dart';
import '../providers/customer_search_provider.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_card.dart';

/// Customers list (plan 8.11, Phase 7).
///
/// One archived-inclusive stream ([allCustomersStreamProvider]) is
/// filtered and ordered in memory by [customerSearchResultsProvider];
/// typing and slice switches never re-query Firestore. The search
/// field is uncontrolled apart from its controller, which exists so
/// the clear button can empty the visible text; typing writes the
/// query provider only (expense-history precedent), so the field
/// never rebuilds its own value and never loses focus.
///
/// Every state provider here is watched for the screen's whole
/// lifetime, so writing them with ref.read(...notifier).state in
/// callbacks always has a live listener.
///
/// Row taps push the Customer Detail route (Phase 8,
/// [AppRoutes.customerDetailPath]); the stream, filters and sort
/// are unchanged from Phase 7.
class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key});

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(customerSearchQueryProvider);
    final filter = ref.watch(customerFilterProvider);
    final sort = ref.watch(customerSortProvider);
    final customersAsync = ref.watch(allCustomersStreamProvider);
    final results = ref.watch(customerSearchResultsProvider);
    final duplicateCount = ref.watch(duplicateCandidatesProvider).length;

    return Scaffold(
      appBar: const HangoutAppBar(title: 'Customers'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              key: const Key('customer_search_field'),
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search name or number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(customerSearchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => ref
                  .read(customerSearchQueryProvider.notifier)
                  .state = value,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: filter == CustomerFilter.all,
                          onSelected: (_) => ref
                              .read(customerFilterProvider.notifier)
                              .state = CustomerFilter.all,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Win-back 30d+'),
                          selected: filter == CustomerFilter.winBack,
                          onSelected: (_) => ref
                              .read(customerFilterProvider.notifier)
                              .state = CustomerFilter.winBack,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Archived'),
                          selected: filter == CustomerFilter.archived,
                          onSelected: (_) => ref
                              .read(customerFilterProvider.notifier)
                              .state = CustomerFilter.archived,
                        ),
                      ],
                    ),
                  ),
                ),
                // Win-back has a fixed ordering (derived order
                // count), so the sort control hides while it is open
                // instead of sitting there ignored.
                if (filter != CustomerFilter.winBack) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<CustomerSort>(
                    key: const Key('customer_sort_menu'),
                  tooltip: 'Sort customers',
                  onSelected: (value) =>
                      ref.read(customerSortProvider.notifier).state = value,
                  itemBuilder: (context) => const [
                    PopupMenuItem<CustomerSort>(
                      value: CustomerSort.recentFirst,
                      child: Text('Recent first'),
                    ),
                    PopupMenuItem<CustomerSort>(
                      value: CustomerSort.nameAsc,
                      child: Text('Name A-Z'),
                    ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        sort == CustomerSort.nameAsc
                            ? 'Name A-Z'
                            : 'Recent first',
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                  ),
                ],
              ],
            ),
          ),
          if (duplicateCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  key: const Key('possible_duplicates_entry'),
                  leading: const Icon(Icons.merge_type_outlined),
                  title: Text('Possible duplicates ($duplicateCount)'),
                  subtitle: const Text(
                    'Review customers that may be the same person',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.customerDuplicates),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allCustomersStreamProvider);
                await ref.read(allCustomersStreamProvider.future);
              },
              child: customersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => _CustomersError(
                  message: _friendlyErrorMessage(error),
                  onRetry: () => ref.invalidate(allCustomersStreamProvider),
                ),
                data: (customers) {
                  if (customers.isEmpty) {
                    return const _CustomersEmpty(
                      title: 'No customers yet',
                      message:
                          'Customers saved from orders will appear here.',
                    );
                  }
                  if (results.isEmpty) {
                    if (query.trim().isNotEmpty) {
                      return const _CustomersEmpty(
                        title: 'No customers found',
                        message: 'Try a different search or filter.',
                      );
                    }
                    if (filter == CustomerFilter.winBack) {
                      return const _CustomersEmpty(
                        title: 'No customers to win back',
                        message:
                            'Customers inactive for 30+ days will appear here.',
                      );
                    }
                    if (filter == CustomerFilter.archived) {
                      return const _CustomersEmpty(
                        title: 'No archived customers',
                        message: 'Archived customers will appear here.',
                      );
                    }
                    return const _CustomersEmpty(
                      title: 'No customers found',
                      message: 'Try a different search or filter.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: results.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final customer = results[index];
                      return CustomerCard(
                        customer: customer,
                        showOrderCount: filter == CustomerFilter.winBack,
                        onTap: () => context.push(
                          AppRoutes.customerDetailPath(customer.phone),
                        ),
                        onToggleArchived: () => _toggleArchived(customer),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleArchived(Customer customer) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(customerRepositoryProvider)
          .setArchived(customer.phone, !customer.archived);

      if (!mounted) return;

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
      if (!mounted) return;

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

  String _friendlyErrorMessage(Object error) {
    final raw = error.toString();
    return raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length)
        : raw;
  }
}

class _CustomersEmpty extends StatelessWidget {
  final String title;
  final String message;

  const _CustomersEmpty({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scrollable so RefreshIndicator's pull gesture still works
        // when there is nothing to scroll.
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CustomersError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CustomersError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
                      "Couldn't load customers",
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
            ),
          ),
        );
      },
    );
  }
}
