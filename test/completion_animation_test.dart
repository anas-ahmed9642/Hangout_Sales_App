import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';
import 'package:hangout_sales_app/features/orders/screens/order_detail_screen.dart';

/// A fake repository that allows tests to control the completion state and simulate failures.
/// It also provides an empty history to prevent `orderEditHistoryProvider` from throwing during tests[cite: 1].
class FakeOrderRepository implements OrderRepository {
  final Completer<void>? completionCompleter;
  final bool shouldThrow;

  FakeOrderRepository({
    this.completionCompleter,
    this.shouldThrow = false,
  });

  @override
  Future<void> updateOrder(
    String orderId,
    Map<String, dynamic> changes, {
    required String changeReason,
  }) async {
    if (shouldThrow) {
      throw StateError('network failure');
    }
    if (completionCompleter != null) {
      return completionCompleter!.future;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderHistory(String orderId) async {
    return [];
  }

  // --- Unused dependencies for this test suite ---
  @override
  Future<void> createOrder(Order order) => throw UnimplementedError();

  @override
  Future<Order?> getOrder(String orderId) => throw UnimplementedError();

  @override
  Future<List<Order>> searchOrdersByPhone(String phoneNumber) => throw UnimplementedError();

  @override
  Stream<List<Order>> streamOrders(DateTime businessDate) => throw UnimplementedError();

  @override
  Stream<List<Order>> streamUnpaidOrders() => Stream.value(const []);
}

void main() {
  // A dummy pending order. The OrderStatus.pending ensures the Complete Order button is rendered[cite: 1].
  final dummyPendingOrder = Order(
    id: 'test-order-id',
    orderNumber: 'ORD-0001',
    createdAt: DateTime(2026, 9, 2),
    businessDate: DateTime(2026, 9, 2),
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: 1500,
    status: OrderStatus.pending,
    paymentStatus: PaymentStatus.unpaid,
  );

  group('OrderDetailScreen Completion Flow', () {
    testWidgets('Test 1 — Pending order exposes completion action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderDetailScreen(order: dummyPendingOrder),
          ),
        ),
      );

      expect(find.text('Complete Order'), findsOneWidget);
    });

    testWidgets('Test 2 — Completion loading state', (tester) async {
      final completionCompleter = Completer<void>();
      final fakeRepository = FakeOrderRepository(completionCompleter: completionCompleter);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: MaterialApp(
            home: OrderDetailScreen(order: dummyPendingOrder),
          ),
        ),
      );

      // Trigger the main action
      await tester.tap(find.text('Complete Order'));
      await tester.pumpAndSettle(); // Wait for the confirmation dialog to fully appear

      // Confirm the completion in the dialog
      await tester.tap(find.text('Complete'));
      await tester.pump(); // Rebuild to observe the immediate loading state

      // Assert that the UI reflects the pending completer
      expect(find.text('Completing…'), findsOneWidget);
    });

    testWidgets('Test 3 — Successful completion', (tester) async {
      // By omitting the Completer, the fake repository completes synchronously.
      final fakeRepository = FakeOrderRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: MaterialApp(
            home: OrderDetailScreen(order: dummyPendingOrder),
          ),
        ),
      );

      // Navigate dialog
      await tester.tap(find.text('Complete Order'));
      await tester.pumpAndSettle();

      // Trigger successful completion
      await tester.tap(find.text('Complete'));
      await tester.pump();

      // Allow the transient AnimatedSwitcher animations to advance and complete[cite: 1]
      await tester.pump(const Duration(milliseconds: 130));
      await tester.pump(const Duration(milliseconds: 140));

      // Assert the button has completely disappeared
      expect(find.text('Complete Order'), findsNothing);
      expect(find.text('Completing…'), findsNothing);
    });

    testWidgets('Test 4 — Failed completion returns to retry state', (tester) async {
      final fakeRepository = FakeOrderRepository(shouldThrow: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(fakeRepository),
          ],
          child: MaterialApp(
            home: OrderDetailScreen(order: dummyPendingOrder),
          ),
        ),
      );

      // Navigate dialog
      await tester.tap(find.text('Complete Order'));
      await tester.pumpAndSettle();

      // Trigger the completion action
      await tester.tap(find.text('Complete'));
      
      // Allow the Future to settle and error handling to execute
      await tester.pump(); 
      await tester.pump();

      // Assert the application recovered back to the original ready state
      expect(find.text('Complete Order'), findsOneWidget);
    });
  });
}