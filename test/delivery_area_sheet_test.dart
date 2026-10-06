import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

import 'package:hangout_sales_app/features/delivery_areas/models/delivery_area.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_area_repository_provider.dart';
import 'package:hangout_sales_app/features/delivery_areas/repositories/delivery_area_repository.dart';
import 'package:hangout_sales_app/features/orders/providers/order_draft_provider.dart';
import 'package:hangout_sales_app/features/orders/widgets/delivery_picker.dart';

final _t = DateTime(2026, 10, 2);

DeliveryArea _area(String id, String name, double charge) {
  return DeliveryArea(
    id: id,
    name: name,
    defaultCharge: charge,
    createdAt: _t,
  );
}

class _FakeDeliveryAreaRepository implements DeliveryAreaRepository {
  final List<DeliveryArea> areas;

  _FakeDeliveryAreaRepository(this.areas);

  @override
  Stream<List<DeliveryArea>> streamAreas({bool activeOnly = false}) async* {
    yield areas.where((area) => !activeOnly || area.active).toList();
  }

  @override
  Future<String> createArea({
    required String name,
    required double defaultCharge,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> updateArea(
    String areaId, {
    required String name,
    required double defaultCharge,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> setAreaActive(String areaId, bool active) =>
      throw UnimplementedError();

  @override
  Future<int> seedVerifiedAreas() => throw UnimplementedError();
}

List<DeliveryArea> _areas() => [
      _area('1', 'Sector 11B', 180),
      _area('2', 'Sector 5C/1', 100),
      _area('3', 'Sector 5C/2', 100),
    ];

ProviderContainer _container() {
  return createTestContainer(overrides: [
    deliveryAreaRepositoryProvider.overrideWithValue(
      _FakeDeliveryAreaRepository(_areas()),
    ),
  ]);
}

Future<void> _pumpPicker(
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

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Select area'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('searching filters areas per 6.4 normalization', (tester) async {
    final container = _container();
    container.read(orderDraftProvider.notifier).setDeliveryCharge(180);
    await _pumpPicker(tester, container);

    await _openSheet(tester);

    expect(find.text('Not listed / other'), findsOneWidget);
    expect(find.text('Sector 11B'), findsOneWidget);

    // The sheet's search field is the last TextField in the tree.
    await tester.enterText(find.byType(TextField).last, '5c1');
    await tester.pump();

    expect(find.text('Sector 5C/1'), findsOneWidget);
    expect(find.text('Sector 5C/2'), findsNothing);
    expect(find.text('Sector 11B'), findsNothing);
    // The unlisted row is never filtered away.
    expect(find.text('Not listed / other'), findsOneWidget);
  });

  testWidgets('choosing an area sets the area and its default charge',
      (tester) async {
    final container = _container();
    container.read(orderDraftProvider.notifier).setDeliveryCharge(70);
    await _pumpPicker(tester, container);

    await _openSheet(tester);
    await tester.tap(find.text('Sector 11B'));
    await tester.pumpAndSettle();

    final draft = container.read(orderDraftProvider);
    expect(draft.deliveryAreaId, '1');
    expect(draft.deliveryAreaName, 'Sector 11B');
    expect(draft.deliveryCharge, 180);
  });

  testWidgets('"Not listed / other" clears the area and keeps the charge',
      (tester) async {
    final container = _container();
    final notifier = container.read(orderDraftProvider.notifier);
    notifier.setDeliveryArea(
      areaId: '1',
      areaName: 'Sector 11B',
      defaultCharge: 180,
    );
    notifier.setDeliveryCharge(250);
    await _pumpPicker(tester, container);

    // The field shows the area name now; tap it to open the sheet.
    await tester.tap(find.text('Sector 11B'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not listed / other'));
    await tester.pumpAndSettle();

    final draft = container.read(orderDraftProvider);
    expect(draft.deliveryAreaId, isNull);
    expect(draft.deliveryAreaName, isNull);
    expect(draft.deliveryCharge, 250);
  });
}