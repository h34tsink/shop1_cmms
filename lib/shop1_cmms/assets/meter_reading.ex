defmodule Shop1Cmms.Assets.MeterReading do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "meter_readings" do
    field :reading, :decimal
    field :reading_date, :utc_datetime
    field :reading_type, :string, default: "manual"
    field :notes, :string
    field :tenant_id, :integer
    field :recorded_by_id, :integer

    # Associations
    belongs_to :recorded_by, Shop1Cmms.Accounts.User, foreign_key: :recorded_by_id, type: :integer
    belongs_to :asset_meter, Shop1Cmms.Assets.AssetMeter, foreign_key: :asset_meter_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(meter_reading, attrs) do
    meter_reading
    |> cast(attrs, [:reading, :reading_date, :reading_type, :notes,
                    :tenant_id, :recorded_by, :asset_meter_id])
    |> validate_required([:reading, :reading_date, :tenant_id, :asset_meter_id])
    |> validate_number(:reading, greater_than_or_equal_to: 0)
    |> validate_inclusion(:reading_type, ["manual", "automatic", "estimated"])
    |> validate_reading_date()
    |> validate_reading_progression()
  end

  defp validate_reading_date(changeset) do
    case get_field(changeset, :reading_date) do
      nil -> changeset
      reading_datetime ->
        now = DateTime.utc_now()
        if DateTime.compare(reading_datetime, now) == :gt do
          add_error(changeset, :reading_date, "cannot be in the future")
        else
          changeset
        end
    end
  end

  defp validate_reading_progression(changeset) do
    # This would typically check against the asset meter's last reading
    # to ensure cumulative readings are increasing
    # For now, we'll add a basic validation
    reading = get_field(changeset, :reading)

    if reading && Decimal.compare(reading, Decimal.new("0")) == :lt do
      add_error(changeset, :reading, "cannot be negative")
    else
      changeset
    end
  end

  def for_tenant(query, tenant_id) do
    from q in query, where: q.tenant_id == ^tenant_id
  end

  def for_asset_meter(query, asset_meter_id) do
    from q in query, where: q.asset_meter_id == ^asset_meter_id
  end

  def by_reading_type(query, reading_type) do
    from q in query, where: q.reading_type == ^reading_type
  end

  def recent_first(query) do
    from q in query, order_by: [desc: q.reading_date]
  end

  def in_date_range(query, start_date, end_date) do
    from q in query,
      where: q.reading_date >= ^start_date and q.reading_date <= ^end_date
  end
end
