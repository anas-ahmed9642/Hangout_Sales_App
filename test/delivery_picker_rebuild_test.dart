import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';
import 'package:hangout_sales_app/features/orders/widgets/delivery_picker.dart';

/// Finding 4: the charge dropdown must reflect programmatic changes
/// (autofill, area selection), not just the first build's initialValue.
void main() {
  Finder chargeText(String fragment) {
    return find.byWidgetPredicate(
      (widget) => widget is Text && (widget.data ?? '').contains(fragment),
    );
  }

  Future<void> pumpPicker(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: DeliveryPicker()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('charge dropdown reflects programmatic changes',
      (tester) async {
    final container = createTestContainer();
    final notifier = container.read(orderDraftProvider.notifier);

    notifier.setDeliveryCharge(180);
    await pumpPicker(tester, container);

    expect(chargeText('Rs. 180'), findsOneWidget);

    notifier.setDeliveryCharge(100);
    await tester.pump();

    expect(chargeText('Rs. 100'), findsOneWidget);
    expect(chargeText('Rs. 180'), findsNothing);
  });

  testWidgets('area field is hidden for Pickup and shown for delivery',
      (tester) async {
    final container = createTestContainer();
    final notifier = container.read(orderDraftProvider.notifier);

    await pumpPicker(tester, container);

    // Pickup (charge 0) by default: no area field.
    expect(find.text('Delivery area (optional)'), findsNothing);

    notifier.setDeliveryCharge(180);
    await tester.pump();

    expect(find.text('Delivery area (optional)'), findsOneWidget);

    notifier.setDeliveryCharge(0);
    await tester.pump();

    expect(find.text('Delivery area (optional)'), findsNothing);
  });
}