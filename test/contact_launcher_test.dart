import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/customers/services/contact_launcher.dart';

/// Pumps a bare Scaffold and returns a context under it.
Future<BuildContext> _context(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: Scaffold()));
  return tester.element(find.byType(Scaffold));
}

void main() {
  testWidgets('openMap launches the parsed maps URI', (tester) async {
    Uri? launched;
    var canLaunchCalls = 0;

    final launcher = ContactLauncher(
      canLaunch: (url) async {
        canLaunchCalls++;
        return true;
      },
      launch: (url) async {
        launched = url;
        return true;
      },
    );

    final context = await _context(tester);

    await launcher.openMap(
      context,
      'https://www.google.com/maps/search/?api=1&query=24.8607,67.0011',
    );

    expect(canLaunchCalls, 1);
    expect(
      launched.toString(),
      'https://www.google.com/maps/search/?api=1&query=24.8607,67.0011',
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('openMap ignores an unrecognized link', (tester) async {
    var launched = false;

    final launcher = ContactLauncher(
      canLaunch: (_) async => true,
      launch: (_) async {
        launched = true;
        return true;
      },
    );

    final context = await _context(tester);

    await launcher.openMap(context, 'not a link');

    expect(launched, isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('openMap shows a SnackBar when launch is unavailable',
      (tester) async {
    final launcher = ContactLauncher(
      canLaunch: (_) async => false,
      launch: (_) async => true,
    );

    final context = await _context(tester);

    await launcher.openMap(context, '24.8607, 67.0011');
    await tester.pump();

    expect(find.text('Could not open Google Maps'), findsOneWidget);
  });

  testWidgets('call builds a tel: URI', (tester) async {
    Uri? launched;

    final launcher = ContactLauncher(
      canLaunch: (_) async => true,
      launch: (url) async {
        launched = url;
        return true;
      },
    );

    final context = await _context(tester);

    await launcher.call(context, '03001234567');

    expect(launched.toString(), 'tel:03001234567');
  });

  testWidgets('openWhatsApp builds a wa.me URI', (tester) async {
    Uri? launched;

    final launcher = ContactLauncher(
      canLaunch: (_) async => true,
      launch: (url) async {
        launched = url;
        return true;
      },
    );

    final context = await _context(tester);

    await launcher.openWhatsApp(context, '03001234567');

    expect(launched.toString(), 'https://wa.me/923001234567');
  });
}