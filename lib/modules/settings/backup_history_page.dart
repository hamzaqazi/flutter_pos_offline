import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/services/auto_backup_service.dart';
import 'package:ad_shop_pos/data/services/import_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Page showing all auto-backup files with restore/delete options.
class BackupHistoryPage extends StatefulWidget {
  const BackupHistoryPage({super.key});

  @override
  State<BackupHistoryPage> createState() => _BackupHistoryPageState();
}

class _BackupHistoryPageState extends State<BackupHistoryPage> {
  List<BackupFileInfo> _backups = [];
  bool _loading = true;
  int _totalSizeKB = 0;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _loading = true);
    final backups = await AutoBackupService.listBackups();
    final totalSize = await AutoBackupService.totalBackupSizeKB();
    if (!mounted) return;
    setState(() {
      _backups = backups;
      _totalSizeKB = totalSize;
      _loading = false;
    });
  }

  String _formattedTotalSize() {
    if (_totalSizeKB < 1024) return '$_totalSizeKB KB';
    return '${(_totalSizeKB / 1024).toStringAsFixed(1)} MB';
  }

  void _confirmDelete(BackupFileInfo info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: Text(
          'Delete backup from ${info.formattedDate} (${info.formattedSize})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AutoBackupService.deleteBackup(info);
              _loadBackups();
              if (mounted) {
                Get.snackbar(
                  'Deleted',
                  'Backup file removed',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BackupFileInfo info) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.lg),
                Text('Reading backup...'),
              ],
            ),
          ),
        ),
      ),
    );

    final data = await AutoBackupService.readBackupFile(info.file);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (data == null) {
      Get.snackbar(
        'Error',
        'Could not read backup file',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final summary = ImportService.analyzeBackup(data);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.restore_outlined, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('Restore Backup?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup from ${info.formattedDate} (${info.formattedSize})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...[
              ('Products', summary.productCount),
              ('Sales', summary.saleCount),
              ('Expenses', summary.expenseCount),
              ('Returns', summary.returnCount),
              ('Customers', summary.customerCount),
              ('Staff', summary.staffCount),
            ]
                .where((e) => e.$2 > 0)
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: AppSpacing.sm),
                          Text('${e.$1}: ${e.$2}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    )),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'This will replace ALL current data!',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.lg),
                Text('Restoring backup...'),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await ImportService.importBackup(data);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (success) {
      Get.snackbar(
        'Restored!',
        'Backup from ${info.formattedDate} restored successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup History'),
        actions: [
          if (_backups.isNotEmpty)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete All Backups?'),
                    content: Text(
                      'This will delete all ${_backups.length} backup files (${_formattedTotalSize()}). This cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await AutoBackupService.deleteAllBackups();
                          _loadBackups();
                          Get.snackbar(
                            'Deleted',
                            'All backup files removed',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.danger),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Delete all backups',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _backups.isEmpty
              ? _EmptyState(onRefresh: _loadBackups)
              : RefreshIndicator(
                  onRefresh: _loadBackups,
                  child: CustomScrollView(
                    slivers: [
                      // Summary card
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(AppSpacing.lg),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.seed,
                                AppColors.seed.withValues(alpha: 0.75),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _SummaryStat(
                                  icon: Icons.folder_outlined,
                                  label: 'Total Backups',
                                  value: _backups.length.toString(),
                                ),
                              ),
                              Container(
                                  width: 1, height: 36, color: Colors.white24),
                              Expanded(
                                child: _SummaryStat(
                                  icon: Icons.sd_card_outlined,
                                  label: 'Total Size',
                                  value: _formattedTotalSize(),
                                ),
                              ),
                              Container(
                                  width: 1, height: 36, color: Colors.white24),
                              Expanded(
                                child: _SummaryStat(
                                  icon: Icons.schedule_outlined,
                                  label: 'Latest',
                                  value: _backups.isNotEmpty
                                      ? _backups.first.formattedDate
                                      : '—',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Backup list
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final backup = _backups[index];
                              return _BackupTile(
                                info: backup,
                                isLatest: index == 0,
                                onRestore: () => _confirmRestore(backup),
                                onDelete: () => _confirmDelete(backup),
                              );
                            },
                            childCount: _backups.length,
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xl),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _BackupTile extends StatelessWidget {
  final BackupFileInfo info;
  final bool isLatest;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupTile({
    required this.info,
    required this.isLatest,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: (isLatest ? AppColors.success : AppColors.seed)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    isLatest
                        ? Icons.check_circle_outline
                        : Icons.folder_outlined,
                    color: isLatest ? AppColors.success : AppColors.seed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            info.formattedDate,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isLatest) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LATEST',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${info.formattedSize} • ${info.filename}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 100,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore_outlined, size: 16),
                    label: const Text('Restore'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 80,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({required this.onRefresh});

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
                color: AppColors.seed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_off_outlined,
                size: 48,
                color: AppColors.seed.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('No backups yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enable auto-backup in Settings to keep\nyour data safe automatically',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
