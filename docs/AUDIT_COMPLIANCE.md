# Audit Logging & Compliance Foundation

## Overview

This document outlines the comprehensive audit logging system and compliance-ready structure for the CMMS, designed to support future regulatory requirements and provide complete traceability of all system activities.

## Audit Requirements

### 1. What to Audit
- All data modifications (create, update, delete)
- User authentication and authorization events
- Work order status changes and completions
- PM schedule modifications and completions
- Asset changes and meter readings
- Inventory transactions
- User role and permission changes
- System configuration changes

### 2. Audit Data Structure
- **Who**: User performing the action
- **What**: Description of the action taken
- **When**: Precise timestamp with timezone
- **Where**: IP address, session info, device info
- **Why**: Context or reason (if applicable)
- **Before/After**: Complete state change tracking

## Database Audit System

### 1. Enhanced Audit Log Schema

```sql
-- Enhanced audit log table with compliance features
drop table if exists audit_log;

create table audit_log (
  id bigserial primary key,
  tenant_id bigint not null references tenants(id) on delete cascade,
  
  -- Event identification
  event_id uuid default gen_random_uuid() unique,
  event_type text not null, -- 'data_change', 'auth_event', 'system_event'
  table_name text not null,
  row_id text not null,
  action text not null, -- 'insert', 'update', 'delete', 'login', 'logout', etc.
  
  -- Actor information
  actor_user_id bigint references users(id),
  actor_session_id text,
  actor_ip_address inet,
  actor_user_agent text,
  
  -- Temporal information
  event_timestamp timestamptz not null default now(),
  business_date date not null default current_date,
  
  -- Change tracking
  field_changes jsonb, -- {field: {old: val, new: val}}
  old_values jsonb,    -- Complete old record
  new_values jsonb,    -- Complete new record
  
  -- Context and metadata
  event_context jsonb, -- Additional context (reason, work_order_id, etc.)
  correlation_id uuid, -- Link related events
  
  -- Compliance and integrity
  audit_hash text,     -- Hash of critical fields for integrity verification
  retention_until date, -- Data retention policy
  compliance_flags text[], -- ['sox', 'iso_27001', 'gdpr'] etc.
  
  -- Immutability enforcement
  created_at timestamptz not null default now(),
  -- No updated_at - audit records are immutable
  
  -- Prevent updates and deletes
  constraint audit_log_immutable check (false) deferrable initially deferred
);

-- Indexes for performance and compliance queries
create index audit_log_tenant_timestamp_idx on audit_log(tenant_id, event_timestamp desc);
create index audit_log_table_row_idx on audit_log(table_name, row_id, event_timestamp desc);
create index audit_log_actor_idx on audit_log(actor_user_id, event_timestamp desc);
create index audit_log_event_type_idx on audit_log(event_type, event_timestamp desc);
create index audit_log_business_date_idx on audit_log(business_date desc);
create index audit_log_correlation_idx on audit_log(correlation_id) where correlation_id is not null;
create index audit_log_compliance_flags_idx on audit_log using gin(compliance_flags);

-- Partition by month for performance (optional for large deployments)
-- create table audit_log_y2024m01 partition of audit_log
-- for values from ('2024-01-01') to ('2024-02-01');

-- Row Level Security for audit log
alter table audit_log enable row level security;

create policy audit_log_tenant_isolation on audit_log
  using (tenant_id = current_setting('app.current_tenant_id', true)::bigint);

-- Prevent direct modifications (except through audit functions)
create policy audit_log_insert_only on audit_log
  for insert with check (true);

create policy audit_log_no_update on audit_log
  for update using (false);

create policy audit_log_no_delete on audit_log
  for delete using (false);
```

### 2. Universal Audit Trigger Function

```sql
-- Enhanced audit trigger function with compliance features
create or replace function audit_trigger_function() 
returns trigger 
language plpgsql
security definer
as $$
declare
  audit_record record;
  field_changes jsonb := '{}';
  old_values jsonb;
  new_values jsonb;
  current_tenant_id bigint;
  current_user_id bigint;
  current_session_id text;
  current_ip inet;
  current_user_agent text;
  correlation_id uuid;
  event_context jsonb := '{}';
  audit_hash text;
begin
  -- Get current context
  current_tenant_id := nullif(current_setting('app.current_tenant_id', true), '')::bigint;
  current_user_id := nullif(current_setting('app.current_user_id', true), '')::bigint;
  current_session_id := current_setting('app.current_session_id', true);
  current_ip := nullif(current_setting('app.current_ip_address', true), '')::inet;
  current_user_agent := current_setting('app.current_user_agent', true);
  correlation_id := nullif(current_setting('app.correlation_id', true), '')::uuid;

  -- Skip audit for audit_log table itself
  if tg_table_name = 'audit_log' then
    case tg_op
      when 'INSERT' then return new;
      when 'UPDATE' then return new;
      when 'DELETE' then return old;
    end case;
  end if;

  -- Determine tenant_id if not set in session
  if current_tenant_id is null then
    case tg_op
      when 'INSERT', 'UPDATE' then
        if new ? 'tenant_id' then
          current_tenant_id := (new->>'tenant_id')::bigint;
        end if;
      when 'DELETE' then
        if old ? 'tenant_id' then
          current_tenant_id := (old->>'tenant_id')::bigint;
        end if;
    end case;
  end if;

  -- Process based on operation
  case tg_op
    when 'INSERT' then
      new_values := to_jsonb(new);
      event_context := jsonb_build_object('operation', 'insert');
    
    when 'UPDATE' then
      old_values := to_jsonb(old);
      new_values := to_jsonb(new);
      
      -- Calculate field-level changes
      select jsonb_object_agg(key, jsonb_build_object('old', old_val, 'new', new_val))
      into field_changes
      from (
        select key, old_values->key as old_val, new_values->key as new_val
        from jsonb_each(new_values)
        where old_values->key is distinct from new_values->key
      ) changes;
      
      event_context := jsonb_build_object(
        'operation', 'update',
        'fields_changed', array(select jsonb_object_keys(field_changes))
      );
    
    when 'DELETE' then
      old_values := to_jsonb(old);
      event_context := jsonb_build_object('operation', 'delete');
  end case;

  -- Generate audit hash for integrity verification
  audit_hash := encode(
    digest(
      coalesce(current_tenant_id::text, '') || 
      tg_table_name || 
      coalesce((coalesce(new, old)->>'id')::text, '') ||
      tg_op ||
      extract(epoch from now())::text ||
      coalesce(current_user_id::text, ''),
      'sha256'
    ),
    'hex'
  );

  -- Insert audit record
  insert into audit_log (
    tenant_id,
    event_type,
    table_name,
    row_id,
    action,
    actor_user_id,
    actor_session_id,
    actor_ip_address,
    actor_user_agent,
    field_changes,
    old_values,
    new_values,
    event_context,
    correlation_id,
    audit_hash,
    compliance_flags
  ) values (
    current_tenant_id,
    'data_change',
    tg_table_name,
    coalesce((coalesce(new, old)->>'id')::text, 'unknown'),
    lower(tg_op),
    current_user_id,
    current_session_id,
    current_ip,
    current_user_agent,
    field_changes,
    old_values,
    new_values,
    event_context,
    correlation_id,
    audit_hash,
    case 
      when tg_table_name in ('maint_work_orders', 'maint_pm_schedules') then array['maintenance_compliance']
      when tg_table_name in ('users', 'user_permissions') then array['access_control']
      when tg_table_name in ('maint_parts', 'maint_parts_usage') then array['inventory_tracking']
      else array[]::text[]
    end
  );

  -- Return appropriate record
  case tg_op
    when 'INSERT', 'UPDATE' then return new;
    when 'DELETE' then return old;
  end case;
  
exception
  when others then
    -- Log audit failures but don't block the main operation
    raise warning 'Audit logging failed for table %: %', tg_table_name, sqlerrm;
    case tg_op
      when 'INSERT', 'UPDATE' then return new;
      when 'DELETE' then return old;
    end case;
end;
$$;

-- Apply audit triggers to all auditable tables
create trigger audit_trigger_maint_assets
  after insert or update or delete on maint_assets
  for each row execute function audit_trigger_function();

create trigger audit_trigger_maint_work_orders
  after insert or update or delete on maint_work_orders
  for each row execute function audit_trigger_function();

create trigger audit_trigger_maint_pm_schedules
  after insert or update or delete on maint_pm_schedules
  for each row execute function audit_trigger_function();

create trigger audit_trigger_users
  after insert or update or delete on users
  for each row execute function audit_trigger_function();

-- Add triggers for other tables as needed...
```

## Elixir Audit Context

### 1. Audit Context Module (lib/shop1_cmms/audit.ex)

```elixir
defmodule Shop1Cmms.Audit do
  @moduledoc """
  Audit logging and compliance functionality for the CMMS.
  Provides comprehensive tracking of all system activities.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Audit.{AuditLog, AuditReport}

  ## Audit Log Queries

  def list_audit_logs(tenant_id, opts \\ []) do
    query = from(a in AuditLog,
      where: a.tenant_id == ^tenant_id,
      order_by: [desc: a.event_timestamp]
    )

    query
    |> apply_audit_filters(opts)
    |> limit_audit_results(opts)
    |> Repo.all()
  end

  def get_audit_trail(table_name, row_id, tenant_id) do
    from(a in AuditLog,
      where: a.tenant_id == ^tenant_id and 
             a.table_name == ^table_name and 
             a.row_id == ^row_id,
      order_by: [desc: a.event_timestamp]
    )
    |> Repo.all()
  end

  def search_audit_logs(tenant_id, search_params) do
    query = from(a in AuditLog, where: a.tenant_id == ^tenant_id)

    query
    |> filter_by_date_range(search_params)
    |> filter_by_user(search_params)
    |> filter_by_table(search_params)
    |> filter_by_action(search_params)
    |> filter_by_compliance_flags(search_params)
    |> order_by([a], desc: a.event_timestamp)
    |> Repo.all()
  end

  ## Manual Audit Events

  def log_authentication_event(user, action, metadata \\ %{}) do
    context = %{
      event_type: "auth_event",
      action: action,
      user_id: user.id,
      tenant_id: user.tenant_id,
      metadata: metadata
    }

    create_audit_entry(context)
  end

  def log_system_event(action, description, metadata \\ %{}) do
    context = %{
      event_type: "system_event",
      action: action,
      description: description,
      metadata: metadata
    }

    create_audit_entry(context)
  end

  def log_business_event(tenant_id, action, resource, metadata \\ %{}) do
    context = %{
      event_type: "business_event",
      action: action,
      resource: resource,
      tenant_id: tenant_id,
      metadata: metadata
    }

    create_audit_entry(context)
  end

  ## Compliance Reports

  def generate_compliance_report(tenant_id, report_type, date_range) do
    case report_type do
      "access_control" -> generate_access_control_report(tenant_id, date_range)
      "data_changes" -> generate_data_changes_report(tenant_id, date_range)
      "work_order_trail" -> generate_work_order_trail_report(tenant_id, date_range)
      "user_activity" -> generate_user_activity_report(tenant_id, date_range)
      "integrity_check" -> generate_integrity_check_report(tenant_id, date_range)
    end
  end

  ## Audit Integrity Verification

  def verify_audit_integrity(tenant_id, date_range \\ nil) do
    query = from(a in AuditLog, where: a.tenant_id == ^tenant_id)
    
    query = if date_range do
      from(a in query, 
        where: a.event_timestamp >= ^date_range.start_date and 
               a.event_timestamp <= ^date_range.end_date
      )
    else
      query
    end

    audit_logs = Repo.all(query)

    results = Enum.map(audit_logs, fn log ->
      expected_hash = calculate_audit_hash(log)
      {log.id, log.audit_hash == expected_hash}
    end)

    failed_verifications = Enum.filter(results, fn {_id, valid} -> not valid end)

    %{
      total_records: length(audit_logs),
      verified_records: length(results) - length(failed_verifications),
      failed_records: length(failed_verifications),
      integrity_score: (length(results) - length(failed_verifications)) / length(results) * 100,
      failed_ids: Enum.map(failed_verifications, fn {id, _} -> id end)
    }
  end

  ## Data Retention

  def apply_retention_policy(tenant_id, retention_policy \\ %{}) do
    default_retention = %{
      auth_events: 2555, # 7 years in days
      data_changes: 2555,
      system_events: 365  # 1 year
    }

    policy = Map.merge(default_retention, retention_policy)

    # Mark records for deletion based on retention policy
    for {event_type, days} <- policy do
      cutoff_date = Date.add(Date.utc_today(), -days)
      
      from(a in AuditLog,
        where: a.tenant_id == ^tenant_id and
               a.event_type == ^to_string(event_type) and
               a.event_timestamp < ^cutoff_date
      )
      |> Repo.update_all(set: [retention_until: cutoff_date])
    end
  end

  def purge_expired_audit_records(tenant_id) do
    today = Date.utc_today()
    
    {count, _} = from(a in AuditLog,
      where: a.tenant_id == ^tenant_id and
             a.retention_until <= ^today
    )
    |> Repo.delete_all()

    count
  end

  ## Private Functions

  defp apply_audit_filters(query, opts) do
    Enum.reduce(opts, query, fn {key, value}, acc ->
      case key do
        :event_type -> from(a in acc, where: a.event_type == ^value)
        :table_name -> from(a in acc, where: a.table_name == ^value)
        :action -> from(a in acc, where: a.action == ^value)
        :user_id -> from(a in acc, where: a.actor_user_id == ^value)
        :date_from -> from(a in acc, where: a.event_timestamp >= ^value)
        :date_to -> from(a in acc, where: a.event_timestamp <= ^value)
        :compliance_flag -> from(a in acc, where: ^value = any(a.compliance_flags))
        _ -> acc
      end
    end)
  end

  defp limit_audit_results(query, opts) do
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)
    
    query
    |> limit(^limit)
    |> offset(^offset)
  end

  defp create_audit_entry(context) do
    # This would typically be called from a background job
    # to avoid blocking the main operation
    audit_attrs = %{
      tenant_id: context[:tenant_id],
      event_type: context[:event_type],
      table_name: context[:table_name] || "system",
      row_id: context[:row_id] || "n/a",
      action: context[:action],
      actor_user_id: context[:user_id],
      event_context: context[:metadata] || %{},
      event_timestamp: DateTime.utc_now()
    }

    %AuditLog{}
    |> AuditLog.changeset(audit_attrs)
    |> Repo.insert()
  end

  defp calculate_audit_hash(audit_log) do
    # Recalculate hash to verify integrity
    data = "#{audit_log.tenant_id}#{audit_log.table_name}#{audit_log.row_id}#{audit_log.action}#{audit_log.actor_user_id}"
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  defp generate_access_control_report(tenant_id, date_range) do
    # Generate report of all access control events
    from(a in AuditLog,
      where: a.tenant_id == ^tenant_id and
             a.event_type in ["auth_event", "data_change"] and
             a.table_name in ["users", "user_permissions"] and
             a.event_timestamp >= ^date_range.start_date and
             a.event_timestamp <= ^date_range.end_date,
      order_by: [desc: a.event_timestamp]
    )
    |> Repo.all()
  end

  defp generate_work_order_trail_report(tenant_id, date_range) do
    # Complete audit trail for work orders
    from(a in AuditLog,
      where: a.tenant_id == ^tenant_id and
             a.table_name in ["maint_work_orders", "maint_wo_tasks", "maint_parts_usage"] and
             a.event_timestamp >= ^date_range.start_date and
             a.event_timestamp <= ^date_range.end_date,
      order_by: [a.correlation_id, desc: a.event_timestamp]
    )
    |> Repo.all()
  end
end
```

### 2. Audit Log Schema (lib/shop1_cmms/audit/audit_log.ex)

```elixir
defmodule Shop1Cmms.Audit.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "audit_log" do
    field :event_id, Ecto.UUID
    field :event_type, :string
    field :table_name, :string
    field :row_id, :string
    field :action, :string
    
    field :actor_session_id, :string
    field :actor_ip_address, EctoNetwork.INET
    field :actor_user_agent, :string
    
    field :event_timestamp, :utc_datetime
    field :business_date, :date
    
    field :field_changes, :map
    field :old_values, :map
    field :new_values, :map
    field :event_context, :map
    field :correlation_id, Ecto.UUID
    
    field :audit_hash, :string
    field :retention_until, :date
    field :compliance_flags, {:array, :string}

    belongs_to :tenant, Shop1Cmms.Tenants.Tenant
    belongs_to :actor_user, Shop1Cmms.Accounts.User

    timestamps(inserted_at: :created_at, updated_at: false)
  end

  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [
      :tenant_id, :event_id, :event_type, :table_name, :row_id, :action,
      :actor_user_id, :actor_session_id, :actor_ip_address, :actor_user_agent,
      :event_timestamp, :business_date, :field_changes, :old_values, :new_values,
      :event_context, :correlation_id, :audit_hash, :retention_until, :compliance_flags
    ])
    |> validate_required([:tenant_id, :event_type, :table_name, :row_id, :action])
    |> validate_inclusion(:event_type, ["data_change", "auth_event", "system_event", "business_event"])
    |> validate_inclusion(:action, ["insert", "update", "delete", "login", "logout", "permission_change", "system_config"])
    |> put_defaults()
  end

  defp put_defaults(changeset) do
    changeset
    |> put_change(:event_id, Ecto.UUID.generate())
    |> put_change(:event_timestamp, DateTime.utc_now())
    |> put_change(:business_date, Date.utc_today())
  end
end
```

## Compliance Features

### 1. GDPR Compliance Helper

```elixir
defmodule Shop1Cmms.Compliance.GDPR do
  @moduledoc """
  GDPR compliance helpers for data protection and privacy rights.
  """

  alias Shop1Cmms.{Repo, Audit}

  def export_user_data(user_id, tenant_id) do
    # Export all personal data for a user
    user_data = collect_user_personal_data(user_id, tenant_id)
    audit_data = collect_user_audit_data(user_id, tenant_id)

    %{
      personal_data: user_data,
      audit_trail: audit_data,
      export_timestamp: DateTime.utc_now(),
      export_format: "JSON"
    }
  end

  def anonymize_user_data(user_id, tenant_id) do
    # Replace personal data with anonymized values
    # This is a complex operation that needs careful handling
    Repo.transaction(fn ->
      # Update user record
      anonymize_user_record(user_id)
      
      # Update audit logs
      anonymize_audit_references(user_id, tenant_id)
      
      # Log the anonymization event
      Audit.log_business_event(tenant_id, "data_anonymization", "user:#{user_id}", %{
        reason: "gdpr_right_to_be_forgotten",
        anonymized_at: DateTime.utc_now()
      })
    end)
  end

  defp collect_user_personal_data(user_id, tenant_id) do
    # Collect all personal data across the system
    # This would need to be comprehensive based on your data model
    %{
      user_account: get_user_account_data(user_id),
      work_orders: get_user_work_order_data(user_id, tenant_id),
      meter_readings: get_user_meter_readings(user_id, tenant_id)
    }
  end
end
```

### 2. Audit Report Generation

```elixir
defmodule Shop1Cmms.Audit.ReportGenerator do
  @moduledoc """
  Generates comprehensive audit reports for compliance and monitoring.
  """

  alias Shop1Cmms.{Audit, Repo}

  def generate_compliance_report(tenant_id, opts \\ []) do
    report_type = Keyword.get(opts, :type, "comprehensive")
    date_range = Keyword.get(opts, :date_range, default_date_range())
    format = Keyword.get(opts, :format, "pdf")

    case report_type do
      "comprehensive" -> generate_comprehensive_report(tenant_id, date_range, format)
      "security" -> generate_security_report(tenant_id, date_range, format)
      "change_management" -> generate_change_management_report(tenant_id, date_range, format)
      "access_control" -> generate_access_control_report(tenant_id, date_range, format)
    end
  end

  defp generate_comprehensive_report(tenant_id, date_range, format) do
    sections = [
      audit_summary(tenant_id, date_range),
      user_activity_summary(tenant_id, date_range),
      data_change_summary(tenant_id, date_range),
      security_events_summary(tenant_id, date_range),
      integrity_verification(tenant_id, date_range)
    ]

    case format do
      "pdf" -> generate_pdf_report(sections)
      "csv" -> generate_csv_report(sections)
      "json" -> generate_json_report(sections)
    end
  end

  defp audit_summary(tenant_id, date_range) do
    %{
      section: "Audit Summary",
      total_events: count_events(tenant_id, date_range),
      events_by_type: count_events_by_type(tenant_id, date_range),
      most_active_users: get_most_active_users(tenant_id, date_range),
      most_modified_entities: get_most_modified_entities(tenant_id, date_range)
    }
  end
end
```

This comprehensive audit logging and compliance foundation provides:

**Audit Capabilities:**
- Complete data change tracking with before/after states
- Authentication and authorization event logging
- System event monitoring
- Immutable audit records with integrity verification
- Comprehensive search and filtering

**Compliance Features:**
- GDPR data export and anonymization
- Configurable data retention policies
- Compliance report generation
- Audit trail integrity verification
- Role-based audit access controls

**Security Features:**
- Hash-based integrity checking
- Row-level security for multi-tenant isolation
- Session and IP tracking
- Correlation IDs for related events
- Automatic audit trigger deployment

This foundation supports current audit needs while preparing for future compliance requirements like SOX, ISO 27001, FDA 21 CFR Part 11, or other industry-specific regulations.
