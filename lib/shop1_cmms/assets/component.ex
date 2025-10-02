defmodule Shop1Cmms.Assets.Component do
  @moduledoc """
  Schema for equipment components.
  Components are physical parts of equipment that can have their own PM schedules.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "components" do
    field :name, :string
    field :description, :string
    field :component_type, :string
    field :manufacturer, :string
    field :model, :string
    field :serial_number, :string
    field :install_date, :date
    field :status, Ecto.Enum, values: [:active, :inactive, :maintenance, :failed], default: :active

    belongs_to :asset, Shop1Cmms.Assets.Asset
    has_many :pm_schedules, Shop1Cmms.Maintenance.PmSchedule
    has_many :pm_executions, Shop1Cmms.Maintenance.PmExecution

    field :tenant_id, :integer

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(component, attrs) do
    component
    |> cast(attrs, [
      :name, :description, :component_type, :manufacturer,
      :model, :serial_number, :install_date, :status,
      :asset_id, :tenant_id
    ])
    |> validate_required([:name, :asset_id, :tenant_id])
    |> foreign_key_constraint(:asset_id)
  end
end
