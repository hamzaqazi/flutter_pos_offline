import 'package:ad_shop_pos/app/routes/app_routes.dart';
import 'package:ad_shop_pos/app/shell/shell_controller.dart';
import 'package:ad_shop_pos/modules/manual/manual_model.dart';
import 'package:get/get.dart';

/// Single place that knows how to get into and out of the manual, used by
/// the hub, the article screen, the app bar help button and empty states.
class ManualNav {
  ManualNav._();

  /// Opens the manual hub.
  static void openHub() => Get.toNamed(Routes.manual);

  /// Opens a single guide by id. Unknown ids fall back to the hub, so a
  /// stale deep link never lands the user on an empty screen.
  static void openGuide(String id) {
    Get.toNamed(Routes.manualArticle, parameters: {'id': id});
  }

  /// Runs a [ManualAction] declared inside a guide — either switching a
  /// bottom-nav tab or pushing a named route.
  ///
  /// Tab navigation pops back to the shell first, so it works the same
  /// whether the action is tapped from the hub or from a deep-linked
  /// article.
  static void runAction(ManualAction action) {
    final tabIndex = action.tabIndex;
    if (tabIndex != null) {
      ShellController.to.navigateToTab(tabIndex);
      return;
    }
    final route = action.route;
    if (route != null) {
      Get.toNamed(route);
    }
  }
}
