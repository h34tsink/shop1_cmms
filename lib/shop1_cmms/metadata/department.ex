defmodule Shop1Cmms.Metadata.Department do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "departments" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :manager_name, :string
    field :manager_email, :string
    field :cost_center, :string
    field :budget_code, :string
    field :is_active, :boolean, default: true

    # Associations
    belongs_to :parent_department, __MODULE__, foreign_key: :parent_department_id
    has_many :child_departments, __MODULE__, foreign_key: :parent_department_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(department, attrs) do
    department
    |> cast(attrs, [:name, :code, :description, :manager_name, :manager_email, :cost_center, :budget_code, :parent_department_id, :is_active, :tenant_id])
    |> validate_required([:name, :tenant_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:code, max: 50)
    |> validate_length(:description, max: 1000)
    |> validate_format(:manager_email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
    |> validate_no_parent_loop()
    |> unique_constraint([:tenant_id, :name], name: :departments_tenant_name_index, message: "Department name already exists")
    |> unique_constraint([:tenant_id, :code], name: :departments_tenant_code_index, message: "Department code already exists")
  end

  defp validate_no_parent_loop(changeset) do
    parent_id = get_field(changeset, :parent_department_id)
    department_id = get_field(changeset, :id)

    if parent_id && department_id && parent_id == department_id do
      add_error(changeset, :parent_department_id, "Department cannot be its own parent")
    else
      changeset
    end
  end

  @doc """
  Query helpers for filtering departments by tenant.
  """
  def by_tenant(query \\ __MODULE__, tenant_id) do
    from d in query, where: d.tenant_id == ^tenant_id
  end

  def active(query \\ __MODULE__) do
    from d in query, where: d.is_active == true
  end

  def root_departments(query \\ __MODULE__) do
    from d in query, where: is_nil(d.parent_department_id)
  end

  def with_parent(query \\ __MODULE__) do
    from d in query, preload: [:parent_department]
  end

  def with_children(query \\ __MODULE__) do
    from d in query, preload: [:child_departments]
  end

  def search(query \\ __MODULE__, term) when is_binary(term) do
    search_term = "%#{term}%"
    from d in query,
      where: ilike(d.name, ^search_term) or
             ilike(d.code, ^search_term) or
             ilike(d.description, ^search_term) or
             ilike(d.manager_name, ^search_term)
  end

  def ordered(query \\ __MODULE__, order_by \\ :name) do
    from d in query, order_by: ^order_by
  end
end
