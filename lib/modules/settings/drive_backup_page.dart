import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/app_widgets.dart';
import 'package:ad_shop_pos/data/services/google_drive_service.dart';
import 'package:ad_shop_pos/data/services/import_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ad_shop_pos/app/widgets/premium_gate.dart';
import 'package:get/get.dart';

/// Page showing backups stored in the user's Google Drive, with
/// restore/delete options.
class DriveBackupPage extends StatefulWidget {
  const DriveBackupPage({super.key});

  @override
  State<DriveBackupPage> createState() => _DriveBackupPageState();
}

class _DriveBackupPageState extends State<DriveBackupPage> {
  List<DriveBackupInfo> _backups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _loading = true);
    final backups = await GoogleDriveService.listBackups();
    if (!mounted) return;
    setState(() {
      _backups = backups;
      _loading = false;
    });
  }

  void _confirmDelete(DriveBackupInfo info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cloud Backup?'),
        content: Text(
          'Delete backup from ${info.formattedDate} (${info.formattedSize}) '
          'from Google Drive? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await GoogleDriveService.deleteBackup(info.id);
              await _loadBackups();
              if (!mounted) return;
              Get.snackbar(
                ok ? 'Deleted' : 'Error',
                ok ? 'Cloud backup removed' : 'Could not delete backup',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Download the backup file from Drive and let the user save it anywhere
  /// on their device via the system file-save dialog (SAF on Android).
  Future<void> _downloadToDevice(DriveBackupInfo info) async {
    _showBlockingLoader('Downloading backup...');
    final bytes = await GoogleDriveService.downloadBackupBytes(info.id);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (bytes == null) {
      Get.snackbar(
        'Error',
        'Could not download this cloud backup',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // Opens the system "save file" dialog — the user picks the folder
      // (Downloads, SD card, etc.). Returns null if they cancel.
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save backup file',
        fileName: info.name,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (path == null) return; // user cancelled

      Get.snackbar(
        'Saved!',
        'Backup (${info.formattedSize}) saved to your device',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not save the file: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _confirmRestore(DriveBackupInfo info) async {
    _showBlockingLoader('Downloading backup...');
    final data = await GoogleDriveService.downloadBackup(info.id);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (data == null) {
      Get.snackbar(
        'Error',
        'Could not download or read this cloud backup',
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
            Icon(Icons.cloud_download_outlined, color: AppColors.warning),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('Restore from Drive?')),
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
            ].where((e) => e.$2 > 0).map(
                  (e) => Padding(
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
                  ),
                ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border:
                    Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
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

    _showBlockingLoader('Restoring backup...');
    final success = await ImportService.importBackup(data);
    if (!mounted) return;
    Navigator.of(context).pop();

    if (success) {
      Get.snackbar(
        'Restored!',
        'Cloud backup from ${info.formattedDate} restored successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showBlockingLoader(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.lg),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Drive Backups'),
        actions: [
          IconButton(
            onPressed: _loadBackups,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: PremiumGate(
        feature: 'Google Drive Backup',
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _backups.isEmpty
              ? _EmptyState(onRefresh: _loadBackups)
              : RefreshIndicator(
                  onRefresh: _loadBackups,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _backups.length,
                    itemBuilder: (context, index) {
                      final backup = _backups[index];
                      return _DriveBackupTile(
                        info: backup,
                        isLatest: index == 0,
                        onRestore: () => _confirmRestore(backup),
                        onDownload: () => _downloadToDevice(backup),
                        onDelete: () => _confirmDelete(backup),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}

class _DriveBackupTile extends StatelessWidget {
  final DriveBackupInfo info;
  final bool isLatest;
  final VoidCallback onRestore;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _DriveBackupTile({
    required this.info,
    required this.isLatest,
    required this.onRestore,
    required this.onDownload,
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
                    Icons.cloud_done_outlined,
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
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (isLatest) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: 0.12),
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
                        '${info.formattedSize} • ${info.name}',
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
                  width: 38,
                  height: 38,
                  child: IconButton.outlined(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    tooltip: 'Save to device',
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.seed,
                      side: BorderSide(
                          color: AppColors.seed.withValues(alpha: 0.5)),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 110,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore_outlined, size: 16),
                    label: const Text('Restore'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: BorderSide(
                          color: AppColors.warning.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 110,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.5)),
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
  const _EmptyState({this.onRefresh});
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'No Drive backups yet',
      subtitle: 'Upload a backup to Google Drive to see it here',
      actionLabel: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
    );
  }
}
