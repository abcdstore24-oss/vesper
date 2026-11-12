# TODO.md — Build Checklist

Nothing has been built yet. This is the true starting point. Check items
off as they're completed; when an AI session finishes a task, it should
tell you what to check off rather than editing this file directly (see
HANDOFF.md).

---

## Phase 1 — Foundation (complete)
- [x] Design tokens: color palette (light/dark) + typography set up as
      code (per CLAUDE.md Section 3)
- [x] ThemeData (light/dark) + theme toggle, persisted
- [x] Local encrypted database connection (Drift + SQLCipher) wired up,
      with `user_profile` and `remote_status_cache` tables
- [x] Navigation shell (bottom nav / drawer — module entry points)
- [x] Dashboard shell (static layout, no real data wired yet)
- [x] App lock: OS biometric/PIN default, custom PIN option, off option
      with one-time warning
- [x] Settings screen scaffold
- [x] Data export (JSON, non-Vault modules) — Settings screen action
- [x] Remote status check (maintenance/kill-switch) with offline-safe
      caching behavior

## Phase 2 — Finance

### Done
- [x] Money foundation — integer paise, Indian formatting, safe parsing (Task 1)
- [x] Categories table + startup bootstrap (local user row + default categories) — 2a
- [x] System categories for loans/investments (kind=system, 6 seeded) — 2b
- [x] Local user id provider + accounts table + DAO + balance stream — 3a
- [x] Credit cards excluded from Total Balance; card dues shown separately,
      never netted across cards — 3a-2, 3a-3
- [x] Finance home, Accounts screen, add/edit account sheet, theme fixes — 3b
- [x] Comma safety in Money.parse, edit type-switch fix, captions — 3b-2
- [x] Transactions: table + DAO + balances that move (transfers = one row) — 4a
- [x] Add transaction (expense/income/transfer) + Recent transactions on the
      Finance home — 4b-1
- [x] Scalable category/account pickers, recent categories, cleaner
      transaction row — 4b-1b
- [x] Widget-test infrastructure: narrow google_fonts filter, stable DB tests
- [x] Full transactions list: See all, lazy date-grouped list, type filter chips — 4b-2a
- [x] Edit a transaction + locked rows (tappable on Recent and the full list) — 4b-2b
- [x] Delete a transaction (confirm with per-account balance change, edit sheet only) — 4b-2c
- [x] Fonts: bundle Fraunces + Karla as app assets (offline-first).
- [x] Test font filter retired (fonts are bundled; a missing font variant now fails tests).
- [x] Manage categories: add your own, rename/restyle (name, icon, colour), archive/restore; 
      built-ins editable, nothing deleted.
- [x] **4d** Account archive / restore / delete (delete only with no transactions; 
      archive only at a zero balance).

### Next up, in this order
- [ ] **Monthly summary** Income / expense / saved for a chosen month with a
      month switcher; counts only transactions WITHOUT a source (no loan or
      investment rows); transfers are not income or expense.
- [ ] **Loans & IOUs** L1: `loans` + `loan_payments` tables, DAO, rules (given /
      taken, add payment or repayment, optional linked transaction with account
      deduction, remaining always computed, no interest). L2: Loans screen
      (you'll receive / you owe totals, excluded from Total Balance). L3: wire
      linked transactions (source = loan, system categories) and lock them.
- [ ] **Recurring** `recurring_rules` table; monthly clamps to the month's last
      day (31st becomes 28/29/30); daily / weekly / monthly / yearly / every N
      days-weeks-months; catch-up on app open; each run created once; created
      transactions count normally in summaries.
- [ ] **Budgets** Monthly limit per expense category; progress shown against
      real spending (no sourced rows).
- [ ] **Investments** Investments + trade history (buy: quantity, price, account
      paid from; sell: sale amount typed by the owner, account received in).
      Holdings, cost basis and realized gain are computed. Total investments
      shown separately from Total Balance.
- [ ] **Analytics** fl_chart: spending by category (category colours are the
      one allowed multi-colour exception), income vs expense over months.
- [ ] **Dashboard card** Financial summary card wired to real data.
- [ ] **Optional money view** Selectable, animated view that can include
      account balances / investments / money owed to me / money I owe / card
      dues. Supersedes "no net worth" in DECISIONS.md when built; every part is
      always shown so the total is explainable. After Loans + Investments.

### Also needed (not Finance)
- [ ] **Profile editor** Settings: display name + birthdate (updates the single
      user_profile row). The dashboard's age / days-to-birthday signature
      feature can't show anything until this exists.
- [ ] **Release-mode check** Judge speed with `flutter run --release` (debug
      builds are much slower).

## Phase 3 — Vault / Notes / Documents
- [ ] Vault setup flow, including recovery phrase generation/display
      (Option A, per DECISIONS.md) and its one-time warning UX
- [ ] Vault CRUD (credentials, private notes, document references) —
      client-side encryption before any write
- [ ] Notes: quick/long notes, folders, tags, search
- [ ] Vault excluded from data export — verify explicitly

## Phase 4 — Goals / Tasks / Birthdays / Reminders
- [ ] Goal tracking (short/long-term, deadlines, progress)
- [ ] Task management (to-dos, recurring, priorities)
- [ ] Birthday & event manager, calendar view
- [ ] Reminders (local notifications) across Goals/Tasks/Events
- [ ] Dashboard: today's tasks, upcoming birthdays, goal progress cards

## Phase 5 — Recipes / Beauty / Health / Wishlist
- [ ] Recipe manager (recipes, ingredients, instructions, tags)
- [ ] Beauty care (routines, product notes)
- [ ] Healthy lifestyle (habit tracking, exercise/nutrition notes)
- [ ] Purchase planner / wishlist (items, priority, savings progress)
- [ ] Dashboard: habit tracking + wishlist highlights cards

## Phase 6 — AI (optional)
- [ ] Supabase Edge Function scaffold (server-side API key only)
- [ ] Smart expense categorization
- [ ] Productivity insights
- [ ] Smart reminders
- [ ] Personalized recommendations

## Phase 7 — iOS
- [ ] Apple Developer account set up
- [ ] iOS-specific platform checks (permissions, secure storage, push)
- [ ] TestFlight build
- [ ] App Store submission

## Not started (decide later)
- Multi-device sync (Supabase Auth + PowerSync + RLS per table): only the
  remote status check (app_status) exists today.
- Push notifications (Firebase Cloud Messaging).
