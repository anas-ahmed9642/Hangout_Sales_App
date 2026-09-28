import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/firebase_market_list_repository.dart';
import '../repositories/market_list_repository.dart';

final marketListRepositoryProvider = Provider<MarketListRepository>((ref) {
  return FirebaseMarketListRepository();
});
