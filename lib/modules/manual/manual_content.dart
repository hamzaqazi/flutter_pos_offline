import 'package:ad_shop_pos/app/routes/app_routes.dart';
import 'package:flutter/material.dart';

import 'manual_model.dart';

/// ═══════════════════════════════════════════════════════════════
///  USER MANUAL — guide content
///
///  This file is the single source of truth for the in-app manual.
///  To add a guide: append one [ManualGuide] to [all]. To reword a
///  guide: edit its blocks. No UI code needs to change.
///
///  ▸ Keep steps imperative and literal ("Tap Save"), and use the
///    exact labels the app shows, so users can follow along verbatim.
///  ▸ Prefer [ManualAction] at the end of a guide so users can jump
///    straight into the screen the guide describes.
/// ═══════════════════════════════════════════════════════════════
class ManualGuides {
  ManualGuides._();

  /// App version the manual was written against — shown on the hub so
  /// support can tell whether a user is reading current instructions.
  static const String version = '1.0.0+2';

  /// Guides featured at the top of the hub, in order.
  static const List<String> quickStartIds = [
    'getting-started',
    'make-a-sale',
    'add-product',
    'backup-export',
  ];

  // ────────────────────────────────────────────────────────────
  //  All guides
  // ────────────────────────────────────────────────────────────

  static const List<ManualGuide> all = [
    // ═══════════════ GETTING STARTED ═══════════════
    ManualGuide(
      id: 'getting-started',
      title: 'Getting Started',
      summary: 'Set up your shop and ring up your first sale.',
      category: ManualCategory.gettingStarted,
      icon: Icons.rocket_launch_outlined,
      keywords: ['setup', 'first', 'start', 'begin', 'install', 'new'],
      relatedIds: ['add-product', 'make-a-sale', 'shop-information'],
      blocks: [
        ManualParagraph(
          'Welcome to Codynest POS. This guide walks you through everything '
          'you need for your first sale — it takes about ten minutes.',
        ),
        const ManualSubheading('Set-up checklist'),
        ManualSteps([
          ManualStep(
            'Choose your plan on the first screen',
            detail:
                'Start a free trial, activate a license key, or continue on '
                'the free plan. You can change this later from the license '
                'screen.',
          ),
          ManualStep(
            'Enter your shop details',
            detail:
                'More tab → Shop Information. Your shop name, address and '
                'phone number print on every receipt.',
          ),
          ManualStep(
            'Add your products',
            detail:
                'Products tab → "Add product". Add at least a name, sell '
                'price and stock quantity.',
          ),
          ManualStep(
            'Set your tax rate (optional)',
            detail: 'More tab → Tax Settings, if you charge sales tax or VAT.',
          ),
          ManualStep(
            'Ring up your first sale',
            detail:
                'Cart tab → tap products to add them → Checkout → choose a '
                'payment method.',
          ),
          ManualStep(
            'Turn on backups',
            detail:
                'More tab → Export & Backup. Your data lives on this device, '
                'so a backup is your safety net.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Everything you enter is stored locally on this device and works '
          'without internet. Data only leaves the device if you switch on '
          'Google Drive backup.',
        ),
        const ManualAction('Open Shop Information', tabIndex: 4),
      ],
    ),

    ManualGuide(
      id: 'shop-information',
      title: 'Setting Up Your Shop Details',
      summary: 'Name, address, phone and currency shown on receipts.',
      category: ManualCategory.gettingStarted,
      icon: Icons.storefront_outlined,
      keywords: ['shop', 'name', 'address', 'phone', 'currency', 'logo'],
      relatedIds: ['receipt-customization', 'tax-settings'],
      blocks: [
        const ManualParagraph(
          'These details appear at the top of every printed receipt, so set '
          'them before you start selling.',
        ),
        const ManualSteps([
          ManualStep('Open the More tab, then tap "Shop Information"'),
          ManualStep('Fill in your shop name, address and phone number'),
          ManualStep(
            'Set the currency symbol',
            detail:
                'For example Rs, ₹, \$ or AED. It is used everywhere '
                'prices are shown.',
          ),
          ManualStep(
            'Add a receipt footer message (optional)',
            detail:
                'A thank-you note or return policy, printed at the '
                'bottom of the receipt.',
          ),
          ManualStep('Tap Save'),
        ]),
        const ManualCallout(
          ManualCalloutKind.note,
          'The edit form starts collapsed — tap the "Shop Information" row to '
          'expand it.',
        ),
      ],
    ),

    ManualGuide(
      id: 'tax-settings',
      title: 'Tax Settings',
      summary: 'Set a tax rate and choose inclusive or exclusive pricing.',
      category: ManualCategory.gettingStarted,
      icon: Icons.receipt_outlined,
      keywords: ['tax', 'vat', 'gst', 'rate', 'inclusive', 'exclusive'],
      relatedIds: ['make-a-sale', 'receipt-customization'],
      blocks: [
        const ManualParagraph(
          'Set your tax rate once and the app applies it to every sale '
          'automatically.',
        ),
        const ManualSteps([
          ManualStep('Open the More tab, then tap "Tax Settings"'),
          ManualStep(
            'Enter your tax rate',
            detail: 'For example, enter 16 for 16% VAT.',
          ),
          ManualStep(
            'Choose how the rate applies',
            detail:
                'Switch on "Tax-inclusive pricing" if your product prices '
                'already include tax. Leave it off if tax should be added on '
                'top of product prices.',
          ),
          ManualStep('Tap Save Tax Settings'),
        ]),
        const ManualCallout(
          ManualCalloutKind.warning,
          'Changing tax settings does not alter past sales. Already-recorded '
          'sales keep the tax they were made with.',
        ),
        const ManualCallout(
          ManualCalloutKind.note,
          'Reports show the tax you are still holding: the tax charged on the '
          'sales in the period, less the tax given back when those items were '
          'refunded. Refunding everything from a sale takes its tax back to '
          'zero.',
        ),
      ],
    ),

    // ═══════════════ SELLING ═══════════════
    ManualGuide(
      id: 'make-a-sale',
      title: 'Making a Sale',
      summary: 'Add items to the cart, apply discounts and check out.',
      category: ManualCategory.selling,
      icon: Icons.point_of_sale_outlined,
      keywords: ['sale', 'sell', 'checkout', 'cart', 'pos', 'payment', 'till'],
      relatedIds: ['hold-cart', 'returns', 'receipt-customization'],
      blocks: [
        ManualParagraph(
          'The Cart tab is your point of sale. Sales work offline — you never '
          'need a connection to complete one.',
        ),
        const ManualSubheading('To ring up a sale'),
        ManualSteps([
          ManualStep(
            'Add items to the cart',
            detail:
                'Open the Cart tab and tap products, or search for them, or '
                'use the barcode scanner.',
          ),
          ManualStep(
            'Adjust quantities',
            detail: 'Use the + and − controls on each cart line.',
          ),
          ManualStep(
            'Apply a discount (optional)',
            detail:
                'Enter a checkout discount as a fixed amount at checkout — '
                'for example Rs 100 off the bill, or tap one of the quick '
                'amounts. You can also set a standing Discount % on an '
                'individual product — if one ever drops the price below what '
                'the item cost, the cart flags that line as "Below cost".',
          ),
          ManualStep(
            'Attach a customer (optional)',
            detail:
                'Pick a customer from the dropdown, or add a new one on the '
                'spot.',
          ),
          ManualStep(
            'Tap Checkout and confirm the total',
            detail: 'Review the subtotal, discount and tax before saving.',
          ),
          ManualStep(
            'Complete the sale and print',
            detail:
                'After saving you can print the receipt to your paired '
                'thermal printer, or share it.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Sold the wrong item? Don\'t delete the sale — record a return '
          'instead so your reports stay accurate.',
        ),
        const ManualCallout(
          ManualCalloutKind.warning,
          'Checkout warns you before you take payment if the additional '
          'discount brings the total below what the items in the cart cost '
          'you, and shows both figures. Completing the sale is still your '
          'call.',
        ),
        const ManualAction('Go to Cart', tabIndex: 2),
      ],
    ),

    ManualGuide(
      id: 'hold-cart',
      title: 'Holding & Resuming a Cart',
      summary: 'Park a sale when a customer steps away, then pick it up.',
      category: ManualCategory.selling,
      icon: Icons.pause_circle_outline,
      keywords: ['hold', 'suspend', 'park', 'resume', 'waiting', 'queue'],
      relatedIds: ['make-a-sale'],
      blocks: [
        const ManualParagraph(
          'If a customer steps away mid-sale, hold the cart instead of '
          'clearing it. You can serve someone else and come back later.',
        ),
        const ManualSteps([
          ManualStep('Add the items to the cart as usual'),
          ManualStep(
            'Tap "Hold" in the Cart app bar',
            detail: 'The Hold button only appears when the cart has items.',
          ),
          ManualStep(
            'Give the held cart a name',
            detail:
                'Use anything you will recognise later — "Customer name, '
                'table number" or similar.',
          ),
          ManualStep('Tap "Hold" to save it'),
          ManualStep(
            'Resume later from the held-carts banner',
            detail:
                'A banner at the top of the Cart tab shows your held carts — '
                'tap it to view the list and tap "Resume" on the one you want.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.note,
          'Held carts survive app restarts — they are saved on the device, so '
          'you can close the app and resume tomorrow.',
        ),
        const ManualCallout(
          ManualCalloutKind.warning,
          '"Clear" empties the current cart completely and cannot be undone. '
          'Use "Hold" if you might need the items again.',
        ),
      ],
    ),

    ManualGuide(
      id: 'sale-customer',
      title: 'Attaching a Customer to a Sale',
      summary: 'Track which customer bought what, for follow-ups and credit.',
      category: ManualCategory.selling,
      icon: Icons.person_add_alt_outlined,
      keywords: ['customer', 'buyer', 'client', 'name', 'credit', 'account'],
      relatedIds: ['customers', 'make-a-sale'],
      blocks: [
        const ManualParagraph(
          'Attaching a customer to a sale links that purchase to their record. '
          'It is optional for every sale.',
        ),
        const ManualSteps([
          ManualStep('Add items to the cart and tap Checkout'),
          ManualStep(
            'Open the "Customer (optional)" dropdown',
            detail: 'It lists everyone in your customer book.',
          ),
          ManualStep(
            'Pick an existing customer — or add a new one',
            detail:
                'Choose the quick-add option to create a customer without '
                'leaving the checkout screen.',
          ),
          ManualStep('Confirm the sale as normal'),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Attaching customers lets you look up their purchase history later, '
          'which is useful for repeat buyers and complaints.',
        ),
      ],
    ),

    ManualGuide(
      id: 'returns',
      title: 'Returns & Refunds',
      summary: 'Record a returned item and adjust your profit correctly.',
      category: ManualCategory.selling,
      icon: Icons.assignment_return_outlined,
      keywords: ['return', 'refund', 'exchange', 'money back', 'credit note'],
      relatedIds: ['sales-history', 'reports'],
      blocks: [
        const ManualParagraph(
          'Recording a return keeps your stock, sales and profit figures '
          'correct. Never delete the original sale — the app needs it to '
          'reconcile the return.',
        ),
        const ManualSteps([
          ManualStep('Open Returns from the dashboard or the More tab'),
          ManualStep(
            'Select the original sale',
            detail:
                'Search by invoice number or customer so the return is linked '
                'to the right transaction.',
          ),
          ManualStep('Choose the items and quantities being returned'),
          ManualStep(
            'Confirm the return',
            detail:
                'Stock is added back to inventory and the refund is recorded '
                'against the original sale.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.note,
          'Returns reduce the profit shown for that sale — this is expected, '
          'and it is why returns should always go through this screen rather '
          'than deleting a sale.',
        ),
        const ManualAction('Open Returns', route: Routes.returns),
      ],
    ),

    ManualGuide(
      id: 'scanner',
      title: 'Using the Barcode Scanner',
      summary:
          'Scan a barcode to find a product or add it straight to the cart.',
      category: ManualCategory.selling,
      icon: Icons.qr_code_scanner_rounded,
      keywords: ['barcode', 'scan', 'scanner', 'qr', 'camera', 'sku'],
      relatedIds: ['add-product', 'make-a-sale'],
      blocks: [
        const ManualParagraph(
          'The scanner uses your device camera to read barcodes and QR codes, '
          'so you never have to type a long number.',
        ),
        const ManualSteps([
          ManualStep(
            'Tap the scanner icon',
            detail:
                'It appears in the app bar on the Products and Dashboard '
                'screens, and inside the Cart screen.',
          ),
          ManualStep(
            'Point the camera at the barcode',
            detail:
                'Keep the code inside the frame. The app reads it '
                'automatically.',
          ),
          ManualStep('Tap the flash icon if the room is dark'),
          ManualStep(
            'The app finds the matching product',
            detail:
                'If a product with that barcode exists it is added to the '
                'cart. If not, you are prompted to create it.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.note,
          'Barcodes only work if the product has one saved. Add a barcode to '
          'each product when you create or edit it.',
        ),
        const ManualCallout(
          ManualCalloutKind.tip,
          'No camera permission? Grant camera access for Codynest POS in your '
          'phone\'s settings, then reopen the scanner.',
        ),
      ],
    ),

    // ═══════════════ INVENTORY ═══════════════
    ManualGuide(
      id: 'add-product',
      title: 'Adding a Product',
      summary: 'Create a product with price, stock and barcode.',
      category: ManualCategory.inventory,
      icon: Icons.add_box_outlined,
      keywords: [
        'product',
        'item',
        'add',
        'new',
        'sku',
        'barcode',
        'price',
        'stock',
      ],
      relatedIds: ['edit-delete-product', 'categories', 'low-stock'],
      blocks: [
        const ManualParagraph(
          'Products are the foundation of the app — you need at least one '
          'before you can make a sale.',
        ),
        const ManualSteps([
          ManualStep('Open the Products tab and tap "Add product"'),
          ManualStep(
            'Enter the product name',
            detail:
                'This is the only field you must fill in — everything '
                'else is optional.',
          ),
          ManualStep('Add a brand (optional)'),
          ManualStep(
            'Set the SKU and barcode',
            detail:
                'The SKU is your own short code (for example W0001). The '
                'barcode is the number printed on the packaging — scanning '
                'it later will find this product.',
          ),
          ManualStep(
            'Enter the sell price',
            detail: 'This is what the customer pays.',
          ),
          ManualStep(
            'Enter the purchase price',
            detail:
                'What the item costs you. The app uses it to work out your '
                'profit on every sale.',
          ),
          ManualStep(
            'Set a product-level discount % (optional)',
            detail: 'Useful for items you always sell at a reduced price.',
          ),
          ManualStep('Enter the current stock quantity'),
          ManualStep(
            'Choose a category',
            detail: 'Categories make products easier to find and report on.',
          ),
          ManualStep('Tap Save'),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Fill in the purchase price for every product. Without it, profit '
          'reports for that item show the full sale amount as profit.',
        ),
        const ManualCallout(
          ManualCalloutKind.warning,
          'A discount that drops the sell price below the purchase price makes '
          'the form warn you that you would lose money on every unit sold. It '
          'is only a warning — you can still save it, for example to clear '
          'old stock — and the cart flags those items as "Below cost" when '
          'they are sold.',
        ),
        const ManualCallout(
          ManualCalloutKind.note,
          'On the free plan the Products title shows how many items you have '
          'used out of your allowance, for example "Products (12/50)".',
        ),
        const ManualAction('Go to Products', tabIndex: 1),
      ],
    ),

    ManualGuide(
      id: 'edit-delete-product',
      title: 'Editing & Deleting Products',
      summary:
          'Update prices or stock, or remove a product you no longer sell.',
      category: ManualCategory.inventory,
      icon: Icons.edit_outlined,
      keywords: ['edit', 'delete', 'remove', 'update', 'price change'],
      relatedIds: ['add-product', 'low-stock'],
      blocks: [
        const ManualSteps([
          ManualStep(
            'Open the Products tab and find the product',
            detail:
                'Use the search field to filter by name, brand, SKU or '
                'barcode.',
          ),
          ManualStep('Tap the product to open it'),
          ManualStep(
            'Change any details and tap Save',
            detail:
                'Price and stock changes take effect on the next sale. Sales '
                'already recorded keep the price they were made at.',
          ),
        ]),
        ManualCallout(
          ManualCalloutKind.warning,
          'Deleting a product removes it from your catalogue permanently. '
          'Past sales that included it keep their own copy of the name and '
          'price, so your history and reports stay correct.',
        ),
        ManualCallout(
          ManualCalloutKind.tip,
          'To take an item off sale temporarily, set its stock to 0 instead of '
          'deleting it — it stays in your reports and can be restocked later.',
        ),
      ],
    ),

    ManualGuide(
      id: 'categories',
      title: 'Organising Products with Categories',
      summary: 'Group products so you can find and report on them faster.',
      category: ManualCategory.inventory,
      icon: Icons.category_outlined,
      keywords: ['category', 'categories', 'group', 'organise', 'filter'],
      relatedIds: ['add-product', 'reports'],
      blocks: [
        const ManualParagraph(
          'Categories group related products — for example Drinks, Snacks or '
          'Stationery. You can filter the Products list by category and see a '
          'breakdown of sales per category in Reports.',
        ),
        const ManualSteps([
          ManualStep('Open the More tab, then tap "Categories"'),
          ManualStep(
            'Tap to add a category and give it a name',
            detail: 'Each category gets a colour used on cards and in charts.',
          ),
          ManualStep(
            'Assign categories to your products',
            detail:
                'When adding or editing a product, pick its category from the '
                'dropdown.',
          ),
          ManualStep('Filter the Products tab by category'),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Keep the list short — around five to ten categories. Too many makes '
          'the reports harder to read and products harder to find.',
        ),
      ],
    ),

    ManualGuide(
      id: 'low-stock',
      title: 'Low Stock & Restocking',
      summary: 'Get warned before items run out, and record new stock.',
      category: ManualCategory.inventory,
      icon: Icons.warning_amber_rounded,
      keywords: [
        'low',
        'stock',
        'restock',
        'out of stock',
        'inventory',
        'alert',
      ],
      relatedIds: ['add-product', 'reports'],
      blocks: [
        const ManualParagraph(
          'The app warns you when stock drops to a level you choose, so you '
          'can reorder before an item sells out.',
        ),
        const ManualSubheading('Set the warning level'),
        ManualSteps([
          ManualStep('Open the More tab, then tap "Low Stock Alert"'),
          ManualStep(
            'Enter your low stock threshold',
            detail:
                'For example 5 units. Any product at or below this level '
                'raises an alert.',
          ),
          ManualStep('Tap Save'),
        ]),
        const ManualSubheading('Restock an item'),
        ManualSteps([
          ManualStep(
            'Open the low stock list',
            detail:
                'Products at or below the threshold appear under "Low '
                'Stock", and zero-stock items under "Out of Stock".',
          ),
          ManualStep('Tap "Restock" on the product you received'),
          ManualStep(
            'Enter the quantity you are adding and tap Add',
            detail: 'The quantity is added to the existing stock level.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.note,
          'Stock is reduced automatically every time you complete a sale, and '
          'increased again when you record a return.',
        ),
      ],
    ),

    // ═══════════════ MONEY & REPORTS ═══════════════
    ManualGuide(
      id: 'sales-history',
      title: 'Finding Past Sales',
      summary: 'Search sales and filter them by date.',
      category: ManualCategory.money,
      icon: Icons.receipt_long_outlined,
      keywords: ['sales', 'history', 'invoice', 'search', 'filter', 'date'],
      relatedIds: ['returns', 'reports', 'make-a-sale'],
      blocks: [
        const ManualParagraph(
          'Every completed sale is kept in the Sales tab, so you can look up '
          'any transaction later.',
        ),
        const ManualSteps([
          ManualStep('Open the Sales tab'),
          ManualStep(
            'Search for a sale',
            detail:
                'Search by invoice number, customer name or item name — for '
                'example "Search by invoice no, customer or item...".',
          ),
          ManualStep(
            'Narrow the list by date',
            detail:
                'Use the date filter chips to jump to today, this week, this '
                'month, or choose "Custom" and pick an exact date range.',
          ),
          ManualStep(
            'Tap any sale to see its invoice',
            detail:
                'The invoice shows the items, prices, discount, tax and total '
                'as they were at the time of sale.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Looking for a refund? Open the sale and record a return from there — '
          'see the Returns & Refunds guide.',
        ),
        const ManualCallout(
          ManualCalloutKind.note,
          'Each result shows the date and the profit that sale made. A sale '
          'that lost money shows the amount in red instead, a fully refunded '
          'sale is marked "Returned" with its total struck through, and a '
          'partly refunded one "Partial return" with the refunded amount '
          'listed beneath it.',
        ),
        const ManualAction('Go to Sales', tabIndex: 3),
      ],
    ),

    ManualGuide(
      id: 'reports',
      title: 'Understanding Reports',
      summary: 'Revenue, profit, top products, categories and inventory.',
      category: ManualCategory.money,
      icon: Icons.insights_outlined,
      keywords: [
        'reports',
        'profit',
        'revenue',
        'margin',
        'chart',
        'top products',
        'analytics',
      ],
      relatedIds: ['expenses', 'sales-history', 'returns'],
      blocks: [
        const ManualParagraph(
          'Reports turn your sales into numbers you can act on. Open them '
          'from the dashboard.',
        ),
        ManualBullets([
          'Summary — headline figures: revenue, profit, net profit, net '
              'margin and average sale value.',
          'Charts — revenue and profit over time, so you can spot slow days '
              'and good weeks.',
          'Top Products — your best sellers by revenue and quantity.',
          'Categories — which categories bring in the most money.',
          'Expenses — what you have spent, broken down by category.',
          'Inventory — the value of the stock you are holding.',
        ]),
        const ManualCallout(
          ManualCalloutKind.note,
          'Profit is calculated as sell price minus purchase price. If you '
          'leave a product\'s purchase price empty, that sale shows as pure '
          'profit — so keep purchase prices up to date.',
        ),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Gross revenue is what customers paid. Net profit subtracts your '
          'cost of goods and your recorded expenses — that is the number to '
          'watch for the health of the shop.',
        ),
        const ManualAction('Open Reports', route: Routes.reports),
      ],
    ),

    ManualGuide(
      id: 'expenses',
      title: 'Recording Expenses',
      summary: 'Log rent, bills and supplies so profit figures are realistic.',
      category: ManualCategory.money,
      icon: Icons.account_balance_wallet_outlined,
      keywords: ['expense', 'cost', 'rent', 'bill', 'spending', 'overhead'],
      relatedIds: ['reports'],
      blocks: [
        const ManualParagraph(
          'Expenses are the day-to-day costs of running your shop that are '
          'not stock purchases — rent, electricity, wages, transport and so '
          'on. Recording them makes your profit figures realistic.',
        ),
        const ManualSteps([
          ManualStep('Open Expenses from the dashboard or the More tab'),
          ManualStep('Tap "Add expense"'),
          ManualStep('Enter the amount'),
          ManualStep('Choose a category'),
          ManualStep(
            'Add a description',
            detail: 'For example "October electricity bill".',
          ),
          ManualStep('Tap Save'),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Record expenses as they happen. A month of expenses entered in one '
          'sitting is easy to forget and hard to check later.',
        ),
        const ManualAction('Open Expenses', route: Routes.expenses),
      ],
    ),

    ManualGuide(
      id: 'customers',
      title: 'Managing Your Customer Book',
      summary: 'Keep customer contact details and purchase history.',
      category: ManualCategory.money,
      icon: Icons.people_outline,
      keywords: ['customer', 'client', 'contact', 'phone', 'directory'],
      relatedIds: ['sale-customer', 'staff'],
      blocks: [
        const ManualParagraph(
          'Your customer book stores names, phone numbers and other contact '
          'details. It is optional — you can sell to walk-in customers '
          'without recording anything.',
        ),
        const ManualSteps([
          ManualStep('Open Customers from the More tab'),
          ManualStep('Tap "Add Customer"'),
          ManualStep(
            'Enter the full name',
            detail: 'This is required — the other fields are optional.',
          ),
          ManualStep('Add their phone number, email and address as needed'),
          ManualStep('Tap Save'),
        ]),
        const ManualSubheading('Editing or removing a customer'),
        ManualSteps([
          ManualStep('Tap the customer in the list'),
          ManualStep(
            'Choose Edit to update their details, or Delete to remove them',
          ),
          ManualStep(
            'Confirm the deletion',
            detail:
                'Past sales that name this customer are not affected — they '
                'keep the details recorded at the time of sale.',
          ),
        ]),
        const ManualAction('Open Customers', route: Routes.customers),
      ],
    ),

    ManualGuide(
      id: 'staff',
      title: 'Staff & Cashier Accounts',
      summary: 'Add cashiers, set roles and track who is on duty.',
      category: ManualCategory.money,
      icon: Icons.groups_outlined,
      keywords: ['staff', 'cashier', 'employee', 'role', 'clock in', 'team'],
      relatedIds: ['pin-lock', 'reports'],
      blocks: [
        const ManualParagraph(
          'Staff accounts let you record who made each sale, and keep track '
          'of who is currently working.',
        ),
        const ManualSteps([
          ManualStep('Open the More tab, then tap "Staff & Cashiers"'),
          ManualStep('Tap "Add Staff"'),
          ManualStep(
            'Enter the full name',
            detail: 'This is the only required field.',
          ),
          ManualStep(
            'Choose their role',
            detail:
                'The role defaults to Cashier. Pick the role that matches '
                'what this person should be able to do.',
          ),
          ManualStep('Add their phone number (optional)'),
          ManualStep('Tap Save'),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'When someone finishes their shift, mark them as clocked out so the '
          'active cashier on the app always matches who is actually at the '
          'counter.',
        ),
        const ManualAction('Open Staff & Cashiers', route: Routes.staff),
      ],
    ),

    // ═══════════════ PRINTING ═══════════════
    ManualGuide(
      id: 'receipt-customization',
      title: 'Customising Your Receipt',
      summary: 'Choose paper size, font, logo and what appears on the receipt.',
      category: ManualCategory.printing,
      icon: Icons.receipt_outlined,
      keywords: [
        'receipt',
        'print',
        'logo',
        'footer',
        'paper',
        '58mm',
        '80mm',
        'font',
      ],
      relatedIds: ['printer-setup', 'shop-information'],
      blocks: [
        const ManualParagraph(
          'The receipt customiser has a live preview, so you can see exactly '
          'what a printed receipt will look like before you print one.',
        ),
        const ManualSteps([
          ManualStep('Open the More tab, then tap "Receipt Customization"'),
          ManualStep(
            'Choose your paper size',
            detail:
                '58mm for the small pocket printers, 80mm for the wider '
                'counter-top models.',
          ),
          ManualStep(
            'Set the font size',
            detail:
                'Small, Normal or Large. Larger text is easier to read but '
                'uses more paper.',
          ),
          ManualStep('Switch the logo on and choose an image (optional)'),
          ManualStep(
            'Turn individual lines on or off',
            detail:
                'You can show or hide the shop name, address, phone, date, '
                'cashier, customer, SKU, brand, barcode, discount details, '
                'tax details and the footer message.',
          ),
          ManualStep('Check the preview, then leave the screen to save'),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Show the SKU or barcode if you process returns by scanning the '
          'receipt. Hide the footer if you are short on paper. Remember to '
          'enter a receipt footer message under Shop Information first.',
        ),
        const ManualCallout(
          ManualCalloutKind.note,
          'Paper size must match your printer. Printing an 80mm layout on '
          '58mm paper cuts off the right-hand side of every line.',
        ),
      ],
    ),

    ManualGuide(
      id: 'printer-setup',
      title: 'Pairing a Thermal Printer',
      summary: 'Connect a Bluetooth receipt printer and run a test print.',
      category: ManualCategory.printing,
      icon: Icons.print_outlined,
      keywords: [
        'printer',
        'bluetooth',
        'pair',
        'thermal',
        'connect',
        'test print',
      ],
      relatedIds: ['receipt-customization', 'make-a-sale'],
      blocks: [
        const ManualParagraph(
          'Codynest POS prints to Bluetooth thermal receipt printers. Pair the '
          'printer once and it stays connected for future receipts.',
        ),
        const ManualSubheading('Before you start'),
        ManualSteps([
          ManualStep('Turn the printer on and load paper'),
          ManualStep(
            'Make sure it is not already connected to another phone',
            detail:
                'If another device is holding the connection, turn that '
                'device\'s Bluetooth off or unpair the printer there first.',
          ),
          ManualStep(
            'Turn the printer\'s Bluetooth pairing mode on',
            detail: 'Most printers show a blinking light when ready.',
          ),
        ]),
        const ManualSubheading('Pair it in the app'),
        ManualSteps([
          ManualStep('Open the More tab, then tap "Thermal Printer"'),
          ManualStep(
            'Grant the Bluetooth permissions when asked',
            detail:
                'The app needs permission to scan for nearby devices. If '
                'you tapped Deny, allow Bluetooth access for Codynest POS '
                'in your phone\'s settings and try again.',
          ),
          ManualStep('Tap "Scan for Printers"'),
          ManualStep(
            'Tap your printer in the list to pair it',
            detail:
                'The app shows the printer as "Paired Printer" with its MAC '
                'address once connected.',
          ),
          ManualStep(
            'Tap "Test Print"',
            detail:
                'A test receipt goes to the printer. If it prints, you are '
                'ready to go.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'If the printer does not appear, keep it within a metre of the phone '
          'and scan again. Thermal printers usually only accept one connected '
          'device at a time.',
        ),
        const ManualCallout(
          ManualCalloutKind.note,
          'Receipt paper is thermal — it fades in heat and sunlight. Keep '
          'printed receipts away from direct sun if they need to last.',
        ),
      ],
    ),

    // ═══════════════ DATA & BACKUP ═══════════════
    ManualGuide(
      id: 'backup-export',
      title: 'Backing Up & Exporting Data',
      summary:
          'Save a full backup, or export products, sales and expenses to CSV.',
      category: ManualCategory.data,
      icon: Icons.file_download_outlined,
      keywords: ['backup', 'export', 'csv', 'json', 'save', 'data'],
      relatedIds: ['restore-import', 'auto-backup', 'drive-backup'],
      blocks: [
        const ManualParagraph(
          'Your data is stored only on this device. A backup is your insurance '
          'if the phone is lost, replaced or reset.',
        ),
        const ManualSubheading('Make a full backup'),
        ManualSteps([
          ManualStep('Open the More tab, then tap "Export & Backup"'),
          ManualStep(
            'Tap "Full Backup"',
            detail:
                'This exports everything — products, sales, expenses, '
                'returns, customers, staff, categories and settings — as a '
                'single restorable file.',
          ),
          ManualStep(
            'Choose where to save or share the file',
            detail:
                'Send it to yourself on WhatsApp or email, or save it to '
                'cloud storage. Keep it somewhere other than this phone.',
          ),
        ]),
        const ManualSubheading('Export a spreadsheet'),
        ManualSteps([
          ManualStep(
            'Tap "Export Products", "Export Sales" or "Export Expenses"',
          ),
          ManualStep(
            'Open the CSV in Excel, Google Sheets or any spreadsheet app',
            detail: 'Useful for accounting and for your own analysis.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.warning,
          'A CSV export is for reading and accounting only — it cannot be '
          'restored into the app. Only a Full Backup file can be restored.',
        ),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Take a full backup at least once a week, and always before '
          'updating the app or changing phones.',
        ),
        const ManualAction('Open Backup Settings', tabIndex: 4),
      ],
    ),

    ManualGuide(
      id: 'restore-import',
      title: 'Restoring from a Backup',
      summary: 'Bring your data back from a backup file.',
      category: ManualCategory.data,
      icon: Icons.restore_outlined,
      keywords: ['restore', 'import', 'recover', 'backup file', 'new phone'],
      relatedIds: ['backup-export', 'drive-backup'],
      blocks: [
        const ManualParagraph(
          'Restoring loads a backup file back into the app. This is how you '
          'move your shop to a new phone, or recover after a reset.',
        ),
        const ManualSteps([
          ManualStep(
            'Make sure the backup file is on this phone',
            detail:
                'If you sent it to yourself, download it from WhatsApp, email '
                'or your cloud drive first.',
          ),
          ManualStep('Open the More tab, then tap "Import & Restore"'),
          ManualStep('Tap "Restore from Backup" and pick the backup file'),
          ManualStep(
            'Review the summary of what the backup contains',
            detail:
                'Check the counts and the date before you continue, so you '
                'know exactly what you are restoring.',
          ),
          ManualStep('Confirm the restore'),
        ]),
        const ManualCallout(
          ManualCalloutKind.warning,
          'Restoring replaces ALL current data in the app. If you have sales '
          'recorded since your last backup, take a fresh backup first — once '
          'the restore runs, the current data is gone.',
        ),
        const ManualCallout(
          ManualCalloutKind.note,
          'Restoring needs the Full Backup file that the app created. A CSV '
          'export from the same screen will not work here.',
        ),
      ],
    ),

    ManualGuide(
      id: 'auto-backup',
      title: 'Auto Backup',
      summary: 'Schedule daily or weekly backups automatically.',
      category: ManualCategory.data,
      icon: Icons.schedule_outlined,
      keywords: [
        'auto',
        'automatic',
        'schedule',
        'daily',
        'weekly',
        'reminder',
      ],
      relatedIds: ['backup-export', 'drive-backup'],
      blocks: [
        const ManualParagraph(
          'Auto backup saves a copy on a schedule you choose, so protecting '
          'your data does not depend on remembering to do it.',
        ),
        const ManualSteps([
          ManualStep('Open the More tab, then tap "Auto Backup"'),
          ManualStep('Switch auto backup on'),
          ManualStep('Choose daily or weekly'),
          ManualStep(
            'Look for the backup shortcut on the dashboard',
            detail:
                'The dashboard shows the current backup status and lets you '
                'run a manual backup whenever you like.',
          ),
          ManualStep(
            'Check past backups in the backup history',
            detail:
                'The history lists the backups that have been taken, so you '
                'can confirm the schedule is working.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.note,
          'Scheduled backups are saved to this device. For protection against '
          'losing the phone itself, use Google Drive backup as well — or take '
          'a manual backup and move the file off the device.',
        ),
      ],
    ),

    ManualGuide(
      id: 'drive-backup',
      title: 'Google Drive Backup',
      summary: 'Keep an off-device copy of your shop in your own Google Drive.',
      category: ManualCategory.data,
      icon: Icons.cloud_upload_outlined,
      keywords: ['google', 'drive', 'cloud', 'online', 'off-device', 'sync'],
      relatedIds: ['backup-export', 'restore-import'],
      blocks: [
        const ManualParagraph(
          'Google Drive backup uploads a backup to your own Google account, '
          'so your data survives a lost, stolen or reset phone. It needs an '
          'internet connection; everything else in the app works offline.',
        ),
        const ManualSteps([
          ManualStep('Open the More tab, then tap "Google Drive Backup"'),
          ManualStep(
            'Sign in with your Google account when prompted',
            detail:
                'You choose which account to use — it is your Drive, not '
                'ours.',
          ),
          ManualStep(
            'Upload a backup',
            detail:
                'The new backup appears in the Google Drive Backups list with '
                'its date.',
          ),
          ManualStep(
            'Select a backup to Restore it, or Download it to this device',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.note,
          'Backups are stored in your own Google Drive, so they count against '
          'your Google storage quota. Deleting the app does not delete them.',
        ),
        const ManualCallout(
          ManualCalloutKind.tip,
          'On a new phone, sign in with the same Google account, open this '
          'screen and restore your most recent backup to bring your shop '
          'across.',
        ),
        const ManualAction('Open Google Drive Backup', tabIndex: 4),
      ],
    ),

    // ═══════════════ SECURITY & PLAN ═══════════════
    ManualGuide(
      id: 'pin-lock',
      title: 'Locking the App with a PIN',
      summary: 'Require a 4-digit PIN whenever the app opens.',
      category: ManualCategory.security,
      icon: Icons.lock_outline,
      keywords: ['pin', 'lock', 'password', 'security', 'privacy', 'passcode'],
      relatedIds: ['staff', 'license-plans'],
      blocks: [
        const ManualParagraph(
          'A PIN stops anyone who picks up the phone from seeing your sales, '
          'customers and takings. It is worth switching on for any shared '
          'device.',
        ),
        const ManualSteps([
          ManualStep('Open the More tab, then tap "App Security"'),
          ManualStep('Switch on "Enable PIN lock"'),
          ManualStep('Choose a 4-digit PIN you will remember'),
          ManualStep(
            'Confirm the PIN',
            detail: 'The app asks for it the next time it opens.',
          ),
        ]),
        const ManualSubheading('Changing your PIN'),
        ManualSteps([
          ManualStep('Open App Security again and tap "Change PIN"'),
          ManualStep('Enter a new 4-digit PIN and confirm it'),
        ]),
        const ManualCallout(
          ManualCalloutKind.warning,
          'There is no "forgot PIN" reset from inside the app — it is a lock, '
          'not a recoverable password. Write the PIN down somewhere safe, and '
          'contact support if you are locked out.',
        ),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Avoid birthdays and repeated digits like 1111. Anyone who knows '
          'your PIN can see every sale and customer in the app.',
        ),
      ],
    ),

    ManualGuide(
      id: 'license-plans',
      title: 'License, Trial & Plans',
      summary: 'What each plan includes, and how to activate a license key.',
      category: ManualCategory.security,
      icon: Icons.workspace_premium_outlined,
      keywords: [
        'license',
        'licence',
        'plan',
        'trial',
        'premium',
        'free',
        'activate',
        'key',
        'upgrade',
        'subscription',
      ],
      relatedIds: ['pin-lock', 'getting-started'],
      blocks: [
        const ManualParagraph(
          'Codynest POS can be used on a free plan, a time-limited free trial, '
          'or a paid license. You choose on first launch and can change it '
          'later.',
        ),
        ManualBullets([
          'Free trial — full access for a limited number of days, so you can '
              'try everything before paying.',
          'Free plan — no time limit, but a cap on how many products you can '
              'add.',
          'Licensed plans — Monthly, Yearly or Lifetime, with the product cap '
              'removed.',
        ]),
        const ManualSubheading('Activating a license'),
        ManualSteps([
          ManualStep(
            'Open the More tab, then tap "App Security" and the plan row',
            detail: 'Or open the License & Plans screen directly.',
          ),
          ManualStep('Tap "Activate License"'),
          ManualStep(
            'Enter the license key you received and confirm',
            detail:
                'Activation checks the key online — you need an internet '
                'connection for this one step.',
          ),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Your plan and remaining days are shown on the App Security screen '
          'in the More tab, so you always know where you stand.',
        ),
        const ManualAction('Open License & Plans', route: Routes.license),
      ],
    ),

    // ═══════════════ SUPPORT ═══════════════
    ManualGuide(
      id: 'troubleshooting',
      title: 'Troubleshooting Common Issues',
      summary: 'Fixes for the problems users run into most often.',
      category: ManualCategory.support,
      icon: Icons.build_outlined,
      keywords: [
        'problem',
        'issue',
        'error',
        'not working',
        'fix',
        'stuck',
        'crash',
        'help',
      ],
      relatedIds: ['printer-setup', 'restore-import', 'contact-support'],
      blocks: [
        const ManualFaq([
          ManualFaqItem(
            'The printer will not connect or nothing prints',
            'Keep the printer within a metre of the phone and make sure it is '
                'switched on with paper loaded. Check that no other phone is '
                'connected to it — a thermal printer usually accepts only one '
                'device. Then re-open Thermal Printer in the More tab and scan '
                'again.',
          ),
          ManualFaqItem(
            'The scanner does not read anything',
            'Grant camera permission to Codynest POS in your phone\'s '
                'settings and reopen the scanner. Make sure the product actually '
                'has a barcode saved, and clean the camera lens. Very dim light '
                'or a scratched, crumpled barcode can also stop it reading — use '
                'the flash or type the code in manually.',
          ),
          ManualFaqItem(
            'A product or sale is missing',
            'Check the search and date filters first — a filter left on from '
                'earlier hides data that is still there. If it has genuinely '
                'disappeared, you may have restored an older backup: restoring '
                'replaces everything with the state of that backup file.',
          ),
          ManualFaqItem(
            'My profit numbers look too high',
            'This almost always means products have no purchase price '
                'recorded. Add the purchase price to each product so the app can '
                'subtract your cost of goods from revenue.',
          ),
          ManualFaqItem(
            'The app is asking for a PIN I do not know',
            'The PIN is not recoverable from inside the app. Contact support '
                'using the details in the next guide.',
          ),
          ManualFaqItem(
            'I cannot add more products',
            'You have probably reached your plan\'s product allowance. The '
                'Products title shows your usage, for example "Products (50/50)". '
                'Activate a license to remove the cap.',
          ),
        ]),
      ],
    ),

    ManualGuide(
      id: 'contact-support',
      title: 'Getting Help from Support',
      summary: 'Reach the team on WhatsApp or by phone.',
      category: ManualCategory.support,
      icon: Icons.support_agent_outlined,
      keywords: ['support', 'contact', 'whatsapp', 'phone', 'help', 'team'],
      relatedIds: ['troubleshooting', 'backup-export'],
      blocks: [
        const ManualParagraph(
          'If this manual does not solve your problem, the support team can '
          'help directly on WhatsApp or by phone.',
        ),
        const ManualBullets(['0315-3507075', '0345-3333316']),
        const ManualSteps([
          ManualStep('Open the More tab and scroll to "Support & WhatsApp"'),
          ManualStep('Tap it to start a WhatsApp chat with the support team'),
        ]),
        const ManualCallout(
          ManualCalloutKind.tip,
          'Messages get answered faster when you include your shop name, what '
          'you were doing, and what you saw on screen. A screenshot helps a '
          'lot.',
        ),
        const ManualCallout(
          ManualCalloutKind.warning,
          'Before contacting support about missing data, do not restore any '
          'backup — a restore overwrites the current data and can remove the '
          'evidence needed to recover it.',
        ),
      ],
    ),
  ];

  // ────────────────────────────────────────────────────────────
  //  Lookup helpers
  // ────────────────────────────────────────────────────────────

  /// Returns the guide with [id], or `null` if there is no such guide.
  static ManualGuide? byId(String id) {
    for (final guide in all) {
      if (guide.id == id) return guide;
    }
    return null;
  }

  /// Guides in [category], in the order they are declared above.
  static List<ManualGuide> inCategory(ManualCategory category) {
    return all.where((g) => g.category == category).toList();
  }

  /// The guides featured on the hub, in [quickStartIds] order.
  static List<ManualGuide> quickStart() {
    final featured = <ManualGuide>[];
    for (final id in quickStartIds) {
      final guide = byId(id);
      if (guide != null) featured.add(guide);
    }
    return featured;
  }

  /// Resolves [ManualGuide.relatedIds] into guides, skipping unknown ids.
  static List<ManualGuide> related(ManualGuide guide) {
    final result = <ManualGuide>[];
    for (final id in guide.relatedIds) {
      final related = byId(id);
      if (related != null) result.add(related);
    }
    return result;
  }

  /// How many guides exist per category.
  static int countIn(ManualCategory category) => inCategory(category).length;

  /// Case-insensitive search across titles, summaries, keywords and
  /// category names. Results are ranked: title matches first, then
  /// keyword matches, then summary/body matches.
  static List<ManualGuide> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;

    final titleHits = <ManualGuide>[];
    final keywordHits = <ManualGuide>[];
    final bodyHits = <ManualGuide>[];

    for (final guide in all) {
      if (guide.title.toLowerCase().contains(q)) {
        titleHits.add(guide);
        continue;
      }
      final inKeywords = guide.keywords.any((k) => k.toLowerCase().contains(q));
      if (inKeywords) {
        keywordHits.add(guide);
        continue;
      }
      final inSummary =
          guide.summary.toLowerCase().contains(q) ||
          guide.category.label.toLowerCase().contains(q);
      if (inSummary) {
        bodyHits.add(guide);
        continue;
      }
      // Last resort: match anywhere in the guide body, so searching
      // "restore" still finds the backup guide even if the word only
      // appears inside a step.
      if (_bodyContains(guide, q)) bodyHits.add(guide);
    }

    return [...titleHits, ...keywordHits, ...bodyHits];
  }

  /// True when any block in [guide] contains [q] (already lower-cased).
  static bool _bodyContains(ManualGuide guide, String q) {
    for (final block in guide.blocks) {
      switch (block) {
        case ManualParagraph p:
          if (p.text.toLowerCase().contains(q)) return true;
        case ManualSteps s:
          for (final step in s.steps) {
            if (step.title.toLowerCase().contains(q)) return true;
            if (step.detail?.toLowerCase().contains(q) ?? false) return true;
          }
        case ManualSubheading h:
          if (h.text.toLowerCase().contains(q)) return true;
        case ManualCallout c:
          if (c.text.toLowerCase().contains(q)) return true;
        case ManualBullets b:
          if (b.items.any((i) => i.toLowerCase().contains(q))) return true;
        case ManualFaq f:
          for (final item in f.items) {
            if (item.question.toLowerCase().contains(q)) return true;
            if (item.answer.toLowerCase().contains(q)) return true;
          }
        case ManualAction a:
          if (a.label.toLowerCase().contains(q)) return true;
      }
    }
    return false;
  }
}
