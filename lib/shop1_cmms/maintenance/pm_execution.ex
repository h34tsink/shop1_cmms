defmodule Shop1Cmms.Maintenance.PmExecution do
  @moduledoc """
  Schema for PM execution records - tracks every time a PM schedule is executed.
  This provides complete audit trail and history for maintenance activities.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pm_executions" do
    field :execution_number, :string
    field :execution_date, :utc_datetime
    field :completed_date, :utc_datetime
    field :status, Ecto.Enum,
      values: [:in_progress, :completed, :incomplete, :cancelled],
      default: :in_progress

    # Execution details
    field :step_results, {:array, :map}, default: []
    field :tech_notes, :string
    field :parts_used, {:array, :map}, default: []
    field :actual_duration_minutes, :integer
    field :meter_reading, :decimal

    # Relationships
    belongs_to :pm_schedule, Shop1Cmms.Maintenance.PmSchedule
    belongs_to :work_order, Shop1Cmms.WorkOrders.WorkOrder
    belongs_to :completed_by_user, Shop1Cmms.Accounts.User,
      foreign_key: :completed_by_user_id, type: :integer
    belongs_to :asset, Shop1Cmms.Assets.Asset
    belongs_to :component, Shop1Cmms.Assets.Component

    field :tenant_id, :integer

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(execution, attrs) do
    execution
    |> cast(attrs, [
      :execution_number, :execution_date, :completed_date, :status,
      :step_results, :tech_notes, :parts_used,
      :actual_duration_minutes, :meter_reading,
      :pm_schedule_id, :work_order_id, :completed_by_user_id,
      :asset_id, :component_id, :tenant_id
    ])
    |> validate_required([
      :execution_number, :execution_date, :status,
      :pm_schedule_id, :asset_id, :tenant_id
    ])
    |> unique_constraint(:execution_number)
    |> foreign_key_constraint(:pm_schedule_id)
    |> foreign_key_constraint(:asset_id)
    |> foreign_key_constraint(:component_id)
    |> foreign_key_constraint(:completed_by_user_id)
  end

  @doc """
  Changeset for completing a PM execution.
  Adds additional validations for completion.
  """
  def completion_changeset(execution, attrs) do
    execution
    |> changeset(attrs)
    |> put_change(:completed_date, DateTime.utc_now())
    |> put_change(:status, :completed)
    |> validate_required([:completed_by_user_id, :actual_duration_minutes])
  end
end
