import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/expense_repository.dart';
import '../repositories/firebase_expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return FirebaseExpenseRepository();
});
