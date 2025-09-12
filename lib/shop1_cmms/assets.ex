defmodule Shop1Cmms.Assets do
  @moduledoc """
  The Assets context for managing physical assets, locations, and related data.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo

  alias Shop1Cmms.Assets.{
    Asset, AssetType, AssetLocation, AssetLocationType,
    MeterType, AssetMeter, MeterReading, AssetDocument
  }

  ## Asset Location Types

  @doc """
  Returns the list of asset location types for a tenant.
  """
  def list_asset_location_types(tenant_id) do
    AssetLocationType
    |> AssetLocationType.for_tenant(tenant_id)
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets a single asset location type.
  """
  def get_asset_location_type!(id), do: Repo.get!(AssetLocationType, id)

  @doc """
  Gets a single asset location type for a tenant.
  """
  def get_asset_location_type!(tenant_id, id) do
    AssetLocationType
    |> AssetLocationType.for_tenant(tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates an asset location type.
  """
  def create_asset_location_type(attrs \\ %{}) do
    %AssetLocationType{}
    |> AssetLocationType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an asset location type.
  """
  def update_asset_location_type(%AssetLocationType{} = location_type, attrs) do
    location_type
    |> AssetLocationType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an asset location type.
  """
  def delete_asset_location_type(%AssetLocationType{} = location_type) do
    Repo.delete(location_type)
  end

  ## Asset Locations

  @doc """
  Returns the list of asset locations for a tenant.
  """
  def list_asset_locations(tenant_id, opts \\ []) do
    query = AssetLocation
    |> AssetLocation.for_tenant(tenant_id)
    |> preload([:location_type, :parent_location])

    query = if opts[:active_only], do: AssetLocation.active(query), else: query
    query = if opts[:location_type_id], do: AssetLocation.by_location_type(query, opts[:location_type_id]), else: query

    query
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets a single asset location.
  """
  def get_asset_location!(id) do
    AssetLocation
    |> preload([:location_type, :parent_location, :child_locations])
    |> Repo.get!(id)
  end

  @doc """
  Gets a single asset location for a tenant.
  """
  def get_asset_location!(tenant_id, id) do
    AssetLocation
    |> AssetLocation.for_tenant(tenant_id)
    |> preload([:location_type, :parent_location, :child_locations])
    |> Repo.get!(id)
  end

  @doc """
  Creates an asset location.
  """
  def create_asset_location(attrs \\ %{}) do
    %AssetLocation{}
    |> AssetLocation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an asset location.
  """
  def update_asset_location(%AssetLocation{} = location, attrs) do
    location
    |> AssetLocation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an asset location.
  """
  def delete_asset_location(%AssetLocation{} = location) do
    Repo.delete(location)
  end

  ## Asset Types

  @doc """
  Returns the list of asset types for a tenant.
  """
  def list_asset_types(tenant_id, opts \\ []) do
    query = AssetType
    |> AssetType.for_tenant(tenant_id)

    query = if opts[:category], do: AssetType.by_category(query, opts[:category]), else: query
    query = if opts[:with_meters], do: AssetType.with_meters(query), else: query

    query
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets a single asset type.
  """
  def get_asset_type!(id), do: Repo.get!(AssetType, id)

  @doc """
  Gets a single asset type for a tenant.
  """
  def get_asset_type!(tenant_id, id) do
    AssetType
    |> AssetType.for_tenant(tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates an asset type.
  """
  def create_asset_type(attrs \\ %{}) do
    %AssetType{}
    |> AssetType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an asset type.
  """
  def update_asset_type(%AssetType{} = asset_type, attrs) do
    asset_type
    |> AssetType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an asset type.
  """
  def delete_asset_type(%AssetType{} = asset_type) do
    Repo.delete(asset_type)
  end

  ## Assets

  @doc """
  Returns the list of assets for a tenant.
  """
  def list_assets(tenant_id, opts \\ []) do
    query = Asset
    |> Asset.for_tenant(tenant_id)
    |> preload([:asset_type, :location, :parent_asset])

    query = if opts[:status], do: Asset.by_status(query, opts[:status]), else: query
    query = if opts[:criticality], do: Asset.by_criticality(query, opts[:criticality]), else: query
    query = if opts[:asset_type_id], do: Asset.by_asset_type(query, opts[:asset_type_id]), else: query
    query = if opts[:location_id], do: Asset.by_location(query, opts[:location_id]), else: query
    query = if opts[:search], do: Asset.search_by_name(query, opts[:search]), else: query

    query
    |> order_by(:asset_number)
    |> Repo.all()
  end

  @doc """
  Returns the list of assets with detailed information for the LiveView.
  """
  def list_assets_with_details(tenant_id, opts \\ []) do
    list_assets(tenant_id, opts)
  end

  @doc """
  Gets a single asset.
  """
  def get_asset!(id) do
    Asset
    |> preload([:asset_type, :location, :parent_asset, :child_assets, :asset_meters, :asset_documents])
    |> Repo.get!(id)
  end

  @doc """
  Gets a single asset for a tenant.
  """
  def get_asset!(tenant_id, id) do
    Asset
    |> Asset.for_tenant(tenant_id)
    |> preload([:asset_type, :location, :parent_asset, :child_assets, :asset_meters, :asset_documents])
    |> Repo.get!(id)
  end

  @doc """
  Gets a single asset with all details for the detail view.
  """
  def get_asset_with_details!(id, tenant_id) do
    Asset
    |> Asset.for_tenant(tenant_id)
    |> preload([:asset_type, :location, :parent_asset, :child_assets, :asset_meters, :asset_documents])
    |> Repo.get!(id)
  end

  @doc """
  Creates an asset.
  """
  def create_asset(attrs \\ %{}) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an asset.
  """
  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an asset.
  """
  def delete_asset(%Asset{} = asset) do
    Repo.delete(asset)
  end

  ## Meter Types

  @doc """
  Returns the list of meter types for a tenant.
  """
  def list_meter_types(tenant_id, opts \\ []) do
    query = MeterType
    |> MeterType.for_tenant(tenant_id)

    query = if opts[:data_type], do: MeterType.by_data_type(query, opts[:data_type]), else: query
    query = if opts[:cumulative_only], do: MeterType.cumulative(query), else: query

    query
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets a single meter type.
  """
  def get_meter_type!(id), do: Repo.get!(MeterType, id)

  @doc """
  Creates a meter type.
  """
  def create_meter_type(attrs \\ %{}) do
    %MeterType{}
    |> MeterType.changeset(attrs)
    |> Repo.insert()
  end

  ## Asset Meters

  @doc """
  Returns the list of asset meters for a tenant.
  """
  def list_asset_meters(tenant_id, opts \\ []) do
    query = AssetMeter
    |> AssetMeter.for_tenant(tenant_id)
    |> preload([:asset, :meter_type])

    query = if opts[:active_only], do: AssetMeter.active(query), else: query
    query = if opts[:asset_id], do: AssetMeter.for_asset(query, opts[:asset_id]), else: query
    query = if opts[:due_for_reading], do: AssetMeter.due_for_reading(query), else: query

    query
    |> Repo.all()
  end

  @doc """
  Gets a single asset meter.
  """
  def get_asset_meter!(id) do
    AssetMeter
    |> preload([:asset, :meter_type, :meter_readings])
    |> Repo.get!(id)
  end

  @doc """
  Creates an asset meter.
  """
  def create_asset_meter(attrs \\ %{}) do
    %AssetMeter{}
    |> AssetMeter.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an asset meter.
  """
  def update_asset_meter(%AssetMeter{} = asset_meter, attrs) do
    asset_meter
    |> AssetMeter.changeset(attrs)
    |> Repo.update()
  end

  ## Meter Readings

  @doc """
  Returns the list of meter readings for a tenant.
  """
  def list_meter_readings(tenant_id, opts \\ []) do
    query = MeterReading
    |> MeterReading.for_tenant(tenant_id)
    |> preload([:asset_meter, :recorded_by])

    query = if opts[:asset_meter_id], do: MeterReading.for_asset_meter(query, opts[:asset_meter_id]), else: query
    query = if opts[:reading_type], do: MeterReading.by_reading_type(query, opts[:reading_type]), else: query

    query = if opts[:start_date] && opts[:end_date] do
      MeterReading.in_date_range(query, opts[:start_date], opts[:end_date])
    else
      query
    end

    query
    |> MeterReading.recent_first()
    |> Repo.all()
  end

  @doc """
  Creates a meter reading and updates the asset meter.
  """
  def create_meter_reading(attrs \\ %{}) do
    Repo.transaction(fn ->
      with {:ok, reading} <- %MeterReading{}
                             |> MeterReading.changeset(attrs)
                             |> Repo.insert(),
           {:ok, _updated_meter} <- update_asset_meter_from_reading(reading) do
        reading
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp update_asset_meter_from_reading(%MeterReading{} = reading) do
    asset_meter = Repo.get!(AssetMeter, reading.asset_meter_id)

    next_due = AssetMeter.calculate_next_reading_due(reading.reading_date, asset_meter.reading_frequency)

    update_asset_meter(asset_meter, %{
      current_reading: reading.reading,
      last_reading_date: reading.reading_date,
      next_reading_due: next_due
    })
  end

  ## Asset Documents

  @doc """
  Returns the list of asset documents for a tenant.
  """
  def list_asset_documents(tenant_id, opts \\ []) do
    query = AssetDocument
    |> AssetDocument.for_tenant(tenant_id)
    |> preload([:asset, :uploaded_by])

    query = if opts[:asset_id], do: AssetDocument.for_asset(query, opts[:asset_id]), else: query
    query = if opts[:document_type], do: AssetDocument.by_document_type(query, opts[:document_type]), else: query

    query
    |> AssetDocument.recent_first()
    |> Repo.all()
  end

  @doc """
  Creates an asset document.
  """
  def create_asset_document(attrs \\ %{}) do
    %AssetDocument{}
    |> AssetDocument.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes an asset document.
  """
  def delete_asset_document(%AssetDocument{} = document) do
    Repo.delete(document)
  end

  ## Utility Functions

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset changes.
  """
  def change_asset(%Asset{} = asset, attrs \\ %{}) do
    Asset.changeset(asset, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset location changes.
  """
  def change_asset_location(%AssetLocation{} = location, attrs \\ %{}) do
    AssetLocation.changeset(location, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset type changes.
  """
  def change_asset_type(%AssetType{} = asset_type, attrs \\ %{}) do
    AssetType.changeset(asset_type, attrs)
  end

  @doc """
  Returns summary statistics for assets in a tenant.
  """
  def get_asset_stats(tenant_id) do
    base_query = Asset |> Asset.for_tenant(tenant_id)

    %{
      total_assets: Repo.aggregate(base_query, :count),
      operational: Repo.aggregate(Asset.operational(base_query), :count),
      needs_maintenance: Repo.aggregate(Asset.needs_maintenance(base_query), :count),
      by_criticality: get_asset_counts_by_criticality(tenant_id),
      by_status: get_asset_counts_by_status(tenant_id)
    }
  end

  defp get_asset_counts_by_criticality(tenant_id) do
    Asset
    |> Asset.for_tenant(tenant_id)
    |> group_by(:criticality)
    |> select([a], {a.criticality, count(a.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end

  defp get_asset_counts_by_status(tenant_id) do
    Asset
    |> Asset.for_tenant(tenant_id)
    |> group_by(:status)
    |> select([a], {a.status, count(a.id)})
    |> Repo.all()
    |> Enum.into(%{})
  end
end
