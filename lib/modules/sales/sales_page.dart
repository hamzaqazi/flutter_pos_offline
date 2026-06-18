import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sales_controller.dart';

class SalesPage extends GetView<SalesController> {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales History")),
      body: Obx(
        () => ListView.builder(
          itemCount: controller.sales.length,
          itemBuilder: (_, index) {
            final sale = controller.sales[index];

            return ListTile(
              title: Text(
                sale.hasInvoiceNumber
                    ? sale.invoiceNumber
                    : "Sale #${sale.id}",
              ),
              subtitle: Text("${sale.date} - Rs ${sale.total}"),
            );
          },
        ),
      ),
    );
  }
}
