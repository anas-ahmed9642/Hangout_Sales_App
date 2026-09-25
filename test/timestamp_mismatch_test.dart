import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:hangout_sales_app/core/services/business_day_service.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';

void main() {
  test('Integration: Exposing the businessDate timestamp mismatch', () async {
    // 1. Setup our Fake Firebase environment
    final fakeFirestore = FakeFirebaseFirestore();
    final repository = FirebaseOrderRepository(firestore: fakeFirestore);
    final container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    // 2. Simulate what NewOrderScreen does to save an order
    final notifier = container.read(orderDraftProvider.notifier);
    notifier.addStandalonePizza(PizzaSize.regular);
    notifier.setFlavor(notifier.state.entries.first.id, 0, 'spicy_bbq');

    // THIS IS THE CULPRIT: NewOrderScreen uses raw DateTime.now()
    final rawNow = DateTime.now(); 
    await notifier.saveOrder(
      orderNumber: 'TEST-BUG',
      businessDate: rawNow,
    );

    // 3. Simulate what OrderHistoryProvider does to read the order
    const businessDayService = BusinessDayService();
    // The history provider uses the normalized business date (e.g., Midnight)
    final correctBusinessDate = businessDayService.businessDate(rawNow); 

    // 4. Try to fetch the order we just saved
    final stream = repository.streamOrders(correctBusinessDate);
    final emittedOrders = await stream.first;

    // 5. This will FAIL because exact timestamps do not match in Firebase!
    expect(
      emittedOrders.length, 
      1, 
      reason: 'Firebase found 0 orders because the hours/minutes/seconds do not match!',
    );
  });
}