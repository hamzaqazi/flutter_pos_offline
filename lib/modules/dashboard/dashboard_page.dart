import 'package:ad_shop_pos/modules/dashboard/dashboard_controlller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shop POS")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: const Text("Products"),
                subtitle: Obx(() => Text(controller.totalProducts.toString())),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Get.toNamed('/products');
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text("Sales"),
                subtitle: Obx(() => Text(controller.totalSales.toString())),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Get.toNamed('/sales');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
