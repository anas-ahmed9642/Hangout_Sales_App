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
  static const String customerDetail = '/customers/detail/:phone';
  static String customerDetailPath(String phone) =>
      '/customers/detail/$phone';
  static const String customerDuplicates = '/customers/duplicates';
  static const String customerMerge = '/customers/merge';

  /// Merge screen location. [sourcePhone] is the duplicate (archived after
  /// the merge); [targetPhone] is the customer to keep. Either may be
  /// omitted and is then chosen on the screen.
  static String customerMergePath({String? sourcePhone, String? targetPhone}) {
    final query = <String, String>{
      'source': ?sourcePhone,
      'target': ?targetPhone,
    };
    return Uri(
      path: customerMerge,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String manageCatalog = '/settings/catalog';
  static const String manageDeliveryAreas = '/settings/delivery-areas';
}
