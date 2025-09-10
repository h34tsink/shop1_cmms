alias Shop1Cmms.Repo
alias Shop1Cmms.Tenants.Site
alias Shop1Cmms.Assets.{Asset, AssetType}

# Get or create tenant (assuming we have the default tenant with id=1)
tenant_id = 1

# Get existing sites
sites = Repo.all(Site)
main_site = Enum.find(sites, fn site -> site.code == "MAIN" end)

if is_nil(main_site) do
  IO.puts("Main site not found. Please check your sites.")
  exit(:normal)
end

IO.puts("Using site: #{main_site.name} (#{main_site.code})")

# Check if asset types already exist
existing_asset_types = Repo.all(AssetType) |> Enum.map(& &1.code)
IO.puts("Existing asset types: #{inspect(existing_asset_types)}")

# Create asset types if they don't exist
asset_types_data = [
  %{name: "CNC Machine", description: "Computer Numerical Control machining equipment", code: "CNC", category: "Equipment", tenant_id: tenant_id},
  %{name: "Air Compressor", description: "Compressed air generation equipment", code: "COMP", category: "Equipment", tenant_id: tenant_id},
  %{name: "Forklift", description: "Material handling equipment", code: "FORK", category: "Vehicles", tenant_id: tenant_id},
  %{name: "HVAC System", description: "Heating, ventilation, and air conditioning equipment", code: "HVAC", category: "Infrastructure", tenant_id: tenant_id},
  %{name: "Testing Equipment", description: "Quality control and testing machinery", code: "TEST", category: "Equipment", tenant_id: tenant_id},
  %{name: "Hydraulic Press", description: "Hydraulic forming and pressing equipment", code: "PRESS", category: "Equipment", tenant_id: tenant_id},
  %{name: "Generator", description: "Power generation equipment", code: "GEN", category: "Infrastructure", tenant_id: tenant_id}
]

# Only create asset types that don't exist
new_asset_types = Enum.filter(asset_types_data, fn type_data ->
  type_data.code not in existing_asset_types
end)

if length(new_asset_types) > 0 do
  IO.puts("Creating #{length(new_asset_types)} new asset types...")

  created_types = Enum.map(new_asset_types, fn type_attrs ->
    %AssetType{}
    |> AssetType.changeset(type_attrs)
    |> Repo.insert!()
  end)

  IO.puts("Created #{length(created_types)} asset types")
else
  IO.puts("All asset types already exist")
end

# Get all asset types for reference
all_asset_types = Repo.all(AssetType)
asset_types_by_code = Enum.reduce(all_asset_types, %{}, fn type, acc ->
  Map.put(acc, type.code, type)
end)

IO.puts("Available asset types: #{inspect(Map.keys(asset_types_by_code))}")

# Check if assets already exist
existing_assets = Repo.all(Asset) |> Enum.map(& &1.asset_number)
IO.puts("Existing assets: #{inspect(existing_assets)}")

# Create assets if they don't exist
assets_data = [
  %{name: "CNC Milling Machine #1", asset_number: "CNC-001", description: "High-precision CNC milling machine for aluminum parts", manufacturer: "Haas Automation", model: "VF-2SS", serial_number: "1234567890", status: "operational", criticality: "high", tenant_id: tenant_id, asset_type_id: asset_types_by_code["CNC"].id, purchase_cost: 85000.00, purchase_date: ~D[2022-03-15], commission_date: ~D[2022-04-01], warranty_expiry: ~D[2025-03-15]},
  %{name: "CNC Lathe #2", asset_number: "CNC-002", description: "Computer-controlled lathe for precision turning operations", manufacturer: "Mazak Corporation", model: "Quick Turn Nexus 250-II", serial_number: "QTN250-987", status: "operational", criticality: "high", tenant_id: tenant_id, asset_type_id: asset_types_by_code["CNC"].id, purchase_cost: 120000.00, purchase_date: ~D[2021-08-10], commission_date: ~D[2021-09-01], warranty_expiry: ~D[2024-08-10]},
  %{name: "Air Compressor System", asset_number: "COMP-001", description: "Industrial air compressor for pneumatic tools", manufacturer: "Atlas Copco", model: "GA 37 VSD", serial_number: "AC37VSD456", status: "operational", criticality: "medium", tenant_id: tenant_id, asset_type_id: asset_types_by_code["COMP"].id, purchase_cost: 25000.00, purchase_date: ~D[2020-06-01], commission_date: ~D[2020-06-15], warranty_expiry: ~D[2023-06-01]},
  %{name: "Forklift #1", asset_number: "FORK-001", description: "Electric forklift for material handling", manufacturer: "Toyota Material Handling", model: "8FBCU25", serial_number: "TY8FB789", status: "maintenance", criticality: "medium", tenant_id: tenant_id, asset_type_id: asset_types_by_code["FORK"].id, purchase_cost: 28000.00, purchase_date: ~D[2019-11-20], commission_date: ~D[2019-12-01], warranty_expiry: ~D[2022-11-20]},
  %{name: "HVAC Unit #1", asset_number: "HVAC-001", description: "Main facility heating and cooling system", manufacturer: "Carrier", model: "50TCA04", serial_number: "CAR50TCA123", status: "operational", criticality: "high", tenant_id: tenant_id, asset_type_id: asset_types_by_code["HVAC"].id, purchase_cost: 45000.00, purchase_date: ~D[2020-01-15], commission_date: ~D[2020-02-01], warranty_expiry: ~D[2025-01-15]}
]

# Only create assets that don't exist
new_assets = Enum.filter(assets_data, fn asset_data ->
  asset_data.asset_number not in existing_assets
end)

if length(new_assets) > 0 do
  IO.puts("Creating #{length(new_assets)} new assets...")

  created_assets = Enum.map(new_assets, fn asset_attrs ->
    %Asset{}
    |> Asset.changeset(asset_attrs)
    |> Repo.insert!()
  end)

  IO.puts("Created #{length(created_assets)} assets")
else
  IO.puts("All assets already exist")
end

IO.puts("\n=== Final Status ===")
IO.puts("Sites: #{Repo.aggregate(Site, :count, :id)}")
IO.puts("Asset Types: #{Repo.aggregate(AssetType, :count, :id)}")
IO.puts("Assets: #{Repo.aggregate(Asset, :count, :id)}")
IO.puts("Ready for testing!")
