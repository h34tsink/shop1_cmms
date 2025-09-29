defmodule Shop1Cmms.Metadata.PriorityCode do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "priority_codes" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :level, :integer
    field :color, :string
    field :sla_hours, :integer
    field :auto_escalate, :boolean, default: false
    field :escalation_hours, :integer
    field :is_active, :boolean, default: true

    # Associations
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(priority_code, attrs) do
    priority_code
    |> cast(attrs, [:name, :code, :description, :level, :color, :sla_hours, :auto_escalate, :escalation_hours, :is_active, :tenant_id])
    |> validate_required([:name, :level, :tenant_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:code, max: 50)
    |> validate_length(:description, max: 1000)
    |> validate_number(:level, greater_than: 0, less_than_or_equal_to: 10)
    |> validate_format(:color, ~r/^#[0-9A-Fa-f]{6}$/, message: "must be a valid hex color code (e.g., #FF0000)")
    |> validate_number(:sla_hours, greater_than: 0)
    |> validate_number(:escalation_hours, greater_than: 0)
    |> validate_escalation_consistency()
    |> unique_constraint([:tenant_id, :name], name: :priority_codes_tenant_name_index, message: "Priority name already exists")
    |> unique_constraint([:tenant_id, :code], name: :priority_codes_tenant_code_index, message: "Priority code already exists")
    |> unique_constraint([:tenant_id, :level], name: :priority_codes_tenant_level_index, message: "Priority level already exists")
  end

  defp validate_escalation_consistency(changeset) do
    auto_escalate = get_field(changeset, :auto_escalate)
    escalation_hours = get_field(changeset, :escalation_hours)

    cond do
      auto_escalate && is_nil(escalation_hours) ->
        add_error(changeset, :escalation_hours, "must be specified when auto escalation is enabled")

      !auto_escalate && escalation_hours ->
        add_error(changeset, :escalation_hours, "should not be set when auto escalation is disabled")

      true ->
        changeset
    end
  end

  @doc """
  Query helpers for filtering priority codes by tenant.
  """
  def by_tenant(query \\ __MODULE__, tenant_id) do
    from p in query, where: p.tenant_id == ^tenant_id
  end

  def active(query \\ __MODULE__) do
    from p in query, where: p.is_active == true
  end

  def by_level_range(query \\ __MODULE__, min_level, max_level) do
    from p in query, where: p.level >= ^min_level and p.level <= ^max_level
  end

  def with_escalation(query \\ __MODULE__) do
    from p in query, where: p.auto_escalate == true
  end

  def search(query \\ __MODULE__, term) when is_binary(term) do
    search_term = "%#{term}%"
    from p in query,
      where: ilike(p.name, ^search_term) or
             ilike(p.code, ^search_term) or
             ilike(p.description, ^search_term)
  end

  def ordered(query \\ __MODULE__, order_by \\ :level) do
    from p in query, order_by: ^order_by
  end

  def ordered_by_level(query \\ __MODULE__) do
    from p in query, order_by: [asc: :level]
  end
end
