import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/delivery_areas/models/delivery_area.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_area_repository_provider.dart';
import 'package:hangout_sales_app/features/delivery_areas/providers/delivery_areas_provider.dart';
import 'package:hangout_sales_app/features/delivery_areas/repositories/delivery_area_repository.dart';

DeliveryArea _area(
  String id,
  String name,
  double charge, {
  bool active = true,
}) {
  return DeliveryArea(
    id: id,
    name: name,
    defaultCharge: charge,
    active: active,
    createdAt: DateTime(2026, 10, 2),
  );
}

class _FakeAreaRepository implements DeliveryAreaRepository {
  List<DeliveryArea> areas;

  _FakeAreaRepository(this.areas);

  @override
  Stream<List<DeliveryArea>> streamAreas({bool activeOnly = false}) async* {
    yield areas
        .where((area) => !activeOnly || area.active)
        .toList();
  }

  @override
  Future<String> createArea({
    required String name,
    required double defaultCharge,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateArea(
    String areaId, {
    required String name,
    required double defaultCharge,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> setAreaActive(String areaId, bool active) {
    throw UnimplementedError();
  }

  @override
  Future<int> seedVerifiedAreas() {
    throw UnimplementedError();
  }
}

ProviderContainer _container(_FakeAreaRepository fake) {
  final container = ProviderContainer(
    overrides: [
      deliveryAreaRepositoryProvider.overrideWithValue(fake),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('deliveryAreasProvider', () {
    test('sorts areas in natural order', () async {
      final container = _container(
        _FakeAreaRepository([
          _area('3', 'Sector 10', 100),
          _area('1', 'Sector 2', 180),
          _area('2', 'Sector 9', 70),
        ]),
      );

      final areas = await container.read(deliveryAreasProvider.future);

      expect(
        areas.map((area) => area.name).toList(),
        ['Sector 2', 'Sector 9', 'Sector 10'],
      );
    });
  });

  group('activeDeliveryAreasProvider', () {
    test('hides inactive areas and keeps natural order', () async {
      final container = _container(
        _FakeAreaRepository([
          _area('3', 'Sector 10', 100),
          _area('1', 'Sector 2', 180),
          _area('2', 'Sector 9', 70, active: false),
        ]),
      );

      await container.read(deliveryAreasProvider.future);

      final active = container.read(activeDeliveryAreasProvider).value;

      expect(
        active?.map((area) => area.name).toList(),
        ['Sector 2', 'Sector 10'],
      );
    });

    test('is empty when every area is inactive', () async {
      final container = _container(
        _FakeAreaRepository([
          _area('1', 'Sector 2', 180, active: false),
        ]),
      );

      await container.read(deliveryAreasProvider.future);

      final active = container.read(activeDeliveryAreasProvider).value;

      expect(active?.length, 0);
    });
  });
}