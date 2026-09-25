import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/order.dart';
import '../providers/order_history_provider.dart';
import '../providers/order_search_provider.dart';
import '../widgets/order_history_item.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the search query
    final searchQuery = ref.watch(orderSearchQueryProvider);
    final isSearching = searchQuery.trim().isNotEmpty;

    // Watch the new filter state
    final isUnpaidOnly = ref.watch(unpaidFilterProvider);
    final isEditedOnly = ref.watch(editedFilterProvider);

    // When the cashier is searching by phone, search results remain
    // the source. Otherwise, Unpaid Only switches to the global unpaid
    // stream rather than the selected business day's history.
    final asyncData = isSearching
        ? ref.watch(orderSearchProvider)
        : isUnpaidOnly
        ? ref.watch(allUnpaidOrdersProvider)
        : ref.watch(orderHistoryProvider);

    return Scaffold(
      appBar: HangoutAppBar(
        title: 'Order History',
        actions: [
          IconButton(
            tooltip: 'Filter by Date',
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final currentDate = ref.read(selectedDateProvider);
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: currentDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );

              if (pickedDate != null) {
                ref.read(selectedDateProvider.notifier).state = pickedDate;
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- THE SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Search by phone number...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          // Clear the text field by resetting the provider
                          ref.invalidate(orderSearchQueryProvider);
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // Update the provider as the cashier types
                ref.read(orderSearchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // --- THE FILTER TOGGLES ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Orders'),
                  selected: !isUnpaidOnly,
                  onSelected: (_) {
                    ref.read(unpaidFilterProvider.notifier).state = false;
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Unpaid Only'),
                  selected: isUnpaidOnly,
                  onSelected: (_) {
                    ref.read(unpaidFilterProvider.notifier).state = true;
                  },
                  selectedColor: Colors.orange.shade100,
                  checkmarkColor: Colors.orange.shade900,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Edited'),
                  selected: isEditedOnly,
                  onSelected: (selected) {
                    ref.read(editedFilterProvider.notifier).state = selected;
                  },
                  avatar: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // --- THE LIST VIEW ---
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (isSearching) {
                  ref.invalidate(orderSearchProvider);
                  await ref.read(orderSearchProvider.future);
                } else if (isUnpaidOnly) {
                  ref.invalidate(allUnpaidOrdersProvider);
                  await ref.read(allUnpaidOrdersProvider.future);
                } else {
                  ref.invalidate(orderHistoryProvider);
                  await ref.read(orderHistoryProvider.future);
                }
              },
              child: asyncData.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _HistoryError(
                  message: _friendlyErrorMessage(error),
                  onRetry: () {
                    if (isSearching) {
                      ref.invalidate(orderSearchProvider);
                    } else {
                      ref.invalidate(orderHistoryProvider);
                    }
                  },
                ),
                data: (orders) {
                  // --- THE FILTER LOGIC ---
                  var displayOrders = orders;

                  if (isUnpaidOnly) {
                    displayOrders = displayOrders
                        .where(
                          (order) =>
                              order.paymentStatus == PaymentStatus.unpaid,
                        )
                        .toList();
                  }

                  if (isEditedOnly) {
                    displayOrders = displayOrders
                        .where((order) => order.editCount > 0)
                        .toList();
                  }

                  if (displayOrders.isEmpty) {
                    return const _HistoryEmpty();
                  }

                  final sortedOrders = [...displayOrders]
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: sortedOrders.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = sortedOrders[index];

                      return OrderHistoryItem(
                        order: order,
                        onTap: () {
                          // The Boundary! We pass the 'order' object straight in.
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailScreen(order: order),
                            ),
                          );
                        },
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

  String _friendlyErrorMessage(Object error) {
    final raw = error.toString();
    return raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length)
        : raw;
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Wrapped in a scrollable so RefreshIndicator's pull gesture
        // still works even when there's nothing to scroll.
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
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No orders found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Orders from this business day will appear here.',
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

class _HistoryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HistoryError({required this.message, required this.onRetry});

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
                      "Couldn't load orders",
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
