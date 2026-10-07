import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hangout_sales_app/features/orders/models/menu_data.dart';
import 'package:hangout_sales_app/features/orders/models/order.dart';
import 'package:hangout_sales_app/features/orders/models/order_item.dart';
import 'package:hangout_sales_app/features/orders/models/pizza_size.dart';
import 'package:hangout_sales_app/features/orders/models/topping_selection.dart';
import 'package:hangout_sales_app/features/orders/providers/order_edit_provider.dart';

Order _testOrder({
  OrderStatus status = OrderStatus.pending,
}) {
  return Order(
    id: 'order-1',
    orderNumber: 'ORD-0001',
    createdAt: DateTime(2026, 9, 2, 20),
    businessDate: DateTime(2026, 9, 2),
    customerName: 'Ali',
    customerPhone: '03001234567',
    customerAddress: 'Karachi',
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
        unitPrice: 800,
      ),
    ],
    deals: const [],
    additionalDrinks: const {},
    additionalDipSauceCount: 0,
    deliveryCharge: 100,
    total: 900,
    status: status,
    paymentStatus: PaymentStatus.unpaid,
  );
}

void main() {
  test(
    'edit provider loads the saved order into editable state',
    () {
      final order = _testOrder();

      final container = ProviderContainer();

      addTearDown(container.dispose);

      final draft = container.read(
        orderEditProvider(order),
      );

      expect(draft.entries, hasLength(1));
      expect(
        draft.customerName,
        'Ali',
      );
      expect(
        draft.customerPhone,
        '03001234567',
      );
      expect(
        draft.customerAddress,
        'Karachi',
      );
      expect(
        draft.deliveryCharge,
        100,
      );
    },
  );

  test(
    'changing customer information does not change the order item state',
    () {
      final order = _testOrder();

      final container = ProviderContainer();

      addTearDown(container.dispose);

      final notifier =
          container.read(
            orderEditProvider(order).notifier,
          );

      notifier.setCustomerName('Ahmed');

      final draft = container.read(
        orderEditProvider(order),
      );

      expect(
        draft.customerName,
        'Ahmed',
      );

      expect(
        draft.entries,
        hasLength(1),
      );

      expect(
        draft.entries.first.flavorIds.first,
        'chicken_tikka',
      );
    },
  );

  test(
    'adding a topping recalculates the edited total',
    () {
      final order = _testOrder();

      final container = ProviderContainer();

      addTearDown(container.dispose);

      final notifier =
          container.read(
            orderEditProvider(order).notifier,
          );

      final before = notifier.total;

      notifier.addTopping(
        notifier.state.entries.first.id,
        0,
        'veggie',
        'Extra Veggie',
      );

      final after = notifier.total;

      expect(after, greaterThan(before));
      expect(after, 950);
    },
  );

  test(
    'removing delivery charge recalculates the total',
    () {
      final order = _testOrder();

      final container = ProviderContainer();

      addTearDown(container.dispose);

      final notifier =
          container.read(
            orderEditProvider(order).notifier,
          );

      expect(notifier.total, 900);

      notifier.setDeliveryCharge(0);

      expect(notifier.total, 800);
    },
  );

  test(
    'buildEditedOrder preserves lifecycle and identity fields',
    () {
      final order = _testOrder();

      final container = ProviderContainer();

      addTearDown(container.dispose);

      final notifier =
          container.read(
            orderEditProvider(order).notifier,
          );

      final edited =
          notifier.buildEditedOrder();

      expect(
        edited.id,
        order.id,
      );

      expect(
        edited.orderNumber,
        order.orderNumber,
      );

      expect(
        edited.createdAt,
        order.createdAt,
      );

      expect(
        edited.businessDate,
        order.businessDate,
      );

      expect(
        edited.status,
        order.status,
      );

      expect(
        edited.paymentStatus,
        order.paymentStatus,
      );
    },
  );

  test('setDeliveryArea presets the charge; pickup clears the area', () {
    final order = _testOrder();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(orderEditProvider(order).notifier);
    notifier.setDeliveryArea(
      areaId: 'area-1',
      areaName: 'Sector 5C/1',
      defaultCharge: 150,
    );
    expect(container.read(orderEditProvider(order)).deliveryCharge, 150);
    notifier.setDeliveryCharge(MenuData.pickupCharge);
    expect(container.read(orderEditProvider(order)).deliveryAreaId, isNull);
  });

  test('buildEditedOrder normalizes a valid phone', () {
    final order = _testOrder();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(orderEditProvider(order).notifier);
    notifier.setCustomerPhone('+92 300 1234567');
    expect(notifier.buildEditedOrder().customerPhone, '03001234567');
  });

  test('buildEditedOrder keeps an invalid phone as typed', () {
    final order = _testOrder();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(orderEditProvider(order).notifier);
    notifier.setCustomerPhone('not-a-number');
    expect(notifier.buildEditedOrder().customerPhone, 'not-a-number');
  });
}
