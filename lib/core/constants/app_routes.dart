class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static const String orders = '/orders';
  static const String expenses = '/expenses';
  static const String expenseHistory = '/expenses/history';
  static const String marketList = '/expenses/market-list';
  static const String expenseDetail = '/expenses/detail/:id';
  static const String expenseEdit = '/expenses/detail/:id/edit';
  static String expenseDetailPath(String id) => '/expenses/detail/$id';
  static String expenseEditPath(String id) => '/expenses/detail/$id/edit';

  static const String customers = '/customers';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String manageCatalog = '/settings/catalog';
  static const String manageDeliveryAreas = '/settings/delivery-areas';
}
