# Graph Report - hangout_sales_app  (2026-09-26)

## Corpus Check
- 147 files · ~56,399 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1457 nodes · 2060 edges · 96 communities (88 shown, 8 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `78fabd45`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- order_draft_provider.dart
- menu_data.dart
- order_history_screen_test.dart
- GeneratedPluginRegistrant.swift
- login_screen.dart
- manage_catalog_screen.dart
- my_application.cc
- new_order_screen.dart
- auth_repository.dart
- firebase_order_repository.dart
- firebase_catalog_repository.dart
- order.dart
- order_draft_notifier_test.dart
- marble_background_painter.dart
- app_routes.dart
- manifest.json
- expense.dart
- business_day_service.dart
- order_summary.dart
- MainActivity.kt
- @hangout
- order_entries_section.dart
- order_item.dart
- orderDraftProvider
- deal.dart
- order_draft_entry.dart
- order_history_screen.dart
- additional_items_section.dart
- package:flutter/material.dart
- order_detail_screen.dart
- payment_status_selector.dart
- package:hangout_sales_app/features/orders/models/order.dart
- expense_providers_test.dart
- hangout_sales_app
- LaunchImage.imageset/README.md
- order_history_provider_test.dart
- package:flutter_test/flutter_test.dart
- _MarkAsPaidButtonState
- firebase_expense_repository.dart
- firebase_order_repository_test.dart
- order_search_provider_test.dart
- StatelessWidget
- List
- Win32Window
- order_edit_history_provider_test.dart
- customer_form.dart
- order_category_selector.dart
- order_repository_failure_test.dart
- orderRepositoryProvider
- order_history_item.dart
- order_payment_transition_test.dart
- edit_order_screen.dart
- receipt_data.dart
- order_edit_provider.dart
- order_receipt_service_test.dart
- order_receipt_service.dart
- build
- mutation_failure_recovery_test.dart
- printer_device_store.dart
- tcp_printer_transport.dart
- thermal_printer_transport.dart
- wWinMain
- receipt_builder.dart
- orders_end_to_end_integration_test.dart
- market_list.dart
- catalog_provider.dart
- catalog_repository.dart
- hangout_app_bar.dart
- theme.dart
- settings_screen.dart
- seed_expense_catalog.dart
- String?
- CustomPainter
- chicken_purchase_line.dart
- expense_line_item.dart
- router.dart
- completion_animation_test.dart
- order_draft.dart
- catalog_item.dart
- expense_history_provider.dart
- verified_catalog_seed.dart
- auth_provider.dart
- package:flutter_riverpod/flutter_riverpod.dart
- flavor.dart
- app.dart
- Order
- auth_repository_provider.dart
- auth_state_provider.dart
- printer_device.dart
- expense_screen.dart
- report_screen.dart
- printer_failure_recovery_test.dart

## God Nodes (most connected - your core abstractions)
1. `orderDraftProvider` - 24 edges
2. `Win32Window` - 24 edges
3. `MessageHandler` - 12 edges
4. `OrderRepository` - 11 edges
5. `orderRepositoryProvider` - 10 edges
6. `FlutterWindow` - 10 edges
7. `Create` - 10 edges
8. `WndProc` - 10 edges
9. `OrderHistoryScreen` - 9 edges
10. `build` - 9 edges

## Surprising Connections (you probably didn't know these)
- `FakeOrderRepository` --implements--> `OrderRepository`  [EXTRACTED]
  test/completion_animation_test.dart → lib/features/orders/repositories/order_repository.dart
- `_TestOrderRepository` --implements--> `OrderRepository`  [EXTRACTED]
  test/order_draft_notifier_test.dart → lib/features/orders/repositories/order_repository.dart
- `_TestOrderRepository` --implements--> `OrderRepository`  [EXTRACTED]
  test/order_edit_history_provider_test.dart → lib/features/orders/repositories/order_repository.dart
- `_TestOrderRepository` --implements--> `OrderRepository`  [EXTRACTED]
  test/order_history_provider_test.dart → lib/features/orders/repositories/order_repository.dart
- `_TestOrderRepository` --implements--> `OrderRepository`  [EXTRACTED]
  test/order_payment_transition_test.dart → lib/features/orders/repositories/order_repository.dart

## Import Cycles
- None detected.

## Communities (96 total, 8 thin omitted)

### Community 0 - "order_draft_provider.dart"
Cohesion: 0.04
Nodes (51): addAdditionalDrink, addDeal, addStandalonePizza, addTopping, basePrice, build, buildOrder, _buildOrderItem (+43 more)

### Community 1 - "menu_data.dart"
Cohesion: 0.14
Nodes (13): flavor.dart, cheesePrices, deals, deliveryCharges, dipSaucePrice, drinkPrices, flavors, MenuData (+5 more)

### Community 2 - "order_history_screen_test.dart"
Cohesion: 0.11
Nodes (16): package:hangout_sales_app/features/orders/screens/new_order_screen.dart, package:hangout_sales_app/features/orders/screens/order_detail_screen.dart, package:hangout_sales_app/features/orders/screens/order_history_screen.dart, package:hangout_sales_app/shared/widgets/hangout_app_bar.dart, _buildScreen, createdAt, customerName, main (+8 more)

### Community 3 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.06
Nodes (29): Any, cloud_firestore, Cocoa, firebase_auth, firebase_core, Flutter, FlutterAppDelegate, FlutterMacOS (+21 more)

### Community 4 - "login_screen.dart"
Cohesion: 0.08
Nodes (27): authProvider, build, controller, createState, _DashedDivider, dispose, _emailController, hint (+19 more)

### Community 5 - "manage_catalog_screen.dart"
Cohesion: 0.03
Nodes (64): ../../expenses/models/catalog_item.dart, ../../expenses/models/expense_category.dart, ../../expenses/providers/catalog_provider.dart, ../../expenses/providers/catalog_repository_provider.dart, FormState, bg, _blackBackground, border (+56 more)

### Community 6 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 7 - "new_order_screen.dart"
Cohesion: 0.13
Nodes (14): ../../../core/constants/app_routes.dart, build, _confirmDiscard, shouldDiscard, _submitOrder, MaterialPageRoute, AppRoutes.dashboard, ../widgets/additional_items_section.dart (+6 more)

### Community 8 - "auth_repository.dart"
Cohesion: 0.18
Nodes (10): FirebaseAuth, firebaseAuthProvider, _auth, authStateChanges, currentUser, signIn, signInWithEmailAndPassword, signOut (+2 more)

### Community 9 - "firebase_order_repository.dart"
Cohesion: 0.07
Nodes (26): changedEntries, createOrder, currentEditCount, _dealFromMap, _dealToMap, _firestore, getOrder, getOrderHistory (+18 more)

### Community 10 - "firebase_catalog_repository.dart"
Cohesion: 0.09
Nodes (22): catalog_repository.dart, CollectionReference, FirebaseFirestore, batch, _catalogCategories, _catalogCollection, _catalogItemFromDocument, _catalogSeedKey (+14 more)

### Community 11 - "order.dart"
Cohesion: 0.12
Nodes (16): additionalDipSauceCount, additionalDrinks, businessDate, createdAt, customerAddress, customerName, customerPhone, deals (+8 more)

### Community 12 - "order_draft_notifier_test.dart"
Cohesion: 0.07
Nodes (27): priceAtOrderTime, toppingId, toppingName, ToppingSelection, package:hangout_sales_app/features/orders/models/menu_data.dart, package:hangout_sales_app/features/orders/widgets/additional_items_section.dart, package:hangout_sales_app/features/orders/widgets/delivery_picker.dart, package:hangout_sales_app/features/orders/widgets/order_category_selector.dart (+19 more)

### Community 13 - "marble_background_painter.dart"
Cohesion: 0.22
Nodes (8): Color, dart:math, mortarColor, paint, seed, shouldRepaint, stoneColor, sunColor

### Community 14 - "app_routes.dart"
Cohesion: 0.17
Nodes (11): AppRoutes, customers, dashboard, expenses, login, manageCatalog, orders, reports (+3 more)

### Community 15 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 16 - "expense.dart"
Cohesion: 0.11
Nodes (17): chicken_purchase_line.dart, expense_line_item.dart, amount, businessDate, chickenLines, category, date, editCount (+9 more)

### Community 17 - "business_day_service.dart"
Cohesion: 0.40
Nodes (4): businessDate, BusinessDayService, closingHour, static const int

### Community 18 - "order_summary.dart"
Cohesion: 0.15
Nodes (12): build, entry, _entryTitle, _EntryTypeBadge, isDeal, isTotal, label, _pizzaSizeLabel (+4 more)

### Community 25 - "order_entries_section.dart"
Cohesion: 0.18
Nodes (10): flavor_selector.dart, build, entry, _EntryTypeBadge, icon, label, onRemove, _OrderEntryCard (+2 more)

### Community 26 - "order_item.dart"
Cohesion: 0.20
Nodes (9): flavorId, flavorName, flavorPriceExtra, OrderItem, quantity, size, toppings, unitPrice (+1 more)

### Community 27 - "orderDraftProvider"
Cohesion: 0.33
Nodes (11): ConsumerWidget, orderDraftProvider, NewOrderScreen, AdditionalItemsSection, DeliveryPicker, FlavorSelector, OrderCategorySelector, OrderEntriesSection (+3 more)

### Community 28 - "deal.dart"
Cohesion: 0.22
Nodes (8): Deal, dipSauceCount, drinkSize, id, name, pizzaSizes, price, pizza_size.dart

### Community 29 - "order_draft_entry.dart"
Cohesion: 0.20
Nodes (8): deal.dart, copyWith, deal, flavorIds, id, standalonePizzaSize, toppings, PizzaSize

### Community 30 - "order_history_screen.dart"
Cohesion: 0.06
Nodes (40): ../../../core/services/business_day_service.dart, getOrderHistory, repository, allUnpaidOrdersProvider, businessDate, orderHistoryProvider, repository, selectedDateProvider (+32 more)

### Community 31 - "additional_items_section.dart"
Cohesion: 0.15
Nodes (12): build, _DrinkOption, _drinkOptions, id, label, build, charge, _DeliveryOption (+4 more)

### Community 32 - "package:flutter/material.dart"
Cohesion: 0.13
Nodes (14): build, CustomerScreen, OrderDraftEntry, build, entry, build, entry, id (+6 more)

### Community 33 - "order_detail_screen.dart"
Cohesion: 0.04
Nodes (51): orderEditHistoryProvider, address, build, _capitalize, child, _confirmCompletion, confirmed, _confirmMarkAsPaid (+43 more)

### Community 34 - "payment_status_selector.dart"
Cohesion: 0.14
Nodes (13): IconData, build, icon, isPaid, label, onChanged, onTap, _paidColor (+5 more)

### Community 35 - "package:hangout_sales_app/features/orders/models/order.dart"
Cohesion: 0.22
Nodes (7): package:hangout_sales_app/features/orders/models/order.dart, package:hangout_sales_app/features/orders/widgets/payment_status_selector.dart, businessDate, createdAt, createOrder, main, main

### Community 36 - "expense_providers_test.dart"
Cohesion: 0.05
Nodes (37): expenseRepositoryProvider, createExpense, ExpenseRepository, getExpense, getExpenseHistory, getExpensesByDateRange, getTotalExpensesByDateRange, streamExpenses (+29 more)

### Community 39 - "order_history_provider_test.dart"
Cohesion: 0.17
Nodes (11): package:hangout_sales_app/features/orders/providers/order_history_provider.dart, Stream, createOrder, getOrder, getOrderHistory, main, ordersStream, searchOrdersByPhone (+3 more)

### Community 40 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.09
Nodes (28): ArgumentError, FakeFirebaseFirestore, FirebaseOrderRepository, package:cloud_firestore/cloud_firestore.dart, package:fake_cloud_firestore/fake_cloud_firestore.dart, package:flutter_test/flutter_test.dart, package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart, StateError (+20 more)

### Community 41 - "_MarkAsPaidButtonState"
Cohesion: 0.32
Nodes (8): _MarkAsPaidButton, _MarkAsPaidButtonState, _ReprintButton, _ReprintButtonState, _CatalogEditorDialog, _CatalogEditorDialogState, State, StatefulWidget

### Community 42 - "firebase_expense_repository.dart"
Cohesion: 0.08
Nodes (25): expense_repository.dart, buildExpenseHistoryEntries, changedEntries, chickenPurchaseLineFromMap, chickenPurchaseLineToMap, createExpense, deepEq, expenseFromMap (+17 more)

### Community 43 - "firebase_order_repository_test.dart"
Cohesion: 0.29
Nodes (6): PaymentStatus, _createTestOrder, id, main, paymentStatus, status

### Community 44 - "order_search_provider_test.dart"
Cohesion: 0.18
Nodes (10): package:hangout_sales_app/features/orders/providers/order_search_provider.dart, package:hangout_sales_app/features/orders/repositories/order_repository.dart, createOrder, getOrder, getOrderHistory, main, searchOrdersByPhone, streamOrders (+2 more)

### Community 45 - "StatelessWidget"
Cohesion: 0.07
Nodes (35): _DashboardHeader, DashboardScreen, icon, label, onTap, _OverviewCard, _OverviewGrid, _QuickActions (+27 more)

### Community 46 - "List"
Cohesion: 0.40
Nodes (4): List, container, createTestContainer, overrides

### Community 47 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 48 - "order_edit_history_provider_test.dart"
Cohesion: 0.11
Nodes (18): OrderRepository, package:hangout_sales_app/features/orders/providers/order_edit_history_provider.dart, FakeOrderRepository, _TestOrderRepository, createOrder, getOrder, getOrderHistory, history (+10 more)

### Community 49 - "customer_form.dart"
Cohesion: 0.20
Nodes (10): _addressController, build, createState, CustomerForm, _CustomerFormState, dispose, initState, _nameController (+2 more)

### Community 50 - "order_category_selector.dart"
Cohesion: 0.20
Nodes (9): build, _DealCard, _DealGroup, deals, onDealSelected, _pizzaSizeLabel, title, ../models/deal.dart (+1 more)

### Community 51 - "order_repository_failure_test.dart"
Cohesion: 0.18
Nodes (10): createOrder, failure, getOrder, getOrderHistory, main, searchOrdersByPhone, streamOrders, streamUnpaidOrders (+2 more)

### Community 52 - "orderRepositoryProvider"
Cohesion: 0.18
Nodes (14): ConsumerState, ConsumerStatefulWidget, orderEditProvider, orderRepositoryProvider, build, EditOrderScreen, _EditOrderScreenState, _save (+6 more)

### Community 53 - "order_history_item.dart"
Cohesion: 0.20
Nodes (9): build, _color, onTap, order, OrderHistoryItem, _OrderStatusBadge, status, _UnpaidBadge (+1 more)

### Community 54 - "order_payment_transition_test.dart"
Cohesion: 0.14
Nodes (12): package:hangout_sales_app/features/orders/providers/order_draft_provider.dart, package:hangout_sales_app/features/orders/providers/order_repository_provider.dart, createOrder, getOrder, getOrderHistory, main, searchOrdersByPhone, streamOrders (+4 more)

### Community 55 - "edit_order_screen.dart"
Cohesion: 0.06
Nodes (34): _AdditionalItemsEditor, charge, createState, _CustomerEditor, _dealToMap, delivery, _DeliveryEditor, dipTotal (+26 more)

### Community 56 - "receipt_data.dart"
Cohesion: 0.07
Nodes (27): additionalDipSauceTotal, additionalDrinksTotal, additionalItems, amount, createdAt, customerAddress, customerName, customerPhone (+19 more)

### Community 57 - "order_edit_provider.dart"
Cohesion: 0.07
Nodes (26): bool get, addAdditionalDrink, addDeal, addStandalonePizza, addTopping, build, buildEditedOrder, canSave (+18 more)

### Community 58 - "order_receipt_service_test.dart"
Cohesion: 0.09
Nodes (22): package:hangout_sales_app/features/orders/services/printer_device.dart, package:hangout_sales_app/features/orders/services/printer_device_store.dart, package:hangout_sales_app/features/orders/services/thermal_printer_transport.dart, async, bluetoothIsEnabled, build, called, clearLastPairedDevice (+14 more)

### Community 59 - "order_receipt_service.dart"
Cohesion: 0.11
Nodes (22): Exception, _builder, _deviceStore, forgetPrinter, getPairedDevices, message, OrderReceiptService, PrinterBluetoothDisabledException (+14 more)

### Community 60 - "build"
Cohesion: 0.50
Nodes (4): build, AppRoutes.expenses, AppRoutes.orders, AppRoutes.settings

### Community 61 - "mutation_failure_recovery_test.dart"
Cohesion: 0.25
Nodes (7): Object?, actionCompleted, error, execute, isUpdating, main, _MutationController

### Community 62 - "printer_device_store.dart"
Cohesion: 0.17
Nodes (12): class, clearLastPairedDevice, _macAddressKey, _nameKey, PrinterDeviceStore, readLastPairedDevice, saveLastPairedDevice, SharedPreferencesPrinterDeviceStore (+4 more)

### Community 63 - "tcp_printer_transport.dart"
Cohesion: 0.17
Nodes (11): dart:io, Future, async, connect, disconnect, host, port, _socket (+3 more)

### Community 64 - "thermal_printer_transport.dart"
Cohesion: 0.15
Nodes (13): TcpPrinterTransport, bluetoothEnabled, BluetoothThermalPrinterTransport, connect, connectionStatus, disconnect, pairedDevices, permissionGranted (+5 more)

### Community 65 - "wWinMain"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 66 - "receipt_builder.dart"
Cohesion: 0.17
Nodes (11): build, _fallbackHeader, _money, ReceiptBuilder, _summaryRow, ../models/receipt_data.dart, package:esc_pos_utils_plus/esc_pos_utils_plus.dart, package:flutter/services.dart (+3 more)

### Community 67 - "orders_end_to_end_integration_test.dart"
Cohesion: 0.10
Nodes (22): OrderStatus, package:hangout_sales_app/features/orders/models/deal.dart, package:hangout_sales_app/features/orders/models/order_item.dart, package:hangout_sales_app/features/orders/models/pizza_size.dart, package:hangout_sales_app/features/orders/models/receipt_data.dart, package:hangout_sales_app/features/orders/models/topping_selection.dart, package:hangout_sales_app/features/orders/providers/order_edit_provider.dart, package:hangout_sales_app/features/orders/services/receipt_builder.dart (+14 more)

### Community 68 - "market_list.dart"
Cohesion: 0.14
Nodes (13): businessDate, createdAt, handedToWorker, id, itemName, items, MarketList, MarketListItem (+5 more)

### Community 69 - "catalog_provider.dart"
Cohesion: 0.22
Nodes (10): catalog_repository_provider.dart, catalogItemsProvider, category, repository, selectedCatalogCategoryProvider, streamCatalog, catalogRepositoryProvider, build (+2 more)

### Community 70 - "catalog_repository.dart"
Cohesion: 0.17
Nodes (10): CatalogRepository, createCatalogItem, seedVerifiedCatalog, setCatalogItemActive, streamCatalog, updateCatalogItem, FirebaseCatalogRepository, ../models/expense_category.dart (+2 more)

### Community 71 - "hangout_app_bar.dart"
Cohesion: 0.22
Nodes (8): actions, build, HangoutAppBar, preferredSize, showBackButton, title, PreferredSizeWidget, Size get

### Community 72 - "theme.dart"
Cohesion: 0.25
Nodes (7): AppTheme, backgroundColor, errorColor, primaryColor, surfaceColor, textColor, static const Color

### Community 73 - "settings_screen.dart"
Cohesion: 0.12
Nodes (16): ../../../app/theme.dart, ../../auth/providers/auth_provider.dart, build, _OrnamentalDivider, SplashScreen, build, destructive, icon (+8 more)

### Community 74 - "seed_expense_catalog.dart"
Cohesion: 0.12
Nodes (15): app/app.dart, dart:async, features/orders/services/order_receipt_service.dart, firebase_options.dart, initializeApp, main, package:firebase_core/firebase_core.dart, package:hangout_sales_app/features/expenses/repositories/firebase_catalog_repository.dart (+7 more)

### Community 76 - "CustomPainter"
Cohesion: 0.50
Nodes (4): CustomPainter, _AshlarPainter, _MeanderPainter, CastleWallPainter

### Community 77 - "chicken_purchase_line.dart"
Cohesion: 0.50
Nodes (3): ChickenPurchaseLine, chickenType, quantityKg

### Community 78 - "expense_line_item.dart"
Cohesion: 0.50
Nodes (3): ExpenseLineItem, itemName, price

### Community 79 - "router.dart"
Cohesion: 0.14
Nodes (13): ../features/auth/providers/auth_state_provider.dart, ../features/auth/screens/login_screen.dart, ../features/auth/screens/splash_screen.dart, ../features/customers/screens/customer_screen.dart, ../features/dashboard/screens/dashboard_screen.dart, ../features/expenses/screens/expense_screen.dart, ../features/orders/screens/new_order_screen.dart, ../features/reports/screens/report_screen.dart (+5 more)

### Community 80 - "completion_animation_test.dart"
Cohesion: 0.15
Nodes (12): Completer, completionCompleter, createOrder, dummyPendingOrder, getOrder, getOrderHistory, main, searchOrdersByPhone (+4 more)

### Community 81 - "order_draft.dart"
Cohesion: 0.17
Nodes (11): additionalDipSauceCount, additionalDrinks, copyWith, customerAddress, customerName, customerPhone, deliveryCharge, entries (+3 more)

### Community 82 - "catalog_item.dart"
Cohesion: 0.18
Nodes (10): expense_category.dart, active, brand, CatalogItem, category, copyWith, createdAt, id (+2 more)

### Community 83 - "expense_history_provider.dart"
Cohesion: 0.22
Nodes (8): DateTime, expense_repository_provider.dart, businessDate, expenseHistoryProvider, repository, selectedExpenseDateProvider, streamExpenses, ../models/expense.dart

### Community 84 - "verified_catalog_seed.dart"
Cohesion: 0.22
Nodes (7): ExpenseCategory, brand, category, name, size, verifiedCatalogSeed, VerifiedCatalogSeedItem

### Community 85 - "auth_provider.dart"
Cohesion: 0.29
Nodes (7): auth_repository_provider.dart, AuthNotifier, build, signIn, signOut, authRepositoryProvider, Notifier

### Community 86 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.29
Nodes (5): package:flutter_riverpod/flutter_riverpod.dart, package:hangout_sales_app/app/app.dart, ../repositories/firebase_order_repository.dart, ../repositories/order_repository.dart, main

### Community 87 - "flavor.dart"
Cohesion: 0.33
Nodes (5): double?, Flavor, id, name, priceExtra

### Community 88 - "app.dart"
Cohesion: 0.40
Nodes (5): build, HangoutSalesManagerApp, routerProvider, router.dart, theme.dart

### Community 89 - "Order"
Cohesion: 0.40
Nodes (5): FamilyNotifier, OrderDraft, Order, OrderDraftNotifier, OrderEditNotifier

### Community 90 - "auth_repository_provider.dart"
Cohesion: 0.40
Nodes (4): firebase_auth_provider.dart, auth, AuthRepository, ../repositories/auth_repository.dart

### Community 91 - "auth_state_provider.dart"
Cohesion: 0.50
Nodes (3): authRepository, authStateChanges, authStateProvider

### Community 92 - "printer_device.dart"
Cohesion: 0.50
Nodes (3): macAddress, name, PrinterDevice

## Knowledge Gaps
- **808 isolated node(s):** `authState`, `AppTheme`, `primaryColor`, `backgroundColor`, `surfaceColor` (+803 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `ExpenseCategory` connect `verified_catalog_seed.dart` to `expense.dart`, `catalog_item.dart`, `manage_catalog_screen.dart`, `catalog_provider.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `build` connect `build` to `StatelessWidget`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **What connects `authState`, `AppTheme`, `primaryColor` to the rest of the system?**
  _808 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `order_draft_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._
- **Should `menu_data.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `order_history_screen_test.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.05807200929152149 - nodes in this community are weakly interconnected._