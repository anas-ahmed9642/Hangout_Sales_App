// File: test/helpers/test_container.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a fresh ProviderContainer for a single test, with any
/// necessary overrides applied, and registers disposal so containers
/// don't leak across tests.
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}