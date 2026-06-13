import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/data/services/invoice_pdf_service.dart';
import 'package:ad_shop_pos/modules/invoice/invoice_page.dart';
import 'package:ad_shop_pos/modules/invoice/invoice_preview_page.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';

import 'cart_controller.dart';

class CartPage extends GetView<CartController> {
  CartPage({super.key});
  final salesController = Get.find<SalesController>();
  final cashController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cart")),
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return const Center(child: Text("Cart is Empty"));
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: controller.cartItems.length,
                itemBuilder: (_, index) {
                  final item = controller.cartItems[index];

                  return ListTile(
                    title: Text(item.product.name),
                    subtitle: Text("Rs ${item.product.price}"),
                    leading: IconButton(
                      onPressed: () {
                        controller.decreaseQuantity(index);
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.quantity.toString()),
                        IconButton(
                          onPressed: () {
                            controller.increaseQuantity(index);
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Total: Rs ${controller.totalAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final cart = Get.find<CartController>();

                        final cashController = TextEditingController();

                        Get.defaultDialog(
                          title: "Enter Cash",
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Total: Rs ${cart.totalAmount.toStringAsFixed(0)}",
                              ),
                              const SizedBox(height: 10),

                              TextField(
                                controller: cashController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: "Enter cash received",
                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // 👇 PUT YOUR WRAP HERE
                              Wrap(
                                spacing: 8,
                                children: [
                                  ActionChip(
                                    label: const Text("Exact"),
                                    onPressed: () {
                                      cashController.text = cart.totalAmount
                                          .toStringAsFixed(0);
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text("+500"),
                                    onPressed: () {
                                      cashController.text =
                                          (cart.totalAmount + 500)
                                              .toStringAsFixed(0);
                                    },
                                  ),
                                  ActionChip(
                                    label: const Text("+1000"),
                                    onPressed: () {
                                      cashController.text =
                                          (cart.totalAmount + 1000)
                                              .toStringAsFixed(0);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          textConfirm: "Pay",
                          textCancel: "Cancel",

                          onConfirm: () {
                            final rawCash = cashController.text.trim();
                            final cash = double.tryParse(rawCash) ?? 0;
                            final total = cart.totalAmount;
                            final change = cash - total;

                            if (cash < total) {
                              Get.snackbar("Error", "Insufficient cash");
                              return;
                            }

                            Get.back(); // close dialog

                            Get.to(
                              () => InvoicePreviewPage(
                                items: cart.cartItems,
                                total: total,
                                cash: cash,
                                change: change,
                              ),
                            );
                          },
                        );
                      },
                      child: const Text("Checkout"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> printInvoice({
    required List<CartItemModel> items,
    required double total,
    required double cash,
    required double change,
  }) async {
    final pdfBytes = await InvoicePdfService.generateInvoice(
      items: items,
      total: total,
      cash: cash,
      change: change,
    );

    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}
