import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/expenses/models/market_list.dart';
import 'package:hangout_sales_app/features/expenses/repositories/firebase_market_list_repository.dart';

void main() {
  test('marketListItemToMap / marketListItemFromMap round-trip', () {
    const item = MarketListItem(itemName: 'Onion', price: 450);
    final restored = marketListItemFromMap(marketListItemToMap(item));
    expect(restored.itemName, 'Onion');
    expect(restored.price, 450);
  });

  test('marketListItemFromMap defaults missing fields', () {
    final restored = marketListItemFromMap({});
    expect(restored.itemName, '');
    expect(restored.price, 0);
  });

  test('marketListToMap / marketListFromMap round-trip', () {
    final list = MarketList(
      id: 'ml-1',
      items: const [
        MarketListItem(itemName: 'Onion', price: 450),
        MarketListItem(itemName: 'Capsicum', price: 300),
      ],
      total: 750,
      status: MarketListStatus.draft,
      handedToWorker: true,
      businessDate: DateTime(2026, 9, 28),
      createdAt: DateTime(2026, 9, 28, 10, 30),
    );
    final restored = marketListFromMap(marketListToMap(list));
    expect(restored.id, 'ml-1');
    expect(restored.items, hasLength(2));
    expect(restored.items.first.itemName, 'Onion');
    expect(restored.total, 750);
    expect(restored.status, MarketListStatus.draft);
    expect(restored.handedToWorker, isTrue);
    expect(restored.reconciledExpenseId, isNull);
    expect(restored.businessDate, DateTime(2026, 9, 28));
    expect(restored.createdAt, DateTime(2026, 9, 28, 10, 30));
  });

  test('marketListToMap writes Firestore-native types', () {
    final list = MarketList(
      id: 'ml-1',
      items: const [],
      total: 0,
      businessDate: DateTime(2026, 9, 28),
      createdAt: DateTime(2026, 9, 28, 10),
    );
    final map = marketListToMap(list);
    expect(map['status'], 'draft');
    expect(map['businessDate'], isA<Timestamp>());
    expect(map['createdAt'], isA<Timestamp>());
  });

  test('marketListFromMap falls back to draft for unknown status', () {
    final list = MarketList(
      id: 'ml-1',
      items: const [],
      total: 0,
      businessDate: DateTime(2026, 9, 28),
      createdAt: DateTime(2026, 9, 28, 10),
    );
    final restored = marketListFromMap({
      ...marketListToMap(list),
      'status': 'archived',
    });
    expect(restored.status, MarketListStatus.draft);
  });
}
