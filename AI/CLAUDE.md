# CLAUDE.md — Project Source of Truth

**Status:** Locked. This file, along with DECISIONS.md, DATABASE.md,
API.md, TODO.md, and COMPONENTS.md, is the single source of truth for
this project. Any AI session working on this project must read all six
files before writing code. Do not reinterpret or "improve" decisions
recorded here without the owner's explicit permission.

---

## 1. Project overview

**App name: Vesper**

Vesper is an offline-first, personal life-management app. It brings
finance, a zero-knowledge encrypted vault, notes, goals, tasks, events,
recipes, beauty/health tracking, and a wishlist/purchase planner into one
private, premium-feeling app. It works fully without an account; sync and
multi-device access are optional add-ons, never a requirement.

The name evokes the evening star — quiet, personal, something you check
in with at the end of the day. It is short, pronounceable, not a
placeholder name, and has no collision with a major existing consumer
app in this category.

### Scope (all modules — see TODO.md for build order)
1. Finance — income/expense tracking, budgets, investments, analytics
2. Personal Vault — zero-knowledge encrypted credentials, private notes,
   document references
3. Notes — quick/long notes, folders, tags, search
4. Goal tracking — short/long-term goals, deadlines, progress, reminders
5. Birthday & event manager — calendar view, reminders, notes on people
6. Task management — to-dos, recurring tasks, priorities, reminders
7. Recipe manager — recipes, ingredients, instructions, tags
8. Beauty care — skin/hair routines, product notes
9. Healthy lifestyle — habits, exercise/nutrition notes
10. Personal dashboard — today's tasks, upcoming birthdays, financial
    summary, goal progress, habits, age/days-to-birthday (from stored
    birthdate), wishlist highlights
11. AI features (Phase 6, optional) — smart categorization, insights,
    smart reminders, recommendations
12. Purchase planner / wishlist — items, price, priority, target date,
    savings progress, linked to Finance and dashboard

### Multi-user-ready, single-user-today
Only one person uses Vesper today, but the data model and auth are
designed so a second, third, or Nth user is just "create an account" —
never a schema migration. Every table is scoped with a `user_id` from
day one (see DATABASE.md). There is no default data sharing between
users. Auth is always optional: the app must work fully offline, forever,
without ever logging in. Multi-user only becomes relevant once more than
one person is actually syncing through Supabase.

### Remote app control (server-controlled status)
Checked via a public (no-login) Supabase read:
- **Maintenance mode** — flag + message; shows a maintenance screen
  instead of the dashboard when set.
- **Kill switch** — flag that blocks all app functionality, regardless of
  whether the APK is still installed.
- **Offline rule (critical):** this check only ever applies when the
  device has internet access *at the time of the check*. No connectivity
  must never be treated as "disabled." The last known status is cached
  locally; the app only blocks when a fresh check from a connected device
  confirms the flag is set. This must never break offline-first use.
- Announcements (e.g. "app back online") are delivered via Firebase Cloud
  Messaging — no separate notification system.
- **This is an app-layer control for legitimate remote management**
  (pausing/retiring the app, announcing downtime) — **it is not a
  security or anti-piracy mechanism.** A modified client can bypass it.
  That is an accepted, known limitation, not a bug to fix.

### Non-negotiable qualities
- UI is genuinely polished/premium — not a generic utility-app look.
- Light/dark theme toggle from the start.
- App lock (biometric/PIN) is user-configurable, never mandatory.
- iOS build is a later phase (Phase 7), gated on an Apple Developer
  account.

---

## 2. Tech stack (locked)

| Layer | Choice |
|---|---|
| Client framework | Flutter |
| Local database | Drift (SQLite wrapper) |
| Local encryption | SQLCipher + flutter_secure_storage (Keystore/Keychain) |
| State management | Riverpod |
| Charts/graphs | fl_chart |
| Backend (optional sync) | Supabase (Postgres + Auth + Storage + Realtime + RLS) |
| Offline sync engine | PowerSync (SQLite ↔ Postgres) |
| Push notifications | Firebase Cloud Messaging |
| AI (Phase 6) | Supabase Edge Function → Claude/OpenAI API (server-side key only, never on-device) |
| Icons | Phosphor Icons (`phosphoricons_flutter`) — the one icon set, app-wide |

Cost target: $0/month at personal scale (free tiers). One-time $25
Google Play fee at Android launch; $99/year Apple Developer fee only if
iOS ships.

Do not add packages that duplicate anything in this table without
updating this file first.

---

## 3. Design system (locked — final, specific values)

Chosen for a mood of **calm, private, premium** — this app holds money,
passwords, and documents, so it must feel trustworthy and personal, not
like a generic CRUD utility.

### Typography (`google_fonts`)
- **Header / display font:** `Fraunces` — a warm, slightly editorial
  serif with personality; used for screen titles, section headers, large
  numbers (e.g. balances, streaks).
- **Body / UI font:** `Karla` — a humanist sans-serif, clean at small
  sizes; used for body text, labels, buttons, form fields.
- Do not substitute Roboto, plain Inter, or any other pairing without
  updating this section and DECISIONS.md.

### Color — Light mode
| Token | Hex | Use |
|---|---|---|
| `background` | `#FAF8F5` | App background |
| `surface` | `#FFFFFF` | Cards, sheets, dialogs |
| `surfaceVariant` | `#F1ECE6` | Subtle section backgrounds |
| `textPrimary` | `#1E1B22` | Primary text |
| `textSecondary` | `#6E6875` | Secondary/meta text |
| `border` | `#E4DED6` | Dividers, outlines |
| `accent` | `#5B4B8A` | **The one accent — CTAs, active states, links only** |
| `success` | `#3F7D58` | Positive amounts, completed states |
| `danger` | `#B3483F` | Destructive actions, negative amounts |

### Color — Dark mode
| Token | Hex | Use |
|---|---|---|
| `background` | `#131118` | App background |
| `surface` | `#1D1A23` | Cards, sheets, dialogs |
| `surfaceVariant` | `#26222E` | Subtle section backgrounds |
| `textPrimary` | `#F3F0F7` | Primary text |
| `textSecondary` | `#A8A2B3` | Secondary/meta text |
| `border` | `#332E3D` | Dividers, outlines |
| `accent` | `#9683E8` | **The one accent — CTAs, active states, links only** |
| `success` | `#6FBE8C` | Positive amounts, completed states |
| `danger` | `#E08277` | Destructive actions, negative amounts |

The accent color is used sparingly — CTAs and active states only. The
dashboard is never multi-color; category colors in Finance charts are the
one deliberate exception and are defined in DATABASE.md/Finance module
docs when built.

### Shape & elevation
- Corner radius: `20px` for cards/sheets, `14px` for buttons/inputs,
  `999px` (full) for chips/pills.
- Spacing grid: multiples of `4px`, with `8/12/16/24/32` as the standard
  step sizes used throughout layouts.
- Elevation: prefer soft, low-spread, higher-blur shadows over hard drop
  shadows (e.g. `blur 24, spread 0, opacity 0.08` in light mode; slightly
  lower opacity, warmer-black shadow color in dark mode where elevation
  is instead conveyed mostly through surface color steps, not shadow).
- Consistent across light and dark — the *shape* language never changes
  between themes, only color tokens do.

### Icons
- `phosphor_flutter`, **regular weight** by default, **fill weight** for
  active/selected navigation states. No mixing with Material icons.

### Signature dashboard feature
The dashboard always shows personalized details derived from the user's
stored birthdate (current age, days until next birthday) — this is a
signature feature of Vesper regardless of theme, and must not be cut in
a later redesign without updating this file.

**This entire design system is final.** No future session may change
the name, palette, fonts, icon set, or shape rules without the owner's
explicit, written permission in that session. If asked to "make it look
nicer" without specifics, apply these tokens more consistently — do not
invent a new palette.

---

## 4. Auth model (locked)

Two fully independent layers:

1. **Account login/logout (Supabase Auth)** — only needed for
   multi-device sync. The app is fully usable forever without ever
   logging in.
2. **Local app lock** — user-configurable in Settings between:
   - (a) the phone's own OS-level device lock (biometric/PIN) —
     default/recommended
   - (b) a separate custom in-app PIN
   - (c) off entirely (one-time warning shown, never a hard block)

   Never mandatory. Never dependent on being logged into an account.

Logging out pauses sync only — it never wipes local data (this is a
single-owner-device assumption; local data always belongs to whoever is
holding the device).

---

## 5. Vault (zero-knowledge) — summary

The Vault (passwords, private notes, document references) is
zero-knowledge encrypted: if this is ever synced, the server must never
see plaintext or a usable decryption key.

**Recovery model: Option A — recovery phrase.** See DECISIONS.md for
full reasoning and DATABASE.md for where recovery-derived key material
is structured. In short: at Vault setup, a one-time 12–24 word recovery
phrase is generated and shown once; it can regenerate the encryption key
if the PIN is forgotten or the device is lost (assuming data was synced).
The phrase is the user's sole responsibility to store — it is never
stored by the app or server in a usable form. Implementation is Phase 3
scope; for now only the model is locked.

---

## 6. Data export / backup (locked)

Everything **outside** the Vault (Finance, Notes, Goals, Tasks, Recipes,
Beauty, Health, Wishlist, Birthdays/Events) is exportable as a JSON file
from Settings, fully offline, independent of Supabase sync. Vault data is
excluded by default — exporting decrypted Vault contents to a plain file
would undermine the zero-knowledge design. A separate, explicitly
considered Vault export flow is out of scope for now.

---

## 7. Folder structure (Flutter conventions)

```
lib/
  app/                     # App entry, routing, top-level providers
  core/
    theme/                 # Design tokens, ThemeData, light/dark themes
    constants/
    utils/
    services/              # Connectivity, remote-status check, secure storage wrapper
    db/                     # Drift database, shared schema helpers
  features/
    finance/
      data/                # Drift tables/DAOs for this feature
      domain/              # Models, business logic
      presentation/        # Screens, widgets, Riverpod providers
    vault/
    notes/
    goals/
    events/
    tasks/
    recipes/
    beauty/
    health/
    dashboard/
    wishlist/
    settings/
  shared/
    widgets/                # Reusable cross-feature widgets (see COMPONENTS.md)
test/
```

Each feature is self-contained (data/domain/presentation). Shared,
reusable widgets go in `shared/widgets/` and are registered in
COMPONENTS.md as they're built — never duplicated per-feature.

---

## 8. Rules AI must follow

1. **Don't rewrite working code unnecessarily.** Only make the specific
   change requested.
2. **Don't introduce new packages** already covered by the stack table in
   Section 2 — use what's already chosen.
3. **Don't duplicate existing widgets/components.** Check COMPONENTS.md
   before creating a new one; reuse or extend instead.
4. **Follow the locked design system exactly** (Section 3) — name,
   colors, fonts, icon set, shape rules. No future session may alter
   these without the owner's explicit permission in that session.
5. **Treat encryption/Vault code as sensitive** — no shortcuts, no
   logging of key material or plaintext, no "temporary" plaintext writes
   to disk for debugging.
6. **Follow the folder structure** in Section 7.
7. **Explain the plan before writing code** — a short summary of what
   will change and which files, before generating.
8. **Update TODO.md and DECISIONS.md after finishing a task** — check off
   completed items and append any new decisions made along the way (see
   HANDOFF.md for how this should be communicated back to the owner
   rather than edited automatically in most workflows).
