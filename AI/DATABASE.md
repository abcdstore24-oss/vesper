# DATABASE.md — Schema Plan (Drift / SQLite, syncs to Postgres via PowerSync)

**Status:** Draft schema, locked structural rules. Exact Drift table
definitions are written when each module is implemented (per TODO.md
phases); this document defines the shape and non-negotiable rules every
table must follow.

## Non-negotiable rules

1. **Every table includes a `user_id` column from day one.** This scopes
   data per user for future Supabase RLS, even though only one user
   exists today and everything works fully offline without an account.
   This is required by the multi-user-ready requirement in CLAUDE.md
   Section 1 — not optional, and not something to defer "until multi-user
   is actually needed."
2. **No global/unscoped tables.** Anything that looks like shared config
   (categories, tags, settings) is still per-`user_id`, not a single
   shared row.
3. Every table has: `id` (UUID, primary key), `user_id` (UUID — the
   device-local user id created by the startup bootstrap, later migrated to
   a real `auth.users.id` if an account is created; Finance tables declare
   it NOT NULL because the bootstrap guarantees it exists; only
   `user_profile` keeps it nullable), `created_at`, `updated_at`.
4. Vault-related fields are marked **[ENCRYPTED]** below — these are
   encrypted client-side before ever touching local storage or sync;
   nothing server-side ever sees plaintext.
5. **All money columns are stored as integer paise** (1 rupee = 100
   paise): `amount`, `starting_balance`, `limit_amount`, `cost_basis`,
   `current_value`, `est_price`, `saved_amount`, and any future money
   field. Never REAL/double. Parse and display only via `Money`
   (lib/core/utils/money.dart).

---

## Finance
- `accounts` (id, user_id NOT NULL, name [trimmed, 1–40 chars, unique per
  user ignoring case — enforced in AccountsDao], type [cash/bank/wallet/
  creditCard/other, stored by name, no CHECK], currency [default 'INR'],
  starting_balance [integer paise, may be negative, |v| <= Money.maxPaise
  enforced in AccountsDao], is_archived [default false], created_at,
  updated_at). Index (user_id). Local schema v3. Balance is never stored:
  computed in account_balance.dart. Total Balance excludes credit-card
  accounts; they are shown separately as "card dues" (see DECISIONS.md).
- `categories` (id, user_id NOT NULL, name, icon [Phosphor key, snake_case],
  color [int 0xFFRRGGBB; defaults defined in category_seeder.dart],
  kind [income/expense/system, stored by name, no CHECK], seed_key
  [nullable; stable id for built-in categories, NULL for user-made],
  is_archived [default false], created_at, updated_at). UNIQUE (user_id,
  seed_key); index (user_id, kind). Built-ins may be renamed/archived,
  never deleted. `system` categories (seed_key sys_*) label loan/investment
  money movements: never user-pickable, never counted as income/expense,
  never in budgets or charts. Seeded: sys_loan_given,
  sys_loan_repayment_received, sys_loan_taken, sys_loan_repayment_made,
  sys_investment_buy, sys_investment_sell. Local schema v2.
- `transactions` (id, user_id NOT NULL, account_id NOT NULL [the account
  money leaves/enters; for a transfer the FROM account], to_account_id
  [transfers only], category_id [none for transfers], amount [integer paise,
  always 1..Money.maxPaise; direction comes from type], type [income/expense/
  transfer, stored by name], note [trimmed, empty -> null, max 100
  characters], occurred_at [not later than the end of today, local time],
  source_type [loan/investment, by name] + source_id [both null or both set;
  set ONLY when a loan payment or investment trade created the row],
  created_at, updated_at). Indexes: (user_id, occurred_at), (account_id).
  No foreign keys or CHECKs: every rule lives in TransactionsDao, in one
  database transaction. A transfer is ONE row. Local schema v4. Account
  balances are computed from these rows (account_balance.dart), never stored.
- `budgets` (PLANNED: id, user_id, category_id, month, limit_amount [integer paise])
- `investments` (PLANNED — redesigned in the Investments task: an
  investment plus a trade history of buys/sells, each with quantity, price,
  the account used, and for sales the amount typed by the user. Holdings,
  cost basis and realized gain are computed from the trades, never stored.
  The old single-row shape with quantity/cost_basis/current_value is
  superseded.)
- `loans`, `loan_payments` (PLANNED — Loans task: a loan is "given" or
  "taken" with a person and principal; each payment can create a linked
  transaction. Remaining = principal − payments, never stored.)
- `recurring_rules` (PLANNED — Recurring task: id, user_id, the transaction
  template [account, type, category, amount, note], frequency [daily / weekly /
  monthly / yearly / every N days-weeks-months], next_run; monthly runs clamp
  to the month's last day. Transactions it creates count normally in summaries
  and link back to the rule; they do NOT use source_type.)

## Vault (zero-knowledge)
- `vault_items` (id, user_id, item_type[credential/note/document_ref],
  title **[ENCRYPTED]**, payload **[ENCRYPTED, JSON blob]**,
  tags **[ENCRYPTED]**)
- `vault_document_refs` (id, user_id, vault_item_id, label
  **[ENCRYPTED]**, storage_pointer **[ENCRYPTED]** — a reference/handle
  only, never the raw document content in this table)
- `vault_recovery_meta` (id, user_id, recovery_scheme_version,
  kdf_params [salt, iterations — not secret], recovery_check_value —
  a value derivable only from the correct key, used to verify a
  recovery attempt succeeded, never usable to reconstruct the key by
  itself). **This table reflects the Section 5 recovery model (Option
  A — recovery phrase): it stores only the parameters needed to derive
  and verify a key from a correctly-entered recovery phrase, never the
  phrase, never the key, never anything server-usable to decrypt Vault
  contents.** Implementation detail is Phase 3 scope.

Nothing in the Vault module is ever included in the Section 6 data
export.

## Notes
- `notes` (id, user_id, folder_id, title, body, is_pinned)
- `note_folders` (id, user_id, name, parent_folder_id)
- `note_tags` (id, user_id, name)
- `note_tag_links` (note_id, tag_id) — join table, still implicitly
  scoped via the parent note's user_id

## Goals
- `goals` (id, user_id, title, description, term[short/long], deadline,
  progress_percent, status)
- `goal_milestones` (id, user_id, goal_id, title, is_done, due_date)

## Birthdays & Events
- `people` (id, user_id, name, birthdate, notes)
- `events` (id, user_id, person_id nullable, title, event_date,
  recurrence_rule, reminder_offset)

## Tasks
- `tasks` (id, user_id, title, notes, priority, due_date,
  recurrence_rule, is_done, reminder_at)

## Recipes
- `recipes` (id, user_id, title, instructions, servings, tags)
- `recipe_ingredients` (id, user_id, recipe_id, name, quantity, unit)

## Beauty
- `beauty_routines` (id, user_id, name, time_of_day[am/pm], steps_json)
- `beauty_products` (id, user_id, name, category, notes,
  routine_id nullable)

## Health
- `habits` (id, user_id, name, frequency_rule, target_count)
- `habit_logs` (id, user_id, habit_id, logged_at, count)
- `health_notes` (id, user_id, category[exercise/nutrition], body,
  logged_at)

## Wishlist / Purchase planner
- `wishlist_items` (id, user_id, name, term[short/long], est_price,
  priority, target_date, status, saved_amount) — `saved_amount`/progress
  links conceptually to Finance (e.g. a tagged savings category or
  manual updates); no hard foreign key required at this stage. Surfaced
  on the dashboard per CLAUDE.md Section 1.

## App-level (not per-feature)
- `user_profile` (id, user_id, display_name, birthdate — the source for
  the dashboard's age/days-to-birthday feature, theme_preference,
  app_lock_mode[os/pin/off])
  Single row only: profile edits UPDATE it, never insert a second.
- `remote_status_cache` (id, last_checked_at, maintenance_mode,
  maintenance_message, kill_switch, last_known_good) — this one is
  intentionally **not** user-scoped in the same way; it mirrors the
  public, no-login Supabase remote-status read described in API.md and
  is cached locally per-device, not per-user-account.

## Data export (Section 6)
No dedicated table — export is a read of the tables above (excluding all
Vault tables) into a single JSON file written to local device storage.
Not stored state, so nothing to schema here beyond noting the exclusion
rule explicitly.

