import 'package:ad_shop_pos/data/models/staff_model.dart';
import 'package:ad_shop_pos/data/services/hive_service.dart';
import 'package:get/get.dart';

class StaffController extends GetxController {
  final staff = <StaffModel>[].obs;
  final Rx<String?> activeCashierId = Rx<String?>(null);

  @override
  void onInit() {
    loadStaff();
    _loadActiveCashier();
    super.onInit();
  }

  void loadStaff() {
    final data = HiveService.staffBox.values.toList();
    staff.assignAll(
      data.where((e) => e['id'] != null && e['id'] != 'activeCashierId').map(
            (e) => StaffModel.fromMap(Map<dynamic, dynamic>.from(e)),
          ),
    );
    _loadActiveCashier();
  }

  void _loadActiveCashier() {
    final id = HiveService.staffBox.get('activeCashierId');
    if (id != null) {
      activeCashierId.value = id.toString();
    }
  }

  void setActiveCashier(String id) {
    activeCashierId.value = id;
    HiveService.staffBox.put('activeCashierId', id);
  }

  void clearActiveCashier() {
    activeCashierId.value = null;
    HiveService.staffBox.delete('activeCashierId');
  }

  StaffModel? get activeCashier {
    if (activeCashierId.value == null) return null;
    try {
      return staff.firstWhere((s) => s.id == activeCashierId.value);
    } catch (_) {
      return null;
    }
  }

  void addStaff(StaffModel member) {
    HiveService.staffBox.put(member.id, member.toMap());
    staff.add(member);
  }

  void updateStaff(StaffModel member) {
    final index = staff.indexWhere((s) => s.id == member.id);
    if (index != -1) {
      staff[index] = member;
      HiveService.staffBox.put(member.id, member.toMap());
    }
  }

  void deleteStaff(String id) {
    if (activeCashierId.value == id) {
      clearActiveCashier();
    }
    staff.removeWhere((s) => s.id == id);
    HiveService.staffBox.delete(id);
  }

  StaffModel? findById(String id) {
    try {
      return staff.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  int get totalStaff => staff.length;
}
