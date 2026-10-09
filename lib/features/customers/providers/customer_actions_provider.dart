import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/contact_launcher.dart';

/// The single [ContactLauncher] the customer UI uses (plan 6.5).
///
/// Widgets never call url_launcher directly; they read this provider,
/// so widget tests override it with a launcher whose canLaunch/launch
/// callbacks capture URIs instead of opening apps
/// (contact_launcher_test.dart pattern). Mirrors
/// customerRepositoryProvider: one place hands the service out.
final contactLauncherProvider = Provider<ContactLauncher>((ref) {
  return ContactLauncher();
});
