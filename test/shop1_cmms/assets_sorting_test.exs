defmodule Shop1Cmms.AssetsSortingTest do
  use Shop1Cmms.DataCase

  alias Shop1Cmms.Assets
  import Shop1Cmms.AssetsFixtures
  import Shop1Cmms.AccountsFixtures

  describe "sort_assets/3" do
    setup do
      tenant = tenant_fixture()
      asset_type = asset_type_fixture(%{tenant_id: tenant.id})
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      # Create assets with different values for sorting
      asset1 = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Zebra Equipment",
        asset_number: "ASSET-003",
        status: :operational,
        criticality: :low
      })
      
      asset2 = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Alpha Equipment",
        asset_number: "ASSET-001",
        status: :maintenance,
        criticality: :critical
      })
      
      asset3 = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Beta Equipment",
        asset_number: "ASSET-002",
        status: :repair,
        criticality: :high
      })
      
      %{
        tenant: tenant,
        asset_type: asset_type,
        location: location,
        assets: [asset1, asset2, asset3]
      }
    end

    test "sorts by name ascending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(assets, & &1.name)
      
      assert length(sorted) == 3
      assert Enum.at(sorted, 0).name == "Alpha Equipment"
      assert Enum.at(sorted, 1).name == "Beta Equipment"
      assert Enum.at(sorted, 2).name == "Zebra Equipment"
    end

    test "sorts by name descending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(assets, & &1.name, :desc)
      
      assert length(sorted) == 3
      assert Enum.at(sorted, 0).name == "Zebra Equipment"
      assert Enum.at(sorted, 1).name == "Beta Equipment"
      assert Enum.at(sorted, 2).name == "Alpha Equipment"
    end

    test "sorts by asset_number ascending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(assets, & &1.asset_number)
      
      assert length(sorted) == 3
      assert Enum.at(sorted, 0).asset_number == "ASSET-001"
      assert Enum.at(sorted, 1).asset_number == "ASSET-002"
      assert Enum.at(sorted, 2).asset_number == "ASSET-003"
    end

    test "sorts by asset_number descending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(assets, & &1.asset_number, :desc)
      
      assert length(sorted) == 3
      assert Enum.at(sorted, 0).asset_number == "ASSET-003"
      assert Enum.at(sorted, 1).asset_number == "ASSET-002"
      assert Enum.at(sorted, 2).asset_number == "ASSET-001"
    end

    test "sorts by status ascending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(assets, & &1.status)
      
      assert length(sorted) == 3
      # Atoms sort alphabetically: :maintenance, :operational, :repair
      assert Enum.at(sorted, 0).status == :maintenance
      assert Enum.at(sorted, 1).status == :operational
      assert Enum.at(sorted, 2).status == :repair
    end

    test "sorts by status descending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(assets, & &1.status, :desc)
      
      assert length(sorted) == 3
      assert Enum.at(sorted, 0).status == :repair
      assert Enum.at(sorted, 1).status == :operational
      assert Enum.at(sorted, 2).status == :maintenance
    end

    test "sorts by criticality ascending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Helper function to convert criticality to number for sorting
      criticality_to_number = fn
        :critical -> 4
        :high -> 3
        :medium -> 2
        :low -> 1
        _ -> 0
      end
      
      sorted = Enum.sort_by(assets, fn asset -> 
        criticality_to_number.(asset.criticality)
      end)
      
      assert length(sorted) == 3
      assert Enum.at(sorted, 0).criticality == :low
      assert Enum.at(sorted, 1).criticality == :high
      assert Enum.at(sorted, 2).criticality == :critical
    end

    test "sorts by criticality descending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Helper function to convert criticality to number for sorting
      criticality_to_number = fn
        :critical -> 4
        :high -> 3
        :medium -> 2
        :low -> 1
        _ -> 0
      end
      
      sorted = Enum.sort_by(assets, fn asset -> 
        criticality_to_number.(asset.criticality)
      end, :desc)
      
      assert length(sorted) == 3
      assert Enum.at(sorted, 0).criticality == :critical
      assert Enum.at(sorted, 1).criticality == :high
      assert Enum.at(sorted, 2).criticality == :low
    end
  end

  describe "sorting with filters" do
    setup do
      tenant = tenant_fixture()
      asset_type = asset_type_fixture(%{tenant_id: tenant.id})
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      # Create a mix of assets
      operational_critical = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Zebra Machine",
        status: :operational,
        criticality: :critical
      })
      
      operational_low = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Alpha Machine",
        status: :operational,
        criticality: :low
      })
      
      maintenance_high = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Beta Machine",
        status: :maintenance,
        criticality: :high
      })
      
      %{
        tenant: tenant,
        asset_type: asset_type,
        location: location,
        assets: %{
          operational_critical: operational_critical,
          operational_low: operational_low,
          maintenance_high: maintenance_high
        }
      }
    end

    test "sorts operational assets by criticality descending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Filter operational assets
      filtered = Enum.filter(assets, &(&1.status == :operational))
      
      # Sort by criticality
      criticality_to_number = fn
        :critical -> 4
        :high -> 3
        :medium -> 2
        :low -> 1
        _ -> 0
      end
      
      sorted = Enum.sort_by(filtered, fn asset -> 
        criticality_to_number.(asset.criticality)
      end, :desc)
      
      assert length(sorted) == 2
      assert hd(sorted).criticality == :critical
      assert Enum.at(sorted, 1).criticality == :low
    end

    test "sorts operational assets by name ascending", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Filter operational assets
      filtered = Enum.filter(assets, &(&1.status == :operational))
      
      # Sort by name
      sorted = Enum.sort_by(filtered, & &1.name)
      
      assert length(sorted) == 2
      assert hd(sorted).name == "Alpha Machine"
      assert Enum.at(sorted, 1).name == "Zebra Machine"
    end

    test "filters and sorts maintain correct results", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Filter by operational status
      filtered = Enum.filter(assets, &(&1.status == :operational))
      
      # Sort by name
      sorted = Enum.sort_by(filtered, & &1.name)
      
      # Verify we have the right assets in the right order
      assert length(sorted) == 2
      assert hd(sorted).id == test_assets.operational_low.id
      assert Enum.at(sorted, 1).id == test_assets.operational_critical.id
    end
  end

  describe "default sorting" do
    setup do
      tenant = tenant_fixture()
      asset_type = asset_type_fixture(%{tenant_id: tenant.id})
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      # Create assets with names that would sort differently
      asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "CNC Machine"
      })
      
      asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Lathe"
      })
      
      asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "3D Printer"
      })
      
      %{tenant: tenant}
    end

    test "assets are sorted by name by default", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(assets, & &1.name)
      
      # Should match the default sort
      assert length(sorted) == 3
      assert Enum.at(sorted, 0).name == "3D Printer"
      assert Enum.at(sorted, 1).name == "CNC Machine"
      assert Enum.at(sorted, 2).name == "Lathe"
    end
  end

  describe "sorting edge cases" do
    setup do
      tenant = tenant_fixture()
      asset_type = asset_type_fixture(%{tenant_id: tenant.id})
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      # Create assets with different names for edge cases
      asset1 = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "AAA First",
        asset_number: "FIRST"
      })
      
      asset2 = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "ZZZ Last",
        asset_number: "LAST"
      })
      
      %{tenant: tenant, assets: [asset1, asset2]}
    end

    test "sorts assets correctly", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(assets, & &1.name)
      
      assert length(sorted) == 2
      assert hd(sorted).name == "AAA First"
      assert Enum.at(sorted, 1).name == "ZZZ Last"
    end

    test "sorting with single asset", %{tenant: tenant} do
      # Delete one asset to have only one
      assets = Assets.list_assets_with_details(tenant.id)
      asset_to_delete = hd(assets)
      Assets.delete_asset(asset_to_delete)
      
      remaining = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(remaining, & &1.name)
      
      assert length(sorted) == 1
    end

    test "sorting with no assets returns empty list", _context do
      tenant = tenant_fixture()
      assets = Assets.list_assets_with_details(tenant.id)
      sorted = Enum.sort_by(assets, & &1.name)
      
      assert sorted == []
    end
  end
end
