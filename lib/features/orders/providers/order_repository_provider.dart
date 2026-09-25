import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/firebase_order_repository.dart';
import '../repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return FirebaseOrderRepository();
});