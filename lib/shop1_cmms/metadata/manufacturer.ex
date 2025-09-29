defmodule Shop1Cmms.Metadata.Manufacturer do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "manufacturers" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :website, :string
    field :contact_email, :string
    field :contact_phone, :string
    field :address, :string
    field :notes, :string
    field :is_active, :boolean, default: true

    # Associations
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(manufacturer, attrs) do
    manufacturer
    |> cast(attrs, [:name, :code, :description, :website, :contact_email, :contact_phone, :address, :notes, :is_active, :tenant_id])
    |> validate_required([:name, :tenant_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:code, max: 50)
    |> validate_length(:description, max: 1000)
    |> validate_format(:contact_email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
    |> validate_format(:website, ~r/^https?:\/\//, message: "must be a valid URL starting with http:// or https://")
    |> unique_constraint([:tenant_id, :name], name: :manufacturers_tenant_name_index, message: "Manufacturer name already exists")
    |> unique_constraint([:tenant_id, :code], name: :manufacturers_tenant_code_index, message: "Manufacturer code already exists")
  end

  @doc """
  Query helpers for filtering manufacturers by tenant.
  """
  def by_tenant(query \\ __MODULE__, tenant_id) do
    from m in query, where: m.tenant_id == ^tenant_id
  end

  def active(query \\ __MODULE__) do
    from m in query, where: m.is_active == true
  end

  def search(query \\ __MODULE__, term) when is_binary(term) do
    search_term = "%#{term}%"
    from m in query,
      where: ilike(m.name, ^search_term) or
             ilike(m.code, ^search_term) or
             ilike(m.description, ^search_term)
  end

  def ordered(query \\ __MODULE__, order_by \\ :name) do
    from m in query, order_by: ^order_by
  end
end
