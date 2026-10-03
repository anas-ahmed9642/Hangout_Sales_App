import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/delivery_area_repository.dart';
import '../repositories/firebase_delivery_area_repository.dart';

final deliveryAreaRepositoryProvider =
    Provider<DeliveryAreaRepository>((ref) {
  return FirebaseDeliveryAreaRepository();
});