defmodule Shop1Cmms.Assets.AssetLocation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "asset_locations" do
    field :name, :string
    field :description, :string
    field :code, :string
    field :address, :string
    field :gps_coordinates, :string
    field :area_size, :decimal
    field :area_unit, :string, default: "sqft"
    field :is_active, :boolean, default: true
    # tenant_id provided via belongs_to :tenant

    # Associations
    belongs_to :parent_location, __MODULE__, foreign_key: :parent_location_id
    has_many :child_locations, __MODULE__, foreign_key: :parent_location_id
    belongs_to :location_type, Shop1Cmms.Assets.AssetLocationType, foreign_key: :location_type_id
    has_many :assets, Shop1Cmms.Assets.Asset, foreign_key: :location_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(asset_location, attrs) do
    asset_location
    |> cast(attrs, [:name, :description, :code, :address, :gps_coordinates, :area_size,
                    :area_unit, :is_active, :tenant_id, :parent_location_id, :location_type_id])
    |> validate_required([:name, :code, :tenant_id, :location_type_id])
    |> validate_length(:name, max: 255)
    |> validate_length(:code, max: 50)
    |> validate_format(:code, ~r/^[A-Z0-9_-]+$/, message: "must be uppercase letters, numbers, hyphens, or underscores only")
    |> validate_inclusion(:area_unit, ["sqft", "sqm", "acres", "hectares"])
    |> validate_number(:area_size, greater_than: 0)
    |> validate_gps_coordinates()
    |> prevent_circular_reference()
    |> unique_constraint([:tenant_id, :code], name: :asset_locations_tenant_id_code_index)
  end

  defp validate_gps_coordinates(changeset) do
    case get_field(changeset, :gps_coordinates) do
      nil -> changeset
      coords ->
        case String.split(coords, ",") do
          [lat_str, lng_str] ->
            with {lat, ""} <- Float.parse(String.trim(lat_str)),
                 {lng, ""} <- Float.parse(String.trim(lng_str)),
                 true <- lat >= -90 and lat <= 90,
                 true <- lng >= -180 and lng <= 180 do
              changeset
            else
              _ -> add_error(changeset, :gps_coordinates, "must be valid latitude,longitude format")
            end
          _ -> add_error(changeset, :gps_coordinates, "must be in latitude,longitude format")
        end
    end
  end

  defp prevent_circular_reference(changeset) do
    parent_id = get_field(changeset, :parent_location_id)
    current_id = get_field(changeset, :id)

    cond do
      is_nil(parent_id) -> changeset
      parent_id == current_id -> add_error(changeset, :parent_location_id, "cannot be self")
      true -> changeset # TODO: Add deeper circular reference check if needed
    end
  end

  def for_tenant(query, tenant_id) do
    from q in query, where: q.tenant_id == ^tenant_id
  end

  def active(query) do
    from q in query, where: q.is_active == true
  end

  def by_location_type(query, location_type_id) do
    from q in query, where: q.location_type_id == ^location_type_id
  end
end
