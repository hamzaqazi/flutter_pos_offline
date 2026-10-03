import 'package:ad_shop_pos/modules/manual/manual_content.dart';
import 'package:ad_shop_pos/modules/manual/manual_model.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// State for the manual hub: the search box, the category filter and the
/// session's recently-viewed list.
///
/// Registered in `InitialBinding` with `fenix: true` (same pattern as the
/// other screen controllers), so the hub can be reopened without losing
/// what the user typed.
class ManualController extends GetxController {
  /// Owned here so [AppSearchBar] can drive filtering directly.
  final TextEditingController searchController = TextEditingController();

  /// Current search text (empty = not searching).
  final query = ''.obs;

  /// Active category filter — `null` means "no filter".
  final Rxn<ManualCategory> selectedCategory = Rxn<ManualCategory>();

  /// Guides opened this session, most recent first. In-memory only: this is
  /// convenience, not data worth persisting.
  final recentIds = <String>[].obs;

  /// True while the user has typed something into the search field.
  bool get isSearching => query.value.trim().isNotEmpty;

  /// Guides to show in the hub list, honouring search first and the
  /// category filter second.
  List<ManualGuide> get visibleGuides {
    if (isSearching) return ManualGuides.search(query.value);
    final category = selectedCategory.value;
    if (category != null) return ManualGuides.inCategory(category);
    return ManualGuides.all;
  }

  /// Resolved recently-viewed guides (skips any id that no longer exists).
  List<ManualGuide> get recentGuides {
    final guides = <ManualGuide>[];
    for (final id in recentIds) {
      final guide = ManualGuides.byId(id);
      if (guide != null) guides.add(guide);
    }
    return guides;
  }

  void onQueryChanged(String value) => query.value = value;

  void clearSearch() {
    searchController.clear();
    query.value = '';
  }

  /// Selecting the active category again clears the filter.
  void toggleCategory(ManualCategory category) {
    final isSame = selectedCategory.value == category;
    selectedCategory.value = isSame ? null : category;
    // A category filter replaces the search so the user sees the full list
    // for that topic rather than an empty intersection.
    if (!isSame) clearSearch();
  }

  void clearCategory() => selectedCategory.value = null;

  /// Records that [id] was opened, keeping the list short and de-duplicated.
  void recordView(String id) {
    recentIds.remove(id);
    recentIds.insert(0, id);
    if (recentIds.length > 4) {
      recentIds.removeRange(4, recentIds.length);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
