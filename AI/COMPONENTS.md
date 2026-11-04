# COMPONENTS.md — Reusable Component Registry

This file lists reusable widgets/classes (in `lib/shared/widgets/` and any other
cross-feature reusable code) as they're built, so future sessions reuse instead
of duplicating them. One entry per item: when something changes, EDIT its entry
here; do not add a second "(UPDATED)" copy.

Entry format:

```
### WidgetOrClassName
- File: path/to/file.dart
- Used by: (features/screens that use it)
- Purpose: one-line description
- Notes: anything a future session should know before modifying it
```

---

## Shared widgets and utilities

### DashboardCard
- File: lib/shared/widgets/dashboard_card.dart
- Used by: dashboard_screen.dart (all 7 Dashboard cards), Accounts empty state,
  Recent transactions empty state
- Purpose: icon + title + body-slot card shell; DashboardCard.emptyState(icon,
  title, message) covers the common icon+title+one-line-copy case
- Notes: styling comes entirely from ThemeData.cardTheme: don't re-specify
  AppRadius.card or surface colors. The greeting card's populated state also
  reuses .emptyState for layout convenience: harmless, just the name.

### AmountText
- File: lib/shared/widgets/amount_text.dart
- Purpose: AmountText(paise, {style, tone: neutral|positive|negative,
  alignment}). Money.format only; ONE line in FittedBox(scaleDown); never
  ellipsis or rounding. Shows "Amount too large" if |paise| > Money.maxPaise.
  Success/danger come from AppColors by brightness.
- Notes: use for EVERY money amount on screen.

### PickerSheet / showPickerSheet
- File: lib/shared/widgets/picker_sheet.dart
- Purpose: showPickerSheet<T>(context, {title, items: List<PickerItem<T>>,
  selected, searchThreshold = 8}) -> T? (null if dismissed). PickerItem(value,
  title, subtitle?, icon?). Lazy fixed-height rows, "Search" box only above the
  threshold (case-insensitive "contains"), a check on the selected row,
  "No matches".
- Notes: use for any long list (categories, accounts, later people, etc.).

### Money
- File: lib/core/utils/money.dart
- Used by: all Finance code (and Wishlist/Dashboard where amounts appear)
- Purpose: the only place money is parsed/displayed. Static format(int paise)
  and parse(String) -> int? paise; Indian grouping, always 2 decimals.
- Notes: never store/compute money as double/num; never round or trim; more
  than 2 decimals is rejected. If the whole-number part of parse() input
  contains any comma it must be valid Western (1,250  100,000  1,234,567) or
  Indian (1,250  12,34,567  1,00,00,000) grouping, otherwise null; commas
  after the dot, trailing or doubled commas are rejected. format() always emits
  valid Indian grouping. Rupee symbol lives in Money.rupeeSymbol only. Amounts
  are capped at Money.maxPaise (10^14 paise).

### AppDates
- File: lib/core/utils/app_dates.dart
- Purpose: format(date, {now}) -> Today / Yesterday / "5 Oct" / "5 Oct 2025"
  (hand-written month names, no intl). occurredAtFor(pickedDate, now) -> now
  for today, otherwise 12:00 local.

## Startup and database plumbing

### ensureBaselineData / baselineSeeders
- File: lib/core/db/db_bootstrap.dart
- Used by: main.dart (startup)
- Purpose: one startup step guaranteeing the local user row and all default
  seed data exist; later modules register a seeder in `baselineSeeders`.
- Notes: seeders must be idempotent and must not open their own transaction.
  Default categories include six `system` rows (see DATABASE.md).

### localUserIdProvider
- File: lib/core/db/local_user_provider.dart
- Used by: every user-scoped Finance provider
- Purpose: returns the device-local user id (ensureLocalUser), idempotent.
- Notes: always await this before building a user-scoped stream.

## Finance data layer (lib/features/finance/data/)

### AccountsDao
- File: accounts_dao.dart
- Purpose: insert/update/read accounts with name + balance validation.
  watchAccountsWithBalance(userId) streams accounts with computed balances.
- Notes: no delete/archive until Task 4d. Name rules live here, not in the UI.

### TransactionsDao
- File: transactions_dao.dart
- Purpose: insert / update / delete / getById / watchRecent. Validates, writes
  and checks the balance range in ONE database transaction; throws
  TransactionValidationException(error). TransactionsDao(db, {clock}).
- Notes: bySource: true (update/delete) is for loans/investments code only;
  rows with a source are otherwise locked (linkedToSource). No dates after the
  end of today.

### CategoriesDao
- File: categories_dao.dart
- Purpose: watchByKind, getById, getBySeedKey, getAll, insert.
- Notes: deliberately NO update/delete (built-ins can be renamed/archived but
  never deleted); a source-guard test enforces it.

### computeBalancePaise / totalBalancePaise / creditCardDuesPaise
- File: account_balance.dart
- Purpose: computeBalancePaise is the ONE place the balance formula lives:
  starting + income − expense + transfersIn − transfersOut (named params,
  default 0). totalBalancePaise = non-archived cash/bank/wallet/other accounts
  (credit cards and archived excluded). creditCardDuesPaise = sum over
  non-archived cards of max(0, −balance): never netted across cards, may exceed
  Money.maxPaise (exact sum; the UI handles display).
- Notes: nothing else may compute a balance.

### selectAccountsWithBalance
- File: balance_queries.dart
- Purpose: one SQL query: accounts + per-account transaction sums; reads
  accounts AND transactions so .watch() re-emits on either. Used by
  AccountsDao.watchAccountsWithBalance and TransactionsDao's range check.

### selectRecentTransactions / TransactionListItem
- File: transaction_queries.dart
- Purpose: joined rows (category name/icon, account names) for the newest
  transactions: order occurred_at, created_at, rowid (all descending).

### selectRecentCategories
- File: category_queries.dart
- Purpose: up to 5 most recently USED active categories of a kind (distinct;
  no sourced rows, no transfers; system kind never matches). Kept out of
  CategoriesDao on purpose.

## Providers (lib/features/finance/presentation/providers/)

### accountsWithBalanceProvider / totalBalanceProvider / creditCardDuesProvider
- File: accounts_providers.dart
- Purpose: live account list with balances (balances include transactions);
  Total Balance; card dues.

### recentTransactionsProvider, categoriesByKindProvider (family),
### recentCategoriesProvider (family), activeAccountsProvider
- File: transactions_providers.dart
- Purpose: the 5 newest transactions; active categories of a kind; the 5
  recently used categories of a kind; non-archived accounts.
- Notes: all user-scoped streams await localUserIdProvider first.

## Finance UI (lib/features/finance/presentation/)

### FinanceHomeScreen, AccountsScreen
- Purpose: Finance tab (balance cards, Recent transactions, Manage, add FAB)
  and the accounts list. Both lists have 96px bottom padding so the FAB never
  covers the last row. The Finance FAB uses heroTag: null.

### BalanceSummary
- File: widgets/balance_summary.dart
- Purpose: Total balance (+ Card dues when an active credit card exists).
  Loading = spinner (never a fake 0); error = message + Retry. One full-width
  card, or two equal-width, equal-height cards. Used by Finance home AND
  Accounts screen.

### account_display helpers
- File: account_display.dart
- Purpose: accountTypeIcon, accountTypeLabel, accountBalanceDisplay(type,
  balance) -> (paise, tone, caption). Cards: owed shows positive + "due";
  overpaid "credit". Pure functions.

### AccountFormSheet / showAccountFormSheet
- File: widgets/account_form_sheet.dart
- Purpose: add/edit account modal sheet. Card amount is typed as "owed" and
  stored negative. Switching card/non-card re-renders an untouched amount from
  the stored balance (never flips a sign silently).

### TransactionFormSheet / showTransactionFormSheet
- File: widgets/transaction_form_sheet.dart
- Purpose: add expense/income/transfer. Category = ONE picker field plus up to 5
  "Recent" one-tap chips; accounts are chips up to accountChipsMax (4 active
  accounts) and picker fields beyond (From and To together). Saves through
  TransactionsDao.insert; the Finance home updates through its streams.

### TransactionTile
- File: widgets/transaction_tile.dart
- Purpose: one descriptive row: icon circle, title, subtitle, and a right column
  with the amount and the date under it. Not tappable yet. Named TransactionTile
  because TransactionRow is Drift's data class.

### RecentTransactions
- File: widgets/recent_transactions.dart
- Purpose: "Recent transactions" section: up to 5 tiles in one Card; empty =
  DashboardCard; loading = spinner card; error = message + Retry.

### transaction_display
- File: transaction_display.dart
- Purpose: transactionDisplay(item, {now}) -> title, subtitle, dateLabel, signed
  paise, tone, icon. The date is NOT part of the subtitle.

### category_display
- File: category_display.dart
- Purpose: categoryIcon(String? key) -> Phosphor icon for a category icon KEY;
  unknown or null falls back to categoryFallbackIcon (tag).
- Notes: add new icon keys to its map.

## Test support (test/support/)

### UI test helpers
- File: ui_test_helpers.dart
- Purpose: disableFontFetching, buildTestTheme / runIgnoringMissingFonts /
  isMissingFontError (the narrow google_fonts filter), pumpUi, settle,
  settleUntil, tapChip, DbHarness, makeAccount / makeAccountRow,
  accountsOverride, recentTransactionsOverride, makeTransactionItem.
- Notes: build AppTheme only through buildTestTheme, never at file load.
  DbHarness.dispose(tester) must be the LAST line of a DB-backed widget test.
  DB tests that create several accounts must give them distinct created_at
  (whole-second resolution). Providers that load lazily need settle/settleUntil
  after the action that first shows them; wait on a condition, never a fixed
  delay. Layout tests should override providers instead of using a database.

### makeInMemoryContainer / pumpUntil
- File: test_db.dart
- Purpose: Riverpod container on an empty in-memory database; pumpUntil waits
  for a condition.
