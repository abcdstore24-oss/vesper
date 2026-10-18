# COMPONENTS.md — Reusable Component Registry

This file lists reusable widgets/classes in `lib/shared/widgets/` (and
any other cross-feature reusable code) as they're built, so future
sessions reuse instead of duplicating them.

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

### ensureBaselineData / baselineSeeders
- File: lib/core/db/db_bootstrap.dart
- Used by: main.dart (startup)
- Purpose: one startup step guaranteeing the local user row and all default
  seed data exist; later modules register a seeder in `baselineSeeders`.
- Notes: seeders must be idempotent and must not open their own transaction.
  Default categories include six system rows (see DATABASE.md).

### localUserIdProvider
- File: lib/core/db/local_user_provider.dart
- Used by: every user-scoped Finance provider
- Purpose: returns the device-local user id (ensureLocalUser), idempotent
- Notes: always await this before building a user-scoped stream.

### AccountsDao
- File: lib/features/finance/data/accounts_dao.dart
- Used by: accounts providers/screens
- Purpose: insert/update/read accounts with name + balance validation
- Notes: no delete/archive until Task 4d. Name rules live here, not in the UI.

### accountsWithBalanceProvider / totalBalanceProvider
- File: lib/features/finance/presentation/providers/accounts_providers.dart
- Used by: Finance screens, Dashboard
- Purpose: live account list with balances; total of non-archived accounts

### makeInMemoryContainer / pumpUntil
- File: test/support/test_db.dart
- Used by: provider tests
- Purpose: Riverpod container on an empty in-memory database

### totalBalancePaise / totalBalanceProvider  (UPDATED)
- Files: lib/features/finance/data/account_balance.dart,
  lib/features/finance/presentation/providers/accounts_providers.dart
- Purpose: Total Balance in paise = non-archived accounts of type cash,
  bank, wallet, other. Credit cards and archived accounts are excluded.
  Empty -> 0.

### creditCardDuesPaise / creditCardDuesProvider  (UPDATED)
- Files: lib/features/finance/data/account_balance.dart,
  lib/features/finance/presentation/providers/accounts_providers.dart
- Purpose: card dues in paise = sum over non-archived credit-card accounts
  of max(0, -balance). What is owed; never negative; never netted across
  cards (an overpaid card adds nothing and does not offset another card's
  debt). Shown separately from Total Balance. Empty -> 0. May exceed
  Money.maxPaise (exact sum; UI handles display).

### AmountText  (shared/widgets/amount_text.dart)
- AmountText(paise, {style, tone: neutral|positive|negative, alignment}).
  Money.format only; one line in FittedBox(scaleDown); never ellipsis or
  rounding. "Amount too large" if |paise| > Money.maxPaise. Success/danger
  come from AppColors by brightness. Use for EVERY money amount on screen.

### BalanceSummary  (features/finance/presentation/widgets/balance_summary.dart)
- Total balance (+ Card dues when an active credit card exists) from
  totalBalanceProvider / creditCardDuesProvider. Loading = spinner (never a
  fake 0); error = message + Retry. One full-width card, or two equal-width,
  equal-height cards. Used by Finance home AND Accounts screen.

### account_display helpers  (features/finance/presentation/account_display.dart)
- accountTypeIcon, accountTypeLabel, accountBalanceDisplay(type, balance) ->
  (paise, tone, caption). Cards: owed shows positive + "due"; overpaid
  "credit". Pure functions, no BuildContext.

### AccountFormSheet / showAccountFormSheet  (…/widgets/account_form_sheet.dart)
- Add/edit account modal sheet. Saves through AccountsDao; the list updates
  via the existing stream. Card amount is typed as "owed" and stored negative.

### FinanceHomeScreen, AccountsScreen  (features/finance/presentation/)
- Finance tab and the accounts list; the Accounts list has 96px bottom
  padding so the FAB never covers the last row.

### UI test helpers  (test/support/ui_test_helpers.dart)
- pumpUi, settle, DbHarness, makeAccount / makeAccountRow, accountsOverride,
  disableFontFetching. Reuse them for every widget test.
- Notes: DbHarness.dispose(tester) must be the LAST line of a DB-backed widget
  test (it flushes Drift's cleanup timer). Layout tests should override
  accountsWithBalanceProvider instead of using a real database.

### Money
- File: lib/core/utils/money.dart
- Used by: all Finance code (and Wishlist/Dashboard where amounts appear)
- Purpose: the only place money is parsed/displayed. Static format(int paise)
  and parse(String) -> int? paise; Indian grouping, always 2 decimals.
- Notes: never store/compute money as double/num; never round or trim;
  >2 decimals is rejected. If the whole-number part of parse() input contains
  any comma, it must be valid Western (1,250  100,000  1,234,567) or Indian
  (1,250  12,34,567  1,00,00,000) grouping, otherwise null; commas after the
  dot, trailing or doubled commas are rejected. format() always emits valid
  Indian grouping. Rupee symbol lives in Money.rupeeSymbol only.

  ### TransactionsDao  (features/finance/data/transactions_dao.dart)
- insert / update / delete / getById. Validates, writes and checks balance
  range in ONE database transaction; throws
  TransactionValidationException(error). TransactionsDao(db, {clock}).
  bySource: true (update/delete) is for loans/investments code only.

### computeBalancePaise  (UPDATED)
- File: lib/features/finance/data/account_balance.dart
- The ONE place the balance formula lives: starting + income − expense +
  transfersIn − transfersOut (named params, default 0).

### selectAccountsWithBalance  (features/finance/data/balance_queries.dart)
- One SQL query: accounts + per-account transaction sums; reads accounts AND
  transactions so .watch() re-emits on either. Used by
  AccountsDao.watchAccountsWithBalance and TransactionsDao's range check.