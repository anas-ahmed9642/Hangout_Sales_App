import '../models/delivery_area.dart';

abstract class DeliveryAreaRepository {
  Stream<List<DeliveryArea>> streamAreas({bool activeOnly = false});

  Future<String> createArea({
    required String name,
    required double defaultCharge,
  });

  Future<void> updateArea(
    String areaId, {
    required String name,
    required double defaultCharge,
  });

  Future<void> setAreaActive(
    String areaId,
    bool active,
  );

  Future<int> seedVerifiedAreas();
}