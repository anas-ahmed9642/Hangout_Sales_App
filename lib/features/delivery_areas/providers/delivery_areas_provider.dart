import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/natural_compare.dart';
import '../models/delivery_area.dart';
import 'delivery_area_repository_provider.dart';

/// All delivery areas, sorted in natural order ("Sector 10" after
/// "Sector 9"). Sorting lives here, not in the repository.
final deliveryAreasProvider =
    StreamProvider.autoDispose<List<DeliveryArea>>((ref) {
  final repository = ref.watch(deliveryAreaRepositoryProvider);

  return repository.streamAreas().map((areas) {
    final sorted = [...areas];
    sorted.sort((a, b) => naturalCompare(a.name, b.name));
    return sorted;
  });
});

/// Only the active areas - the list order screens consume. Derived from
/// [deliveryAreasProvider] so there is a single Firestore subscription.
final activeDeliveryAreasProvider =
    Provider.autoDispose<AsyncValue<List<DeliveryArea>>>((ref) {
  return ref.watch(deliveryAreasProvider).whenData(
        (areas) => areas.where((area) => area.active).toList(),
      );
});