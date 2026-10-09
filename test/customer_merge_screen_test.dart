import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hangout_sales_app/core/constants/app_routes.dart';
import 'package:hangout_sales_app/features/customers/models/customer.dart';
import 'package:hangout_sales_app/features/customers/models/customer_duplicate_candidate.dart';
import 'package:hangout_sales_app/features/customers/providers/customer_merge_provider.dart';
import 'package:hangout_sales_app/features/customers/providers/customers_provider.dart';
import 'package:hangout_sales_app/features/customers/repositories/customer_merge_repository.dart';
import 'package:hangout_sales_app/features/customers/screens/customer_duplicates_screen.dart';
import 'package:hangout_sales_app/features/customers/screens/customer_merge_screen.dart';
import 'package:hangout_sales_app/features/customers/screens/customer_screen.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/providers/order_repository_provider.dart';
import 'package:hangout_sales_app/features/orders/repositories/order_repository.dart';

const _a = '03001111111';
const _b = '03002222222';

final _t = DateTime(2026, 10, 2);

Customer _customer(
  String phone, {
  String? name,
  bool archived = false,
  String? mergedInto,
  DateTime? lastOrderAt,
}) {
  return Customer(
    phone: phone,
    name: name,
    archived: archived,
    mergedInto: mergedInto,
    createdAt: _t,
    updatedAt: _t,
    lastOrderAt: lastOrderAt,
  );
}

Order _order(String id) {
  return Order(
    id: id,
    orderNumber: 'ORD-$id',
    createdAt: _t,
    businessDate: _t,
    items: const [],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 0,
    total: 1000,
    status: OrderStatus.completed,
    paymentStatus: PaymentStatus.paid,
  );
}

class _FakeMergeRepository implements CustomerMergeRepository {
  final List<String> mergeCalls = <String>[];
  final List<String> dismissCalls = <String>[];
  Object? mergeError;

  @override
  Future<CustomerMergeResult> mergeCustomers({
    required String sourcePhone,
    required String targetPhone,
    required String reason,
    void Function(int ordersMoved)? onProgress,
  }) async {
    final error = mergeError;
    if (error != null) {
      throw error;
    }
    mergeCalls.add('$sourcePhone>$targetPhone:$reason');
    onProgress?.call(2);
    return const CustomerMergeResult(ordersMoved: 2, addressesAdded: 1);
  }

  @override
  Stream<Set<String>> streamDismissedPairs() => Stream.value(<String>{});

  @override
  Future<void> dismissPair(String phoneA, String phoneB) async {
    dismissCalls.add(duplicatePairKey(phoneA, phoneB));
  }
}

class _FakeOrderRepository implements OrderRepository {
  _FakeOrderRepository(this.ordersByPhone);

  final Map<String, List<Order>> ordersByPhone;

  @override
  Stream<List<Order>> streamOrdersByCustomerPhone(String phone) {
    return Stream.value(ordersByPhone[phone] ?? const <Order>[]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String initialLocation,
  required List<Customer> customers,
  required _FakeMergeRepository mergeRepository,
  Map<String, List<Order>> orders = const {},
  Set<String> dismissed = const {},
}) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: AppRoutes.customers,
        builder: (context, state) => const CustomerScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerDuplicates,
        builder: (context, state) => const CustomerDuplicatesScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerMerge,
        builder: (context, state) => CustomerMergeScreen(
          initialSourcePhone: state.uri.queryParameters['source'],
          initialTargetPhone: state.uri.queryParameters['target'],
        ),
      ),
      GoRoute(
        path: AppRoutes.customerDetail,
        builder: (context, state) =>
            Scaffold(body: Text('detail ${state.pathParameters['phone']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        allCustomersStreamProvider
            .overrideWith((ref) => Stream.value(customers)),
        dismissedDuplicatePairsProvider
            .overrideWith((ref) => Stream.value(dismissed)),
        customerMergeRepositoryProvider.overrideWithValue(mergeRepository),
        orderRepositoryProvider
            .overrideWithValue(_FakeOrderRepository(orders)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

List<Customer> _sameNamePair() {
  return [
    _customer(_a, name: 'Ahmed Raza', lastOrderAt: DateTime(2026, 9, 1)),
    _customer(_b, name: 'Ahmed Raza', lastOrderAt: DateTime(2026, 9, 20)),
  ];
}

void main() {
  final pairKey = duplicatePairKey(_a, _b);

  group('Customers list entry', () {
    testWidgets('shows the possible-duplicates entry and opens the screen',
        (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.customers,
        customers: _sameNamePair(),
        mergeRepository: _FakeMergeRepository(),
      );

      expect(find.text('Possible duplicates (1)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('possible_duplicates_entry')));
      await tester.pumpAndSettle();

      expect(find.byType(CustomerDuplicatesScreen), findsOneWidget);
      expect(find.text('Same name'), findsOneWidget);
    });

    testWidgets('hides the entry when the only pair was dismissed',
        (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.customers,
        customers: _sameNamePair(),
        mergeRepository: _FakeMergeRepository(),
        dismissed: {pairKey},
      );

      expect(find.byKey(const Key('possible_duplicates_entry')), findsNothing);
    });

    testWidgets('hides the entry when there are no duplicates',
        (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.customers,
        customers: [
          _customer(_a, name: 'Ahmed Raza'),
          _customer(_b, name: 'Sara Khan'),
        ],
        mergeRepository: _FakeMergeRepository(),
      );

      expect(find.byKey(const Key('possible_duplicates_entry')), findsNothing);
    });
  });

  group('Duplicates screen', () {
    testWidgets('dismissing a pair calls the repository', (tester) async {
      final repository = _FakeMergeRepository();
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.customerDuplicates,
        customers: _sameNamePair(),
        mergeRepository: repository,
      );

      await tester.tap(find.byKey(Key('dismiss_$pairKey')));
      await tester.pumpAndSettle();

      expect(repository.dismissCalls, [pairKey]);
    });

    testWidgets('review opens the merge screen with the suggested direction',
        (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.customerDuplicates,
        customers: _sameNamePair(),
        mergeRepository: _FakeMergeRepository(),
      );

      await tester.tap(find.byKey(Key('review_$pairKey')));
      await tester.pumpAndSettle();

      expect(find.byType(CustomerMergeScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('merge_source_card')),
          matching: find.textContaining(_a),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('merge_target_card')),
          matching: find.textContaining(_b),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the empty state when nothing is left', (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.customerDuplicates,
        customers: _sameNamePair(),
        mergeRepository: _FakeMergeRepository(),
        dismissed: {pairKey},
      );

      expect(find.text('No possible duplicates'), findsOneWidget);
    });
  });

  group('Merge screen', () {
    final location = AppRoutes.customerMergePath(
      sourcePhone: _a,
      targetPhone: _b,
    );

    testWidgets('previews the merge and needs a reason', (tester) async {
      await _pumpApp(
        tester,
        initialLocation: location,
        customers: _sameNamePair(),
        mergeRepository: _FakeMergeRepository(),
        orders: {
          _a: [_order('o1'), _order('o2')],
        },
      );

      expect(find.byKey(const Key('merge_preview_card')), findsOneWidget);
      expect(find.textContaining('2 orders will move'), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('merge_confirm_button')),
      );
      expect(button.onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('merge_reason_field')),
        'Same person',
      );
      await tester.pump();

      final enabled = tester.widget<FilledButton>(
        find.byKey(const Key('merge_confirm_button')),
      );
      expect(enabled.onPressed, isNotNull);
    });

    testWidgets('confirming runs the merge and opens the kept customer',
        (tester) async {
      final repository = _FakeMergeRepository();
      await _pumpApp(
        tester,
        initialLocation: location,
        customers: _sameNamePair(),
        mergeRepository: repository,
        orders: {
          _a: [_order('o1'), _order('o2')],
        },
      );

      await tester.enterText(
        find.byKey(const Key('merge_reason_field')),
        'Same person',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('merge_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.text('Merge customers?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('merge_dialog_confirm')));
      await tester.pumpAndSettle();

      expect(repository.mergeCalls, ['$_a>$_b:Same person']);
      expect(find.text('detail $_b'), findsOneWidget);
    });

    testWidgets('cancelling the dialog does not merge', (tester) async {
      final repository = _FakeMergeRepository();
      await _pumpApp(
        tester,
        initialLocation: location,
        customers: _sameNamePair(),
        mergeRepository: repository,
      );

      await tester.enterText(
        find.byKey(const Key('merge_reason_field')),
        'Same person',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('merge_confirm_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('merge_dialog_cancel')));
      await tester.pumpAndSettle();

      expect(repository.mergeCalls, isEmpty);
      expect(find.byType(CustomerMergeScreen), findsOneWidget);
    });

    testWidgets('a failed merge stays on screen and can be retried',
        (tester) async {
      final repository = _FakeMergeRepository()..mergeError = StateError('boom');
      await _pumpApp(
        tester,
        initialLocation: location,
        customers: _sameNamePair(),
        mergeRepository: repository,
      );

      await tester.enterText(
        find.byKey(const Key('merge_reason_field')),
        'Same person',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('merge_confirm_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('merge_dialog_confirm')));
      await tester.pumpAndSettle();

      expect(find.textContaining('boom'), findsOneWidget);
      expect(find.byType(CustomerMergeScreen), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('merge_confirm_button')),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('swap exchanges the duplicate and the customer to keep',
        (tester) async {
      await _pumpApp(
        tester,
        initialLocation: location,
        customers: _sameNamePair(),
        mergeRepository: _FakeMergeRepository(),
      );

      await tester.tap(find.byKey(const Key('merge_swap_button')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('merge_source_card')),
          matching: find.textContaining(_b),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('merge_target_card')),
          matching: find.textContaining(_a),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an already merged duplicate shows a blocker and no merge',
        (tester) async {
      await _pumpApp(
        tester,
        initialLocation: location,
        customers: [
          _customer(
            _a,
            name: 'Ahmed Raza',
            archived: true,
            mergedInto: '03009999999',
          ),
          _customer(_b, name: 'Ahmed Raza'),
        ],
        mergeRepository: _FakeMergeRepository(),
      );

      expect(find.byKey(const Key('merge_blocker')), findsOneWidget);
      expect(find.byKey(const Key('merge_preview_card')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('merge_reason_field')),
        'Same person',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('merge_confirm_button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('the picker chooses a customer to keep', (tester) async {
      await _pumpApp(
        tester,
        initialLocation: AppRoutes.customerMergePath(sourcePhone: _a),
        customers: [
          _customer(_a, name: 'Ahmed Raza'),
          _customer(_b, name: 'Sara Khan'),
        ],
        mergeRepository: _FakeMergeRepository(),
      );

      expect(find.text('No customer selected'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('merge_target_card')),
          matching: find.text('Choose'),
        ),
      );
      await tester.pumpAndSettle();

      // The duplicate itself is not offered as the customer to keep.
      expect(find.byKey(Key('merge_pick_$_a')), findsNothing);

      await tester.tap(find.byKey(Key('merge_pick_$_b')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const Key('merge_target_card')),
          matching: find.textContaining(_b),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('merge_preview_card')), findsOneWidget);
    });
  });
}
