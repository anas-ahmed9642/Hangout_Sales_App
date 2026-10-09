import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customer_actions_provider.dart';

/// Call / WhatsApp actions for one normalized phone (plan 8.12, F3).
///
/// Both buttons go through [contactLauncherProvider]: Call opens the
/// dialer with the plain number, WhatsApp opens wa.me/92… — the URI
/// shapes are pinned by contact_launcher_test.dart.
class ContactActionsRow extends ConsumerWidget {
  final String phone;

  const ContactActionsRow({super.key, required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        OutlinedButton.icon(
          key: const Key('call_button'),
          onPressed: () =>
              ref.read(contactLauncherProvider).call(context, phone),
          icon: const Icon(Icons.call_outlined),
          label: const Text('Call'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          key: const Key('whatsapp_button'),
          onPressed: () => ref
              .read(contactLauncherProvider)
              .openWhatsApp(context, phone),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('WhatsApp'),
        ),
      ],
    );
  }
}
