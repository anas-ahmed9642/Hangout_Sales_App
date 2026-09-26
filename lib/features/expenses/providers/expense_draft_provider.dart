import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chicken_purchase_line.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../models/expense_draft.dart';
import '../models/expense_line_item.dart';
import 'expense_repository_provider.dart';

final expenseDraftProvider =
    NotifierProvider<ExpenseDraftNotifier, ExpenseDraft>(
  ExpenseDraftNotifier.new,
);

class ExpenseDraftNotifier extends Notifier<ExpenseDraft> {
  static const _uuid = Uuid();

  @override
  ExpenseDraft build() {
    return const ExpenseDraft();
  }

  /// Selects the category and restarts the draft.
  ///
  /// Inputs from the previous entry shape never leak into the new one:
  /// each category is a different form.
  void setCategory(ExpenseCategory category) {
    state = ExpenseDraft(category: category);
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setWorkerName(String workerName) {
    state = state.copyWith(workerName: workerName);
  }

  void setPricePerKg(double pricePerKg) {
    state = state.copyWith(pricePerKg: pricePerKg);
  }

  void addChickenLine({
    required String chickenType,
    required int quantityKg,
  }) {
    state = state.copyWith(
      chickenLines: [
        ...state.chickenLines,
        ChickenPurchaseLine(
          chickenType: chickenType,
          quantityKg: quantityKg,
        ),
      ],
    );
  }

  void updateChickenLine(
    int index, {
    required String chickenType,
    required int quantityKg,
  }) {
    if (index < 0 || index >= state.chickenLines.length) {
      return;
    }
    final updated = [...state.chickenLines];
    updated[index] = ChickenPurchaseLine(
      chickenType: chickenType,
      quantityKg: quantityKg,
    );
    state = state.copyWith(chickenLines: updated);
  }

  void removeChickenLine(int index) {
    if (index < 0 || index >= state.chickenLines.length) {
      return;
    }
    final updated = [...state.chickenLines]..removeAt(index);
    state = state.copyWith(chickenLines: updated);
  }

  /// Adds a catalog pick. [itemName] is the catalog item's display name
  /// copied as plain text (snapshot-at-add); no reference is stored.
  void addLineItem({
    required String itemName,
    required double price,
  }) {
    state = state.copyWith(
      lineItems: [
        ...state.lineItems,
        ExpenseLineItem(itemName: itemName, price: price),
      ],
    );
  }

  void updateLineItem(
    int index, {
    required String itemName,
    required double price,
  }) {
    if (index < 0 || index >= state.lineItems.length) {
      return;
    }
    final updated = [...state.lineItems];
    updated[index] = ExpenseLineItem(itemName: itemName, price: price);
    state = state.copyWith(lineItems: updated);
  }

  void removeLineItem(int index) {
    if (index < 0 || index >= state.lineItems.length) {
      return;
    }
    final updated = [...state.lineItems]..removeAt(index);
    state = state.copyWith(lineItems: updated);
  }

  /// Total chicken weight across all lines, in kg.
  int get totalKg {
    return state.chickenLines.fold(
      0,
      (total, line) => total + line.quantityKg,
    );
  }

  /// The amount the draft will be saved with.
  ///
  /// Chicken and catalog-items shapes compute it from their lines;
  /// plain and wages shapes use the manually entered amount.
  double get computedAmount {
    switch (state.entryShape) {
      case ExpenseEntryShape.chicken:
        return totalKg * state.pricePerKg;
      case ExpenseEntryShape.catalogItems:
        return state.lineItems.fold(
          0,
          (total, item) => total + item.price,
        );
      case ExpenseEntryShape.plain:
      case ExpenseEntryShape.wages:
      case null:
        return state.amount;
    }
  }

  List<String> get validationErrors {
    final errors = <String>[];
    final category = state.category;

    if (category == null) {
      errors.add('Select an expense category.');
      return errors;
    }

    if (state.title.trim().isEmpty) {
      errors.add('Title is required.');
    }

    switch (category.entryShape) {
      case ExpenseEntryShape.plain:
        if (state.amount <= 0) {
          errors.add('Amount must be greater than zero.');
        }
      case ExpenseEntryShape.wages:
        if (state.workerName.trim().isEmpty) {
          errors.add('Worker name is required.');
        }
        if (state.amount <= 0) {
          errors.add('Amount must be greater than zero.');
        }
      case ExpenseEntryShape.chicken:
        if (state.chickenLines.isEmpty) {
          errors.add('Add at least one chicken line.');
        }
        for (final line in state.chickenLines) {
          if (line.chickenType.trim().isEmpty) {
            errors.add('Each chicken line needs a type.');
          }
          if (line.quantityKg <= 0) {
            errors.add('Chicken quantity must be greater than zero.');
          }
        }
        if (state.pricePerKg <= 0) {
          errors.add('Price per kg must be greater than zero.');
        }
      case ExpenseEntryShape.catalogItems:
        if (state.lineItems.isEmpty) {
          errors.add('Add at least one item.');
        }
        for (final item in state.lineItems) {
          if (item.itemName.trim().isEmpty) {
            errors.add('Each item needs a name.');
          }
          if (item.price <= 0) {
            errors.add('Item price must be greater than zero.');
          }
        }
    }

    return errors;
  }

  bool get canConfirm {
    return validationErrors.isEmpty;
  }

  Expense buildExpense({
    required DateTime businessDate,
    DateTime? createdAt,
  }) {
    final errors = validationErrors;

    if (errors.isNotEmpty) {
      throw StateError(errors.join(' '));
    }

    final now = createdAt ?? DateTime.now();
    final shape = state.entryShape!;

    return Expense(
      id: _uuid.v4(),
      title: state.title.trim(),
      category: state.category!,
      amount: computedAmount,
      notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
      date: now,
      businessDate: businessDate,
      workerName:
          shape == ExpenseEntryShape.wages ? state.workerName.trim() : null,
      pricePerKg:
          shape == ExpenseEntryShape.chicken ? state.pricePerKg : null,
      chickenLines: shape == ExpenseEntryShape.chicken
          ? List<ChickenPurchaseLine>.unmodifiable(state.chickenLines)
          : null,
      lineItems: shape == ExpenseEntryShape.catalogItems
          ? List<ExpenseLineItem>.unmodifiable(state.lineItems)
          : null,
    );
  }

  Future<void> saveExpense({
    required DateTime businessDate,
  }) async {
    final expense = buildExpense(businessDate: businessDate);
    final repository = ref.read(expenseRepositoryProvider);
    await repository.createExpense(expense);
  }

  void clearDraft() {
    state = const ExpenseDraft();
  }
}
