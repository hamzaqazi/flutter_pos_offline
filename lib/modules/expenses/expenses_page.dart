import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/data/models/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'expenses_controller.dart';

class ExpensesPage extends GetView<ExpensesController> {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Expenses")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Add expense"),
      ),
      body: Obx(() {
        if (controller.expenses.isEmpty) {
          return _EmptyExpenses();
        }

        final sorted = controller.expenses.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return Column(
          children: [
            // Total banner
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.danger,
                    AppColors.danger.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Expenses",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    Formatters.currency(controller.totalExpenses),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                itemCount: sorted.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, index) {
                  final expense = sorted[index];
                  return _ExpenseTile(
                    expense: expense,
                    onDelete: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text("Delete Expense"),
                          content: Text(
                            "Delete \"${expense.description}\" for ${Formatters.currency(expense.amount)}?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: Get.back,
                              child: const Text("Cancel"),
                            ),
                            FilledButton(
                              onPressed: () {
                                controller.deleteExpense(expense.id);
                                Get.back();
                              },
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = ExpenseModel.categories.first;

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: StatefulBuilder(
            builder: (context, setState) {
              final theme = Theme.of(context);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text("Add Expense",
                            style: theme.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: "Amount",
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: ExpenseModel.categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedCategory = value!),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: descController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: Get.back,
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (amountController.text.isEmpty ||
                                  double.tryParse(amountController.text) ==
                                      null ||
                                  double.parse(amountController.text) <= 0) {
                                Get.snackbar(
                                  "Invalid amount",
                                  "Please enter a valid amount",
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              controller.addExpense(ExpenseModel(
                                id: UniqueKey().toString(),
                                amount: double.parse(amountController.text),
                                category: selectedCategory,
                                description: descController.text.trim().isEmpty
                                    ? selectedCategory
                                    : descController.text.trim(),
                                date: DateTime.now(),
                              ));
                              Get.back();
                            },
                            child: const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onDelete;

  const _ExpenseTile({required this.expense, required this.onDelete});

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Rent':
        return Icons.home_outlined;
      case 'Salary':
        return Icons.people_outlined;
      case 'Utilities':
        return Icons.electrical_services_outlined;
      case 'Maintenance':
        return Icons.build_outlined;
      case 'Supplies':
        return Icons.inventory_2_outlined;
      case 'Transport':
        return Icons.local_shipping_outlined;
      case 'Marketing':
        return Icons.campaign_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'Rent':
        return const Color(0xFF8B5CF6);
      case 'Salary':
        return const Color(0xFF06B6D4);
      case 'Utilities':
        return const Color(0xFFF59E0B);
      case 'Maintenance':
        return const Color(0xFFEF4444);
      case 'Supplies':
        return const Color(0xFF10B981);
      case 'Transport':
        return const Color(0xFF3B82F6);
      case 'Marketing':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _colorForCategory(expense.category);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(_iconForCategory(expense.category),
                  color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          expense.category,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        Formatters.dateTime(expense.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              Formatters.currency(expense.amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            InkWell(
              onTap: onDelete,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Icon(Icons.delete_outline,
                    size: 18, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyExpenses extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("No expenses yet", style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Track rent, salaries, utilities & more",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
