defmodule Shop1Cmms.Assets.AssetMeter do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "asset_meters" do
    field :current_reading, :decimal, default: Decimal.new("0.0")
    field :last_reading_date, :utc_datetime
    field :reading_frequency, :integer
    field :next_reading_due, :date
    field :is_active, :boolean, default: true
  # tenant_id provided via belongs_to :tenant

    # Associations
    belongs_to :asset, Shop1Cmms.Assets.Asset, foreign_key: :asset_id
    belongs_to :meter_type, Shop1Cmms.Assets.MeterType, foreign_key: :meter_type_id
    has_many :meter_readings, Shop1Cmms.Assets.MeterReading, foreign_key: :asset_meter_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(asset_meter, attrs) do
    asset_meter
    |> cast(attrs, [:current_reading, :last_reading_date, :reading_frequency,
                    :next_reading_due, :is_active, :tenant_id, :asset_id, :meter_type_id])
    |> validate_required([:tenant_id, :asset_id, :meter_type_id])
    |> validate_number(:current_reading, greater_than_or_equal_to: 0)
    |> validate_number(:reading_frequency, greater_than: 0)
    |> validate_next_reading_due()
    |> unique_constraint([:asset_id, :meter_type_id], name: :asset_meters_asset_id_meter_type_id_index)
  end

  defp validate_next_reading_due(changeset) do
    case get_field(changeset, :next_reading_due) do
      nil -> changeset
      date ->
        if Date.compare(date, Date.utc_today()) == :lt do
          add_error(changeset, :next_reading_due, "cannot be in the past")
        else
          changeset
        end
    end
  end

  def calculate_next_reading_due(last_reading_date, frequency_days) do
    case {last_reading_date, frequency_days} do
      {nil, _} -> Date.utc_today()
      {_, nil} -> nil
      {date, freq} when is_integer(freq) and freq > 0 ->
        case date do
          %DateTime{} -> date |> DateTime.to_date() |> Date.add(freq)
          %Date{} -> Date.add(date, freq)
          _ -> Date.utc_today()
        end
      _ -> nil
    end
  end

  def for_tenant(query, tenant_id) do
    from q in query, where: q.tenant_id == ^tenant_id
  end

  def active(query) do
    from q in query, where: q.is_active == true
  end

  def for_asset(query, asset_id) do
    from q in query, where: q.asset_id == ^asset_id
  end

  def due_for_reading(query) do
    today = Date.utc_today()
    from q in query, where: q.next_reading_due <= ^today and q.is_active == true
  end

  def overdue_for_reading(query) do
    today = Date.utc_today()
    from q in query, where: q.next_reading_due < ^today and q.is_active == true
  end
end
