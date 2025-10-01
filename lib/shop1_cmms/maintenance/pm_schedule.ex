defmodule Shop1Cmms.Maintenance.PmSchedule do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @frequency_values [:daily, :weekly, :biweekly, :monthly, :quarterly, :semiannual, :annual, :biennial, :meter_based, :condition_based]

  schema "pm_schedules" do
    field :schedule_number, :string
    field :title, :string
    field :description, :string
    
    # Scheduling
    field :frequency, Ecto.Enum, values: @frequency_values
    field :frequency_interval, :integer, default: 1
    field :meter_threshold, :decimal
    field :meter_unit, :string
    
    # Work Instructions
    field :work_instructions, :string
    field :estimated_duration, :decimal
    field :required_skills, {:array, :string}, default: []
    field :required_tools, {:array, :string}, default: []
    field :required_parts, :map, default: %{}
    
    # Safety
    field :safety_notes, :string
    field :ppe_required, {:array, :string}, default: []
    
    # Scheduling info
    field :last_completed_date, :utc_datetime
    field :next_due_date, :utc_datetime
    field :is_active, :boolean, default: true
    
    # References
    belongs_to :asset, Shop1Cmms.Assets.Asset, type: :binary_id
    field :created_by, :integer
    field :updated_by, :integer
    
    # Associations
    has_many :components, Shop1Cmms.Maintenance.PmScheduleComponent
    has_many :checklist_items, Shop1Cmms.Maintenance.PmChecklistItem
    has_many :documents, Shop1Cmms.Maintenance.AssetDocument
    
    # Multi-tenancy
    field :tenant_id, :integer
    
    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(pm_schedule, attrs) do
    pm_schedule
    |> cast(attrs, [
      :schedule_number, :title, :description,
      :frequency, :frequency_interval, :meter_threshold, :meter_unit,
      :work_instructions, :estimated_duration, :required_skills, :required_tools, :required_parts,
      :safety_notes, :ppe_required,
      :last_completed_date, :next_due_date, :is_active,
      :asset_id, :created_by, :updated_by, :tenant_id
    ])
    |> validate_required([:schedule_number, :title, :frequency, :asset_id, :tenant_id])
    |> validate_inclusion(:frequency, @frequency_values)
    |> validate_length(:title, min: 3, max: 255)
    |> validate_length(:schedule_number, min: 1, max: 50)
    |> validate_number(:frequency_interval, greater_than: 0)
    |> validate_number(:estimated_duration, greater_than_or_equal_to: 0)
    |> unique_constraint([:schedule_number, :tenant_id])
    |> validate_meter_based_fields()
  end

  defp validate_meter_based_fields(changeset) do
    frequency = get_field(changeset, :frequency)
    
    if frequency == :meter_based do
      changeset
      |> validate_required([:meter_threshold, :meter_unit])
      |> validate_number(:meter_threshold, greater_than: 0)
    else
      changeset
    end
  end

  # Helper functions
  def frequency_values, do: @frequency_values
  
  def frequency_label(frequency) do
    case frequency do
      :daily -> "Daily"
      :weekly -> "Weekly"
      :biweekly -> "Bi-Weekly"
      :monthly -> "Monthly"
      :quarterly -> "Quarterly"
      :semiannual -> "Semi-Annual"
      :annual -> "Annual"
      :biennial -> "Biennial"
      :meter_based -> "Meter Based"
      :condition_based -> "Condition Based"
      _ -> to_string(frequency)
    end
  end

  def status_color(is_active) do
    if is_active, do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800"
  end

  # Query helpers
  def active(query \\ __MODULE__) do
    from pm in query, where: pm.is_active == true
  end

  def for_asset(query \\ __MODULE__, asset_id) do
    from pm in query, where: pm.asset_id == ^asset_id
  end

  def due_soon(query \\ __MODULE__, days \\ 30) do
    future = DateTime.add(DateTime.utc_now(), days * 24 * 60 * 60, :second)
    from pm in query, 
      where: pm.next_due_date <= ^future and pm.is_active == true,
      order_by: [asc: pm.next_due_date]
  end

  def overdue(query \\ __MODULE__) do
    now = DateTime.utc_now()
    from pm in query, 
      where: pm.next_due_date < ^now and pm.is_active == true,
      order_by: [asc: pm.next_due_date]
  end

  def by_frequency(query \\ __MODULE__, frequency) when frequency in @frequency_values do
    from pm in query, where: pm.frequency == ^frequency
  end
  def by_frequency(query, _), do: query

  def search_text(query \\ __MODULE__, term) when is_binary(term) and term != "" do
    term = "%" <> String.downcase(term) <> "%"
    from pm in query,
      where: ilike(pm.title, ^term) or
             ilike(pm.description, ^term) or
             ilike(pm.schedule_number, ^term)
  end
  def search_text(query, _), do: query
end
