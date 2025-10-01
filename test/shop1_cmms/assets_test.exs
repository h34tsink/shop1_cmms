defmodule Shop1Cmms.AssetsTest do
  use Shop1Cmms.DataCase

  alias Shop1Cmms.{Assets, Tenants}

  describe "assets" do
    alias Shop1Cmms.Assets.Asset

    setup do
      # Create test tenant
      tenant_attrs = %{
        name: "Test Tenant",
        code: "TEST",
        description: "Test tenant for unit tests",
        email: "test@example.com",
        is_active: true
      }

      {:ok, tenant} = Tenants.create_tenant(tenant_attrs)

      # Create test asset type
      asset_type_attrs = %{
        name: "Test Equipment",
        description: "Test equipment type",
        code: "TEST_EQUIP",
        category: "Equipment",
        tenant_id: tenant.id
      }

      {:ok, asset_type} = Assets.create_asset_type(asset_type_attrs)

      # Create test location type
      location_type_attrs = %{
        name: "Test Location Type",
        code: "TEST_LOC",
        tenant_id: tenant.id
      }

      {:ok, location_type} = Assets.create_asset_location_type(location_type_attrs)

      # Create test location
      location_attrs = %{
        name: "Test Location",
        code: "LOC001",
        tenant_id: tenant.id,
        location_type_id: location_type.id,
        is_active: true
      }

      {:ok, location} = Assets.create_asset_location(location_attrs)

      %{
        tenant: tenant,
        asset_type: asset_type,
        location: location
      }
    end

    @valid_attrs %{
      name: "some name",
      asset_number: "AST001",
      status: :operational,
      criticality: :medium,
      description: "some description"
    }

    @update_attrs %{
      name: "some updated name",
      asset_number: "AST002",
      status: :maintenance,
      criticality: :high,
      description: "some updated description"
    }

    @invalid_attrs %{name: nil, asset_number: nil, status: nil}

    def asset_fixture(attrs \\ %{}) do
      {:ok, asset} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Assets.create_asset()

      asset
    end

    test "list_assets/0 returns all assets", %{tenant: tenant, asset_type: asset_type, location: location} do
      attrs = Map.merge(@valid_attrs, %{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      asset = asset_fixture(attrs)
      assets = Assets.list_assets()
      assert length(assets) == 1
      assert Enum.any?(assets, fn a -> a.id == asset.id end)
    end

    test "get_asset!/1 returns the asset with given id", %{tenant: tenant, asset_type: asset_type, location: location} do
      attrs = Map.merge(@valid_attrs, %{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      asset = asset_fixture(attrs)
      fetched_asset = Assets.get_asset!(asset.id)
      assert fetched_asset.id == asset.id
      assert fetched_asset.name == asset.name
      assert fetched_asset.asset_number == asset.asset_number
    end

    test "create_asset/1 with valid data creates a asset", %{tenant: tenant, asset_type: asset_type, location: location} do
      attrs = Map.merge(@valid_attrs, %{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      assert {:ok, %Asset{} = asset} = Assets.create_asset(attrs)
      assert asset.name == "some name"
      assert asset.asset_number == "AST001"
      assert asset.status == :operational
      assert asset.criticality == :medium
      assert asset.description == "some description"
    end

    test "create_asset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_asset(@invalid_attrs)
    end

    test "update_asset/2 with valid data updates the asset", %{tenant: tenant, asset_type: asset_type, location: location} do
      attrs = Map.merge(@valid_attrs, %{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      asset = asset_fixture(attrs)
      update_attrs = Map.merge(@update_attrs, %{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      assert {:ok, %Asset{} = asset} = Assets.update_asset(asset, update_attrs)
      assert asset.name == "some updated name"
      assert asset.asset_number == "AST002"
      assert asset.status == :maintenance
      assert asset.criticality == :high
      assert asset.description == "some updated description"
    end

    test "update_asset/2 with invalid data returns error changeset", %{tenant: tenant, asset_type: asset_type, location: location} do
      attrs = Map.merge(@valid_attrs, %{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      asset = asset_fixture(attrs)
      assert {:error, %Ecto.Changeset{}} = Assets.update_asset(asset, @invalid_attrs)
      unchanged_asset = Assets.get_asset!(asset.id)
      assert unchanged_asset.id == asset.id
      assert unchanged_asset.name == asset.name
    end

    test "delete_asset/1 deletes the asset", %{tenant: tenant, asset_type: asset_type, location: location} do
      attrs = Map.merge(@valid_attrs, %{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      asset = asset_fixture(attrs)
      assert {:ok, %Asset{}} = Assets.delete_asset(asset)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_asset!(asset.id) end
    end

    test "change_asset/1 returns a asset changeset", %{tenant: tenant, asset_type: asset_type, location: location} do
      attrs = Map.merge(@valid_attrs, %{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      asset = asset_fixture(attrs)
      assert %Ecto.Changeset{} = Assets.change_asset(asset)
    end

    test "search_assets/2 filters assets by search term", %{tenant: tenant, asset_type: asset_type, location: location} do
      attrs1 = Map.merge(@valid_attrs, %{
        name: "Pump Equipment",
        asset_number: "PMP001",
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      attrs2 = Map.merge(@valid_attrs, %{
        name: "Motor Equipment",
        asset_number: "MOT001",
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      pump_asset = asset_fixture(attrs1)
      _motor_asset = asset_fixture(attrs2)

      # Search for pump
      results = Assets.search_assets(tenant.id, "pump")
      assert length(results) == 1
      assert Enum.any?(results, fn asset -> asset.id == pump_asset.id end)
    end

    test "filter_assets_by_status/2 filters assets by status", %{tenant: tenant, asset_type: asset_type, location: location} do
      attrs1 = Map.merge(@valid_attrs, %{
        name: "Operational Asset",
        asset_number: "OPR001",
        status: :operational,
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      attrs2 = Map.merge(@valid_attrs, %{
        name: "Repair Asset",
        asset_number: "REP001",
        status: :repair,
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id
      })

      operational_asset = asset_fixture(attrs1)
      _repair_asset = asset_fixture(attrs2)

      # Filter by operational status
      results = Assets.filter_assets_by_status(tenant.id, :operational)
      assert length(results) == 1
      assert Enum.any?(results, fn asset -> asset.id == operational_asset.id end)
    end
  end
end
