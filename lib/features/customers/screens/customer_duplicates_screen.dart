import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_routes.dart';
import '../../../shared/widgets/hangout_app_bar.dart';
import '../models/customer.dart';
import '../models/customer_duplicate_candidate.dart';
import '../providers/customer_merge_provider.dart';
import '../providers/customers_provider.dart';

/// Possible duplicates (plan Phase 12): suggested pairs only. Each pair
/// can be reviewed (opens the merge screen with the suggested direction)
/// or dismissed ("Not a duplicate", remembered across sessions).
class CustomerDuplicatesScreen extends ConsumerWidget {
  const CustomerDuplicatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(allCustomersStreamProvider);
    final dismissedAsync = ref.watch(dismissedDuplicatePairsProvider);
    final candidates = ref.watch(duplicateCandidatesProvider);

    final Object? error = customersAsync.error ?? dismissedAsync.error;

    final Widget body;
    if (error != null) {
      body = _DuplicatesError(
        message: _friendlyError(error),
        onRetry: () {
          ref.invalidate(allCustomersStreamProvider);
          ref.invalidate(dismissedDuplicatePairsProvider);
        },
      );
    } else if (!customersAsync.hasValue || !dismissedAsync.hasValue) {
      body = const Center(child: CircularProgressIndicator());
    } else if (candidates.isEmpty) {
      body = const _DuplicatesEmpty();
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: candidates.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final candidate = candidates[index];
          return _CandidateCard(
            key: Key('duplicate_${candidate.pairKey}'),
            candidate: candidate,
            onReview: () => context.push(
              AppRoutes.customerMergePath(
                sourcePhone: candidate.suggestedSource.phone,
                targetPhone: candidate.suggestedTarget.phone,
              ),
            ),
            onDismiss: () => _dismiss(context, ref, candidate),
          );
        },
      );
    }

    return Scaffold(
      appBar: const HangoutAppBar(
        title: 'Possible duplicates',
        showBackButton: true,
      ),
      body: body,
    );
  }
}

Future<void> _dismiss(
  BuildContext context,
  WidgetRef ref,
  CustomerDuplicateCandidate candidate,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref
        .read(customerMergeRepositoryProvider)
        .dismissPair(candidate.first.phone, candidate.second.phone);

    if (!context.mounted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Dismissed. This pair will not be suggested again.'),
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
          content: Text('Unable to dismiss: ${_friendlyError(error)}'),
        ),
      );
  }
}

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

String _reasonLabel(DuplicateReason reason) {
  switch (reason) {
    case DuplicateReason.sameName:
      return 'Same name';
    case DuplicateReason.sameAddress:
      return 'Same address';
    case DuplicateReason.sameMapLink:
      return 'Same map link';
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    super.key,
    required this.candidate,
    required this.onReview,
    required this.onDismiss,
  });

  final CustomerDuplicateCandidate candidate;
  final VoidCallback onReview;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final reasons =
        DuplicateReason.values.where(candidate.reasons.contains).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PersonRow(customer: candidate.first),
            const SizedBox(height: 6),
            _PersonRow(customer: candidate.second),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final reason in reasons)
                  Chip(label: Text(_reasonLabel(reason))),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  key: Key('dismiss_${candidate.pairKey}'),
                  onPressed: onDismiss,
                  child: const Text('Not a duplicate'),
                ),
                FilledButton(
                  key: Key('review_${candidate.pairKey}'),
                  onPressed: onReview,
                  child: const Text('Review and merge'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            customer.name ?? 'Unnamed customer',
            style: theme.textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          customer.phone,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DuplicatesEmpty extends StatelessWidget {
  const _DuplicatesEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
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
              'No possible duplicates',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Customers sharing a name, address or map link will appear here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DuplicatesError extends StatelessWidget {
  const _DuplicatesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
              "Couldn't load duplicates",
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
