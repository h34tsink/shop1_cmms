defmodule Shop1Cmms.Metadata.Supplier do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @supplier_types ~w(vendor contractor service_provider)

  schema "suppliers" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :type, :string
    field :contact_name, :string
    field :contact_email, :string
    field :contact_phone, :string
    field :address, :string
    field :website, :string
    field :tax_id, :string
    field :payment_terms, :string
    field :credit_rating, :string
    field :notes, :string
    field :is_active, :boolean, default: true

    # Associations
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(supplier, attrs) do
    supplier
    |> cast(attrs, [:name, :code, :description, :type, :contact_name, :contact_email, :contact_phone, :address, :website, :tax_id, :payment_terms, :credit_rating, :notes, :is_active, :tenant_id])
    |> validate_required([:name, :tenant_id])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:code, max: 50)
    |> validate_length(:description, max: 1000)
    |> validate_inclusion(:type, @supplier_types, message: "must be one of: #{Enum.join(@supplier_types, ", ")}")
    |> validate_format(:contact_email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email address")
    |> validate_format(:website, ~r/^https?:\/\//, message: "must be a valid URL starting with http:// or https://")
    |> unique_constraint([:tenant_id, :name], name: :suppliers_tenant_name_index, message: "Supplier name already exists")
    |> unique_constraint([:tenant_id, :code], name: :suppliers_tenant_code_index, message: "Supplier code already exists")
  end

  @doc """
  Returns available supplier types.
  """
  def supplier_types, do: @supplier_types

  @doc """
  Query helpers for filtering suppliers by tenant.
  """
  def by_tenant(query \\ __MODULE__, tenant_id) do
    from s in query, where: s.tenant_id == ^tenant_id
  end

  def active(query \\ __MODULE__) do
    from s in query, where: s.is_active == true
  end

  def by_type(query \\ __MODULE__, type) when type in @supplier_types do
    from s in query, where: s.type == ^type
  end

  def search(query \\ __MODULE__, term) when is_binary(term) do
    search_term = "%#{term}%"
    from s in query,
      where: ilike(s.name, ^search_term) or
             ilike(s.code, ^search_term) or
             ilike(s.description, ^search_term) or
             ilike(s.contact_name, ^search_term)
  end

  def ordered(query \\ __MODULE__, order_by \\ :name) do
    from s in query, order_by: ^order_by
  end
end
