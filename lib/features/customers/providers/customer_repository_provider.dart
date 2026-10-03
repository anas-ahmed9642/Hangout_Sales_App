import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/customer_repository.dart';
import '../repositories/firebase_customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return FirebaseCustomerRepository();
});