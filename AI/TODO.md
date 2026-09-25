# TODO.md — Build Checklist

Nothing has been built yet. This is the true starting point. Check items
off as they're completed; when an AI session finishes a task, it should
tell you what to check off rather than editing this file directly (see
HANDOFF.md).

## Phase 1 — Foundation
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
- [x] Accounts, categories + CRUD
- [ ] Transactions
- [ ] Monthly summary view
- [ ] Budget tracking
- [ ] Investment tracking
- [ ] Graphs/analytics (fl_chart)
- [ ] Dashboard: financial summary card wired to real data

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
