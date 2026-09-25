import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';
import 'package:hangout_sales_app/features/orders/widgets/payment_status_selector.dart';

void main() {
  testWidgets(
    'PaymentStatusSelector starts with Unpaid selected',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentStatusSelector(),
            ),
          ),
        ),
      );

      expect(find.text('Payment Status'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Unpaid'), findsOneWidget);

      final context = tester.element(
        find.byType(PaymentStatusSelector),
      );

      final container = ProviderScope.containerOf(context);

      expect(
        container.read(orderDraftProvider).paymentStatus,
        PaymentStatus.unpaid,
      );
    },
  );

  testWidgets(
    'tapping Paid changes the draft payment status',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentStatusSelector(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Paid').first);
      // Wait for selection animations to complete
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byType(PaymentStatusSelector),
      );

      final container = ProviderScope.containerOf(context);

      expect(
        container.read(orderDraftProvider).paymentStatus,
        PaymentStatus.paid,
      );

      // Updated to match the exact icon used in the widget
      expect(
        find.byIcon(Icons.check_circle_rounded),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tapping Unpaid changes the draft payment status back',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaymentStatusSelector(),
            ),
          ),
        ),
      );

      final context = tester.element(
        find.byType(PaymentStatusSelector),
      );

      final container = ProviderScope.containerOf(context);

      container
          .read(orderDraftProvider.notifier)
          .setPaymentStatus(PaymentStatus.paid);

      // Settle any state changes from the manual update
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unpaid').first);
      // Wait for selection animations to complete
      await tester.pumpAndSettle();

      expect(
        container.read(orderDraftProvider).paymentStatus,
        PaymentStatus.unpaid,
      );
    },
  );
  test('a fresh draft defaults to unpaid', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
 
    final draft = container.read(orderDraftProvider);
 
    expect(draft.paymentStatus, PaymentStatus.unpaid);
  });
 
  test('setting Paid does not touch unrelated draft fields', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
 
    final notifier = container.read(orderDraftProvider.notifier);
    final before = container.read(orderDraftProvider);
 
    notifier.setPaymentStatus(PaymentStatus.paid);
 
    final after = container.read(orderDraftProvider);
 
    expect(after.paymentStatus, PaymentStatus.paid);
    // Everything else on the draft must be byte-for-byte unchanged —
    // this is the automated equivalent of "total/delivery/customer
    // fields remain unchanged" from the manual checklist.
    expect(after.entries, before.entries);
    expect(after.deliveryCharge, before.deliveryCharge);
    expect(after.customerName, before.customerName);
    expect(after.customerPhone, before.customerPhone);
    expect(after.customerAddress, before.customerAddress);
    expect(after.additionalDrinks, before.additionalDrinks);
    expect(
      after.additionalDipSauceCount,
      before.additionalDipSauceCount,
    );
  });
 
  test(
    'payment status survives an unrelated update (customer name change)',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
 
      final notifier = container.read(orderDraftProvider.notifier);
 
      notifier.setPaymentStatus(PaymentStatus.paid);
      notifier.setCustomerName('Ali Raza');
 
      final draft = container.read(orderDraftProvider);
 
      expect(draft.paymentStatus, PaymentStatus.paid);
      expect(draft.customerName, 'Ali Raza');
    },
  );
 
  test('clearDraft resets payment status back to the default (unpaid)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
 
    final notifier = container.read(orderDraftProvider.notifier);
 
    notifier.setPaymentStatus(PaymentStatus.paid);
    expect(
      container.read(orderDraftProvider).paymentStatus,
      PaymentStatus.paid,
    );
 
    notifier.clearDraft();
 
    expect(
      container.read(orderDraftProvider).paymentStatus,
      PaymentStatus.unpaid,
    );
  });
}