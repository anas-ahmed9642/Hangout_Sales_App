import 'chicken_purchase_line.dart';
import 'expense.dart';
import 'expense_line_item.dart';

class ExpenseEditInput {
  final String title;
  final String notes;
  final String workerName;
  final double amount;
  final double pricePerKg;
  final List<int> chickenQuantities;
  final List<double> lineItemPrices;
  const ExpenseEditInput({required this.title, this.notes = '', this.workerName = '', this.amount = 0, this.pricePerKg = 0, this.chickenQuantities = const [], this.lineItemPrices = const []});
  factory ExpenseEditInput.fromExpense(Expense expense) => ExpenseEditInput(title: expense.title, notes: expense.notes ?? '', workerName: expense.workerName ?? '', amount: expense.amount, pricePerKg: expense.pricePerKg ?? 0, chickenQuantities: [for (final line in expense.chickenLines ?? const <ChickenPurchaseLine>[]) line.quantityKg], lineItemPrices: [for (final item in expense.lineItems ?? const <ExpenseLineItem>[]) item.price]);
}
