import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/map_link_helper.dart';
import '../../../core/utils/phone_normalizer.dart';

/// Wraps url_launcher so widgets never call it directly and tests can
/// fake it (plan 6.5). All launches use LaunchMode.externalApplication.
/// Failures show a SnackBar and never throw into the UI.
class ContactLauncher {
  final Future<bool> Function(Uri url) _canLaunch;
  final Future<bool> Function(Uri url) _launch;

  ContactLauncher({
    Future<bool> Function(Uri url)? canLaunch,
    Future<bool> Function(Uri url)? launch,
  })  : _canLaunch = canLaunch ?? canLaunchUrl,
        _launch = launch ?? _defaultLaunch;

  static Future<bool> _defaultLaunch(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  /// Opens a Google Maps link or coordinates. No-op for unrecognized
  /// input (the map button only shows for valid links; this is defensive).
  Future<void> openMap(BuildContext context, String mapLink) async {
    final target = MapLinkHelper.parse(mapLink);
    if (target == null) {
      return;
    }
    await _open(
      context,
      MapLinkHelper.toLaunchUri(target),
      'Could not open Google Maps',
    );
  }

  /// Opens the dialer for a normalized phone.
  Future<void> call(BuildContext context, String normalizedPhone) async {
    await _open(
      context,
      Uri(scheme: 'tel', path: normalizedPhone),
      'Could not open the dialer',
    );
  }

  /// Opens a WhatsApp chat for a normalized phone.
  Future<void> openWhatsApp(
    BuildContext context,
    String normalizedPhone,
  ) async {
    await _open(
      context,
      Uri.parse(
        'https://wa.me/${PhoneNormalizer.toInternational(normalizedPhone)}',
      ),
      'Could not open WhatsApp',
    );
  }

  Future<void> _open(
    BuildContext context,
    Uri uri,
    String failureMessage,
  ) async {
    try {
      if (!await _canLaunch(uri)) {
        if (context.mounted) {
          _snack(context, failureMessage);
        }
        return;
      }
      final launched = await _launch(uri);
      if (!launched) {
        if (context.mounted) {
          _snack(context, failureMessage);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _snack(context, failureMessage);
      }
    }
  }

  void _snack(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}