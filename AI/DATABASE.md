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
3. Every table has: `id` (UUID, primary key), `user_id` (UUID, foreign
   key to the user — nullable locally when no account exists yet, backed
   by a local device-generated UUID until/unless an account is created
   and data is migrated to a real `auth.users.id`), `created_at`,
   `updated_at`.
4. Vault-related fields are marked **[ENCRYPTED]** below — these are
   encrypted client-side before ever touching local storage or sync;
   nothing server-side ever sees plaintext.
5. **All money values are stored as integers in minor currency units
   (cents), never as REAL/float.** This applies to every current and
   future money field — `accounts.starting_balance_cents`,
   `transactions.amount`, `budgets.limit_amount`,
   `investments.cost_basis`/`current_value`,
   `wishlist_items.est_price`/`saved_amount`, and any money field
   added later. Floats accumulate silent rounding drift once values
   are summed repeatedly (e.g. computing a running account balance);
   integers don't. Decimal display values (e.g. "$12.50") are computed
   from the stored integer only at the UI layer — never stored,
   never summed as decimals. Locked 2026-09-25, see DECISIONS.md.

---

## Finance
- `accounts` (id, user_id, name, type, currency, starting_balance_cents)
- `transactions` (id, user_id, account_id, category_id, amount,
  type[income/expense], note, occurred_at, is_recurring)
- `categories` (id, user_id, name, icon, color, kind[income/expense])
- `budgets` (id, user_id, category_id, month, limit_amount)
- `investments` (id, user_id, name, type, quantity, cost_basis,
  current_value, last_updated_at)
  
  ### Default category colors (Phase 2, Task 2.1)
   Categories get color from a fixed 8-swatch set, not free hex entry —
   this is the "category colors... are the one deliberate exception" to
   the one-accent rule referenced in CLAUDE.md Section 3. Each swatch is
   a light/dark hex pair; the `categories.color` column stores only the
   light-mode hex (canonical), with the dark-mode pairing derived via a
   fixed code-side lookup table — custom categories also pick from this
   same 8-swatch set at creation time, so no category ever needs a hex
   outside this table.

   | Category | Kind | Icon (Phosphor) | Light hex | Dark hex |
   |---|---|---|---|---|
   | Food | expense | forkKnife | #966E40 | #D9AC78 |
   | Transport | expense | carSimple | #4E6D97 | #8CACD9 |
   | Bills | expense | receipt | #82745E | #B7A78F |
   | Salary | income | handCoins | #637E44 | #A1C775 |
   | Shopping | expense | shoppingBag | #96547B | #D491B8 |
   | Health | expense | heartbeat | #428080 | #70C2C2 |
   | Entertainment | expense | filmSlate | #A48D46 | #DBC480 |
   | Other | expense | archiveBox | #8A8075 | #B3A89E |

   None of these reuse the locked accent/success/danger hexes. This
   palette is new data, not part of Section 3's locked design system —
   it can be revised by a future session without owner sign-off the way
   Section 3 itself requires, though changing it after real data exists
   would need a migration note in DECISIONS.md.

`budgets.month` is stored as TEXT in 'YYYY-MM' format (e.g. '2026-09'),
not a DateTime column — it's a label, not a timestamp. `category_id`
must reference an expense-kind category only (not enforced at the DB
level, enforced by the category picker UI) — a budget caps spending,
so income categories are excluded.

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

