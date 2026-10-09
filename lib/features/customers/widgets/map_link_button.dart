import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/map_link_helper.dart';
import '../providers/customer_actions_provider.dart';

/// Map button for one saved address (plan 8.12, F4).
///
/// Renders nothing when [mapLink] is null or not a recognized Google
/// Maps link / coordinates — the button appears only on addresses
/// with a link. Goes through [contactLauncherProvider] so tests can
/// capture the launch; failures surface as the launcher's SnackBar.
/// Icon and tooltip match the New Order form's map button
/// (customer_form.dart).
class MapLinkButton extends ConsumerWidget {
  final String? mapLink;

  const MapLinkButton({super.key, required this.mapLink});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final link = mapLink;
    if (link == null || MapLinkHelper.parse(link) == null) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: 'Open in Maps',
      icon: const Icon(Icons.map_outlined),
      onPressed: () =>
          ref.read(contactLauncherProvider).openMap(context, link),
    );
  }
}
