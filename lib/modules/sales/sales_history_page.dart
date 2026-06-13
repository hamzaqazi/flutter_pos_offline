import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sales_controller.dart';
import '../invoice/invoice_preview_page.dart';

class SalesHistoryPage extends GetView<SalesController> {
  const SalesHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales History")),
      body: Obx(() {
        if (controller.sales.isEmpty) {
          return const Center(child: Text("No sales found"));
        }

        return ListView.builder(
          itemCount: controller.sales.length,
          itemBuilder: (_, index) {
            final sale = controller.sales[index];

            return ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text("Rs ${sale.total}"),
              subtitle: Text(sale.date.toString()),
              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () {
                Get.to(
                  () => InvoicePreviewPage(
                    items: sale.items,
                    total: sale.total,
                    cash: sale.cash,
                    change: sale.change,
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}
