import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:hangout_sales_app/features/expenses/repositories/firebase_catalog_repository.dart';
import 'package:hangout_sales_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final repository = FirebaseCatalogRepository();

  final createdCount = await repository.seedVerifiedCatalog();

  debugPrint(
    'Verified expense catalog seed completed. '
    'Created $createdCount new catalog item(s).',
  );

  if (createdCount == 38) {
    debugPrint(
      'All 38 verified catalog items were created.',
    );
  } else if (createdCount == 0) {
    debugPrint(
      'Catalog already contained all 38 verified items.',
    );
  }

  runApp(
    const _SeedCompleteApp(),
  );
}

class _SeedCompleteApp extends StatelessWidget {
  const _SeedCompleteApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Catalog Seed'),
        ),
        body: const Center(
          child: Text(
            'Verified expense catalog seed completed.\n'
            'Check the terminal output for the created-item count.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}