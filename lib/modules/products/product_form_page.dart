import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/app_widgets.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:ad_shop_pos/data/services/category_service.dart';
import 'package:ad_shop_pos/modules/scanner/barcode_scanner_page.dart';
import 'package:ad_shop_pos/widgets/product_image_picker.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'products_controller.dart';

/// Full-screen form for adding a new product or editing an existing one.
///
/// A dedicated page (not an inline dialog) so the eight text controllers
/// have a real [State] lifecycle: created in [initState] and released in
/// [dispose] at the exact moment Flutter guarantees they are no longer in
/// use. An inline `Get.dialog` + `StatefulBuilder` has no such lifecycle,
/// which is why disposing them on route-pop threw
/// "used after being disposed".
class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});

  /// The product to edit. `null` adds a new product.
  final ProductModel? product;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _purchasePriceController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  late String _selectedCategory;
  String? _imagePath;

  bool get _isEditing => widget.product != null;

  ProductsController get _controller => Get.find<ProductsController>();

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) {
      _selectedCategory =
          Get.find<CategoryController>().categoryNames.firstOrNull ??
          "General";
      // New products start with a suggested SKU.
      _skuController.text = _controller.generateSku(_selectedCategory);
    } else {
      _nameController.text = product.name;
      _brandController.text = product.brand;
      _skuController.text = product.sku;
      _barcodeController.text = product.barcode;
      _priceController.text = product.price.toStringAsFixed(0);
      _purchasePriceController.text =
          product.purchasePrice.toStringAsFixed(0);
      _discountController.text = product.discount.toStringAsFixed(0);
      _stockController.text = product.stock.toString();
      _selectedCategory = product.category;
      _imagePath = product.image;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _regenerateSku(String category) =>
      _skuController.text = _controller.generateSku(category);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Live figures for the below-cost warning: an empty or unparseable box
    // counts as 0, matching what Save will store.
    final priceNow = double.tryParse(_priceController.text.trim()) ?? 0;
    final purchaseNow =
        double.tryParse(_purchasePriceController.text.trim()) ?? 0;
    final discountNow = double.tryParse(_discountController.text.trim()) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: DefaultTextStyle.merge(
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 16,
          ),
          child: Text(_isEditing ? "Edit Product" : "Add Product"),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primaryContainer, cs.surface],
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
        backgroundColor: cs.surface,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductImagePicker(
                        imagePath: _imagePath,
                        onChanged: (path) =>
                            setState(() => _imagePath = path),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: "Product name",
                          prefixIcon: Icon(Icons.label_outline),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _brandController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: "Brand (optional)",
                          prefixIcon: Icon(Icons.branding_watermark_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // SKU field (internal code)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _skuController,
                              textCapitalization:
                                  TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: "SKU",
                                hintText: "e.g. W0001",
                                prefixIcon: Icon(Icons.tag_outlined),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton.outlined(
                            onPressed: () {
                              _regenerateSku(_selectedCategory);
                              setState(() {});
                            },
                            icon: const Icon(Icons.autorenew, size: 20),
                            tooltip: "Auto-generate SKU",
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Barcode (real-world code from product packaging)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _barcodeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Barcode",
                                hintText: "e.g. 8901234567890",
                                prefixIcon: Icon(Icons.qr_code_outlined),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton.outlined(
                            onPressed: () async {
                              final result = await BarcodeScannerHelper
                                  .scanAndLookupRaw();
                              // Guard: the page can be dismissed while the
                              // scan is still in flight.
                              if (!mounted) return;
                              if (result != null && result.isNotEmpty) {
                                setState(() =>
                                    _barcodeController.text = result);
                              }
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 20),
                            tooltip: "Scan barcode with camera",
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: "Sell price",
                                prefixIcon: Icon(Icons.sell_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextField(
                              controller: _purchasePriceController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: "Purchase price",
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: "Discount %",
                                prefixIcon: Icon(Icons.discount_outlined),
                                suffixText: "%",
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Stock",
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // A standing discount can quietly put the item under
                      // what it cost — say so while the numbers are typed.
                      BelowCostWarning(
                        price: priceNow,
                        purchasePrice: purchaseNow,
                        discountPercent: discountNow,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "Category",
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: Get.find<CategoryController>().categoryNames
                            .map(
                              (name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedCategory = value;
                            if (!_isEditing) _regenerateSku(value);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ---------- Action bar ----------
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  if (_isEditing) ...[
                    IconButton.outlined(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.danger,
                      tooltip: "Delete product",
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: Get.back,
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final product = widget.product;
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _stockController.text.isEmpty) {
      Get.snackbar(
        "Missing info",
        "Please fill all required fields",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final discountVal = double.tryParse(_discountController.text) ?? 0;
    if (discountVal < 0 || discountVal > 100) {
      Get.snackbar(
        "Invalid discount",
        "Discount must be between 0 and 100",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Reject unparseable or negative numbers rather than letting `?? 0`
    // silently save a free or negatively-priced product.
    final priceVal = double.tryParse(_priceController.text.trim());
    final purchaseText = _purchasePriceController.text.trim();
    final purchaseVal =
        purchaseText.isEmpty ? 0.0 : double.tryParse(purchaseText);
    final stockVal = int.tryParse(_stockController.text.trim());
    if (priceVal == null ||
        purchaseVal == null ||
        stockVal == null ||
        priceVal < 0 ||
        purchaseVal < 0 ||
        stockVal < 0) {
      Get.snackbar(
        "Invalid value",
        "Enter a valid sell price, purchase price and stock — none can be "
        "negative",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final name = _nameController.text;
    final brand = _brandController.text;
    final sku = _skuController.text.trim();
    final barcode = _barcodeController.text.trim();

    if (product == null) {
      _controller.addProduct(
        ProductModel(
          id: UniqueKey().toString(),
          name: name,
          brand: brand,
          category: _selectedCategory,
          price: priceVal,
          purchasePrice: purchaseVal,
          discount: discountVal,
          stock: stockVal,
          image: _imagePath,
          sku: sku,
          barcode: barcode,
        ),
      );
    } else {
      _controller.updateProduct(
        product
            .copyWith(
              name: name,
              brand: brand,
              category: _selectedCategory,
              price: priceVal,
              purchasePrice: purchaseVal,
              discount: discountVal,
              stock: stockVal,
              sku: sku,
              barcode: barcode,
            )
            .withImage(_imagePath),
      );
    }
    Get.back();
  }

  Future<void> _delete() async {
    final product = widget.product;
    if (product == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: AppSpacing.sm),
            Text("Delete Product"),
          ],
        ),
        content: Text(
          "Are you sure you want to delete \"${product.name}\"? "
          "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _controller.deleteProduct(product.id);
      Get.back();
    }
  }
}
