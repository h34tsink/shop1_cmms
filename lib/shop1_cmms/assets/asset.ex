defmodule Shop1Cmms.Assets.Asset do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "assets" do
    field :asset_number, :string
    field :name, :string
    field :description, :string
    field :manufacturer, :string
    field :model, :string
    field :serial_number, :string
    field :barcode, :string
    field :qr_code, :string
    field :purchase_date, :date
    field :purchase_cost, :decimal
    field :warranty_expiry, :date
    field :install_date, :date
    field :commission_date, :date
    field :status, Ecto.Enum, values: [:operational, :maintenance, :repair, :retired, :disposed], default: :operational
    field :criticality, Ecto.Enum, values: [:low, :medium, :high, :critical], default: :medium
    field :specifications, :map
    field :notes, :string
  # tenant_id field comes from belongs_to :tenant; explicit field removed to avoid duplication

    # Associations
    belongs_to :parent_asset, __MODULE__, foreign_key: :parent_asset_id
    has_many :child_assets, __MODULE__, foreign_key: :parent_asset_id
    belongs_to :location, Shop1Cmms.Assets.AssetLocation, foreign_key: :location_id
    belongs_to :asset_type, Shop1Cmms.Assets.AssetType, foreign_key: :asset_type_id
    has_many :asset_meters, Shop1Cmms.Assets.AssetMeter, foreign_key: :asset_id
    has_many :asset_documents, Shop1Cmms.Assets.AssetDocument, foreign_key: :asset_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(asset, attrs) do
    asset
    |> cast(attrs, [:asset_number, :name, :description, :manufacturer, :model, :serial_number,
                    :barcode, :qr_code, :purchase_date, :purchase_cost, :warranty_expiry,
                    :install_date, :commission_date, :status, :criticality, :specifications,
                    :notes, :tenant_id, :parent_asset_id, :location_id, :asset_type_id])
    |> validate_required([:asset_number, :name, :tenant_id, :asset_type_id, :status, :criticality])
    |> validate_length(:asset_number, max: 100)
    |> validate_length(:name, max: 255)
    |> validate_length(:serial_number, max: 100)
    |> validate_length(:barcode, max: 100)
    |> validate_length(:qr_code, max: 100)
    |> validate_number(:purchase_cost, greater_than: 0)
    |> validate_date_order()
    |> prevent_circular_reference()
    |> unique_constraint([:tenant_id, :asset_number], name: :assets_tenant_id_asset_number_index)
    |> unique_constraint(:serial_number, name: :assets_serial_number_index)
    |> unique_constraint(:barcode, name: :assets_barcode_index)
  end

  defp validate_date_order(changeset) do
    purchase_date = get_field(changeset, :purchase_date)
    install_date = get_field(changeset, :install_date)
    commission_date = get_field(changeset, :commission_date)
    warranty_expiry = get_field(changeset, :warranty_expiry)

    changeset
    |> validate_date_not_future(:purchase_date)
    |> validate_date_not_future(:install_date)
    |> validate_date_not_future(:commission_date)
    |> validate_date_after(:install_date, purchase_date, "install date must be after purchase date")
    |> validate_date_after(:commission_date, install_date, "commission date must be after install date")
    |> validate_date_after(:warranty_expiry, purchase_date, "warranty expiry must be after purchase date")
  end

  defp validate_date_not_future(changeset, field) do
    case get_field(changeset, field) do
      nil -> changeset
      date ->
        if Date.compare(date, Date.utc_today()) == :gt do
          add_error(changeset, field, "cannot be in the future")
        else
          changeset
        end
    end
  end

  defp validate_date_after(changeset, field, reference_date, message) do
    case {get_field(changeset, field), reference_date} do
      {nil, _} -> changeset
      {_, nil} -> changeset
      {date, ref_date} ->
        if Date.compare(date, ref_date) == :lt do
          add_error(changeset, field, message)
        else
          changeset
        end
    end
  end

  defp prevent_circular_reference(changeset) do
    parent_id = get_field(changeset, :parent_asset_id)
    current_id = get_field(changeset, :id)

    cond do
      is_nil(parent_id) -> changeset
      parent_id == current_id -> add_error(changeset, :parent_asset_id, "cannot be self")
      true -> changeset # TODO: Add deeper circular reference check if needed
    end
  end

  def for_tenant(query, tenant_id), do: from(q in query, where: q.tenant_id == ^tenant_id)
  def by_status(query, status), do: from(q in query, where: q.status == ^status)
  def by_criticality(query, criticality), do: from(q in query, where: q.criticality == ^criticality)
  def by_asset_type(query, asset_type_id), do: from(q in query, where: q.asset_type_id == ^asset_type_id)
  def by_location(query, location_id), do: from(q in query, where: q.location_id == ^location_id)
  def operational(query), do: from(q in query, where: q.status == :operational)
  def needs_maintenance(query), do: from(q in query, where: q.status in [:maintenance, :repair])
  def search_by_name(query, search_term) do
    pattern = "%#{search_term}%"
    from(q in query,
      where: ilike(q.name, ^pattern) or ilike(q.asset_number, ^pattern) or ilike(q.serial_number, ^pattern)
    )
  end
end
