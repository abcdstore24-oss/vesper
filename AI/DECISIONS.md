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

### 2026-09-22 — ID generation without the `uuid` package
`user_profile`/`remote_status_cache` use a custom `generateId()` in
app_database.dart (dart:math `Random.secure()`, formatted as a UUID-v4
*shaped* string) instead of the `uuid` package, to avoid adding a
dependency for something already solved. Not RFC-4122-certified, but
cryptographically random and correctly shaped. This is the standing
approach for ID generation project-wide — don't introduce the `uuid`
package later without a real reason to revisit this.

### 2026-09-22 — remote_status_cache field set confirmed
DATABASE.md's literal field list for `remote_status_cache` (no
user_id/created_at/updated_at) is correct as written — this table is
explicitly device-scoped, not user-scoped, per DATABASE.md's own
description. Confirmed, not a gap.

### 2026-09-22 — Icon package swapped: phosphor_flutter → phosphoricons_flutter
The original phosphor_flutter package extends IconData, which Flutter's
SDK now marks as a final class (an upstream Flutter breaking change),
making phosphor_flutter uninstallable on current Flutter regardless of
version. Switched to phosphoricons_flutter (community-maintained,
rebuilt without extending IconData) as a drop-in replacement carrying
the same Phosphor icon set — the locked design decision (CLAUDE.md
Section 3: "one consistent icon set app-wide") is unchanged; only the
underlying package implementing it changed. Usage pattern:
PhosphorIconsRegular.x / PhosphorIconsFill.x, replacing the old
PhosphorIcons.x(PhosphorIconsStyle.x) calls.

### 2026-09-22 — Dashboard greeting date math (approved)
Age = today.year − birthdate.year, minus 1 if this year's birthday
hasn't occurred yet. Days-to-next-birthday = difference to the next
occurrence of birthdate's month/day (this year if not yet passed, else
next year), both dates normalized to midnight first; 0 days shows a
"today's your birthday" message instead of "0 days." Feb 29 birthdates
are observed on March 1 in non-leap years, via Dart's own DateTime
day-overflow normalization rather than a special case — not specified
anywhere in CLAUDE.md/DATABASE.md, so this is a convention, not a
locked fact. Time-of-day greeting (morning/afternoon/evening) is
likewise an interpretation of CLAUDE.md's "e.g. Good evening" example,
not a locked value. Confirmed working on-device.

### 2026-09-22 — Settings entry point & layout

Settings isn't a bottom-bar tab or a More-list item — it's reached via a gear icon in Dashboard's AppBar (plain Navigator.push, no router package), since it's a cross-cutting screen rather than a content module. Theme mode uses a SegmentedButton<ThemeMode> (Light/Dark/System) over a radio list or dropdown — shows all three states and lets you change in one tap, in a single compact row. App Lock / Data export rows use a hybrid "coming soon" treatment: a persistent "Soon" badge for an at-a-glance cue, plus a SnackBar on tap for interactive feedback — not a fully disabled row. App version is hardcoded "1.0.0" rather than reading it dynamically, since package_info_plus isn't in the locked stack and wasn't worth adding for one string — worth revisiting once a real release/build-number scheme exists. See CLAUDE.md Section 4 (App Lock), Section 6 (Data export).

### 2026-09-22 — App Lock implementation
Three modes (OS biometric/PIN via `local_auth`, custom 6-digit PIN, off)
per CLAUDE.md Section 4. PIN hashed with SHA-256 + random salt (`crypto`
package, added as a direct dependency) via `PinStorage`, both values in
`flutter_secure_storage`, never the raw PIN. Lock state split into two
providers: `appLockModeProvider` (persisted, defaults to `os` per
Section 4's "default/recommended") and `isUnlockedProvider`
(session-only, never persisted — always `false` on a real cold start).
Lock overlay intercepts both cold start and every background→foreground
resume, guarding against re-locking during the OS-auth prompt's own
pause/resume cycle via `authPromptActiveProvider`. Turning App Lock off
shows a one-time confirmation dialog naming exactly what's exposed.
Confirmed working on-device. See CLAUDE.md Section 1, Section 4.

### 2026-09-22 — Change PIN / Forgot PIN deferred
The nested-Navigator approach used to let LockScreen push PinSetupScreen
(needed because LockScreen sits outside the main Navigator, as a Stack
sibling in main.dart's overlay) caused intermittent black-screen/frozen
UI on-device — likely a GlobalKey/Navigator identity conflict during
lock/unlock transitions, which appears to corrupt the app's Navigator
state broadly (unrelated screens went black afterward too). Reverted to
the last known-good state: base App Lock (OS/PIN/off + the one-time
off-warning) is intact and tested. Change PIN and Forgot PIN are
deferred until a simpler, non-nested-Navigator design is built —
proposal: swap screens via plain in-place state (an enum + setState
inside the lock overlay itself), not Navigator.push, avoiding a second
Navigator entirely.

### 2026-09-24 — Data export: Save to Downloads (Phase 1, Task 8b)
Added `DataExportService.saveToDownloads()`, which reuses `exportToFile()`
and hands the result to `file_saver`'s `saveAs()` (Android: Storage
Access Framework "Save As" dialog). Settings' "Export my data" row now
opens a bottom sheet (same interaction pattern as the App Lock picker)
offering **Share...** (existing, unchanged) or **Save to Downloads**
(Android only — iOS already has an equivalent via the Share sheet's
"Save to Files").

**Why `file_saver`/`saveAs()` and not a MediaStore-writing plugin:** the
popular general-purpose package (`file_saver`, 483 likes, verified
publisher) does *not* write to public Downloads via its plain
`saveFile()` on Android — its own docs say that goes to app-private
`Android/data/<package>/files/`, the same category of problem this task
exists to fix. Packages that specifically claim silent MediaStore writes
to public Downloads (`better_download_saver`, `public_file_saver`,
`android_file_storage`) all had ~0 downloads/likes and unverified
publishers at the time of checking — too unproven to add to an app that
also handles passwords and financial data (Vault, Finance). `file_saver`'s
`saveAs()` sidesteps both problems: it's the well-audited package, and it
uses Android's own SAF "Save As" system dialog to place the file — a
direct write to wherever the user picks, with the added benefit that the
user sees and confirms exactly where their data is going. Standing
guidance for future Vesper dependency choices: a package being
well-known/liked and a package actually solving the stated problem are
separate questions — check both before adding anything, especially for
storage/security-adjacent features. Confirmed working on-device: file
appears in the phone's Downloads folder via Save to Downloads, and Share
still opens the OS share sheet correctly.

### 2026-09-24 — Known issue: KGP/Built-in Kotlin warning (share_plus, file_saver)
`flutter run` emits a `WARNING: ... plugins that apply Kotlin Gradle
Plugin (KGP): file_saver, share_plus`. This is a known, ecosystem-wide
Flutter deprecation (many popular plugins affected, actively being
migrated upstream) ahead of AGP 9's removal of KGP support — not caused
by anything in Vesper's own code, and not currently build-blocking.
`share_plus` has a fix in `^12.0.0`, but it's a breaking change requiring
AGP ≥8.12.1 / Gradle ≥8.13 / Kotlin ≥2.2.0 — deferred until those
project-level versions are checked. `file_saver` has no fixed release yet
as of this date. Revisit when either package ships a fix, or when
Flutter's compatibility shim is scheduled for removal.

### 2026-09-24 — Known issue: intermittent Kotlin daemon build failure (Windows)
One `flutter run` on Windows showed mid-build Kotlin daemon errors
(`Unresolved reference`, `NoSuchFileException`, "Storage already
registered") that looked severe but were a transient, known class of
Windows Kotlin-incremental-compile-cache corruption — Gradle discarded
the broken state and retried, producing a successful `assembleDebug` and
a working installed app in the same run. Not a real code defect in
Vesper, share_plus, or file_saver. If a future build genuinely fails
(no successful APK, no install) with similar errors, standard fix: `cd
android && .\gradlew --stop`, then `flutter clean`, then `flutter run`
again, to clear stale daemon/incremental state.

### 2026-09-24 — Remote status check (Phase 1, Task 9) — complete
Public, no-login `app_status` table on Supabase (RLS: anon SELECT only,
verified no write grant exists for anon at all), checked opportunistically
on app start via `RemoteStatusService.checkAndCache()`, cached into local
`remote_status_cache`. `last_known_good` = true only when both
maintenance_mode and kill_switch are false on a successful check. Layering
in main.dart, outermost to innermost: KillSwitch → App Lock → Maintenance
→ App. Kill switch bypasses Lock entirely (nothing to protect behind a
dead end); Maintenance sits INSIDE Lock deliberately, so a maintenance
window clearing while the phone is unattended can never hand over the app
without requiring a PIN/biometric first. Maintenance re-checks every 30s
while its screen is mounted and clears itself reactively; kill switch is
deliberately relaunch-only, no auto-recovery polling — a full kill is
meant to be a deliberate, harder stop.

Cold-start flash fix: the first value `effectiveRemoteStatusProvider`
returns is seeded synchronously in main() (via a manually-created
ProviderContainer + UncontrolledProviderScope, reading the real cached
row before runApp) rather than defaulting to "open" for one frame while
a StreamProvider warms up — same pattern already used for
ThemeModeNotifier/AppLockModeNotifier. Residual, expected behavior: the
very first relaunch immediately after a real status change on the
server still shows a brief flash of the old cached state before the
background check lands and updates it — this is inherent to
offline-first design (the alternative would be blocking app launch on a
network call, which is explicitly disallowed) and is not a bug. Every
relaunch after that one is instant, since the cache is already correct.

Also fixed as part of this: LockScreen's OS-auth prompt no longer starts
at all (or is actively cancelled mid-prompt via `stopAuthentication()`)
when kill switch is or becomes active, preventing the native biometric
dialog from visibly floating over KillSwitchScreen during the moment
_KillSwitchGate unmounts the Lock subtree out from under an in-flight
authenticate() call.

Confirmed working on-device: normal state, maintenance on/off with
auto-recheck, kill switch on/off, offline-never-blocks, cached-block-
persists-offline, kill-switch-bypasses-lock, light/dark rendering.
**Phase 1 (Foundation) is now fully complete — see TODO.md.**

### 2026-09-25 — Phase 2, Task 2.1: Accounts + Categories (tested, working)

1. Local user id mechanism (`lib/core/services/local_user_id.dart`) —
   first implementation of DATABASE.md's local device-generated UUID
   rule; every future feature should reuse this, not invent a second
   local-id mechanism.
2. accounts.type is a fixed enum (cash/bank/card/other), not free text.
3. Category colors: fixed 8-swatch palette, not free hex entry —
   approved exception to the one-accent rule (CLAUDE.md Section 3).
   See DATABASE.md's Finance section for the table.
4. All money values are stored as integer minor units (cents), never
   float/REAL — project-wide convention, not just Accounts.

Tested on-device, flutter analyze clean.

### 2026-09-26 — Phase 2, Task 2.2: Transactions (tested, working)

1. transactions.type is auto-derived from the selected category's
   kind, not independently selectable — stamped historically, not
   recalculated if the category's kind later changes.
2. is_recurring is stored as a plain flag only — no auto-repeat engine
   yet (separate TODO.md item).
3. No DB-level FK on transactions.accountId/categoryId — deleting an
   account/category with existing transactions is blocked, not
   orphaned. Revisit if/when PowerSync sync is wired up for Finance.

Tested on-device: add/edit/delete, live balance recalculation,
deletion-blocking, account filter — all confirmed. flutter analyze
clean.

