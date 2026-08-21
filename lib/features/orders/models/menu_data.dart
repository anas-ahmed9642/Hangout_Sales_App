import 'pizza_size.dart';
import 'flavor.dart';
import 'deal.dart';

class MenuData {
  static const Map<PizzaSize, double> pizzaPrices = {
    PizzaSize.small: 330,
    PizzaSize.regular: 550,
    PizzaSize.large: 700,
  };
  static const List<Flavor> flavors = [
  Flavor(
    id: 'super_sicilian',
    name: 'Super Sicilian',
    priceExtra: null,
  ),
  Flavor(
    id: 'spicy_bbq',
    name: 'Spicy BBQ',
    priceExtra: null,
  ),
  Flavor(
    id: 'malai_boti',
    name: 'Malai Boti',
    priceExtra: null,
  ),
  Flavor(
    id: 'chicken_tikka',
    name: 'Chicken Tikka',
    priceExtra: null,
  ),
  Flavor(
    id: 'shawarma_red',
    name: 'Shawarma Red',
    priceExtra: null,
  ),
  Flavor(
    id: 'gypsy_euro',
    name: 'Gypsy Euro',
    priceExtra: null,
  ),
  Flavor(
    id: 'chicken_supreme',
    name: 'Chicken Supreme',
    priceExtra: null,
  ),
  Flavor(
    id: 'cheesy_bake',
    name: 'Cheesy Bake',
    priceExtra: null,
  ),
  Flavor(
    id: 'creamy_tikka',
    name: 'Creamy Tikka',
    priceExtra: null,
  ),
  Flavor(
    id: 'chicken_fajita',
    name: 'Chicken Fajita',
    priceExtra: null,
  ),
  Flavor(
    id: 'chicken_challenger',
    name: 'Chicken Challenger',
    priceExtra: null,
  ),
  Flavor(
    id: 'cheese_n_pepperoni',
    name: 'Cheese N Pepperoni',
    priceExtra: null,
  ),
  Flavor(
    id: 'afghani_feast',
    name: 'Afghani Feast',
    priceExtra: null,
  ),
  Flavor(
    id: 'veggie_lover',
    name: 'Veggie Lover',
    priceExtra: null,
  ),
  Flavor(
    id: 'creamy_que',
    name: 'Creamy Que',
    priceExtra: null,
  ),
  Flavor(
    id: 'ranch_blast',
    name: 'Ranch Blast',
    priceExtra: null,
  ),
  Flavor(
    id: 'hot_n_spicy_sriracha',
    name: 'Hot N Spicy Sriracha',
    priceExtra: null,
  ),
  Flavor(
    id: 'spicy_italian',
    name: 'Spicy Italian',
    priceExtra: null,
  ),
];
static const Map<String, double> toppingPrices = {
  'meat': 100,
  'veggie': 50,
};
static const Map<PizzaSize, double> cheesePrices = {
  PizzaSize.small: 70,
  PizzaSize.regular: 100,
  PizzaSize.large: 150,
};
static const Map<String, double> drinkPrices = {
  'drink_1.5ltr': 220,
  'drink_1ltr': 170,
  'drink_345ml': 80,
};

static const double dipSaucePrice = 30;
static const List<double> deliveryCharges = [
  70,
  100,
  130,
  150,
  200,
  250,
  300,
];

static const double pickupCharge = 0;

static const List<Deal> deals = [
  Deal(
    id: 'deal_1',
    name: 'Deal 1',
    price: 380,
    pizzaSizes: [
      PizzaSize.small,
    ],
    dipSauceCount: 0,
    drinkSize: 'drink_345ml',
  ),
  Deal(
  id: 'deal_2',
  name: 'Deal 2',
  price: 600,
  pizzaSizes: [
    PizzaSize.regular,
  ],
  dipSauceCount: 0,
  drinkSize: 'drink_345ml',
),

Deal(
  id: 'deal_3',
  name: 'Deal 3',
  price: 800,
  pizzaSizes: [
    PizzaSize.large,
  ],
  dipSauceCount: 1,
  drinkSize: 'drink_1ltr',
),

Deal(
  id: 'deal_4',
  name: 'Deal 4',
  price: 2200,
  pizzaSizes: [
    PizzaSize.large,
    PizzaSize.large,
    PizzaSize.large,
  ],
  dipSauceCount: 3,
  drinkSize: 'drink_1.5ltr',
),

Deal(
  id: 'deal_5',
  name: 'Deal 5',
  price: 1250,
  pizzaSizes: [
    PizzaSize.regular,
    PizzaSize.regular,
  ],
  dipSauceCount: 2,
  drinkSize: 'drink_1ltr',
),

Deal(
  id: 'deal_6',
  name: 'Deal 6',
  price: 1550,
  pizzaSizes: [
    PizzaSize.large,
    PizzaSize.large,
  ],
  dipSauceCount: 2,
  drinkSize: 'drink_1.5ltr',
),

Deal(
  id: 'deal_7',
  name: 'Deal 7',
  price: 1350,
  pizzaSizes: [
    PizzaSize.large,
    PizzaSize.regular,
  ],
  dipSauceCount: 0,
  drinkSize: 'drink_1ltr',
),

Deal(
  id: 'party_deal_1',
  name: 'Party Deal 1',
  price: 2700,
  pizzaSizes: [
    PizzaSize.large,
    PizzaSize.large,
    PizzaSize.regular,
    PizzaSize.regular,
  ],
  dipSauceCount: 4,
  drinkSize: 'drink_1.5ltr',
),

Deal(
  id: 'party_deal_2',
  name: 'Party Deal 2',
  price: 3600,
  pizzaSizes: [
    PizzaSize.large,
    PizzaSize.large,
    PizzaSize.large,
    PizzaSize.large,
    PizzaSize.large,
  ],
  dipSauceCount: 5,
  drinkSize: 'drink_1.5ltr',
),
];


}