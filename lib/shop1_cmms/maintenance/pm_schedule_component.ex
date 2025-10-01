defmodule Shop1Cmms.Maintenance.PmScheduleComponent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pm_schedule_components" do
    field :component_name, :string
    field :component_description, :string
    field :component_location, :string
    
    belongs_to :pm_schedule, Shop1Cmms.Maintenance.PmSchedule, type: :binary_id
    field :tenant_id, :integer
    
    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(component, attrs) do
    component
    |> cast(attrs, [:component_name, :component_description, :component_location, :pm_schedule_id, :tenant_id])
    |> validate_required([:component_name, :pm_schedule_id, :tenant_id])
    |> validate_length(:component_name, min: 2, max: 255)
  end
end
