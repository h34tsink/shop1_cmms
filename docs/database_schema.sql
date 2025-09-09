-- Multi-Tenant CMMS Database Schema
-- Focused on PM Scheduling and User Management
-- PostgreSQL 14+ with Row Level Security (RLS) support

-- ============================================================================
-- TENANT/SITE MANAGEMENT
-- ============================================================================

-- tenants table for multi-tenant architecture
create table tenants (
  id bigserial primary key,
  name text not null,
  slug text unique not null,
  active boolean default true,
  settings jsonb default '{}',
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- sites within tenants (your multiple locations)
create table sites (
  id bigserial primary key,
  tenant_id bigint references tenants(id) on delete cascade,
  name text not null,
  code text not null, -- site identifier
  address text,
  active boolean default true,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(tenant_id, code)
);

create index on sites(tenant_id);

-- ============================================================================
-- USER MANAGEMENT (Integration with existing Shop1FinishLine users table)
-- ============================================================================

-- NOTE: This assumes you already have a users table in Shop1FinishLine
-- We'll extend it with CMMS-specific fields instead of creating a new one

-- Add CMMS-specific columns to existing users table (if they don't exist)
-- Adjust these ALTER statements based on your existing users table structure
alter table users add column if not exists cmms_enabled boolean default false;
alter table users add column if not exists default_site_id bigint references sites(id);
alter table users add column if not exists preferences jsonb default '{}';
alter table users add column if not exists last_cmms_login timestamptz;

-- Add these only if they don't exist in your current users table
alter table users add column if not exists phone text;
alter table users add column if not exists employee_id text;
alter table users add column if not exists first_name text;
alter table users add column if not exists last_name text;
alter table users add column if not exists active boolean default true;

create index if not exists idx_users_cmms_enabled on users(cmms_enabled) where cmms_enabled = true;
create index if not exists idx_users_default_site on users(default_site_id);

-- CMMS-specific user roles (many-to-many relationship)
-- This allows users to have different roles in different tenants/sites
create table cmms_user_roles (
  id bigserial primary key,
  user_id bigint not null references users(id) on delete cascade,
  tenant_id bigint not null references tenants(id) on delete cascade,
  role text not null, -- 'maintenance_manager', 'supervisor', 'technician', 'operator'
  site_id bigint references sites(id), -- Optional site restriction
  granted_by bigint references users(id),
  granted_at timestamptz default now(),
  active boolean default true,
  
  unique(user_id, tenant_id, role, site_id)
);

create index on cmms_user_roles(user_id, tenant_id);
create index on cmms_user_roles(site_id);
create index on cmms_user_roles(tenant_id, role);

-- CMMS permissions - more granular than roles
create table cmms_user_permissions (
  id bigserial primary key,
  user_id bigint not null references users(id) on delete cascade,
  tenant_id bigint not null references tenants(id) on delete cascade,
  permission text not null,
  resource_type text, -- 'asset', 'work_order', 'site', etc.
  resource_id bigint, -- Specific resource ID if applicable
  site_id bigint references sites(id), -- Site restriction
  granted_at timestamptz default now(),
  expires_at timestamptz, -- Optional expiration
  active boolean default true
);

create index on cmms_user_permissions(user_id, tenant_id);
create index on cmms_user_permissions(user_id, permission, resource_type);

-- ============================================================================
-- ASSETS & COMPONENTS (Multi-tenant)
-- ============================================================================

create table maint_assets (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  site_id bigint not null references sites(id) on delete cascade,
  name text not null,
  tag text not null, -- asset tag/number
  location text,
  criticality int default 3, -- 1=critical, 5=low
  status text default 'active',
  manufacturer text,
  model text,
  serial_number text,
  installation_date date,
  warranty_expires date,
  notes text,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(tenant_id, tag)
);

create index on maint_assets(tenant_id, site_id);
create index on maint_assets(status, criticality);
create index on maint_assets(tag);

create table maint_components (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  asset_id bigint references maint_assets(id) on delete cascade,
  name text not null,
  component_type text, -- motor, bearing, belt, etc.
  manufacturer text,
  model text,
  serial_number text,
  installation_date date,
  notes text,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index on maint_components(tenant_id);
create index on maint_components(asset_id);

-- ============================================================================
-- METERS & READINGS
-- ============================================================================

create table maint_meters (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  asset_id bigint references maint_assets(id) on delete cascade,
  component_id bigint references maint_components(id) on delete cascade,
  name text not null,         -- e.g. runtime_hours, cycles, temperature
  unit text not null,         -- hours, count, degrees_c
  meter_type text default 'counter', -- counter, gauge
  active boolean default true,
  inserted_at timestamptz default now()
);

create index on maint_meters(tenant_id);
create index on maint_meters(asset_id);
create index on maint_meters(component_id);

create table maint_meter_readings (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  meter_id bigint references maint_meters(id) on delete cascade,
  reading numeric not null,
  reading_at timestamptz not null default now(),
  recorded_by bigint references users(id),
  notes text,
  inserted_at timestamptz default now()
);

create index on maint_meter_readings(tenant_id);
create index on maint_meter_readings(meter_id, reading_at desc);

-- ============================================================================
-- PM TEMPLATES & SCHEDULING (Core Focus)
-- ============================================================================

create table maint_pm_templates (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  name text not null,
  description text,
  -- Time-based scheduling
  frequency_days int,           -- every N days
  -- Meter-based scheduling  
  meter_type text,             -- runtime_hours, cycles, etc.
  meter_frequency numeric,     -- every N units
  -- Hybrid: use earliest of time or meter
  use_meter_and_time boolean default false,
  -- Task template
  task_list text[], -- array of task descriptions
  estimated_duration_hours numeric default 1,
  required_skills text[], -- required technician skills
  required_parts jsonb default '[]', -- [{part_sku, qty}]
  active boolean default true,
  created_by bigint references users(id),
  inserted_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index on maint_pm_templates(tenant_id);
create index on maint_pm_templates(active);

-- PM schedules - links assets/components to PM templates
create table maint_pm_schedules (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  asset_id bigint references maint_assets(id) on delete cascade,
  component_id bigint references maint_components(id) on delete cascade,
  pm_template_id bigint references maint_pm_templates(id) on delete cascade,
  meter_id bigint references maint_meters(id), -- for meter-based PMs
  
  -- Last completion tracking
  last_completed_at timestamptz,
  last_completed_meter numeric,
  last_completed_by bigint references users(id),
  
  -- Next due calculations (updated by background job)
  next_due_date date,
  next_due_meter numeric,
  days_overdue int generated always as (
    case when next_due_date is null then null
         else extract(days from now() - next_due_date::timestamptz)::int
    end
  ) stored,
  
  active boolean default true,
  assigned_to bigint references users(id), -- default assignee
  
  inserted_at timestamptz default now(),
  updated_at timestamptz default now(),
  
  -- ensure one schedule per asset/component + template combo
  unique(asset_id, component_id, pm_template_id)
);

create index on maint_pm_schedules(tenant_id);
create index on maint_pm_schedules(next_due_date) where active = true;
create index on maint_pm_schedules(asset_id);
create index on maint_pm_schedules(assigned_to);
create index on maint_pm_schedules(days_overdue) where days_overdue > 0;

-- ============================================================================
-- WORK ORDERS
-- ============================================================================

create table maint_work_orders (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  site_id bigint not null references sites(id) on delete cascade,
  number text not null, -- auto-generated WO number
  
  -- Asset/Component link
  asset_id bigint references maint_assets(id),
  component_id bigint references maint_components(id),
  pm_schedule_id bigint references maint_pm_schedules(id), -- if from PM
  
  -- Work order details
  title text not null,
  description text,
  work_type text not null default 'reactive', -- reactive, preventive, predictive, project
  priority int default 3, -- 1=urgent, 5=low
  status text not null default 'new', -- new, assigned, in_progress, waiting_parts, review, completed, cancelled
  
  -- People & timing
  requested_by bigint references users(id),
  assigned_to bigint references users(id),
  completed_by bigint references users(id),
  
  due_date date,
  scheduled_start timestamptz,
  actual_start timestamptz,
  actual_completion timestamptz,
  
  -- Labor tracking
  estimated_hours numeric,
  actual_hours numeric,
  
  -- Completion notes
  completion_notes text,
  
  inserted_at timestamptz default now(),
  updated_at timestamptz default now(),
  
  unique(tenant_id, number)
);

create index on maint_work_orders(tenant_id, site_id);
create index on maint_work_orders(status, priority);
create index on maint_work_orders(asset_id);
create index on maint_work_orders(assigned_to);
create index on maint_work_orders(due_date);
create index on maint_work_orders(pm_schedule_id);

-- work order tasks
create table maint_wo_tasks (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  work_order_id bigint references maint_work_orders(id) on delete cascade,
  sequence_no int not null,
  description text not null,
  completed boolean default false,
  completed_by bigint references users(id),
  completed_at timestamptz,
  notes text
);

create index on maint_wo_tasks(tenant_id);
create index on maint_wo_tasks(work_order_id, sequence_no);

-- ============================================================================
-- INVENTORY (Simplified for MVP)
-- ============================================================================

create table maint_parts (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  sku text not null,
  name text not null,
  description text,
  unit text default 'ea',
  unit_cost numeric default 0,
  category text,
  location text, -- bin/shelf location
  
  -- Inventory levels (per tenant)
  min_qty numeric default 0,
  max_qty numeric,
  current_qty numeric default 0,
  reserved_qty numeric default 0, -- reserved for work orders
  
  active boolean default true,
  inserted_at timestamptz default now(),
  updated_at timestamptz default now(),
  
  unique(tenant_id, sku)
);

create index on maint_parts(tenant_id);
create index on maint_parts(sku);
create index on maint_parts(current_qty) where current_qty <= min_qty; -- low stock

-- parts usage on work orders
create table maint_parts_usage (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  work_order_id bigint references maint_work_orders(id) on delete cascade,
  part_id bigint references maint_parts(id),
  qty_planned numeric default 0,
  qty_used numeric default 0,
  unit_cost numeric default 0,
  issued_by bigint references users(id),
  issued_at timestamptz
);

create index on maint_parts_usage(tenant_id);
create index on maint_parts_usage(work_order_id);
create index on maint_parts_usage(part_id);

-- ============================================================================
-- AUDIT LOG (Compliance-ready)
-- ============================================================================

create table audit_log (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  table_name text not null,
  row_id text not null,
  action text not null, -- insert, update, delete
  actor_user_id bigint references users(id),
  actor_ip_address inet,
  changes jsonb, -- {field: {old: val, new: val}}
  full_old_data jsonb,
  full_new_data jsonb,
  created_at timestamptz default now()
);

create index on audit_log(tenant_id, created_at desc);
create index on audit_log(table_name, row_id);
create index on audit_log(actor_user_id);

-- ============================================================================
-- ROW LEVEL SECURITY (Multi-tenant isolation)
-- ============================================================================

-- Enable RLS on all tenant-scoped tables
alter table tenants enable row level security;
alter table sites enable row level security;
alter table users enable row level security;
alter table maint_assets enable row level security;
alter table maint_components enable row level security;
alter table maint_meters enable row level security;
alter table maint_meter_readings enable row level security;
alter table maint_pm_templates enable row level security;
alter table maint_pm_schedules enable row level security;
alter table maint_work_orders enable row level security;
alter table maint_wo_tasks enable row level security;
alter table maint_parts enable row level security;
alter table maint_parts_usage enable row level security;
alter table audit_log enable row level security;

-- RLS policies (to be implemented per user session)
-- Example policy for assets:
create policy tenant_isolation_policy on maint_assets
  using (tenant_id = current_setting('app.current_tenant_id')::bigint);

-- ============================================================================
-- FUNCTIONS FOR PM SCHEDULING
-- ============================================================================

-- Function to calculate next PM due date
create or replace function calculate_next_pm_due(
  p_schedule_id bigint
) returns void language plpgsql as $$
declare
  schedule_rec record;
  template_rec record;
  latest_reading numeric;
  next_date date;
  next_meter numeric;
begin
  -- Get schedule and template info
  select ps.*, pt.frequency_days, pt.meter_frequency, pt.meter_type, pt.use_meter_and_time
  into schedule_rec
  from maint_pm_schedules ps
  join maint_pm_templates pt on ps.pm_template_id = pt.id
  where ps.id = p_schedule_id and ps.active = true;
  
  if not found then
    return;
  end if;
  
  -- Calculate next due date (time-based)
  if schedule_rec.frequency_days is not null then
    next_date := coalesce(schedule_rec.last_completed_at::date, current_date) + schedule_rec.frequency_days;
  end if;
  
  -- Calculate next due meter (meter-based)
  if schedule_rec.meter_frequency is not null and schedule_rec.meter_id is not null then
    next_meter := coalesce(schedule_rec.last_completed_meter, 0) + schedule_rec.meter_frequency;
  end if;
  
  -- Update the schedule
  update maint_pm_schedules 
  set 
    next_due_date = next_date,
    next_due_meter = next_meter,
    updated_at = now()
  where id = p_schedule_id;
end $$;

-- Function to get overdue PMs
create or replace function get_overdue_pms(p_tenant_id bigint)
returns table (
  schedule_id bigint,
  asset_name text,
  component_name text,
  pm_name text,
  days_overdue int,
  assigned_to_name text
) language sql as $$
  select 
    ps.id,
    a.name,
    c.name,
    pt.name,
    ps.days_overdue,
    u.email
  from maint_pm_schedules ps
  join maint_pm_templates pt on ps.pm_template_id = pt.id
  left join maint_assets a on ps.asset_id = a.id
  left join maint_components c on ps.component_id = c.id
  left join users u on ps.assigned_to = u.id
  where ps.tenant_id = p_tenant_id
    and ps.active = true
    and ps.days_overdue > 0
  order by ps.days_overdue desc, a.criticality asc;
$$;

-- ============================================================================
-- SEED DATA STRUCTURE
-- ============================================================================

-- Sample tenant and admin user (to be customized)
insert into tenants (name, slug) values ('Shop1 Manufacturing', 'shop1') on conflict do nothing;

-- Sample sites
insert into sites (tenant_id, name, code) 
select t.id, 'Main Plant', 'MAIN' from tenants t where t.slug = 'shop1'
union all
select t.id, 'Warehouse', 'WH01' from tenants t where t.slug = 'shop1'
on conflict do nothing;
