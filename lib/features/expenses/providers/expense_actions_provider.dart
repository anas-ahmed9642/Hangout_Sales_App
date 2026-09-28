import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chicken_purchase_line.dart';
import '../models/expense.dart';
import '../models/expense_draft.dart';
import '../models/expense_edit_input.dart';
import '../models/expense_line_item.dart';
import '../repositories/expense_repository.dart';
import '../repositories/firebase_expense_repository.dart';
import 'expense_repository_provider.dart';

/// Phase 10: edit/void business logic, kept out of the UI.
final expenseActionsProvider = Provider<ExpenseActions>((ref) {
  return ExpenseActions(ref.watch(expenseRepositoryProvider));
});

String? _normalizedNotes(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// The amount an expense will have after applying [input].
///
/// Chicken and catalog shapes derive it from their lines (same formulas
/// the draft provider uses at save time); plain and wages use the
/// manually entered amount.
double computeEditedAmount(Expense original, ExpenseEditInput input) {
  switch (original.category.entryShape) {
    case ExpenseEntryShape.chicken:
      final totalKg = input.chickenQuantities.fold<int>(
        0,
        (total, kg) => total + kg,
      );
      return totalKg * input.pricePerKg;
    case ExpenseEntryShape.catalogItems:
      return input.lineItemPrices.fold<double>(
        0,
        (total, price) => total + price,
      );
    case ExpenseEntryShape.plain:
    case ExpenseEntryShape.wages:
      return input.amount;
  }
}

/// Validation errors for applying [input] to [original]; empty means OK.
List<String> validateExpenseEdit(Expense original, ExpenseEditInput input) {
  final errors = <String>[];

  if (input.title.trim().isEmpty) {
    errors.add('Title is required.');
  }

  switch (original.category.entryShape) {
    case ExpenseEntryShape.plain:
      if (input.amount <= 0) {
        errors.add('Amount must be greater than zero.');
      }
    case ExpenseEntryShape.wages:
      if (input.workerName.trim().isEmpty) {
        errors.add('Worker name is required.');
      }
      if (input.amount <= 0) {
        errors.add('Amount must be greater than zero.');
      }
    case ExpenseEntryShape.chicken:
      final savedLines =
          original.chickenLines ?? const <ChickenPurchaseLine>[];
      if (savedLines.isEmpty) {
        errors.add('This expense has no chicken lines to edit.');
      } else if (input.chickenQuantities.length != savedLines.length) {
        errors.add('Chicken quantities do not match the saved lines.');
      }
      if (input.chickenQuantities.any((kg) => kg <= 0)) {
        errors.add('Chicken quantity must be greater than zero.');
      }
      if (input.pricePerKg <= 0) {
        errors.add('Price per kg must be greater than zero.');
      }
    case ExpenseEntryShape.catalogItems:
      final savedItems = original.lineItems ?? const <ExpenseLineItem>[];
      if (savedItems.isEmpty) {
        errors.add('This expense has no items to edit.');
      } else if (input.lineItemPrices.length != savedItems.length) {
        errors.add('Item prices do not match the saved items.');
      }
      if (input.lineItemPrices.any((price) => price <= 0)) {
        errors.add('Item price must be greater than zero.');
      }
  }

  return errors;
}

/// The Firestore update map for applying [input] to [original].
///
/// Contains ONLY fields that actually changed (empty map = nothing to
/// save). When chicken/catalog lines or the price change, `amount` is
/// recomputed and included in the same map so the history shows both.
/// Throws [StateError] if the input is invalid.
Map<String, dynamic> buildExpenseChanges(
  Expense original,
  ExpenseEditInput input,
) {
  final errors = validateExpenseEdit(original, input);
  if (errors.isNotEmpty) {
    throw StateError(errors.join(' '));
  }

  final changes = <String, dynamic>{};

  final title = input.title.trim();
  if (title != original.title.trim()) {
    changes['title'] = title;
  }

  final notes = _normalizedNotes(input.notes);
  if (notes != _normalizedNotes(original.notes)) {
    changes['notes'] = notes;
  }

  switch (original.category.entryShape) {
    case ExpenseEntryShape.plain:
      if (input.amount != original.amount) {
        changes['amount'] = input.amount;
      }
    case ExpenseEntryShape.wages:
      final workerName = input.workerName.trim();
      if (workerName != (original.workerName ?? '').trim()) {
        changes['workerName'] = workerName;
      }
      if (input.amount != original.amount) {
        changes['amount'] = input.amount;
      }
    case ExpenseEntryShape.chicken:
      final savedLines =
          original.chickenLines ?? const <ChickenPurchaseLine>[];
      var linesChanged = false;
      for (var i = 0; i < savedLines.length; i++) {
        if (savedLines[i].quantityKg != input.chickenQuantities[i]) {
          linesChanged = true;
        }
      }
      final priceChanged = input.pricePerKg != original.pricePerKg;
      if (priceChanged) {
        changes['pricePerKg'] = input.pricePerKg;
      }
      if (linesChanged) {
        changes['chickenLines'] = [
          for (var i = 0; i < savedLines.length; i++)
            chickenPurchaseLineToMap(
              ChickenPurchaseLine(
                chickenType: savedLines[i].chickenType,
                quantityKg: input.chickenQuantities[i],
              ),
            ),
        ];
      }
      if (priceChanged || linesChanged) {
        final newAmount = computeEditedAmount(original, input);
        if (newAmount != original.amount) {
          changes['amount'] = newAmount;
        }
      }
    case ExpenseEntryShape.catalogItems:
      final savedItems = original.lineItems ?? const <ExpenseLineItem>[];
      var itemsChanged = false;
      for (var i = 0; i < savedItems.length; i++) {
        if (savedItems[i].price != input.lineItemPrices[i]) {
          itemsChanged = true;
        }
      }
      if (itemsChanged) {
        changes['lineItems'] = [
          for (var i = 0; i < savedItems.length; i++)
            expenseLineItemToMap(
              ExpenseLineItem(
                itemName: savedItems[i].itemName,
                price: input.lineItemPrices[i],
              ),
            ),
        ];
        final newAmount = computeEditedAmount(original, input);
        if (newAmount != original.amount) {
          changes['amount'] = newAmount;
        }
      }
  }

  return changes;
}

class ExpenseActions {
  final ExpenseRepository _repository;

  const ExpenseActions(this._repository);

  /// Applies [input] to [original]. Returns true if something was written,
  /// false if there was nothing to change (no repository call is made).
  ///
  /// Throws [ArgumentError] for a blank [changeReason], [StateError] for a
  /// voided expense or invalid input.
  Future<bool> saveEdit({
    required Expense original,
    required ExpenseEditInput input,
    required String changeReason,
  }) async {
    final reason = changeReason.trim();
    if (reason.isEmpty) {
      throw ArgumentError('A change reason is required.');
    }
    if (original.voided) {
      throw StateError('Voided expenses cannot be edited.');
    }

    final changes = buildExpenseChanges(original, input);
    if (changes.isEmpty) {
      return false;
    }

    await _repository.updateExpense(
      original.id,
      changes,
      changeReason: reason,
    );
    return true;
  }

  /// Soft-voids [expense]. Throws [ArgumentError] for a blank
  /// [changeReason] and [StateError] if it is already voided.
  Future<void> voidExpense({
    required Expense expense,
    required String changeReason,
  }) async {
    final reason = changeReason.trim();
    if (reason.isEmpty) {
      throw ArgumentError('A change reason is required to void an expense.');
    }
    if (expense.voided) {
      throw StateError('This expense is already voided.');
    }

    await _repository.voidExpense(expense.id, changeReason: reason);
  }
}
