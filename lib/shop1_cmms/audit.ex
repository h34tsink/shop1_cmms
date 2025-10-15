defmodule Shop1Cmms.Audit do
  @moduledoc """
  The Audit context - handles audit trail logging for all entities
  """
  import Ecto.Query
  alias Shop1Cmms.Repo
  alias Shop1Cmms.AuditLog

  @doc """
  Create an audit log entry
  """
  def log(attrs) do
    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Log a component creation
  """
  def log_component_created(component, user_id, tenant_id, metadata \\ %{}) do
    log(%{
      entity_type: "component",
      entity_id: component.id,
      action: "created",
      changes: %{
        "name" => component.name,
        "component_type" => component.component_type,
        "manufacturer" => component.manufacturer,
        "model" => component.model,
        "serial_number" => component.serial_number,
        "install_date" => component.install_date,
        "status" => component.status,
        "asset_id" => component.asset_id
      },
      metadata: stringify_keys(metadata),
      performed_by_id: user_id,
      tenant_id: tenant_id
    })
  end

  @doc """
  Log a component update
  """
  def log_component_updated(component, changes, user_id, tenant_id, metadata \\ %{}) do
    log(%{
      entity_type: "component",
      entity_id: component.id,
      action: "updated",
      changes: stringify_keys(changes),
      metadata: stringify_keys(metadata),
      performed_by_id: user_id,
      tenant_id: tenant_id
    })
  end

  @doc """
  Log a component deletion
  """
  def log_component_deleted(component, user_id, tenant_id, metadata \\ %{}) do
    log(%{
      entity_type: "component",
      entity_id: component.id,
      action: "deleted",
      changes: %{
        "name" => component.name,
        "component_type" => component.component_type,
        "serial_number" => component.serial_number
      },
      metadata: stringify_keys(Map.merge(%{reason: "User deleted"}, metadata)),
      performed_by_id: user_id,
      tenant_id: tenant_id
    })
  end

  @doc """
  Log a component replacement (when a component is replaced with a new one)
  """
  def log_component_replaced(old_component, new_component, user_id, tenant_id, reason \\ nil) do
    log(%{
      entity_type: "component",
      entity_id: old_component.id,
      action: "replaced",
      changes: %{
        "old_serial_number" => old_component.serial_number,
        "old_install_date" => old_component.install_date,
        "new_serial_number" => new_component.serial_number,
        "new_install_date" => new_component.install_date,
        "new_component_id" => new_component.id
      },
      metadata: %{
        "reason" => reason || "Component replaced",
        "replacement_component_id" => new_component.id
      },
      performed_by_id: user_id,
      tenant_id: tenant_id
    })
  end

  @doc """
  Log a component status change
  """
  def log_component_status_changed(component, old_status, new_status, user_id, tenant_id, reason \\ nil) do
    log(%{
      entity_type: "component",
      entity_id: component.id,
      action: "status_changed",
      changes: %{
        "old_status" => old_status,
        "new_status" => new_status,
        "name" => component.name
      },
      metadata: %{"reason" => reason || "Status updated"},
      performed_by_id: user_id,
      tenant_id: tenant_id
    })
  end

  # Helper to convert map keys to strings for JSON storage
  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end
  
  defp stringify_keys(value), do: value

  @doc """
  Get audit history for a component
  """
  def get_component_history(component_id, tenant_id) do
    AuditLog
    |> AuditLog.for_entity("component", component_id)
    |> AuditLog.for_tenant(tenant_id)
    |> preload(:performed_by)
    |> Repo.all()
  end

  @doc """
  Get audit history for an asset (including component changes)
  """
  def get_asset_history(asset_id, tenant_id) do
    AuditLog
    |> AuditLog.for_entity("asset", asset_id)
    |> AuditLog.for_tenant(tenant_id)
    |> preload(:performed_by)
    |> Repo.all()
  end

  @doc """
  Get all audit logs for a tenant within a date range
  """
  def get_audit_logs(tenant_id, opts \\ []) do
    query = AuditLog
    |> AuditLog.for_tenant(tenant_id)
    |> preload(:performed_by)

    query = if opts[:entity_type], do: where(query, [a], a.entity_type == ^opts[:entity_type]), else: query
    query = if opts[:action], do: AuditLog.by_action(query, opts[:action]), else: query
    query = if opts[:from_date] && opts[:to_date], do: AuditLog.between_dates(query, opts[:from_date], opts[:to_date]), else: query

    query
    |> order_by([a], desc: a.inserted_at)
    |> limit(^(opts[:limit] || 100))
    |> Repo.all()
  end

  @doc """
  Get recent audit activity (last 50 entries)
  """
  def get_recent_activity(tenant_id, limit \\ 50) do
    AuditLog
    |> AuditLog.for_tenant(tenant_id)
    |> preload(:performed_by)
    |> order_by([a], desc: a.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end
end
