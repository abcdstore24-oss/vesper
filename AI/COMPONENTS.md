# COMPONENTS.md — Reusable Component Registry

This file lists reusable widgets/classes in `lib/shared/widgets/` (and
any other cross-feature reusable code) as they're built, so future
sessions reuse instead of duplicating them.

Nothing has been built yet — this registry is empty.

When adding an entry, use this format:

```
### WidgetOrClassName
- File: lib/shared/widgets/path/to/file.dart
- Used by: (features/screens that use it)
- Purpose: one-line description
- Notes: anything a future session should know before modifying it
```

### DashboardCard
- File: lib/shared/widgets/dashboard_card.dart
- Used by: dashboard_screen.dart (all 7 Dashboard cards)
- Purpose: icon + title + body-slot card shell for Dashboard sections;
  DashboardCard.emptyState(icon, title, message) covers the common
  icon+title+one-line-copy case
- Notes: styling comes entirely from ThemeData.cardTheme — don't
  re-specify AppRadius.card or surface colors when using/extending this.
  Note: the greeting card's *populated* state also currently reuses
  .emptyState for layout convenience even though it shows real data —
  harmless, but don't be confused by the name if reading that call site.

### Funding section pattern (duplicated, not shared)
- Files: investment_form_sheet.dart, buy_more_investment_sheet.dart,
  sell_investment_sheet.dart, loan_form_sheet.dart,
  loan_add_more_sheet.dart, loan_repayment_sheet.dart
- Purpose: account + category pickers with a funding toggle.
- Notes: copied into six files. Rule: fundingBlocked starts TRUE and
  clears only when both providers resolve with non-empty data;
  defaults are computed in build(), never via addPostFrameCallback.
  Any change must be applied to all six. Candidate for extraction
  into one shared widget.

### Shared finance helpers (reuse, don't re-implement)
- category_style.dart: CategoryPalette (colorFromHex, darkHexFor),
  CategoryIcons. month_key.dart: month label/step helpers.
  InvestmentType.formatQuantity / preferredFundingCategory.
  LoanDirection.preferredCategoryNameFor.

### Default-category pattern
- To add a default category: add it to defaultCategories, call
  ensureDefaultCategoryExists from categoriesSeedProvider, and
  ref.watch(categoriesSeedProvider) in any screen that lists or picks
  categories (Recurring and Loans missed this once).