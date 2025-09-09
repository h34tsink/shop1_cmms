defmodule Shop1Cmms.Assets.AssetLocationType do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "asset_location_types" do
    field :name, :string
    field :description, :string
    field :code, :string
    field :icon, :string
    field :color, :string
  # tenant_id provided by belongs_to :tenant

    # Associations
    has_many :asset_locations, Shop1Cmms.Assets.AssetLocation, foreign_key: :location_type_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(asset_location_type, attrs) do
    asset_location_type
    |> cast(attrs, [:name, :description, :code, :icon, :color, :tenant_id])
    |> validate_required([:name, :code, :tenant_id])
    |> validate_length(:name, max: 255)
    |> validate_length(:code, max: 50)
    |> validate_format(:code, ~r/^[A-Z0-9_]+$/, message: "must be uppercase letters, numbers, or underscores only")
    |> validate_format(:color, ~r/^#[0-9A-Fa-f]{6}$/, message: "must be a valid hex color code")
    |> unique_constraint([:tenant_id, :code], name: :asset_location_types_tenant_id_code_index)
  end

  def for_tenant(query, tenant_id), do: from(q in query, where: q.tenant_id == ^tenant_id)
end
