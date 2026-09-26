# HANDOFF.md — Paste This at the Start of Any Future AI Session

I'm continuing work on **Vesper**, a Flutter life-management app. Before
doing anything, read all eight files in this project's `AI/` folder, in
this order:

1. `AI/CLAUDE.md` — project overview, locked design system, auth model,
   and the Rules AI must follow
2. `AI/DATABASE.md` — LOCAL (Drift/SQLite) schema plan
3. `AI/SUPABASE.md` — SERVER-SIDE (Supabase) schema, RLS policies, and
   grants — append-only, re-runnable SQL log. Do not confuse this with
   DATABASE.md: they are different databases, and a table with a
   similar name in each (e.g. `app_status` here vs.
   `remote_status_cache` in DATABASE.md) is not the same table.
4. `AI/API.md` — backend integration notes
5. `AI/DECISIONS.md` — append-only decision log (history, don't edit
   past entries)
6. `AI/TODO.md` — build checklist / current status
7. `AI/COMPONENTS.md` — reusable widget/component registry

**Rules for this session:**
- Follow every rule in `CLAUDE.md` Section "Rules AI must follow" —
  don't rewrite working code unnecessarily, don't introduce packages
  outside the locked stack, don't duplicate existing widgets (check
  COMPONENTS.md first), follow the locked design system exactly (name,
  colors, fonts, icons — do not alter these), treat Vault/encryption code
  as sensitive, follow the folder structure, and explain your plan
  before writing code.
- **Only touch files relevant to the specific task I give you below.**
  Don't refactor or "clean up" unrelated code as a side effect.
- Do **not** edit `TODO.md` or `DECISIONS.md` directly. Instead, at the
  end of your response, tell me exactly what to check off in `TODO.md`
  and what (if anything) to append to `DECISIONS.md`, so I can apply it
  myself and keep one clean edit history.
- If something in my task request conflicts with a locked decision in
  these files, tell me about the conflict and ask before proceeding —
  don't silently override it.
- Any task that requires a change to the Supabase project itself (a
  new table, an RLS policy, a grant, anything run in the Supabase SQL
  editor) must give me the exact SQL to run there directly — you
  cannot run it for me. Write it as safely re-runnable SQL (`if not
  exists`, `drop ... if exists` then `create`, `on conflict do
  nothing`), and tell me exactly what to append to `SUPABASE.md`
  afterward, including a verification query I can run to confirm RLS/
  grants are actually correct — not just "looks right in the
  dashboard."
- DECISIONS.md entries are selective, not automatic. Only append an
  entry for: an ambiguity the locked docs didn't settle, a
  project-wide convention, a rejected-alternative trade-off worth
  preserving, or something explicitly deferred. Don't restate a
  pattern already established in a prior entry (e.g. "migration was
  additive and safe" — see the 2026-09-26 standing-practice entry,
  that's said once, not per task). If a task has nothing genuinely new
  to decide, say so in one line instead of padding a numbered list to
  look thorough.

**My task for this session:**

[Describe the single, small task here — see TODO.md for what's next in
the current phase.]