defmodule Shop1Cmms.AuditLog do
  @moduledoc """
  Schema for audit trail logging.
  Tracks all changes to entities across the system for accountability and history.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "audit_logs" do
    field :entity_type, :string
    field :entity_id, :binary_id
    field :action, :string
    field :changes, :map
    field :metadata, :map

    belongs_to :performed_by, Shop1Cmms.Accounts.User, type: :integer
    field :tenant_id, :integer

    timestamps(type: :naive_datetime, updated_at: false)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:entity_type, :entity_id, :action, :changes, :metadata, :performed_by_id, :tenant_id])
    |> validate_required([:entity_type, :entity_id, :action, :tenant_id])
    |> validate_inclusion(:entity_type, ["component", "asset", "work_order", "pm_schedule", "pm_execution", "user", "metadata"])
    |> validate_inclusion(:action, ["created", "updated", "deleted", "replaced", "status_changed", "installed", "removed", "repaired"])
  end

  @doc """
  Query helper to get audit logs for a specific entity
  """
  def for_entity(query \\ __MODULE__, entity_type, entity_id) do
    query
    |> where([a], a.entity_type == ^entity_type and a.entity_id == ^entity_id)
    |> order_by([a], desc: a.inserted_at)
  end

  @doc """
  Query helper to filter by tenant
  """
  def for_tenant(query \\ __MODULE__, tenant_id) do
    where(query, [a], a.tenant_id == ^tenant_id)
  end

  @doc """
  Query helper to filter by action
  """
  def by_action(query \\ __MODULE__, action) when is_binary(action) do
    where(query, [a], a.action == ^action)
  end

  @doc """
  Query helper to filter by date range
  """
  def between_dates(query \\ __MODULE__, from_date, to_date) do
    query
    |> where([a], a.inserted_at >= ^from_date)
    |> where([a], a.inserted_at <= ^to_date)
  end
end
