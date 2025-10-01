defmodule Shop1Cmms.AssetsFixtures do
  @moduledoc """
  This module defines test fixtures for Assets context.
  """

  alias Shop1Cmms.Assets
  alias Shop1Cmms.Repo

  @doc """
  Generate an asset type.
  """
  def asset_type_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"

    {:ok, asset_type} =
      attrs
      |> Enum.into(%{
        name: "Test Asset Type",
        code: "TEST_TYPE_#{System.unique_integer([:positive])}",
        description: "Test asset type description",
        category: "Equipment",
        has_meters: false,
        has_components: false,
        tenant_id: tenant_id
      })
      |> Assets.create_asset_type()

    asset_type
  end

  @doc """
  Generate an asset location.
  """
  def asset_location_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"

    location_type = attrs[:location_type] || location_type_fixture(%{tenant_id: tenant_id})

    {:ok, location} =
      attrs
      |> Enum.into(%{
        name: "Test Location",
        code: "TEST_LOC_#{System.unique_integer([:positive])}",
        description: "Test location description",
        area_unit: "sqft",
        is_active: true,
        tenant_id: tenant_id,
        location_type_id: location_type.id
      })
      |> Assets.create_asset_location()

    location
  end

  @doc """
  Generate a location type.
  """
  def location_type_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"

    {:ok, location_type} =
      attrs
      |> Enum.into(%{
        name: "Test Location Type",
        code: "TEST_LOC_TYPE_#{System.unique_integer([:positive])}",
        description: "Test location type",
        tenant_id: tenant_id
      })
      |> Assets.create_asset_location_type()

    location_type
  end

  @doc """
  Generate an asset.
  """
  def asset_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"
    asset_type_id = attrs[:asset_type_id] || raise "asset_type_id is required"
    location_id = attrs[:location_id] || raise "location_id is required"

    {:ok, asset} =
      attrs
      |> Enum.into(%{
        asset_number: "ASSET-#{System.unique_integer([:positive])}",
        name: "Test Asset",
        description: "Test asset description",
        manufacturer: "Test Manufacturer",
        model: "Test Model",
        serial_number: "SN-#{System.unique_integer([:positive])}",
        status: :operational,
        criticality: :medium,
        tenant_id: tenant_id,
        asset_type_id: asset_type_id,
        location_id: location_id
      })
      |> Assets.create_asset()

    asset
  end
end
