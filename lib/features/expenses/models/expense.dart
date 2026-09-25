import 'chicken_purchase_line.dart';
import 'expense_category.dart';
import 'expense_line_item.dart';

class Expense {
  final String id;
  final String title;
  final ExpenseCategory category;
  final double amount;
  final String? notes;
  final DateTime date;
  final DateTime businessDate;
  final bool voided;
  final int editCount;

  final String? workerName;

  final String? linkedMarketListId;

  final double? pricePerKg;
  final List<ChickenPurchaseLine>? chickenLines;

  final List<ExpenseLineItem>? lineItems;

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.notes,
    required this.date,
    required this.businessDate,
    this.voided = false,
    this.editCount = 0,
    this.workerName,
    this.linkedMarketListId,
    this.pricePerKg,
    this.chickenLines,
    this.lineItems,
  });
}