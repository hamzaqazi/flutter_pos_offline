# In-App User Manual

The app ships a complete user manual inside the binary. It is **content-driven**:
screens are generic, and every guide is plain data. Adding documentation is a
content change — no UI code is touched.

## Files

| File | Purpose |
|------|---------|
| `lib/modules/manual/manual_model.dart` | Content model — `ManualGuide`, `ManualCategory`, and the sealed `ManualBlock` types. |
| `lib/modules/manual/manual_content.dart` | **The guides.** Single source of truth. |
| `lib/modules/manual/manual_home_page.dart` | Hub — search, quick start, recently viewed, guides grouped by topic. |
| `lib/modules/manual/manual_article_page.dart` | Generic renderer for any single guide. |
| `lib/modules/manual/manual_controller.dart` | Search text, category filter, recently-viewed list. |
| `lib/modules/manual/manual_nav.dart` | Opens the hub / a guide, and runs a guide's action button. |

## Adding a guide

Append one `ManualGuide` to `ManualGuides.all` in `manual_content.dart`:

```dart
ManualGuide(
  id: 'my-guide',                    // stable; also the deep-link id
  title: 'My Guide',
  summary: 'One line, shown on cards and in search results.',
  category: ManualCategory.inventory,
  icon: Icons.inventory_2_outlined,
  keywords: ['extra', 'search', 'terms'],   // words not in the title/summary
  relatedIds: ['add-product'],              // shown as "Related guides"
  blocks: [
    const ManualParagraph('Intro text.'),
    const ManualSteps([
      ManualStep('Tap the thing', detail: 'Use the exact label the app shows.'),
    ]),
    const ManualCallout(ManualCalloutKind.tip, 'A helpful tip.'),
    const ManualAction('Go to Products', tabIndex: 1),
  ],
)
```

That is the whole change — the hub picks it up automatically, search indexes it,
and it is reachable at `/manual/article?id=my-guide`.

To feature it on the hub's quick-start row, add its id to
`ManualGuides.quickStartIds`.

## Block types

| Block | Renders as |
|-------|------------|
| `ManualParagraph(text)` | Body paragraph. |
| `ManualSteps([ManualStep(...)], title: ...)` | Numbered step list; each step has an optional `detail`. |
| `ManualCallout(kind, text)` | Highlighted box — `tip` (green), `note` (blue) or `warning` (amber). |
| `ManualBullets([...])` | Bulleted list. |
| `ManualFaq([ManualFaqItem(q, a)])` | Collapsible question & answer card. |
| `ManualAction(label, tabIndex: n)` | Button that switches a bottom-nav tab (0 Home, 1 Products, 2 Cart, 3 Sales, 4 More). |
| `ManualAction(label, route: Routes.x)` | Button that pushes a named route. |

`ManualAction` is what makes these guides a manual rather than help articles —
a guide can drop the user straight into the screen it describes.

## Entry points

- **More tab → Help & Guides → User Manual** — the hub.
- **Help icon in the app bar** — for screens where the bar has room. Set
  `helpTopicId: '<guide id>'` on `AppShellAppBar`. Currently enabled on
  Dashboard, Sales History and Settings. Products and Cart deliberately omit it
  (their app bars already carry scanner/cart/Hold/Clear actions).
- **Empty states** — e.g. the Products empty state links to `add-product`, so a
  first-time user is never left at a dead end.

## Deep-linking

From anywhere in the app:

```dart
ManualNav.openHub();                  // the hub
ManualNav.openGuide('make-a-sale');   // one guide
```

or declaratively on a route:

```dart
Get.toNamed(Routes.manualArticle, parameters: {'id': 'make-a-sale'});
```

## House rules when writing content

1. **Use the app's real labels** — "Add product", "Checkout", "Full Backup".
   Users follow the words on screen, so a paraphrase breaks the instructions.
2. **Steps are imperative and short**; put explanation in `detail`.
3. **End with a `ManualAction`** where there is a screen to jump to.
4. **Warn about destructive actions** with `ManualCalloutKind.warning` —
   restoring a backup and deleting a product are the two that bite users.
5. Bump `ManualGuides.version` when the manual changes materially, so support
   can tell whether a user is reading current instructions.
