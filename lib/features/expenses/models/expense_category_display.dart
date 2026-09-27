import 'expense_category.dart';

/// Human-readable labels for the expense category picker.
///
/// Lives in its own file so the Phase 2 enum stays untouched.
extension ExpenseCategoryDisplay on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.marketBills:
        return 'Market Bills';
      case ExpenseCategory.vegetables:
        return 'Vegetables';
      case ExpenseCategory.chicken:
        return 'Chicken';
      case ExpenseCategory.beveragesAndDrinks:
        return 'Beverages & Drinks';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.gas:
        return 'Gas';
      case ExpenseCategory.electricity:
        return 'Electricity';
      case ExpenseCategory.internet:
        return 'Internet';
      case ExpenseCategory.workersWages:
        return 'Workers Wages';
      case ExpenseCategory.packaging:
        return 'Packaging';
      case ExpenseCategory.miscellaneous:
        return 'Miscellaneous';
    }
  }
}
