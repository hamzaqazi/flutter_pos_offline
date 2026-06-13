import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../data/models/expense_model.dart';

class ExpensesController extends GetxController {
  final expenses = <ExpenseModel>[].obs;

  @override
  void onInit() {
    loadExpenses();
    super.onInit();
  }

  void loadExpenses() {
    final box = Hive.box('expenses');
    final data = box.values.toList();
    expenses.assignAll(
      data.map((e) => ExpenseModel.fromMap(Map<dynamic, dynamic>.from(e))),
    );
  }

  void addExpense(ExpenseModel expense) {
    final box = Hive.box('expenses');
    box.put(expense.id, expense.toMap());
    expenses.add(expense);
  }

  void deleteExpense(String id) {
    final box = Hive.box('expenses');
    box.delete(id);
    expenses.removeWhere((e) => e.id == id);
  }

  double get totalExpenses =>
      expenses.fold(0, (sum, e) => sum + e.amount);

  /// Expenses filtered by date range.
  List<ExpenseModel> filteredExpenses(DateTime start, DateTime end) {
    return expenses.where((e) {
      return e.date.isAfter(start) &&
          e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Total expenses in a date range.
  double totalExpensesInRange(DateTime start, DateTime end) {
    return filteredExpenses(start, end).fold(0, (sum, e) => sum + e.amount);
  }

  /// Expenses grouped by category for a date range.
  Map<String, double> expensesByCategory(DateTime start, DateTime end) {
    final map = <String, double>{};
    for (final e in filteredExpenses(start, end)) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }
}
