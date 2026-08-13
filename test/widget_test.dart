import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hangout_sales_app/app/app.dart';

void main() {
  testWidgets('App starts and shows Hangout Sales Manager', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HangoutSalesManagerApp(),
      ),
    );

    expect(find.text('Hangout Sales Manager'), findsOneWidget);
  });
}