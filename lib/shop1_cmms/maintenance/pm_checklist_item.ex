defmodule Shop1Cmms.Maintenance.PmChecklistItem do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pm_checklist_items" do
    field :sequence, :integer
    field :item_description, :string
    field :expected_result, :string
    field :pass_fail, :boolean, default: false
    field :requires_measurement, :boolean, default: false
    field :measurement_unit, :string
    field :min_value, :decimal
    field :max_value, :decimal
    
    belongs_to :pm_schedule, Shop1Cmms.Maintenance.PmSchedule, type: :binary_id
    field :tenant_id, :integer
    
    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(checklist_item, attrs) do
    checklist_item
    |> cast(attrs, [
      :sequence, :item_description, :expected_result, :pass_fail,
      :requires_measurement, :measurement_unit, :min_value, :max_value,
      :pm_schedule_id, :tenant_id
    ])
    |> validate_required([:sequence, :item_description, :pm_schedule_id, :tenant_id])
    |> validate_number(:sequence, greater_than_or_equal_to: 1)
    |> validate_length(:item_description, min: 3, max: 500)
    |> validate_measurement_fields()
  end

  defp validate_measurement_fields(changeset) do
    requires_measurement = get_field(changeset, :requires_measurement)
    
    if requires_measurement do
      changeset
      |> validate_required([:measurement_unit])
    else
      changeset
    end
  end

  # Query helpers
  def for_schedule(query \\ __MODULE__, schedule_id) do
    from item in query,
      where: item.pm_schedule_id == ^schedule_id,
      order_by: [asc: item.sequence]
  end
end
