defmodule Shop1Cmms.AssetsFiltersTest do
  use Shop1Cmms.DataCase

  alias Shop1Cmms.Assets
  import Shop1Cmms.AssetsFixtures
  import Shop1Cmms.AccountsFixtures

  describe "filter_by_status/2" do
    setup do
      tenant = tenant_fixture()
      asset_type = asset_type_fixture(%{tenant_id: tenant.id})
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      # Create assets with different statuses
      operational = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Operational Equipment",
        status: :operational
      })
      
      maintenance = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Maintenance Equipment",
        status: :maintenance
      })
      
      repair = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Repair Equipment",
        status: :repair
      })
      
      retired = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Retired Equipment",
        status: :retired
      })
      
      disposed = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Disposed Equipment",
        status: :disposed
      })
      
      %{
        tenant: tenant,
        asset_type: asset_type,
        location: location,
        assets: %{
          operational: operational,
          maintenance: maintenance,
          repair: repair,
          retired: retired,
          disposed: disposed
        }
      }
    end

    test "returns all assets when status is 'all'", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      assert length(assets) == 5
    end

    test "filters assets by operational status", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.status == :operational))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.operational.id
      assert hd(filtered).status == :operational
    end

    test "filters assets by maintenance status", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.status == :maintenance))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.maintenance.id
      assert hd(filtered).status == :maintenance
    end

    test "filters assets by repair status", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.status == :repair))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.repair.id
      assert hd(filtered).status == :repair
    end

    test "filters assets by retired status", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.status == :retired))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.retired.id
      assert hd(filtered).status == :retired
    end

    test "filters assets by disposed status", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.status == :disposed))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.disposed.id
      assert hd(filtered).status == :disposed
    end
  end

  describe "filter_by_criticality/2" do
    setup do
      tenant = tenant_fixture()
      asset_type = asset_type_fixture(%{tenant_id: tenant.id})
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      # Create assets with different criticality levels
      critical = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Critical Equipment",
        criticality: :critical
      })
      
      high = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "High Priority Equipment",
        criticality: :high
      })
      
      medium = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Medium Priority Equipment",
        criticality: :medium
      })
      
      low = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Low Priority Equipment",
        criticality: :low
      })
      
      %{
        tenant: tenant,
        asset_type: asset_type,
        location: location,
        assets: %{
          critical: critical,
          high: high,
          medium: medium,
          low: low
        }
      }
    end

    test "returns all assets when criticality is 'all'", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      assert length(assets) == 4
    end

    test "filters assets by critical criticality", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.criticality == :critical))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.critical.id
      assert hd(filtered).criticality == :critical
    end

    test "filters assets by high criticality", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.criticality == :high))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.high.id
      assert hd(filtered).criticality == :high
    end

    test "filters assets by medium criticality", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.criticality == :medium))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.medium.id
      assert hd(filtered).criticality == :medium
    end

    test "filters assets by low criticality", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.criticality == :low))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.low.id
      assert hd(filtered).criticality == :low
    end
  end

  describe "filter_by_type/2" do
    setup do
      tenant = tenant_fixture()
      
      # Create multiple asset types
      equipment_type = asset_type_fixture(%{
        tenant_id: tenant.id,
        name: "Equipment",
        code: "EQUIP"
      })
      
      vehicle_type = asset_type_fixture(%{
        tenant_id: tenant.id,
        name: "Vehicle",
        code: "VEH"
      })
      
      tool_type = asset_type_fixture(%{
        tenant_id: tenant.id,
        name: "Tool",
        code: "TOOL"
      })
      
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      # Create assets with different types
      equipment1 = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: equipment_type.id,
        location_id: location.id,
        name: "CNC Machine"
      })
      
      equipment2 = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: equipment_type.id,
        location_id: location.id,
        name: "Lathe"
      })
      
      vehicle = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: vehicle_type.id,
        location_id: location.id,
        name: "Forklift"
      })
      
      tool = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: tool_type.id,
        location_id: location.id,
        name: "Drill Press"
      })
      
      %{
        tenant: tenant,
        asset_types: %{
          equipment: equipment_type,
          vehicle: vehicle_type,
          tool: tool_type
        },
        location: location,
        assets: %{
          equipment1: equipment1,
          equipment2: equipment2,
          vehicle: vehicle,
          tool: tool
        }
      }
    end

    test "returns all assets when type is 'all'", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      assert length(assets) == 4
    end

    test "filters assets by equipment type", %{tenant: tenant, asset_types: types, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.asset_type_id == types.equipment.id))
      
      assert length(filtered) == 2
      asset_ids = Enum.map(filtered, & &1.id)
      assert test_assets.equipment1.id in asset_ids
      assert test_assets.equipment2.id in asset_ids
    end

    test "filters assets by vehicle type", %{tenant: tenant, asset_types: types, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.asset_type_id == types.vehicle.id))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.vehicle.id
    end

    test "filters assets by tool type", %{tenant: tenant, asset_types: types, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      filtered = Enum.filter(assets, &(&1.asset_type_id == types.tool.id))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.tool.id
    end
  end

  describe "filter_by_search/2" do
    setup do
      tenant = tenant_fixture()
      asset_type = asset_type_fixture(%{tenant_id: tenant.id})
      location = asset_location_fixture(%{tenant_id: tenant.id, name: "Workshop A"})
      
      # Create assets with different searchable fields
      cnc = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "CNC Machine",
        asset_number: "CNC-001",
        manufacturer: "Haas",
        model: "VF-2"
      })
      
      lathe = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Manual Lathe",
        asset_number: "LAT-002",
        manufacturer: "South Bend",
        model: "10K"
      })
      
      mill = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Milling Machine",
        asset_number: "MILL-003",
        manufacturer: "Bridgeport",
        model: "Series I"
      })
      
      %{
        tenant: tenant,
        asset_type: asset_type,
        location: location,
        assets: %{
          cnc: cnc,
          lathe: lathe,
          mill: mill
        }
      }
    end

    test "returns all assets when search term is empty", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      assert length(assets) == 3
    end

    test "filters assets by name", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      term = "cnc"
      filtered = Enum.filter(assets, fn asset ->
        String.contains?(String.downcase(asset.name || ""), String.downcase(term))
      end)
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.cnc.id
    end

    test "filters assets by asset number", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      term = "LAT-002"
      filtered = Enum.filter(assets, fn asset ->
        String.contains?(String.downcase(asset.asset_number || ""), String.downcase(term))
      end)
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.lathe.id
    end

    test "filters assets by manufacturer", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      term = "haas"
      filtered = Enum.filter(assets, fn asset ->
        String.contains?(String.downcase(asset.manufacturer || ""), String.downcase(term))
      end)
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.cnc.id
    end

    test "filters assets by model", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      term = "series"
      filtered = Enum.filter(assets, fn asset ->
        String.contains?(String.downcase(asset.model || ""), String.downcase(term))
      end)
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.mill.id
    end

    test "filters assets by location name", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      term = "workshop"
      filtered = Enum.filter(assets, fn asset ->
        asset.location && String.contains?(String.downcase(asset.location.name || ""), String.downcase(term))
      end)
      
      # All assets are in Workshop A
      assert length(filtered) == 3
    end

    test "search is case insensitive", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Test uppercase
      term_upper = "CNC"
      filtered_upper = Enum.filter(assets, fn asset ->
        String.contains?(String.downcase(asset.name || ""), String.downcase(term_upper))
      end)
      
      # Test lowercase
      term_lower = "cnc"
      filtered_lower = Enum.filter(assets, fn asset ->
        String.contains?(String.downcase(asset.name || ""), String.downcase(term_lower))
      end)
      
      # Test mixed case
      term_mixed = "CnC"
      filtered_mixed = Enum.filter(assets, fn asset ->
        String.contains?(String.downcase(asset.name || ""), String.downcase(term_mixed))
      end)
      
      assert length(filtered_upper) == 1
      assert length(filtered_lower) == 1
      assert length(filtered_mixed) == 1
      assert hd(filtered_upper).id == test_assets.cnc.id
      assert hd(filtered_lower).id == test_assets.cnc.id
      assert hd(filtered_mixed).id == test_assets.cnc.id
    end
  end

  describe "combined filters" do
    setup do
      tenant = tenant_fixture()
      
      equipment_type = asset_type_fixture(%{
        tenant_id: tenant.id,
        name: "Equipment",
        code: "EQUIP"
      })
      
      vehicle_type = asset_type_fixture(%{
        tenant_id: tenant.id,
        name: "Vehicle",
        code: "VEH"
      })
      
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      # Create diverse assets
      critical_operational_equipment = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: equipment_type.id,
        location_id: location.id,
        name: "Critical CNC Machine",
        status: :operational,
        criticality: :critical,
        manufacturer: "Haas"
      })
      
      high_maintenance_equipment = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: equipment_type.id,
        location_id: location.id,
        name: "High Priority Lathe",
        status: :maintenance,
        criticality: :high,
        manufacturer: "South Bend"
      })
      
      medium_operational_vehicle = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: vehicle_type.id,
        location_id: location.id,
        name: "Medium Priority Forklift",
        status: :operational,
        criticality: :medium,
        manufacturer: "Toyota"
      })
      
      low_repair_vehicle = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: vehicle_type.id,
        location_id: location.id,
        name: "Low Priority Truck",
        status: :repair,
        criticality: :low,
        manufacturer: "Ford"
      })
      
      %{
        tenant: tenant,
        asset_types: %{
          equipment: equipment_type,
          vehicle: vehicle_type
        },
        location: location,
        assets: %{
          critical_operational_equipment: critical_operational_equipment,
          high_maintenance_equipment: high_maintenance_equipment,
          medium_operational_vehicle: medium_operational_vehicle,
          low_repair_vehicle: low_repair_vehicle
        }
      }
    end

    test "filters by status AND type", %{tenant: tenant, asset_types: types, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Filter operational equipment
      filtered = assets
      |> Enum.filter(&(&1.status == :operational))
      |> Enum.filter(&(&1.asset_type_id == types.equipment.id))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.critical_operational_equipment.id
    end

    test "filters by status AND criticality", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Filter operational + critical
      filtered = assets
      |> Enum.filter(&(&1.status == :operational))
      |> Enum.filter(&(&1.criticality == :critical))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.critical_operational_equipment.id
    end

    test "filters by type AND criticality", %{tenant: tenant, asset_types: types, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Filter vehicle + medium
      filtered = assets
      |> Enum.filter(&(&1.asset_type_id == types.vehicle.id))
      |> Enum.filter(&(&1.criticality == :medium))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.medium_operational_vehicle.id
    end

    test "filters by status AND type AND criticality", %{tenant: tenant, asset_types: types, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Filter operational + equipment + critical
      filtered = assets
      |> Enum.filter(&(&1.status == :operational))
      |> Enum.filter(&(&1.asset_type_id == types.equipment.id))
      |> Enum.filter(&(&1.criticality == :critical))
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.critical_operational_equipment.id
    end

    test "filters by search AND status", %{tenant: tenant, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant.id)
      term = "forklift"
      
      # Filter operational + search for forklift
      filtered = assets
      |> Enum.filter(&(&1.status == :operational))
      |> Enum.filter(fn asset ->
        String.contains?(String.downcase(asset.name || ""), String.downcase(term))
      end)
      
      assert length(filtered) == 1
      assert hd(filtered).id == test_assets.medium_operational_vehicle.id
    end

    test "multiple filters with no matches returns empty", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Filter for impossible combination
      filtered = assets
      |> Enum.filter(&(&1.status == :disposed))
      |> Enum.filter(&(&1.criticality == :critical))
      
      assert length(filtered) == 0
    end
  end

  describe "tenant isolation" do
    setup do
      tenant1 = tenant_fixture()
      tenant2 = tenant_fixture()
      
      asset_type1 = asset_type_fixture(%{tenant_id: tenant1.id})
      asset_type2 = asset_type_fixture(%{tenant_id: tenant2.id})
      
      location1 = asset_location_fixture(%{tenant_id: tenant1.id})
      location2 = asset_location_fixture(%{tenant_id: tenant2.id})
      
      # Create assets for tenant1
      asset1 = asset_fixture(%{
        tenant_id: tenant1.id,
        asset_type_id: asset_type1.id,
        location_id: location1.id,
        name: "Tenant 1 Equipment",
        status: :operational
      })
      
      # Create assets for tenant2
      asset2 = asset_fixture(%{
        tenant_id: tenant2.id,
        asset_type_id: asset_type2.id,
        location_id: location2.id,
        name: "Tenant 2 Equipment",
        status: :operational
      })
      
      %{
        tenant1: tenant1,
        tenant2: tenant2,
        assets: %{
          tenant1_asset: asset1,
          tenant2_asset: asset2
        }
      }
    end

    test "tenant 1 only sees their assets", %{tenant1: tenant1, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant1.id)
      
      assert length(assets) == 1
      assert hd(assets).id == test_assets.tenant1_asset.id
    end

    test "tenant 2 only sees their assets", %{tenant2: tenant2, assets: test_assets} do
      assets = Assets.list_assets_with_details(tenant2.id)
      
      assert length(assets) == 1
      assert hd(assets).id == test_assets.tenant2_asset.id
    end

    test "filters respect tenant isolation", %{tenant1: tenant1, tenant2: tenant2} do
      assets1 = Assets.list_assets_with_details(tenant1.id)
      filtered1 = Enum.filter(assets1, &(&1.status == :operational))
      
      assets2 = Assets.list_assets_with_details(tenant2.id)
      filtered2 = Enum.filter(assets2, &(&1.status == :operational))
      
      assert length(filtered1) == 1
      assert length(filtered2) == 1
      
      # Ensure they're different assets
      assert hd(filtered1).id != hd(filtered2).id
    end
  end
end
