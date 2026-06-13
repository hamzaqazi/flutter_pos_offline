import 'package:ad_shop_pos/data/models/customer_model.dart';
import 'package:ad_shop_pos/data/services/hive_service.dart';
import 'package:get/get.dart';

class CustomersController extends GetxController {
  final customers = <CustomerModel>[].obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    loadCustomers();
    super.onInit();
  }

  void loadCustomers() {
    final data = HiveService.customersBox.values.toList();
    customers.assignAll(
      data.map((e) => CustomerModel.fromMap(Map<dynamic, dynamic>.from(e))),
    );
  }

  void addCustomer(CustomerModel customer) {
    HiveService.customersBox.put(customer.id, customer.toMap());
    customers.add(customer);
  }

  void updateCustomer(CustomerModel customer) {
    final index = customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      customers[index] = customer;
      HiveService.customersBox.put(customer.id, customer.toMap());
    }
  }

  void deleteCustomer(String id) {
    customers.removeWhere((c) => c.id == id);
    HiveService.customersBox.delete(id);
  }

  CustomerModel? findById(String id) {
    try {
      return customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search customers by name, phone, or email.
  List<CustomerModel> get filteredCustomers {
    if (searchQuery.value.isEmpty) return customers;
    final query = searchQuery.value.toLowerCase();
    return customers.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query);
    }).toList();
  }

  /// Total number of customers.
  int get totalCustomers => customers.length;
}
