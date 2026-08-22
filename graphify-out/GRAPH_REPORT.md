# Graph Report - hangout_sales_app  (2026-08-22)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 435 nodes · 499 edges · 25 communities (23 shown, 2 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 3 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `13c93964`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- order_draft_provider.dart
- menu_data.dart
- dashboard_screen.dart
- GeneratedPluginRegistrant.swift
- login_screen.dart
- package:flutter/material.dart
- my_application.cc
- router.dart
- auth_repository.dart
- firebase_order_repository.dart
- order_draft.dart
- order.dart
- order_draft_notifier_test.dart
- marble_background_painter.dart
- app_routes.dart
- manifest.json
- flavor.dart
- business_day_service.dart
- topping_selection.dart
- MainActivity.kt
- @hangout

## God Nodes (most connected - your core abstractions)
1. `_MyApplication` - 7 edges
2. `authProvider` - 6 edges
3. `AppDelegate` - 4 edges
4. `my_application_local_command_line()` - 4 edges
5. `PizzaSize` - 4 edges
6. `build` - 4 edges
7. `FlutterMacOS` - 4 edges
8. `_LoginScreenState` - 4 edges
9. `AppDelegate` - 3 edges
10. `RunnerTests` - 3 edges

## Surprising Connections (you probably didn't know these)
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `build` --references--> `authProvider`  [EXTRACTED]
  lib/features/auth/screens/login_screen.dart → lib/features/auth/providers/auth_provider.dart
- `_login` --references--> `authProvider`  [EXTRACTED]
  lib/features/auth/screens/login_screen.dart → lib/features/auth/providers/auth_provider.dart
- `SettingsScreen` --references--> `authProvider`  [EXTRACTED]
  lib/features/settings/screens/settings_screen.dart → lib/features/auth/providers/auth_provider.dart

## Import Cycles
- None detected.

## Communities (25 total, 2 thin omitted)

### Community 0 - "order_draft_provider.dart"
Cohesion: 0.04
Nodes (50): addAdditionalDrink, addDeal, addStandalonePizza, addTopping, basePrice, build, buildOrder, _buildOrderItem (+42 more)

### Community 1 - "menu_data.dart"
Cohesion: 0.05
Nodes (42): deal.dart, flavor.dart, Deal, dipSauceCount, drinkSize, id, name, pizzaSizes (+34 more)

### Community 2 - "dashboard_screen.dart"
Cohesion: 0.07
Nodes (37): ../../../app/theme.dart, ../../auth/providers/auth_provider.dart, IconData, _DashedDivider, _ReceiptField, build, _OrnamentalDivider, SplashScreen (+29 more)

### Community 3 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.07
Nodes (24): Any, cloud_firestore, Cocoa, firebase_auth, firebase_core, Flutter, FlutterAppDelegate, FlutterMacOS (+16 more)

### Community 4 - "login_screen.dart"
Cohesion: 0.08
Nodes (28): ConsumerState, ConsumerStatefulWidget, authProvider, build, controller, createState, dispose, _emailController (+20 more)

### Community 5 - "package:flutter/material.dart"
Cohesion: 0.07
Nodes (21): app/app.dart, firebase_options.dart, AppTheme, backgroundColor, errorColor, primaryColor, surfaceColor, textColor (+13 more)

### Community 6 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 7 - "router.dart"
Cohesion: 0.09
Nodes (21): ConsumerWidget, ../core/constants/app_routes.dart, ../features/auth/providers/auth_state_provider.dart, ../features/auth/screens/login_screen.dart, ../features/auth/screens/splash_screen.dart, ../features/customers/screens/customer_screen.dart, ../features/dashboard/screens/dashboard_screen.dart, ../features/expenses/screens/expense_screen.dart (+13 more)

### Community 8 - "auth_repository.dart"
Cohesion: 0.10
Nodes (18): auth_repository_provider.dart, firebase_auth_provider.dart, FirebaseAuth, auth, authRepository, authStateChanges, authStateProvider, firebaseAuthProvider (+10 more)

### Community 9 - "firebase_order_repository.dart"
Cohesion: 0.11
Nodes (18): CollectionReference, FirebaseFirestore, createOrder, _dealToMap, FirebaseOrderRepository, _firestore, _orderItemToMap, _ordersCollection (+10 more)

### Community 10 - "order_draft.dart"
Cohesion: 0.11
Nodes (18): AuthNotifier, build, signIn, signOut, authRepositoryProvider, additionalDipSauceCount, additionalDrinks, copyWith (+10 more)

### Community 11 - "order.dart"
Cohesion: 0.11
Nodes (17): DateTime, additionalDipSauceCount, additionalDrinks, businessDate, createdAt, customerAddress, customerName, customerPhone (+9 more)

### Community 12 - "order_draft_notifier_test.dart"
Cohesion: 0.11
Nodes (16): ../lib/features/orders/models/menu_data.dart, ../lib/features/orders/models/order.dart, Order, ../lib/features/orders/models/pizza_size.dart, ../lib/features/orders/providers/order_draft_provider.dart, package:flutter_test/flutter_test.dart, package:hangout_sales_app/app/app.dart, container (+8 more)

### Community 13 - "marble_background_painter.dart"
Cohesion: 0.18
Nodes (10): Color, CustomPainter, dart:math, CastleWallPainter, mortarColor, paint, seed, shouldRepaint (+2 more)

### Community 14 - "app_routes.dart"
Cohesion: 0.18
Nodes (10): AppRoutes, customers, dashboard, expenses, login, orders, reports, settings (+2 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "flavor.dart"
Cohesion: 0.33
Nodes (5): double?, Flavor, id, name, priceExtra

### Community 17 - "business_day_service.dart"
Cohesion: 0.40
Nodes (4): businessDate, BusinessDayService, closingHour, static const int

### Community 18 - "topping_selection.dart"
Cohesion: 0.40
Nodes (4): priceAtOrderTime, toppingId, toppingName, ToppingSelection

## Knowledge Gaps
- **209 isolated node(s):** `addAdditionalDrink`, `addDeal`, `addStandalonePizza`, `addTopping`, `basePrice` (+204 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `PizzaSize` connect `menu_data.dart` to `order_draft_provider.dart`?**
  _High betweenness centrality (0.096) - this node is a cross-community bridge._
- **Why does `Order` connect `order_draft_notifier_test.dart` to `order.dart`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `OrderDraftNotifier` connect `order_draft.dart` to `order_draft_provider.dart`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **What connects `addAdditionalDrink`, `addDeal`, `addStandalonePizza` to the rest of the system?**
  _209 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `order_draft_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Should `menu_data.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04810360777058279 - nodes in this community are weakly interconnected._
- **Should `dashboard_screen.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06666666666666667 - nodes in this community are weakly interconnected._