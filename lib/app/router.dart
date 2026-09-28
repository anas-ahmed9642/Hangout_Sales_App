import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/auth/providers/auth_state_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/customers/screens/customer_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/expenses/screens/expense_detail_screen.dart';
import '../features/expenses/screens/expense_edit_screen.dart';
import '../features/expenses/screens/expense_history_screen.dart';
import '../features/expenses/screens/expense_screen.dart';
import '../features/expenses/screens/market_list_screen.dart';
import '../features/orders/screens/new_order_screen.dart';
import '../features/reports/screens/report_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/settings/screens/manage_catalog_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,

    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;

      final isGoingToLogin = state.matchedLocation == AppRoutes.login;
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

      if (authState.isLoading) {
        return AppRoutes.splash;
      }

      if (!isAuthenticated && !isGoingToLogin) {
        return AppRoutes.login;
      }

      if (isAuthenticated && (isGoingToLogin || isGoingToSplash)) {
        return AppRoutes.dashboard;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const NewOrderScreen(),
      ),
      GoRoute(
        path: AppRoutes.customers,
        builder: (context, state) => const CustomerScreen(),
      ),
      GoRoute(
        path: AppRoutes.expenses,
        builder: (context, state) => const ExpenseScreen(),
      ),
      GoRoute(
        path: AppRoutes.expenseHistory,
        builder: (context, state) => const ExpenseHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.expenseDetail,
        builder: (context, state) => ExpenseDetailScreen(expenseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.expenseEdit,
        builder: (context, state) => ExpenseEditScreen(expenseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.marketList,
        builder: (context, state) => const MarketListScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        builder: (context, state) => const ReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageCatalog,
        builder: (context, state) => const ManageCatalogScreen(),
      ),
    ],
  );
});

