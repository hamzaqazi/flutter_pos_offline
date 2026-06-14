import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/models/staff_model.dart';
import 'package:ad_shop_pos/modules/staff/staff_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StaffPage extends GetView<StaffController> {
  const StaffPage({super.key});

  static const _roles = ['Cashier', 'Manager', 'Owner'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Staff")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text("Add Staff"),
      ),
      body: Column(
        children: [
          // Active cashier banner
          Obx(() {
            final cashier = controller.activeCashier;
            if (cashier == null) {
              return Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "No active cashier",
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "Set an active cashier to track who processes sales",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            return Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.seed,
                    AppColors.seed.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Active Cashier",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          cashier.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          cashier.role,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => controller.clearActiveCashier(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Clock out"),
                  ),
                ],
              ),
            );
          }),

          // Staff list
          Expanded(
            child: Obx(() {
              if (controller.staff.isEmpty) {
                return _EmptyStaff();
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  100,
                ),
                itemCount: controller.staff.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, index) {
                  final member = controller.staff[index];
                  final isActive =
                      controller.activeCashierId.value == member.id;
                  return _StaffTile(member: member, isActive: isActive);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog([StaffModel? existing]) {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    String selectedRole = existing?.role ?? 'Cashier';

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
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
                        color: AppColors.seed.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_outlined
                            : Icons.person_add_outlined,
                        color: AppColors.seed,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      isEdit ? "Edit Staff" : "Add Staff",
                      style: Get.textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: "Full name *",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: "Role",
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => selectedRole = v ?? 'Cashier',
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone number",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(Get.overlayContext!).pop(),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            Get.snackbar(
                              "Missing info",
                              "Staff name is required",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          if (isEdit) {
                            controller.updateStaff(
                              existing!.copyWith(
                                name: nameController.text.trim(),
                                role: selectedRole,
                                phone: phoneController.text.trim(),
                              ),
                            );
                          } else {
                            controller.addStaff(
                              StaffModel(
                                id: UniqueKey().toString(),
                                name: nameController.text.trim(),
                                role: selectedRole,
                                phone: phoneController.text.trim(),
                              ),
                            );
                          }
                          Navigator.of(Get.overlayContext!).pop();
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final StaffModel member;
  final bool isActive;
  const _StaffTile({required this.member, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final controller = Get.find<StaffController>();

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isActive ? AppColors.seed.withValues(alpha: 0.08) : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.seed.withValues(alpha: 0.2)
                    : cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isActive ? AppColors.seed : cs.onSurfaceVariant,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs, vertical: 1),
                        decoration: BoxDecoration(
                          color: _roleColor(member.role)
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          member.role,
                          style: TextStyle(
                            color: _roleColor(member.role),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (member.hasPhone) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          member.phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.seed,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Text(
                  "Active",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              IconButton.outlined(
                onPressed: () => controller.setActiveCashier(member.id),
                icon: const Icon(Icons.login_outlined, size: 18),
                color: AppColors.seed,
                tooltip: "Set as active cashier",
                padding: const EdgeInsets.all(AppSpacing.sm),
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Get.find<StaffPage>()._showAddEditDialog(member);
                } else if (value == 'delete') {
                  Get.dialog(
                    AlertDialog(
                      title: const Text("Delete Staff"),
                      content: Text(
                          "Delete ${member.name}? Their sales records will remain."),
                      actions: [
                        TextButton(
                            onPressed: Get.back, child: const Text("Cancel")),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.danger),
                          onPressed: () {
                            controller.deleteStaff(member.id);
                            Get.back();
                          },
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text("Edit")),
                PopupMenuItem(
                  value: 'delete',
                  child: Text("Delete",
                      style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Owner':
        return AppColors.seed;
      case 'Manager':
        return AppColors.accent;
      default:
        return AppColors.success;
    }
  }
}

class _EmptyStaff extends StatelessWidget {
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
                Icons.people_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("No staff yet", style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Add staff members and track who processes each sale",
              textAlign: TextAlign.center,
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
