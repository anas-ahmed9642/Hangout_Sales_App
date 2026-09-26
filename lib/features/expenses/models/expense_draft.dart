import 'chicken_purchase_line.dart';
import 'expense_category.dart';
import 'expense_line_item.dart';

/// The four entry shapes an expense draft can take.
///
/// Derived from [ExpenseCategory] via [ExpenseDraftShapeX.entryShape].
/// The add-expense UI reads this to decide which input section to render.
enum ExpenseEntryShape {
  /// Manual title + amount.
  /// Used by utilities, gas, electricity, internet, miscellaneous.
  plain,

  /// One or more [ChickenPurchaseLine] plus a price per kg.
  /// Used by chicken.
  chicken,

  /// One or more [ExpenseLineItem] picked from the catalog and copied
  /// as plain text. There is no free-text fallback.
  /// Used by marketBills, vegetables, beveragesAndDrinks, packaging.
  catalogItems,

  /// Worker name + manual amount.
  /// Used by workersWages.
  wages,
}

extension ExpenseDraftShapeX on ExpenseCategory {
  ExpenseEntryShape get entryShape {
    switch (this) {
      case ExpenseCategory.chicken:
        return ExpenseEntryShape.chicken;
      case ExpenseCategory.workersWages:
        return ExpenseEntryShape.wages;
      case ExpenseCategory.marketBills:
      case ExpenseCategory.vegetables:
      case ExpenseCategory.beveragesAndDrinks:
      case ExpenseCategory.packaging:
        return ExpenseEntryShape.catalogItems;
      case ExpenseCategory.utilities:
      case ExpenseCategory.gas:
      case ExpenseCategory.electricity:
      case ExpenseCategory.internet:
      case ExpenseCategory.miscellaneous:
        return ExpenseEntryShape.plain;
    }
  }
}

/// Immutable in-progress expense being built by the add-expense UI.
///
/// Mirrors the orders draft-state pattern: every mutation goes through
/// [copyWith] and the notifier replaces the whole state object, so
/// Riverpod rebuilds correctly. All fields are non-nullable with empty
/// defaults so [copyWith] never needs null-clearing sentinels; the
/// notifier maps empty strings to null when building the expense.
class ExpenseDraft {
  final ExpenseCategory? category;
  final String title;
  final double amount;
  final String notes;
  final String workerName;
  final double pricePerKg;
  final List<ChickenPurchaseLine> chickenLines;
  final List<ExpenseLineItem> lineItems;

  const ExpenseDraft({
    this.category,
    this.title = '',
    this.amount = 0,
    this.notes = '',
    this.workerName = '',
    this.pricePerKg = 0,
    this.chickenLines = const [],
    this.lineItems = const [],
  });

  /// The entry shape for the selected category, or null until a
  /// category is chosen.
  ExpenseEntryShape? get entryShape => category?.entryShape;

  ExpenseDraft copyWith({
    ExpenseCategory? category,
    String? title,
    double? amount,
    String? notes,
    String? workerName,
    double? pricePerKg,
    List<ChickenPurchaseLine>? chickenLines,
    List<ExpenseLineItem>? lineItems,
  }) {
    return ExpenseDraft(
      category: category ?? this.category,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      workerName: workerName ?? this.workerName,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      chickenLines: chickenLines ?? this.chickenLines,
      lineItems: lineItems ?? this.lineItems,
    );
  }
}
