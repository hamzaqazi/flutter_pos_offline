import 'package:ad_shop_pos/app/shell/shell_controller.dart';
import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared app bar for every AppShell tab page — same title style and the
/// same trailing actions (theme toggle + settings shortcut) everywhere.
/// Page-specific actions (e.g. Products' scan/cart icons) go in [actions]
/// and render before the shared ones.
class AppShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppShellAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.showSettingsAction = true,
  });

  /// Usually a `Text(...)`, but any widget works — e.g. Products passes a
  /// `Builder` so the title can reflect the free-tier product count.
  final Widget title;
  final List<Widget> actions;

  /// Hide the settings shortcut on the Settings page itself.
  final bool showSettingsAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return AppBar(
      // Use google fonts for the title, but let the page itself override the font size if needed.
      title: DefaultTextStyle.merge(
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          fontSize: 18,
        ),
        child: title,
      ),

      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      elevation: 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        ...actions,
        Obx(
          () => IconButton(
            onPressed: themeController.toggle,
            icon: Icon(
              themeController.isDark.value
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle theme',
          ),
        ),
        if (showSettingsAction)
          IconButton(
            onPressed: () => ShellController.to.goSettings(),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}
