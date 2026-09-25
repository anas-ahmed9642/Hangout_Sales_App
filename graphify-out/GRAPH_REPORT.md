# Graph Report - hangout_sales_app  (2026-09-23)

## Corpus Check
- 140 files · ~54,514 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1396 nodes · 1984 edges · 79 communities (74 shown, 5 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `57cdef80`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- order_draft_provider.dart
- menu_data.dart
- completion_animation_test.dart
- GeneratedPluginRegistrant.swift
- login_screen.dart
- manage_catalog_screen.dart
- my_application.cc
- new_order_screen.dart
- package:flutter_riverpod/flutter_riverpod.dart
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
- package:flutter/material.dart
- topping_selector.dart
- order_detail_screen.dart
- payment_status_selector.dart
- package:hangout_sales_app/features/orders/models/order.dart
- package:flutter_test/flutter_test.dart
- hangout_sales_app
- LaunchImage.imageset/README.md
- order_history_provider_test.dart
- order_lifecycle_repository_regression_test.dart
- _MarkAsPaidButtonState
- OrderRepository
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
- dashboard_screen.dart
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
- catalog_repository_provider.dart
- ../providers/order_draft_provider.dart
- String?
- CustomPainter
- chicken_purchase_line.dart
- expense_line_item.dart

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

## Communities (79 total, 5 thin omitted)

### Community 0 - "order_draft_provider.dart"
Cohesion: 0.04
Nodes (51): addAdditionalDrink, addDeal, addStandalonePizza, addTopping, basePrice, build, buildOrder, _buildOrderItem (+43 more)

### Community 1 - "menu_data.dart"
Cohesion: 0.14
Nodes (13): flavor.dart, cheesePrices, deals, deliveryCharges, dipSaucePrice, drinkPrices, flavors, MenuData (+5 more)

### Community 2 - "completion_animation_test.dart"
Cohesion: 0.04
Nodes (43): app/app.dart, Completer, dart:async, features/orders/services/order_receipt_service.dart, firebase_options.dart, initializeApp, main, package:firebase_core/firebase_core.dart (+35 more)

### Community 3 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.06
Nodes (29): Any, cloud_firestore, Cocoa, firebase_auth, firebase_core, Flutter, FlutterAppDelegate, FlutterMacOS (+21 more)

### Community 4 - "login_screen.dart"
Cohesion: 0.05
Nodes (43): ../../../app/theme.dart, ../../auth/providers/auth_provider.dart, authProvider, build, controller, createState, _DashedDivider, dispose (+35 more)

### Community 5 - "manage_catalog_screen.dart"
Cohesion: 0.03
Nodes (64): ../../expenses/models/catalog_item.dart, ../../expenses/models/expense_category.dart, ../../expenses/providers/catalog_provider.dart, ../../expenses/providers/catalog_repository_provider.dart, FormState, bg, _blackBackground, border (+56 more)

### Community 6 - "my_application.cc"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 7 - "new_order_screen.dart"
Cohesion: 0.06
Nodes (31): ../../../core/constants/app_routes.dart, ../features/auth/providers/auth_state_provider.dart, ../features/auth/screens/login_screen.dart, ../features/auth/screens/splash_screen.dart, ../features/customers/screens/customer_screen.dart, ../features/dashboard/screens/dashboard_screen.dart, ../features/expenses/screens/expense_screen.dart, ../features/orders/screens/new_order_screen.dart (+23 more)

### Community 8 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.06
Nodes (31): auth_repository_provider.dart, firebase_auth_provider.dart, FirebaseAuth, AuthNotifier, build, signIn, signOut, auth (+23 more)

### Community 9 - "firebase_order_repository.dart"
Cohesion: 0.07
Nodes (27): changedEntries, createOrder, currentEditCount, _dealFromMap, _dealToMap, _firestore, getOrder, getOrderHistory (+19 more)

### Community 10 - "firebase_catalog_repository.dart"
Cohesion: 0.09
Nodes (22): catalog_repository.dart, CollectionReference, FirebaseFirestore, batch, _catalogCategories, _catalogCollection, _catalogItemFromDocument, _catalogSeedKey (+14 more)

### Community 11 - "order.dart"
Cohesion: 0.07
Nodes (28): additionalDipSauceCount, additionalDrinks, businessDate, createdAt, customerAddress, customerName, customerPhone, deals (+20 more)

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
Cohesion: 0.05
Nodes (39): chicken_purchase_line.dart, double?, expense_category.dart, expense_line_item.dart, active, brand, CatalogItem, category (+31 more)

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
Cohesion: 0.29
Nodes (12): ConsumerWidget, orderDraftProvider, NewOrderScreen, _submitOrder, AdditionalItemsSection, DeliveryPicker, FlavorSelector, OrderCategorySelector (+4 more)

### Community 28 - "deal.dart"
Cohesion: 0.22
Nodes (8): Deal, dipSauceCount, drinkSize, id, name, pizzaSizes, price, pizza_size.dart

### Community 29 - "order_draft_entry.dart"
Cohesion: 0.18
Nodes (9): deal.dart, copyWith, deal, flavorIds, id, OrderDraftEntry, standalonePizzaSize, toppings (+1 more)

### Community 30 - "order_history_screen.dart"
Cohesion: 0.06
Nodes (40): ../../../core/services/business_day_service.dart, DateTime, getOrderHistory, repository, allUnpaidOrdersProvider, businessDate, orderHistoryProvider, repository (+32 more)

### Community 31 - "package:flutter/material.dart"
Cohesion: 0.18
Nodes (9): build, CustomerScreen, build, _DrinkOption, _drinkOptions, id, label, package:flutter/material.dart (+1 more)

### Community 32 - "topping_selector.dart"
Cohesion: 0.25
Nodes (7): build, entry, id, name, _options, pizzaIndex, _ToppingOption

### Community 33 - "order_detail_screen.dart"
Cohesion: 0.04
Nodes (52): orderEditHistoryProvider, address, build, _capitalize, child, _confirmCompletion, confirmed, _confirmMarkAsPaid (+44 more)

### Community 34 - "payment_status_selector.dart"
Cohesion: 0.15
Nodes (12): IconData, build, icon, isPaid, label, onChanged, onTap, _paidColor (+4 more)

### Community 35 - "package:hangout_sales_app/features/orders/models/order.dart"
Cohesion: 0.22
Nodes (7): package:hangout_sales_app/features/orders/models/order.dart, package:hangout_sales_app/features/orders/widgets/payment_status_selector.dart, businessDate, createdAt, createOrder, main, main

### Community 36 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.11
Nodes (16): package:flutter_test/flutter_test.dart, package:hangout_sales_app/core/services/business_day_service.dart, package:hangout_sales_app/features/expenses/models/catalog_item.dart, package:hangout_sales_app/features/expenses/models/chicken_purchase_line.dart, package:hangout_sales_app/features/expenses/models/expense_category.dart, package:hangout_sales_app/features/expenses/models/expense.dart, package:hangout_sales_app/features/expenses/models/expense_line_item.dart, package:hangout_sales_app/features/expenses/models/market_list.dart (+8 more)

### Community 39 - "order_history_provider_test.dart"
Cohesion: 0.17
Nodes (11): package:hangout_sales_app/features/orders/providers/order_history_provider.dart, Stream, createOrder, getOrder, getOrderHistory, main, ordersStream, searchOrdersByPhone (+3 more)

### Community 40 - "order_lifecycle_repository_regression_test.dart"
Cohesion: 0.10
Nodes (25): ArgumentError, FakeFirebaseFirestore, FirebaseOrderRepository, package:cloud_firestore/cloud_firestore.dart, package:fake_cloud_firestore/fake_cloud_firestore.dart, package:hangout_sales_app/features/orders/repositories/firebase_order_repository.dart, StateError, firestore (+17 more)

### Community 41 - "_MarkAsPaidButtonState"
Cohesion: 0.32
Nodes (8): _MarkAsPaidButton, _MarkAsPaidButtonState, _ReprintButton, _ReprintButtonState, _CatalogEditorDialog, _CatalogEditorDialogState, State, StatefulWidget

### Community 42 - "OrderRepository"
Cohesion: 0.25
Nodes (8): OrderRepository, FakeOrderRepository, _TestOrderRepository, _TestOrderRepository, _TestOrderRepository, _TestOrderRepository, _FailingOrderRepository, _MockSearchRepository

### Community 43 - "firebase_order_repository_test.dart"
Cohesion: 0.29
Nodes (6): package:hangout_sales_app/features/orders/repositories/order_repository.dart, _createTestOrder, id, main, paymentStatus, status

### Community 44 - "order_search_provider_test.dart"
Cohesion: 0.20
Nodes (9): package:hangout_sales_app/features/orders/providers/order_search_provider.dart, createOrder, getOrder, getOrderHistory, main, searchOrdersByPhone, streamOrders, streamUnpaidOrders (+1 more)

### Community 45 - "StatelessWidget"
Cohesion: 0.07
Nodes (27): build, ExpenseScreen, _EditSummary, _ActivityEntry, _ActivityError, _ActivityLoading, _AdditionalItemsSection, _CustomerInformationSection (+19 more)

### Community 46 - "List"
Cohesion: 0.33
Nodes (5): List, return, container, createTestContainer, overrides

### Community 47 - "Win32Window"
Cohesion: 0.05
Nodes (57): PluginRegistry, RECT, unique_ptr, RegisterPlugins(), DartProject, HWND, LPARAM, LRESULT (+49 more)

### Community 48 - "order_edit_history_provider_test.dart"
Cohesion: 0.18
Nodes (10): package:hangout_sales_app/features/orders/providers/order_edit_history_provider.dart, createOrder, getOrder, getOrderHistory, history, main, searchOrdersByPhone, streamOrders (+2 more)

### Community 49 - "customer_form.dart"
Cohesion: 0.20
Nodes (10): _addressController, build, createState, CustomerForm, _CustomerFormState, dispose, initState, _nameController (+2 more)

### Community 50 - "order_category_selector.dart"
Cohesion: 0.18
Nodes (10): build, _DealCard, _DealGroup, deals, onDealSelected, _pizzaSizeLabel, title, ../models/deal.dart (+2 more)

### Community 51 - "order_repository_failure_test.dart"
Cohesion: 0.18
Nodes (10): createOrder, failure, getOrder, getOrderHistory, main, searchOrdersByPhone, streamOrders, streamUnpaidOrders (+2 more)

### Community 52 - "orderRepositoryProvider"
Cohesion: 0.18
Nodes (14): ConsumerState, ConsumerStatefulWidget, orderEditProvider, orderRepositoryProvider, build, EditOrderScreen, _EditOrderScreenState, _save (+6 more)

### Community 53 - "order_history_item.dart"
Cohesion: 0.15
Nodes (12): FamilyNotifier, Order, OrderEditNotifier, build, _color, onTap, order, OrderHistoryItem (+4 more)

### Community 54 - "order_payment_transition_test.dart"
Cohesion: 0.14
Nodes (12): package:hangout_sales_app/features/orders/providers/order_draft_provider.dart, package:hangout_sales_app/features/orders/providers/order_repository_provider.dart, createOrder, getOrder, getOrderHistory, main, searchOrdersByPhone, streamOrders (+4 more)

### Community 55 - "edit_order_screen.dart"
Cohesion: 0.06
Nodes (33): _AdditionalItemsEditor, charge, createState, _CustomerEditor, _dealToMap, delivery, _DeliveryEditor, dipTotal (+25 more)

### Community 56 - "receipt_data.dart"
Cohesion: 0.07
Nodes (27): additionalDipSauceTotal, additionalDrinksTotal, additionalItems, amount, createdAt, customerAddress, customerName, customerPhone (+19 more)

### Community 57 - "order_edit_provider.dart"
Cohesion: 0.07
Nodes (26): bool get, addAdditionalDrink, addDeal, addStandalonePizza, addTopping, build, buildEditedOrder, canSave (+18 more)

### Community 58 - "order_receipt_service_test.dart"
Cohesion: 0.05
Nodes (43): OrderStatus, macAddress, name, PrinterDevice, package:hangout_sales_app/features/orders/models/deal.dart, package:hangout_sales_app/features/orders/models/order_item.dart, package:hangout_sales_app/features/orders/models/pizza_size.dart, package:hangout_sales_app/features/orders/models/receipt_data.dart (+35 more)

### Community 59 - "order_receipt_service.dart"
Cohesion: 0.11
Nodes (22): Exception, _builder, _deviceStore, forgetPrinter, getPairedDevices, message, OrderReceiptService, PrinterBluetoothDisabledException (+14 more)

### Community 60 - "dashboard_screen.dart"
Cohesion: 0.11
Nodes (17): build, _DashboardHeader, DashboardScreen, icon, label, onTap, _OverviewCard, _OverviewGrid (+9 more)

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
Cohesion: 0.29
Nodes (6): buildTestOrder, businessDate, createdAt, firestore, main, repository

### Community 68 - "market_list.dart"
Cohesion: 0.14
Nodes (13): businessDate, createdAt, handedToWorker, id, itemName, items, MarketList, MarketListItem (+5 more)

### Community 69 - "catalog_provider.dart"
Cohesion: 0.24
Nodes (9): catalog_repository_provider.dart, catalogItemsProvider, category, repository, selectedCatalogCategoryProvider, streamCatalog, build, ManageCatalogScreen (+1 more)

### Community 70 - "catalog_repository.dart"
Cohesion: 0.29
Nodes (6): createCatalogItem, seedVerifiedCatalog, setCatalogItemActive, streamCatalog, updateCatalogItem, ../models/catalog_item.dart

### Community 71 - "hangout_app_bar.dart"
Cohesion: 0.22
Nodes (8): actions, build, HangoutAppBar, preferredSize, showBackButton, title, PreferredSizeWidget, Size get

### Community 72 - "theme.dart"
Cohesion: 0.25
Nodes (7): AppTheme, backgroundColor, errorColor, primaryColor, surfaceColor, textColor, static const Color

### Community 73 - "catalog_repository_provider.dart"
Cohesion: 0.33
Nodes (5): catalogRepositoryProvider, CatalogRepository, FirebaseCatalogRepository, ../repositories/catalog_repository.dart, ../repositories/firebase_catalog_repository.dart

### Community 74 - "../providers/order_draft_provider.dart"
Cohesion: 0.20
Nodes (9): build, charge, _DeliveryOption, label, build, entry, ../models/menu_data.dart, ../models/order_draft_entry.dart (+1 more)

### Community 76 - "CustomPainter"
Cohesion: 0.50
Nodes (4): CustomPainter, _AshlarPainter, _MeanderPainter, CastleWallPainter

### Community 77 - "chicken_purchase_line.dart"
Cohesion: 0.50
Nodes (3): ChickenPurchaseLine, chickenType, quantityKg

### Community 78 - "expense_line_item.dart"
Cohesion: 0.50
Nodes (3): ExpenseLineItem, itemName, price

## Knowledge Gaps
- **767 isolated node(s):** `authState`, `AppTheme`, `primaryColor`, `backgroundColor`, `surfaceColor` (+762 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Order` connect `order_history_item.dart` to `order_detail_screen.dart`, `order.dart`, `order_draft_notifier_test.dart`, `edit_order_screen.dart`, `order_edit_provider.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Why does `ExpenseCategory` connect `expense.dart` to `manage_catalog_screen.dart`, `catalog_provider.dart`?**
  _High betweenness centrality (0.013) - this node is a cross-community bridge._
- **What connects `authState`, `AppTheme`, `primaryColor` to the rest of the system?**
  _767 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `order_draft_provider.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._
- **Should `menu_data.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `completion_animation_test.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0425531914893617 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.05807200929152149 - nodes in this community are weakly interconnected._