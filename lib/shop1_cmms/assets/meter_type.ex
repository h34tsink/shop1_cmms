defmodule Shop1Cmms.Assets.MeterType do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "meter_types" do
    field :name, :string
    field :description, :string
    field :unit, :string
    field :data_type, :string, default: "integer"
    field :is_cumulative, :boolean, default: true
    field :tenant_id, :integer

    # Associations
    has_many :asset_meters, Shop1Cmms.Assets.AssetMeter, foreign_key: :meter_type_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(meter_type, attrs) do
    meter_type
    |> cast(attrs, [:name, :description, :unit, :data_type, :is_cumulative, :tenant_id])
    |> validate_required([:name, :unit, :data_type, :tenant_id])
    |> validate_length(:name, max: 255)
    |> validate_length(:unit, max: 50)
    |> validate_inclusion(:data_type, ["integer", "decimal", "counter"])
    |> unique_constraint([:tenant_id, :name], name: :meter_types_tenant_id_name_index)
  end

  def for_tenant(query, tenant_id) do
    from q in query, where: q.tenant_id == ^tenant_id
  end

  def by_data_type(query, data_type) do
    from q in query, where: q.data_type == ^data_type
  end

  def cumulative(query) do
    from q in query, where: q.is_cumulative == true
  end
end
