import 'package:flutter_test/flutter_test.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/models/topping_selection.dart';
import 'package:hangout_sales_app/features/orders/models/receipt_data.dart';
import 'package:hangout_sales_app/features/orders/services/receipt_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final createdAt =
      DateTime(2026, 9, 3, 15, 0);

  Order createTestOrder() {
    return Order(
      id: 'order-1',
      orderNumber: 'ORD-0042',
      createdAt: createdAt,
      businessDate:
          DateTime(2026, 9, 3),
      customerName: 'Test Customer',
      customerPhone: '03001234567',
      customerAddress: 'Test Address',
      items: const [
        OrderItem(
          flavorId: 'chicken_tikka',
          flavorName: 'Chicken Tikka',
          flavorPriceExtra: null,
          size: PizzaSize.large,
          toppings: [
            ToppingSelection(
              toppingId: 'meat',
              toppingName: 'Extra Meat',
              priceAtOrderTime: 100,
            ),
          ],
          quantity: 1,
          unitPrice: 750,
        ),
      ],
      deals: const [],
      additionalDrinks: {
        'drink_1.5ltr': 2,
      },
      additionalDipSauceCount: 1,
      deliveryCharge: 150,
      total: 1510,
      status: OrderStatus.pending,
      paymentStatus: PaymentStatus.paid,
    );
  }

  test(
    'ReceiptData preserves saved order information',
    () {
      final data =
          ReceiptData.fromOrder(
        createTestOrder(),
      );

      expect(
        data.orderNumber,
        'ORD-0042',
      );

      expect(
        data.customerName,
        'Test Customer',
      );

      expect(
        data.items,
        hasLength(1),
      );

      expect(
        data.items.single.detail,
        contains('Chicken Tikka'),
      );

      expect(
        data.items.single.detail,
        contains('Extra Meat'),
      );

      expect(
        data.additionalItems,
        hasLength(2),
      );

      expect(
        data.total,
        1510,
      );

      expect(
        data.paymentStatus,
        'Paid',
      );
    },
  );

  test(
    'ReceiptBuilder generates a non-empty ESC/POS payload',
    () async {
      final data =
          ReceiptData.fromOrder(
        createTestOrder(),
      );

      final builder =
          const ReceiptBuilder();

      final bytes =
          await builder.build(data);

      expect(
        bytes,
        isNotEmpty,
      );

      expect(
        bytes.length,
        greaterThan(100),
      );
    },
  );

  test('ReceiptBuilder prints the NOTE line when delivery notes exist', () async {
    final order = createTestOrder();
    final data = ReceiptData.fromOrder(
      Order(
        id: order.id,
        orderNumber: order.orderNumber,
        createdAt: order.createdAt,
        businessDate: order.businessDate,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        customerAddress: order.customerAddress,
        deliveryNotes: 'Ring twice',
        items: order.items,
        deals: order.deals,
        additionalDrinks: order.additionalDrinks,
        additionalDipSauceCount: order.additionalDipSauceCount,
        deliveryCharge: order.deliveryCharge,
        total: order.total,
        status: order.status,
        paymentStatus: order.paymentStatus,
      ),
    );
    final bytes = await const ReceiptBuilder().build(data);
    expect(String.fromCharCodes(bytes), contains('NOTE: Ring twice'));
  });

  test('ReceiptBuilder omits the NOTE line when notes are absent', () async {
    final bytes = await const ReceiptBuilder().build(
      ReceiptData.fromOrder(createTestOrder()),
    );
    expect(String.fromCharCodes(bytes), isNot(contains('NOTE:')));
  });
}
