alias Shop1Cmms.{Repo, Assets, Tenants}
alias Shop1Cmms.Assets.{Asset, AssetType, AssetLocation, AssetLocationType}
alias Shop1Cmms.Tenants.Tenant
import Ecto.Query

IO.puts("Creating sample assets for testing...")

# Get or create tenant
tenant = Repo.get_by(Tenant, name: "Shop1") ||
  Repo.insert!(%Tenant{
    name: "Shop1",
    code: "SHOP1",
    description: "Shop1 CMMS System"
  })

# Create some asset types if they don't exist
asset_types = [
  %{name: "CNC Machine", description: "Computer Numerical Control machines", code: "CNC_MACHINE", category: "Equipment", tenant_id: tenant.id},
  %{name: "Conveyor", description: "Material conveyor systems", code: "CONVEYOR", category: "Equipment", tenant_id: tenant.id},
  %{name: "Pump", description: "Fluid pumps and systems", code: "PUMP", category: "Equipment", tenant_id: tenant.id},
  %{name: "Compressor", description: "Air and gas compressors", code: "COMPRESSOR", category: "Equipment", tenant_id: tenant.id},
  %{name: "Generator", description: "Power generators", code: "GENERATOR", category: "Equipment", tenant_id: tenant.id},
  %{name: "HVAC Unit", description: "Heating, ventilation, and air conditioning", code: "HVAC", category: "Equipment", tenant_id: tenant.id},
  %{name: "Vehicle", description: "Forklifts, trucks, and other vehicles", code: "VEHICLE", category: "Vehicles", tenant_id: tenant.id}
]

# Insert asset types
Enum.each(asset_types, fn type_attrs ->
  case Repo.get_by(AssetType, name: type_attrs.name, tenant_id: tenant.id) do
    nil -> Repo.insert!(%AssetType{} |> AssetType.changeset(type_attrs))
    _existing -> :ok
  end
end)

# Create location types first
location_types = [
  %{name: "Production Area", description: "Manufacturing and production areas", code: "PRODUCTION", tenant_id: tenant.id},
  %{name: "Storage Area", description: "Warehouses and storage facilities", code: "STORAGE", tenant_id: tenant.id},
  %{name: "Maintenance Area", description: "Equipment maintenance and repair areas", code: "MAINTENANCE", tenant_id: tenant.id},
  %{name: "Office Area", description: "Administrative and office spaces", code: "OFFICE", tenant_id: tenant.id},
  %{name: "Outdoor Area", description: "External and yard areas", code: "OUTDOOR", tenant_id: tenant.id}
]

# Insert location types
Enum.each(location_types, fn type_attrs ->
  case Repo.get_by(AssetLocationType, name: type_attrs.name, tenant_id: tenant.id) do
    nil -> Repo.insert!(%AssetLocationType{} |> AssetLocationType.changeset(type_attrs))
    _existing -> :ok
  end
end)

# Get location types for reference
production_type = Repo.get_by!(AssetLocationType, code: "PRODUCTION", tenant_id: tenant.id)
storage_type = Repo.get_by!(AssetLocationType, code: "STORAGE", tenant_id: tenant.id)
maintenance_type = Repo.get_by!(AssetLocationType, code: "MAINTENANCE", tenant_id: tenant.id)
office_type = Repo.get_by!(AssetLocationType, code: "OFFICE", tenant_id: tenant.id)
outdoor_type = Repo.get_by!(AssetLocationType, code: "OUTDOOR", tenant_id: tenant.id)

# Create some asset locations if they don't exist
locations = [
  %{name: "Production Floor A", description: "Main production area A", code: "PROD_A", location_type_id: production_type.id, tenant_id: tenant.id},
  %{name: "Production Floor B", description: "Main production area B", code: "PROD_B", location_type_id: production_type.id, tenant_id: tenant.id},
  %{name: "Warehouse", description: "Storage and shipping area", code: "WAREHOUSE", location_type_id: storage_type.id, tenant_id: tenant.id},
  %{name: "Maintenance Shop", description: "Equipment maintenance area", code: "MAINT_SHOP", location_type_id: maintenance_type.id, tenant_id: tenant.id},
  %{name: "Office Building", description: "Administrative offices", code: "OFFICE_BLDG", location_type_id: office_type.id, tenant_id: tenant.id},
  %{name: "Yard", description: "Outdoor equipment area", code: "YARD", location_type_id: outdoor_type.id, tenant_id: tenant.id}
]

Enum.each(locations, fn loc_attrs ->
  case Repo.get_by(AssetLocation, name: loc_attrs.name, tenant_id: tenant.id) do
    nil -> Repo.insert!(%AssetLocation{} |> AssetLocation.changeset(loc_attrs))
    _existing -> :ok
  end
end)

# Get the created asset types and locations
cnc_type = Repo.get_by!(AssetType, name: "CNC Machine", tenant_id: tenant.id)
conveyor_type = Repo.get_by!(AssetType, name: "Conveyor", tenant_id: tenant.id)
pump_type = Repo.get_by!(AssetType, name: "Pump", tenant_id: tenant.id)
compressor_type = Repo.get_by!(AssetType, name: "Compressor", tenant_id: tenant.id)
generator_type = Repo.get_by!(AssetType, name: "Generator", tenant_id: tenant.id)
hvac_type = Repo.get_by!(AssetType, name: "HVAC Unit", tenant_id: tenant.id)
vehicle_type = Repo.get_by!(AssetType, name: "Vehicle", tenant_id: tenant.id)

floor_a = Repo.get_by!(AssetLocation, name: "Production Floor A", tenant_id: tenant.id)
floor_b = Repo.get_by!(AssetLocation, name: "Production Floor B", tenant_id: tenant.id)
warehouse = Repo.get_by!(AssetLocation, name: "Warehouse", tenant_id: tenant.id)
maint_shop = Repo.get_by!(AssetLocation, name: "Maintenance Shop", tenant_id: tenant.id)
office = Repo.get_by!(AssetLocation, name: "Office Building", tenant_id: tenant.id)
yard = Repo.get_by!(AssetLocation, name: "Yard", tenant_id: tenant.id)

# Delete existing sample assets first
from(a in Asset, where: a.tenant_id == ^tenant.id and like(a.asset_number, "TEST-%"))
|> Repo.delete_all()

# Sample assets with realistic data
sample_assets = [
  # CNC Machines
  %{
    name: "Haas VF-2SS CNC Mill",
    asset_number: "TEST-CNC001",
    asset_type_id: cnc_type.id,
    location_id: floor_a.id,
    status: :operational,
    manufacturer: "Haas Automation",
    model: "VF-2SS",
    serial_number: "3093847",
    description: "3-axis vertical machining center for precision parts",
    purchase_date: ~D[2022-03-15],
    install_date: ~D[2022-04-01],
    purchase_cost: 85000.00,
    warranty_expiry: ~D[2025-03-15],
    criticality: :high,
    tenant_id: tenant.id
  },
  %{
    name: "Mazak Quick Turn 200",
    asset_number: "TEST-CNC002",
    asset_type_id: cnc_type.id,
    location_id: floor_a.id,
    status: :maintenance,
    manufacturer: "Mazak",
    model: "Quick Turn 200",
    serial_number: "QT200-4847",
    description: "CNC turning center for shaft production",
    purchase_date: ~D[2021-08-10],
    install_date: ~D[2021-09-01],
    purchase_cost: 95000.00,
    warranty_expiry: ~D[2024-08-10],
    criticality: :high,
    tenant_id: tenant.id
  },

  # Conveyors
  %{
    name: "Main Line Conveyor A1",
    asset_number: "TEST-CONV001",
    asset_type_id: conveyor_type.id,
    location_id: floor_a.id,
    status: :operational,
    manufacturer: "Dorner Manufacturing",
    model: "2200 Series",
    serial_number: "2200-A1-847",
    description: "Primary production line conveyor system",
    purchase_date: ~D[2020-01-20],
    install_date: ~D[2020-02-15],
    purchase_cost: 12500.00,
    warranty_expiry: ~D[2023-01-20],
    criticality: :critical,
    tenant_id: tenant.id
  },
  %{
    name: "Packaging Line Conveyor",
    asset_number: "TEST-CONV002",
    asset_type_id: conveyor_type.id,
    location_id: floor_b.id,
    status: :operational,
    manufacturer: "Hytrol",
    model: "EZ Logic",
    serial_number: "EZ-PKG-293",
    description: "Automated packaging conveyor with sorting",
    purchase_date: ~D[2023-05-12],
    install_date: ~D[2023-06-01],
    purchase_cost: 18750.00,
    warranty_expiry: ~D[2026-05-12],
    criticality: :medium,
    tenant_id: tenant.id
  },

  # Pumps
  %{
    name: "Coolant Circulation Pump",
    asset_number: "TEST-PUMP001",
    asset_type_id: pump_type.id,
    location_id: floor_a.id,
    status: :operational,
    manufacturer: "Grundfos",
    model: "CR 32-4",
    serial_number: "GR-CR32-847",
    description: "Centrifugal pump for coolant circulation",
    purchase_date: ~D[2022-11-03],
    install_date: ~D[2022-11-15],
    purchase_cost: 4500.00,
    warranty_expiry: ~D[2025-11-03],
    criticality: :medium,
    tenant_id: tenant.id
  },
  %{
    name: "Hydraulic System Pump",
    asset_number: "TEST-PUMP002",
    asset_type_id: pump_type.id,
    location_id: floor_b.id,
    status: :repair,
    manufacturer: "Rexroth",
    model: "A10VSO71",
    serial_number: "REX-A10-934",
    description: "Variable displacement hydraulic pump",
    purchase_date: ~D[2021-07-22],
    install_date: ~D[2021-08-05],
    purchase_cost: 8900.00,
    warranty_expiry: ~D[2024-07-22],
    criticality: :high,
    tenant_id: tenant.id
  },

  # Compressors
  %{
    name: "Main Air Compressor",
    asset_number: "TEST-COMP001",
    asset_type_id: compressor_type.id,
    location_id: maint_shop.id,
    status: :operational,
    manufacturer: "Ingersoll Rand",
    model: "R90n",
    serial_number: "IR-R90-584",
    description: "75 HP rotary screw air compressor",
    purchase_date: ~D[2020-09-14],
    install_date: ~D[2020-10-01],
    purchase_cost: 28500.00,
    warranty_expiry: ~D[2023-09-14],
    criticality: :critical,
    tenant_id: tenant.id
  },
  %{
    name: "Backup Air Compressor",
    asset_number: "TEST-COMP002",
    asset_type_id: compressor_type.id,
    location_id: maint_shop.id,
    status: :operational,
    manufacturer: "Atlas Copco",
    model: "GA 37",
    serial_number: "AC-GA37-293",
    description: "37 kW backup rotary screw compressor",
    purchase_date: ~D[2023-01-18],
    install_date: ~D[2023-02-10],
    purchase_cost: 19200.00,
    warranty_expiry: ~D[2026-01-18],
    criticality: :medium,
    tenant_id: tenant.id
  },

  # Generators
  %{
    name: "Emergency Generator",
    asset_number: "TEST-GEN001",
    asset_type_id: generator_type.id,
    location_id: yard.id,
    status: :operational,
    manufacturer: "Caterpillar",
    model: "C9 ACERT",
    serial_number: "CAT-C9-847",
    description: "200 kW diesel emergency generator",
    purchase_date: ~D[2019-06-30],
    install_date: ~D[2019-08-15],
    purchase_cost: 45000.00,
    warranty_expiry: ~D[2022-06-30],
    criticality: :high,
    tenant_id: tenant.id
  },

  # HVAC Units
  %{
    name: "Production Floor HVAC Unit 1",
    asset_number: "TEST-HVAC001",
    asset_type_id: hvac_type.id,
    location_id: floor_a.id,
    status: :operational,
    manufacturer: "Carrier",
    model: "50TCQ",
    serial_number: "CAR-50T-392",
    description: "50 ton rooftop air conditioning unit",
    purchase_date: ~D[2021-04-12],
    install_date: ~D[2021-05-20],
    purchase_cost: 15600.00,
    warranty_expiry: ~D[2024-04-12],
    criticality: :medium,
    tenant_id: tenant.id
  },
  %{
    name: "Office HVAC System",
    asset_number: "TEST-HVAC002",
    asset_type_id: hvac_type.id,
    location_id: office.id,
    status: :operational,
    manufacturer: "Trane",
    model: "XL16i",
    serial_number: "TRA-XL16-584",
    description: "Variable speed heat pump system",
    purchase_date: ~D[2022-09-05],
    install_date: ~D[2022-10-12],
    purchase_cost: 8900.00,
    warranty_expiry: ~D[2025-09-05],
    criticality: :low,
    tenant_id: tenant.id
  },

  # Vehicles
  %{
    name: "Toyota Forklift 8FGU25",
    asset_number: "TEST-VEH001",
    asset_type_id: vehicle_type.id,
    location_id: warehouse.id,
    status: :operational,
    manufacturer: "Toyota",
    model: "8FGU25",
    serial_number: "TOY-8FG-938",
    description: "5000 lb capacity propane forklift",
    purchase_date: ~D[2023-02-28],
    install_date: ~D[2023-03-15],
    purchase_cost: 32500.00,
    warranty_expiry: ~D[2026-02-28],
    criticality: :medium,
    tenant_id: tenant.id
  },
  %{
    name: "Crown Reach Truck",
    asset_number: "TEST-VEH002",
    asset_type_id: vehicle_type.id,
    location_id: warehouse.id,
    status: :maintenance,
    manufacturer: "Crown Equipment",
    model: "RR 5700",
    serial_number: "CRW-RR57-384",
    description: "Electric reach truck for high racking",
    purchase_date: ~D[2022-12-10],
    install_date: ~D[2023-01-05],
    purchase_cost: 38900.00,
    warranty_expiry: ~D[2025-12-10],
    criticality: :medium,
    tenant_id: tenant.id
  },
  %{
    name: "Maintenance Truck",
    asset_number: "TEST-VEH003",
    asset_type_id: vehicle_type.id,
    location_id: yard.id,
    status: :operational,
    manufacturer: "Ford",
    model: "F-350",
    serial_number: "FORD-F350-847",
    description: "Service truck with tool boxes and crane",
    purchase_date: ~D[2021-11-15],
    install_date: ~D[2021-12-01],
    purchase_cost: 65000.00,
    warranty_expiry: ~D[2024-11-15],
    criticality: :medium,
    tenant_id: tenant.id
  },

  # Additional equipment
  %{
    name: "Overhead Bridge Crane",
    asset_number: "TEST-CRANE001",
    asset_type_id: conveyor_type.id, # Using conveyor type as closest match
    location_id: floor_a.id,
    status: :operational,
    manufacturer: "Konecranes",
    model: "CXT",
    serial_number: "KONE-CXT-483",
    description: "10 ton overhead bridge crane",
    purchase_date: ~D[2020-05-08],
    install_date: ~D[2020-07-20],
    purchase_cost: 125000.00,
    warranty_expiry: ~D[2023-05-08],
    criticality: :high,
    tenant_id: tenant.id
  },
  %{
    name: "Welding Station Robot",
    asset_number: "TEST-ROBOT001",
    asset_type_id: cnc_type.id, # Using CNC type as closest match
    location_id: floor_b.id,
    status: :operational,
    manufacturer: "FANUC",
    model: "Arc Mate 120iD",
    serial_number: "FAN-AM120-847",
    description: "6-axis robotic welding system",
    purchase_date: ~D[2023-08-22],
    install_date: ~D[2023-09-30],
    purchase_cost: 95000.00,
    warranty_expiry: ~D[2026-08-22],
    criticality: :high,
    tenant_id: tenant.id
  },
  %{
    name: "Parts Washer System",
    asset_number: "TEST-WASH001",
    asset_type_id: pump_type.id, # Using pump type as related
    location_id: maint_shop.id,
    status: :operational,
    manufacturer: "Safety-Kleen",
    model: "SmartWasher SW-28",
    serial_number: "SK-SW28-293",
    description: "Aqueous parts cleaning system",
    purchase_date: ~D[2022-06-14],
    install_date: ~D[2022-07-01],
    purchase_cost: 12800.00,
    warranty_expiry: ~D[2025-06-14],
    criticality: :low,
    tenant_id: tenant.id
  }
]

# Insert all sample assets
IO.puts("Inserting #{length(sample_assets)} sample assets...")

inserted_count =
  Enum.reduce(sample_assets, 0, fn asset_attrs, count ->
    case Assets.create_asset(asset_attrs) do
      {:ok, asset} ->
        IO.puts("  ✓ Created: #{asset.name} (#{asset.asset_number})")
        count + 1
      {:error, changeset} ->
        IO.puts("  ✗ Failed to create asset: #{inspect(changeset.errors)}")
        count
    end
  end)

IO.puts("")
IO.puts("✅ Sample assets creation completed!")
IO.puts("📊 Successfully created #{inserted_count} assets")
IO.puts("")
IO.puts("🏭 Asset Types Created:")
IO.puts("   • CNC Machine (2 assets)")
IO.puts("   • Conveyor (3 assets)")
IO.puts("   • Pump (3 assets)")
IO.puts("   • Compressor (2 assets)")
IO.puts("   • Generator (1 asset)")
IO.puts("   • HVAC Unit (2 assets)")
IO.puts("   • Vehicle (3 assets)")
IO.puts("   • Other Equipment (3 assets)")
IO.puts("")
IO.puts("📍 Locations Used:")
IO.puts("   • Production Floor A")
IO.puts("   • Production Floor B")
IO.puts("   • Warehouse")
IO.puts("   • Maintenance Shop")
IO.puts("   • Office Building")
IO.puts("   • Yard")
IO.puts("")
IO.puts("🌐 View assets at: http://localhost:4000/assets")
