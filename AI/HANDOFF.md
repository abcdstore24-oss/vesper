# HANDOFF.md — Paste This at the Start of Any Future AI Session

I'm continuing work on **Vesper**, a Flutter life-management app. Before
doing anything, read all six files in this project's `AI/` folder, in
this order:

1. `AI/CLAUDE.md` — project overview, locked design system, auth model,
   and the Rules AI must follow
2. `AI/DATABASE.md` — schema plan
3. `AI/API.md` — backend integration notes
4. `AI/DECISIONS.md` — append-only decision log (history, don't edit
   past entries)
5. `AI/TODO.md` — build checklist / current status
6. `AI/COMPONENTS.md` — reusable widget/component registry

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

**My task for this session:**

[Describe the single, small task here — see TODO.md for what's next in
the current phase.]
