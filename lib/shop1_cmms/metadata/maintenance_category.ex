defmodule Shop1Cmms.Metadata.MaintenanceCategory do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @maintenance_types ~w(preventive corrective predictive emergency condition_based)

  schema "maintenance_categories" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :type, :string
    field :default_frequency_days, :integer
    field :requires_shutdown, :boolean, default: false
    field :skill_requirements, :string
    field :safety_requirements, :string
    field :is_active, :boolean, default: true

    # Associations
    belongs_to :parent_category, __MODULE__, foreign_key: :parent_category_id
    has_many :child_categories, __MODULE__, foreign_key: :parent_category_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(maintenance_category, attrs) do
    maintenance_category
    |> cast(attrs, [:name, :code, :description, :type, :default_frequency_days, :requires_shutdown, :skill_requirements, :safety_requirements, :parent_category_id, :is_active, :tenant_id])
    |> validate_required([:name, :type, :tenant_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:code, max: 50)
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:type, @maintenance_types, message: "must be one of: #{Enum.join(@maintenance_types, ", ")}")
    |> validate_number(:default_frequency_days, greater_than: 0)
    |> validate_no_parent_loop()
    |> unique_constraint([:tenant_id, :name], name: :maintenance_categories_tenant_name_index, message: "Maintenance category name already exists")
    |> unique_constraint([:tenant_id, :code], name: :maintenance_categories_tenant_code_index, message: "Maintenance category code already exists")
  end

  defp validate_no_parent_loop(changeset) do
    parent_id = get_field(changeset, :parent_category_id)
    category_id = get_field(changeset, :id)

    if parent_id && category_id && parent_id == category_id do
      add_error(changeset, :parent_category_id, "Category cannot be its own parent")
    else
      changeset
    end
  end

  @doc """
  Returns available maintenance types.
  """
  def maintenance_types, do: @maintenance_types

  @doc """
  Query helpers for filtering maintenance categories by tenant.
  """
  def by_tenant(query \\ __MODULE__, tenant_id) do
    from mc in query, where: mc.tenant_id == ^tenant_id
  end

  def active(query \\ __MODULE__) do
    from mc in query, where: mc.is_active == true
  end

  def by_type(query \\ __MODULE__, type) when type in @maintenance_types do
    from mc in query, where: mc.type == ^type
  end

  def root_categories(query \\ __MODULE__) do
    from mc in query, where: is_nil(mc.parent_category_id)
  end

  def with_parent(query \\ __MODULE__) do
    from mc in query, preload: [:parent_category]
  end

  def with_children(query \\ __MODULE__) do
    from mc in query, preload: [:child_categories]
  end

  def requires_shutdown(query \\ __MODULE__) do
    from mc in query, where: mc.requires_shutdown == true
  end

  def with_frequency(query \\ __MODULE__) do
    from mc in query, where: not is_nil(mc.default_frequency_days)
  end

  def search(query \\ __MODULE__, term) when is_binary(term) do
    search_term = "%#{term}%"
    from mc in query,
      where: ilike(mc.name, ^search_term) or
             ilike(mc.code, ^search_term) or
             ilike(mc.description, ^search_term) or
             ilike(mc.skill_requirements, ^search_term)
  end

  def ordered(query \\ __MODULE__, order_by \\ :name) do
    from mc in query, order_by: ^order_by
  end
end
