# CMMS Blueprint (Phoenix LiveView + PostgreSQL)

Lean, opinionated plan for a Computerized Maintenance Management System (CMMS) that actually ships.

## Table of Contents
- [Why this stack](#why-this-stack)
- [Core Modules](#core-modules)
- [Data Model (ER-lite)](#data-model-er-lite)
- [PostgreSQL Schema (MVP)](#postgresql-schema-mvp)
- [Universal Audit Trigger](#universal-audit-trigger)
- [Scheduling Logic](#scheduling-logic)
- [Roles & Permissions](#roles--permissions)
- [Phoenix Scaffolding Commands](#phoenix-scaffolding-commands)
- [Background Jobs](#background-jobs)
- [LiveView UI Sketch](#liveview-ui-sketch)
- [Predictive Maintenance (Phase 2)](#predictive-maintenance-phase-2)
- [Security & Compliance](#security--compliance)
- [Today, Not Someday Checklist](#today-not-someday-checklist)
- [Notes & Next Steps](#notes--next-steps)

---

## Why this stack

**Stack**: Phoenix LiveView, PostgreSQL (prefer 14+), Oban for jobs, Tailwind, phx_gen_auth, optional Postgres RLS.

**Why**: LiveView gives real-time UIs (work orders, calendars, inventory counts) without SPA overhead. Postgres is battle-tested and simple to operate. Oban keeps PM generation, recalculations, and reorder checks honest.

> If you must go .NET: Blazor Server + Identity + EF Core + Postgres. Still, Phoenix ships faster for this use case.

---

## Core Modules

1. **Assets & Components**
   - Equipment → Components (1:N), Locations, Meters (hours/cycles), Attachments.
   - Condition monitoring hooks (vibration, temp, oil).

2. **PM Scheduling**
   - Templates (time-based, meter-based, or hybrid).
   - Next-due calculation + calendar + auto-WO generation.
   - Component-level PMs roll up to Equipment dashboards.

3. **Work Orders**
   - States: `new → assigned → in_progress → waiting_parts → qa → closed`.
   - Tasks, labor time, parts used, photos, signatures.
   - Kanban + Calendar views.

4. **Inventory & Parts**
   - Parts, bins/locations, min/max, reorder suggestions.
   - Barcode/QR for check-in/out.
   - (v1.1) Suppliers & simple POs.

5. **Users, Roles, Permissions**
   - Roles: Maintenance Manager, Supervisor, Technician, Operator.
   - RBAC policies + optional RLS by site/department.

6. **Auditing**
   - Append-only audit_log with triggers (who/what/when/old→new JSONB).
   - Diff viewer in UI, CSV/JSON export.

7. **Predictive Maintenance (Phase 2)**
   - Timeseries ingest (TimescaleDB optional).
   - Thresholds, rate-of-change rules → ML later for failure risk.

---

## Data Model (ER-lite)

```
Asset 1--N Component
Asset 1--N Meter 1--N MeterReading
Component 1--N PMSchedule -> PMTemplate (N:1)
PMSchedule 1--N WorkOrder
WorkOrder 1--N WOTask
WorkOrder N--N Part (via PartsUsage)
User (role) 1--N WorkOrder (assigned_to, requested_by)
AuditLog (append-only, any table)
```

---

## PostgreSQL Schema (MVP)

> All lowercase identifiers. Adjust types to your PG version (prefer 14+). add maint_ infront of the tables for maintenance related tables. for users and role reuse tables for users and roles in localhost:5433

```sql
-- assets & components
create table assets (
  id bigserial primary key,
  name text not null,
  tag text unique,
  location text,
  criticality int default 0,
  status text default 'active',
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table components (
  id bigserial primary key,
  asset_id bigint references assets(id) on delete cascade,
  name text not null,
  manufacturer text,
  model text,
  serial text,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index on components(asset_id);

-- meters & readings
create table meters (
  id bigserial primary key,
  asset_id bigint references assets(id) on delete cascade,
  name text not null,         -- e.g. runtime_hours, cycles
  unit text not null,         -- hours, count
  inserted_at timestamptz default now()
);
create index on meters(asset_id);

create table meter_readings (
  id bigserial primary key,
  meter_id bigint references meters(id) on delete cascade,
  reading numeric not null,
  reading_at timestamptz not null default now(),
  inserted_at timestamptz default now()
);
create index on meter_readings(meter_id, reading_at);

-- pm templates & schedules
create table pm_templates (
  id bigserial primary key,
  name text not null,
  cadence_days int,           -- nullable if meter-based
  meter_id bigint,            -- optional: link to a named meter type
  meter_interval numeric,     -- e.g. every 500 hours
  description text
);

create table pm_schedules (
  id bigserial primary key,
  component_id bigint references components(id) on delete cascade,
  pm_template_id bigint references pm_templates(id),
  last_done_at timestamptz,
  last_done_meter numeric,
  next_due_at timestamptz,
  next_due_meter numeric,
  active boolean default true
);
create index on pm_schedules(component_id);
create index on pm_schedules(next_due_at);

-- work orders
create table work_orders (
  id bigserial primary key,
  number text unique not null,
  asset_id bigint references assets(id),
  component_id bigint references components(id),
  pm_schedule_id bigint references pm_schedules(id),
  title text not null,
  description text,
  status text not null default 'new',
  priority int default 3, -- 1=urgent..5=low
  requested_by bigint,
  assigned_to bigint,
  due_at timestamptz,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);
create index on work_orders(status, priority);
create index on work_orders(asset_id);
create index on work_orders(due_at);

create table wo_tasks (
  id bigserial primary key,
  work_order_id bigint references work_orders(id) on delete cascade,
  step_no int not null,
  text text not null,
  done boolean default false
);
create index on wo_tasks(work_order_id);

-- inventory
create table parts (
  id bigserial primary key,
  sku text unique,
  name text not null,
  unit text default 'ea',
  min_qty numeric default 0,
  max_qty numeric,
  current_qty numeric default 0,
  location text, -- simple bin/aisle for MVP
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table parts_usage (
  id bigserial primary key,
  work_order_id bigint references work_orders(id) on delete cascade,
  part_id bigint references parts(id),
  qty numeric not null,
  used_at timestamptz default now()
);
create index on parts_usage(part_id);
create index on parts_usage(work_order_id);

-- users & roles


-- audit log
create table audit_log (
  id bigserial primary key,
  table_name text not null,
  row_id text not null,
  action text not null, -- insert|update|delete
  actor_user_id bigint,
  at timestamptz default now(),
  old_data jsonb,
  new_data jsonb
);
create index on audit_log(table_name, at desc);
```

---

## Universal Audit Trigger

```sql
create or replace function audit_row() returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    insert into audit_log(table_name,row_id,action,actor_user_id,old_data,new_data)
    values (tg_table_name, new.id::text, 'insert', current_setting('app.user_id', true)::bigint, null, to_jsonb(new));
    return new;
  elsif tg_op = 'UPDATE' then
    insert into audit_log(table_name,row_id,action,actor_user_id,old_data,new_data)
    values (tg_table_name, new.id::text, 'update', current_setting('app.user_id', true)::bigint, to_jsonb(old), to_jsonb(new));
    return new;
  else
    insert into audit_log(table_name,row_id,action,actor_user_id,old_data,new_data)
    values (tg_table_name, old.id::text, 'delete', current_setting('app.user_id', true)::bigint, to_jsonb(old), null);
    return old;
  end if;
end $$;
```

Attach to any table you care about:

```sql
create trigger t_audit_work_orders
after insert or update or delete on work_orders
for each row execute function audit_row();
```

In Phoenix (set acting user after auth):

```elixir
# in a Plug after auth success
:ok = Ecto.Adapters.SQL.query(Repo, "select set_config('app.user_id', $1, true)", ["#{conn.assigns.current_user.id}"])
```

---

## Scheduling Logic

- **Time-based PM**: `next_due_at = coalesce(last_done_at, inserted_at) + interval 'cadence_days day'`
- **Meter-based PM**: `next_due_meter = last_done_meter + meter_interval`
- **Hybrid**: next due is the **earliest** of the two
- Nightly job recomputes next-due; hourly job emits WOs when due/overdue

---

## Roles & Permissions

- **Maintenance Manager**: everything + admin (users, roles, PM templates)
- **Supervisor**: create/assign WOs, approve close-out, adjust schedules
- **Technician**: view/execute WOs, log labor/parts, add readings
- **Operator**: submit requests, basic readings, view asset status

Implement `can?(user, action, resource)` in context policy modules. Optional Postgres RLS if you need per-site scoping.

---

## Phoenix Scaffolding Commands

```bash
mix phx.new cmms --database postgresql
cd cmms
mix ecto.create

# auth
mix phx.gen.auth Accounts User users
mix ecto.migrate

# contexts
mix phx.gen.context Assets Asset assets name:string tag:string location:string status:string:default:active criticality:integer:default:0
mix phx.gen.context Assets Component components asset_id:references:assets name:string manufacturer:string model:string serial:string

mix phx.gen.context Maintenance PMTemplate pm_templates name:string cadence_days:integer meter_interval:decimal description:text
mix phx.gen.context Maintenance PMSchedule pm_schedules component_id:references:components pm_template_id:references:pm_templates last_done_at:utc_datetime last_done_meter:decimal next_due_at:utc_datetime next_due_meter:decimal active:boolean

mix phx.gen.context Work WorkOrder work_orders number:string:unique asset_id:references:assets component_id:references:components pm_schedule_id:references:pm_schedules title:string description:text status:string priority:integer due_at:utc_datetime assigned_to:integer requested_by:integer
mix phx.gen.context Work WOTask wo_tasks work_order_id:references:work_orders step_no:integer text:text done:boolean

mix phx.gen.context Inventory Part parts sku:string:unique name:string unit:string min_qty:decimal max_qty:decimal current_qty:decimal location:string
mix phx.gen.context Inventory PartUsage parts_usage work_order_id:references:work_orders part_id:references:parts qty:decimal

# background jobs
# add {:oban, "~> 2.18"} to mix.exs, then:
mix oban.migration
mix ecto.migrate
```

**Jobs to add**:
- `Maintenance.RecalcNextDueJob` (daily)
- `Maintenance.AutoCreateWOJob` (hourly)
- `Inventory.ReorderCheckJob` (daily)

---

## LiveView UI Sketch

- **Dashboard**: overdue PMs, WOs by state, stock below min
- **Assets**: table → detail (components, meters, PMs, recent WOs, attachments)
- **PM Calendar**: month/week; click to open WO or mark complete
- **Work Orders**: Kanban + filters (asset/site/priority/assignee)
- **Inventory**: table + barcode quick-adjust; modal to issue parts to WO
- **Operator Portal (Phase 2)**: “Report an issue” + quick meter entry
- **Audit**: table with diff viewer (old vs new)

Use `phx-update="stream"` for WO lanes; PubSub pushes live state changes.

---

## Predictive Maintenance (Phase 2)

1. **Collect**: meter readings + optional sensor feeds (CSV or API ingest).
2. **Features**: rolling means, deltas, spikes, time-since-last-PM, hrs-since-last-failure.
3. **Rules first**: hard thresholds + rate-of-change alerts to prove value quickly.
4. **ML next**: classifier for “failure in next X days” per component type.
5. **Action**: if risk > threshold, auto-suggest WO; supervisor confirms.

(Consider TimescaleDB + continuous aggregates.)

---

## Security & Compliance

- **Least privilege**: policy checks in contexts + controller plugs
- **RLS (optional)**: per-site tenant keys on all tables
- **Audit**: immutable append-only (no updates/deletes on `audit_log`)
- **Backups**: PITR with WAL archiving; test restores quarterly

---

## Today, Not Someday Checklist

- [ ] Create Phoenix app + auth + Oban
- [ ] Run migrations with schema above
- [ ] Add audit triggers to `assets`, `components`, `work_orders`, `parts`
- [ ] Build Asset → Component → PM Schedule CRUD
- [ ] Implement next-due compute + auto-WO job
- [ ] Build WO Kanban + detail with tasks & parts usage
- [ ] Inventory min/max + “below min” widget
- [ ] Role gating in LiveViews (Manager/Supervisor/Tech/Operator)
- [ ] Seed data + demo users for each role

---

## Notes & Next Steps

- If you're on PG 9.5, plan an upgrade path (containerized PG 14+ with logical replication or dump/restore during a cutover).
- Barcode/QR: start with code-128/QR images on parts; add scanning later.
- Attachments: store in S3-compatible storage (MinIO in dev). Keep DB paths only.
- Export: CSV for management; JSON for integrations.
- API (later): add `/api` read-only endpoints for reporting and data lakes.
