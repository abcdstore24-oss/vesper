# API.md — Backend Integration Notes

Vesper is offline-first. Everything below is optional infrastructure that
enhances the app when a connection and/or account exist — none of it is
required for core functionality.

## Supabase Auth
- Used only for multi-device sync, never required for local use.
- Sign up / log in / log out via `supabase_flutter`.
- Logging out pauses sync only; it never deletes local data (see
  CLAUDE.md Section 4).
- Row Level Security (RLS) policies scope every table by `auth.uid()` =
  `user_id`, matching the schema rule in DATABASE.md. RLS policies are
  written per-table as each module reaches Phase where sync is wired up
  — not required for Phase 1–2's local-only work.

## PowerSync (SQLite ↔ Postgres)
- Bidirectional sync engine between the local Drift/SQLite database and
  Supabase Postgres.
- Sync rules mirror the RLS scoping — a user only ever syncs their own
  rows.
- Vault tables (see DATABASE.md) sync as opaque encrypted blobs only;
  PowerSync never needs to understand their contents, and the server
  side never decrypts them.
- The app must function fully with PowerSync disconnected — sync status
  is informational (e.g. "last synced 2 hours ago"), never a blocking
  gate on any feature.

## Remote app control (maintenance mode / kill switch)
- A single public, **no-login-required** Supabase table/read (e.g. a
  `app_status` row readable via an anonymous key with a read-only RLS
  policy) holds: `maintenance_mode` (bool), `maintenance_message`
  (text), `kill_switch` (bool).
- Checked opportunistically when the device has connectivity (e.g. on
  app foreground, on a timer) — never polled in a way that assumes
  connectivity.
- **Offline rule (critical, non-negotiable):** the app caches the last
  known status locally (`remote_status_cache` in DATABASE.md). A device
  with no internet access at check time must **never** be treated as
  "disabled." The app only blocks or shows the maintenance screen when a
  *fresh, successful* check from a connected device confirms the flag.
  Absence of a successful check = fall back to cached status = normal
  operation if nothing was ever confirmed.
- `maintenance_mode` shows a maintenance screen (with the message)
  instead of the dashboard. `kill_switch` blocks all app functionality
  entirely.
- Announcements (e.g. "app back online") are delivered via **Firebase
  Cloud Messaging** — there is no separate announcement/notification
  system.
- **This is explicitly an app-layer control for legitimate remote
  management** (pausing or retiring the app, announcing downtime) — **it
  is not a security or anti-piracy mechanism.** A modified/patched client
  can bypass this check entirely. That is an accepted, known limitation
  of this design, not a bug to be solved later.

## AI features (Phase 6)
- All AI calls go through a **Supabase Edge Function**, which holds the
  Claude/OpenAI API key server-side. The key is **never** present
  on-device or in client code.
- The client sends only the minimum data needed for a given feature
  (e.g. a transaction description for categorization) — never raw Vault
  data, and never a full data dump.
- Features: smart expense categorization, productivity insights, smart
  reminders, personalized recommendations. Each is a distinct Edge
  Function endpoint with its own narrow input contract, defined when
  Phase 6 is actually built.

## Vault data — hard rule
**Vault data (see DATABASE.md `vault_items`, `vault_document_refs`) is
never sent in plaintext to any API call, Edge Function, or third-party
service, and is never included in the Section 6 data export.** If synced
at all, it syncs only as ciphertext the server cannot read. Any future
feature that would need to touch Vault contents server-side (even
encrypted) must be treated as a separate, explicitly-considered decision
— not an assumed extension of an existing API.
