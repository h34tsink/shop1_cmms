defmodule Shop1Cmms.WorkOrders.WorkOrder do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @status_values [:open, :assigned, :in_progress, :on_hold, :completed, :cancelled]
  @priority_values [:low, :medium, :high, :urgent]
  @type_values [:corrective, :preventive, :emergency, :project]

  schema "work_orders" do
    field :work_order_number, :string
    field :title, :string
    field :description, :string
    field :status, Ecto.Enum, values: @status_values, default: :open
    field :priority, Ecto.Enum, values: @priority_values, default: :medium
    field :type, Ecto.Enum, values: @type_values, default: :corrective

    # Dates
    field :requested_date, :utc_datetime
    field :scheduled_start_date, :utc_datetime
    field :scheduled_end_date, :utc_datetime
    field :actual_start_date, :utc_datetime
    field :actual_end_date, :utc_datetime
    field :due_date, :utc_datetime

    # Users and Assignment (Note: These are integer foreign keys)
    field :requested_by, :integer
    field :assigned_to, :integer
    field :created_by, :integer
    field :updated_by, :integer

    # Asset and Location
    belongs_to :asset, Shop1Cmms.Assets.Asset, type: :binary_id
    field :location_description, :string

    # Costs and Labor
    field :estimated_hours, :decimal
    field :actual_hours, :decimal
    field :estimated_cost, :decimal
    field :actual_cost, :decimal

    # Additional Fields
    field :completion_notes, :string
    field :work_performed, :string
    field :failure_reason, :string
    field :parts_used, :map, default: %{}
    field :safety_notes, :string
    field :attachments, :map, default: %{}

    # Multi-tenancy (Note: This is an integer foreign key)
    field :tenant_id, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(work_order, attrs) do
    work_order
    |> cast(attrs, [
      :work_order_number, :title, :description, :status, :priority, :type,
      :requested_date, :scheduled_start_date, :scheduled_end_date,
      :actual_start_date, :actual_end_date, :due_date,
      :requested_by, :assigned_to, :created_by, :updated_by,
      :asset_id, :location_description,
      :estimated_hours, :actual_hours, :estimated_cost, :actual_cost,
      :completion_notes, :work_performed, :failure_reason,
      :parts_used, :safety_notes, :attachments,
      :tenant_id
    ])
    |> validate_required([:work_order_number, :title, :status, :priority, :type, :requested_date, :tenant_id])
    |> validate_inclusion(:status, @status_values)
    |> validate_inclusion(:priority, @priority_values)
    |> validate_inclusion(:type, @type_values)
    |> validate_length(:title, min: 3, max: 255)
    |> validate_length(:work_order_number, min: 1, max: 50)
    |> unique_constraint([:work_order_number, :tenant_id])
    |> validate_date_order()
    |> validate_positive_numbers()
  end

  defp validate_date_order(changeset) do
    scheduled_start = get_field(changeset, :scheduled_start_date)
    scheduled_end = get_field(changeset, :scheduled_end_date)
    actual_start = get_field(changeset, :actual_start_date)
    actual_end = get_field(changeset, :actual_end_date)

    changeset
    |> validate_date_pair(:scheduled_start_date, :scheduled_end_date, scheduled_start, scheduled_end)
    |> validate_date_pair(:actual_start_date, :actual_end_date, actual_start, actual_end)
  end

  defp validate_date_pair(changeset, start_field, end_field, start_date, end_date) do
    if start_date && end_date && DateTime.compare(start_date, end_date) == :gt do
      add_error(changeset, end_field, "must be after #{start_field}")
    else
      changeset
    end
  end

  defp validate_positive_numbers(changeset) do
    changeset
    |> validate_number(:estimated_hours, greater_than_or_equal_to: 0)
    |> validate_number(:actual_hours, greater_than_or_equal_to: 0)
    |> validate_number(:estimated_cost, greater_than_or_equal_to: 0)
    |> validate_number(:actual_cost, greater_than_or_equal_to: 0)
  end

  # Helper functions
  def status_values, do: @status_values
  def priority_values, do: @priority_values
  def type_values, do: @type_values

  def status_color(status) do
    case status do
      :open -> "bg-blue-100 text-blue-800"
      :assigned -> "bg-purple-100 text-purple-800"
      :in_progress -> "bg-yellow-100 text-yellow-800"
      :on_hold -> "bg-orange-100 text-orange-800"
      :completed -> "bg-green-100 text-green-800"
      :cancelled -> "bg-gray-100 text-gray-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  def priority_color(priority) do
    case priority do
      :low -> "bg-gray-100 text-gray-800"
      :medium -> "bg-blue-100 text-blue-800"
      :high -> "bg-orange-100 text-orange-800"
      :urgent -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  def type_color(type) do
    case type do
      :corrective -> "bg-red-100 text-red-800"
      :preventive -> "bg-green-100 text-green-800"
      :emergency -> "bg-red-200 text-red-900"
      :project -> "bg-blue-100 text-blue-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  # Filters for queries
  def by_status(query, status) when status in @status_values do
    where(query, [wo], wo.status == ^status)
  end
  def by_status(query, _), do: query

  def by_priority(query, priority) when priority in @priority_values do
    where(query, [wo], wo.priority == ^priority)
  end
  def by_priority(query, _), do: query

  def by_type(query, type) when type in @type_values do
    where(query, [wo], wo.type == ^type)
  end
  def by_type(query, _), do: query

  def by_assigned_to(query, user_id) when is_integer(user_id) do
    where(query, [wo], wo.assigned_to == ^user_id)
  end
  def by_assigned_to(query, _), do: query

  def by_asset(query, asset_id) when is_binary(asset_id) do
    where(query, [wo], wo.asset_id == ^asset_id)
  end
  def by_asset(query, _), do: query

  def overdue(query) do
    now = DateTime.utc_now()
    where(query, [wo], wo.due_date < ^now and wo.status not in [:completed, :cancelled])
  end

  def due_soon(query, hours \\ 24) do
    future = DateTime.add(DateTime.utc_now(), hours, :hour)
    where(query, [wo], wo.due_date <= ^future and wo.status not in [:completed, :cancelled])
  end

  def search_text(query, term) when is_binary(term) and term != "" do
    term = "%" <> String.downcase(term) <> "%"
    where(query, [wo],
      ilike(wo.title, ^term) or
      ilike(wo.description, ^term) or
      ilike(wo.work_order_number, ^term)
    )
  end
  def search_text(query, _), do: query
end
