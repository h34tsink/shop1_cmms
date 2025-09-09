defmodule Shop1Cmms.Assets.AssetType do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "asset_types" do
    field :name, :string
    field :description, :string
    field :code, :string
    field :category, :string
    field :icon, :string
    field :color, :string
    field :has_meters, :boolean, default: false
    field :has_components, :boolean, default: false
    field :default_pm_frequency, :integer
    # tenant_id provided via belongs_to :tenant

    # Associations
    has_many :assets, Shop1Cmms.Assets.Asset, foreign_key: :asset_type_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(asset_type, attrs) do
    asset_type
    |> cast(attrs, [:name, :description, :code, :category, :icon, :color,
                    :has_meters, :has_components, :default_pm_frequency, :tenant_id])
    |> validate_required([:name, :code, :category, :tenant_id])
    |> validate_length(:name, max: 255)
    |> validate_length(:code, max: 50)
    |> validate_format(:code, ~r/^[A-Z0-9_]+$/, message: "must be uppercase letters, numbers, or underscores only")
    |> validate_inclusion(:category, ["Equipment", "Tools", "Vehicles", "Infrastructure", "Facility", "IT", "Other"])
    |> validate_format(:color, ~r/^#[0-9A-Fa-f]{6}$/, message: "must be a valid hex color code")
    |> validate_number(:default_pm_frequency, greater_than: 0)
    |> unique_constraint([:tenant_id, :code], name: :asset_types_tenant_id_code_index)
  end

  def for_tenant(query, tenant_id) do
    from q in query, where: q.tenant_id == ^tenant_id
  end

  def by_category(query, category) do
    from q in query, where: q.category == ^category
  end

  def with_meters(query) do
    from q in query, where: q.has_meters == true
  end

  def with_components(query) do
    from q in query, where: q.has_components == true
  end
end
