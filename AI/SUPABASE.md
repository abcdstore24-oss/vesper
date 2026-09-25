# SUPABASE.md — Backend Schema & Policies (Supabase Project)

**Status:** Append-only log. Never edit or delete a past dated entry —
if something changes later, add a new dated entry that references and
supersedes the old one, same convention as DECISIONS.md.

This is the source of truth for everything set up directly in the
Supabase dashboard/SQL editor — the server-side counterpart to
DATABASE.md, which covers the LOCAL Drift/SQLite schema only. The two
are different databases; don't conflate a table here with a
similarly-named local table (e.g. `app_status` here vs.
`remote_status_cache` in DATABASE.md — the former is the server's
opinion, the latter is the local cache of it).

Every statement below should be written to be safely re-runnable
(`if not exists` / `if exists` guards, `on conflict do nothing`, etc.)
so this file can, in principle, be replayed from scratch on a fresh
Supabase project.

**Project:** https://kgezuhrygxozuaechxga.supabase.co

---

## 2026-09-24 — app_status table (Remote app control, Phase 1 Task 9)

Public, read-only status table backing CLAUDE.md's "Remote app
control" section (maintenance mode / kill switch). See API.md for the
client-side consumption pattern and DECISIONS.md's "Remote status
check" entry for full design rationale (offline-safe caching,
last_known_good semantics, main.dart layering).

**Settings used when creating this project:**
- Enable Data API: ON (required for supabase_flutter to work at all)
- Automatically expose new tables: OFF (secure-by-default — nothing is
  public unless explicitly granted, matching this project's general
  posture)
- Enable automatic RLS: ON (a new table with no policies defaults to
  fully inaccessible, not fully open)

```sql
-- Table
create table if not exists public.app_status (
  id integer primary key default 1,
  maintenance_mode boolean not null default false,
  maintenance_message text not null default '',
  kill_switch boolean not null default false,
  updated_at timestamptz not null default now(),
  constraint app_status_singleton check (id = 1)
);

-- RLS (belt-and-suspenders with "Enable automatic RLS" above, but
-- explicit here so this file is correct even against a project that
-- didn't have that project-level setting on)
alter table public.app_status enable row level security;

-- Public read policy
drop policy if exists "Public can read app status" on public.app_status;
create policy "Public can read app status"
  on public.app_status
  for select
  using (true);

-- Base table grant — required separately from the RLS policy above,
-- because "Automatically expose new tables" was OFF, so no grants
-- exist for anon by default. Without this GRANT, the RLS policy above
-- is never even reached — Postgres checks table-level privileges
-- first (learned the hard way during setup, see DECISIONS.md).
grant select on public.app_status to anon;

-- Deliberately NO insert/update/delete grant or policy for anon or
-- authenticated. This is what makes the table genuinely read-only
-- from any client — verified directly, see below.

-- Seed row (id is fixed at 1 — this table is a device-agnostic
-- singleton, never more than one row)
insert into public.app_status (id, maintenance_mode, maintenance_message, kill_switch)
values (1, false, '', false)
on conflict (id) do nothing;
```

**Verified working (2026-09-24):** `anon` role has `SELECT` only.
Confirmed no write access via direct SQL test, run as one transaction
so the role assignment doesn't reset between statements:

```sql
begin;
set local role anon;
update public.app_status set kill_switch = true;
rollback;
```

Correctly fails with `42501: permission denied for table app_status`.
Also confirmed via `information_schema.role_table_grants` that `anon`
has exactly `SELECT` (plus default Postgres `PUBLIC` grants —
`TRUNCATE`/`REFERENCES`/`TRIGGER` — which aren't reachable through
Supabase's REST API and aren't a real exposure).

---

## Template for future entries

Copy the pattern below for every new entry — add it below the line
above this template, newest entry at the bottom, oldest entries never
edited once written.

> ## YYYY-MM-DD — *(short title of what changed)*
>
> *(One or two sentences: what this is for, which CLAUDE.md /
> DATABASE.md / API.md / DECISIONS.md section it relates to.)*
>
> ```sql
> -- the actual, re-runnable SQL — use `if not exists`,
> -- drop-then-create, or `on conflict do nothing`, so this file could
> -- be replayed from scratch on a fresh Supabase project
> ```
>
> **Verified working (YYYY-MM-DD):** *(how you confirmed RLS/grants
> are correct — the exact test query and its result, not just "looks
> fine in the dashboard")*