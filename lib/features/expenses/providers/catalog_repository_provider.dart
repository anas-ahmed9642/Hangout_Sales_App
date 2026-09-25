import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/catalog_repository.dart';
import '../repositories/firebase_catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return FirebaseCatalogRepository();
});