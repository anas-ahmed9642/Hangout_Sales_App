import '../models/expense_category.dart';

class VerifiedCatalogSeedItem {
  final ExpenseCategory category;
  final String name;
  final String? brand;
  final String? size;

  const VerifiedCatalogSeedItem({
    required this.category,
    required this.name,
    this.brand,
    this.size,
  });
}

const verifiedCatalogSeed = <VerifiedCatalogSeedItem>[
  // ---------------------------------------------------------------------------
  // Chicken — 3
  // ---------------------------------------------------------------------------

  VerifiedCatalogSeedItem(
    category: ExpenseCategory.chicken,
    name: 'Malai Boti',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.chicken,
    name: 'Fajita',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.chicken,
    name: 'Tikka',
  ),

  // ---------------------------------------------------------------------------
  // Vegetables — 2
  // ---------------------------------------------------------------------------

  VerifiedCatalogSeedItem(
    category: ExpenseCategory.vegetables,
    name: 'Onion',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.vegetables,
    name: 'Capsicum',
  ),

  // ---------------------------------------------------------------------------
  // Beverages and Drinks — 7
  // ---------------------------------------------------------------------------

  VerifiedCatalogSeedItem(
    category: ExpenseCategory.beveragesAndDrinks,
    name: 'Cola Next 345ml',
    brand: 'Cola Next',
    size: '345ml',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.beveragesAndDrinks,
    name: 'Cola Next 1ltr',
    brand: 'Cola Next',
    size: '1ltr',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.beveragesAndDrinks,
    name: 'Cola Next 1.5ltr',
    brand: 'Cola Next',
    size: '1.5ltr',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.beveragesAndDrinks,
    name: 'Fizzup 345ml',
    brand: 'Fizzup',
    size: '345ml',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.beveragesAndDrinks,
    name: 'Fizzup 1ltr',
    brand: 'Fizzup',
    size: '1ltr',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.beveragesAndDrinks,
    name: 'Fizzup 1.5ltr',
    brand: 'Fizzup',
    size: '1.5ltr',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.beveragesAndDrinks,
    name: 'Coke 1ltr',
    brand: 'Coke',
    size: '1ltr',
  ),

  // ---------------------------------------------------------------------------
// Packaging — 5
// ---------------------------------------------------------------------------

VerifiedCatalogSeedItem(
  category: ExpenseCategory.packaging,
  name: 'Boxes',
),
VerifiedCatalogSeedItem(
  category: ExpenseCategory.packaging,
  name: 'Shoppers',
),
VerifiedCatalogSeedItem(
  category: ExpenseCategory.packaging,
  name: 'P1',
),
VerifiedCatalogSeedItem(
  category: ExpenseCategory.packaging,
  name: 'Box Stopper',
),
VerifiedCatalogSeedItem(
  category: ExpenseCategory.packaging,
  name: 'Napkins',
),
  // ---------------------------------------------------------------------------
  // Market Bills — 21
  // ---------------------------------------------------------------------------

  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Mushroom Slices',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Black Olive',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Green Jalapeno',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Red Jalapeno',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Ketchup Sachet',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Chilli Garlic Sachet',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Tomato Ketchup 1kg',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Green Chilli Sauce 1kg',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Youngs Mayo 2kg (Blue)',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Goods Mayo (Carton)',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Acha Cheese (Blue) 2kg',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Dipitt Sriracha Sauce',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Crushed Chilli',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'White Pepper',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Garlic Powder',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Rossmoore Mustard Sauce',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Irani Cream',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Safa Tomato Paste',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Chicken Pepperoni',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Chicken Sausage',
  ),
  VerifiedCatalogSeedItem(
    category: ExpenseCategory.marketBills,
    name: 'Chicken Powder',
  ),
];