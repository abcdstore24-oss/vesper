# DECISIONS.md — Append-Only Decision Log

Rules for this file: **never edit or delete a past entry.** If a decision
changes later, add a new dated entry that references and supersedes the
old one — the old entry stays for history. Every future AI session should
append entries here when it finishes a task, not silently make decisions
that aren't recorded.

---

### 2026-09-22 — Tech stack chosen
Flutter + Drift (SQLite) + SQLCipher/flutter_secure_storage + Riverpod +
fl_chart, with Supabase (Auth/Postgres/Storage/Realtime/RLS) and
PowerSync as optional sync infrastructure, Firebase Cloud Messaging for
push, and a Supabase Edge Function fronting the Phase 6 AI provider.
Reasoning: fully offline-capable client stack, free-tier-friendly
backend, and a sync engine (PowerSync) purpose-built for local-first
SQLite apps rather than bolting sync on manually. Cost target: $0/month
at personal scale. See CLAUDE.md Section 2.

### 2026-09-22 — Multi-user-ready data model
Every table gets a `user_id` column from day one, with no unscoped/global
tables, even though only one user exists today and the app is fully
usable offline without any account. Reasoning: adding a second user later
must be "create an account," never a database migration. See CLAUDE.md
Section 1 and DATABASE.md.

### 2026-09-22 — Two-layer auth model
Account login (Supabase Auth, sync-only, always optional) is kept fully
independent from local app lock (OS biometric/PIN by default, custom PIN,
or off — user-configurable, never mandatory). Logging out pauses sync
only and never wipes local data. Reasoning: this is a personal,
single-owner-device app first — requiring an account to use it, or tying
local security to account state, would work against that. See CLAUDE.md
Section 4.

### 2026-09-22 — Vault recovery model: Option A (recovery phrase)
Chose a one-time 12–24 word recovery phrase, generated at Vault setup,
capable of regenerating the encryption key if the PIN is forgotten or the
device is lost (assuming prior sync). The phrase is the user's sole
responsibility — never stored by the app or server in a usable form.

**Reasoning:** The Vault holds passwords, IDs, and bank details —
categories of data where "permanently gone if you forget a PIN" is a
high, and for most people surprising, cost, especially since the Vault
sits inside a broader life-management app that people will use casually,
not a dedicated security tool they've consciously opted into. A recovery
phrase is a well-understood mental model already (password managers like
Bitwarden's emergency access model, and crypto wallet seed phrases), so
it doesn't require inventing new user education. It also doesn't weaken
zero-knowledge: the phrase never leaves the user's custody, and the
server only ever stores non-secret parameters needed to verify a
correctly-entered phrase (see `vault_recovery_meta` in DATABASE.md), not
anything that can reconstruct the key on its own. Option B (no recovery)
was rejected as the default specifically because it's *silently* harsher
than most users will expect from an app that also manages birthdays and
recipes — a bank-vault-grade trade-off hiding inside a lifestyle app.
Implementation is deferred to Phase 3; only the model is locked now. See
CLAUDE.md Section 5 and DATABASE.md.

### 2026-09-22 — Data export requirement
Everything outside the Vault is exportable as JSON from Settings, fully
offline, independent of Supabase sync. Vault data is excluded by default.
Reasoning: gives peace-of-mind backup without undermining the
zero-knowledge design of the Vault, and without requiring a backend at
all for people who never sync. See CLAUDE.md Section 6.

### 2026-09-22 — App name and design system
**Name: Vesper.** Short, personal, evokes the evening star / an
end-of-day check-in — fits a private life-management app without
sounding like a placeholder ("MyApp", "LifeHub").

**Typography:** `Fraunces` (headers/display) + `Karla` (body), via
`google_fonts`. Reasoning: Fraunces gives the app a warm, slightly
editorial, non-generic personality for headers and numbers (balances,
streaks, ages), while Karla stays clean and legible at small sizes for
dense UI — avoids the overused Roboto/Inter-only pairing.

**Color:** one accent, `#5B4B8A` (light) / `#9683E8` (dark) — a muted
violet-indigo. Reasoning: avoids the two most overused "trustworthy app"
defaults (blue for finance apps, warm amber for "cozy" apps) while still
reading as calm and premium rather than playful; used sparingly for CTAs
and active states only, per the "one accent, not a multi-color
dashboard" requirement.

**Shape:** 20px card radius, 14px control radius, 4px spacing grid,
soft/low-spread shadows. Reasoning: rounded-but-not-childish, consistent
across light/dark via color-token elevation rather than heavier shadows
in dark mode.

**Icons:** Phosphor Icons, one set app-wide (regular weight default,
fill weight for active nav states).

All of the above are now final and locked; see CLAUDE.md Section 3 for
exact values. No future session may change these without the owner's
explicit permission in that session.

### 2026-09-22 — Build order
Phase 1 Foundation → Phase 2 Finance → Phase 3 Vault/Notes/Documents →
Phase 4 Goals/Tasks/Birthdays/Reminders → Phase 5
Recipes/Beauty/Health/Wishlist → Phase 6 AI → Phase 7 iOS. Reasoning:
foundation and Finance first since they're used daily and establish the
design system in practice; Vault next since it's high-value and
sensitive; lifestyle modules after the core habit-forming loop exists;
AI and iOS last since both are optional/gated (AI needs real usage data
to be useful, iOS needs a paid developer account). See CLAUDE.md Section
7 / TODO.md.

### 2026-09-22 — Typography numeric scale (approved)
CLAUDE.md Section 3 locks the font families (Fraunces/Karla) and their usage but does not specify sizes, weights, or letter-spacing. Implemented a first type scale in app_typography.dart: displayLarge (Fraunces 57/600/-0.25), headlineLarge (Fraunces 32/600/0), titleMedium (Fraunces 20/500/0.15), bodyLarge (Karla 16/400/0.15), bodyMedium (Karla 14/400/0.25), labelLarge (Karla 14/600/0.1). Unlike the rest of Section 3, this scale is not yet locked — it's a working default that can be revised freely rather than superseded. Owner should review and either approve as-is or adjust.

### 2026-09-22 — ThemeData derived tokens (approved)
CLAUDE.md Section 3 locks colors/typography/shape but doesn't cover
Material's additional required roles. Resolved in app_theme.dart:
on-accent/on-error text color derived from the `background` token (not
a new hex); `secondary` mapped to `accent` (Vesper has only "one
accent"); disabled-button state derived as accent at 38% opacity; card
elevation approximated via `shadowColor`+`elevation` since CLAUDE.md's
exact blur-24/spread-0 shadow isn't expressible through ThemeData alone
and will need a widget-level BoxShadow later, when a real Card component
is built; unlocked TextTheme roles (display/headline/title-Medium&Small,
bodySmall, labelMedium/Small) default to GoogleFonts.karlaTextTheme()'s
own sizing. None of this changes the locked hex values, fonts, or radii
— it only fills Material's extra required fields. Approved as-is.