alias Shop1Cmms.Repo
alias Shop1Cmms.Tenants.Site
alias Shop1Cmms.Assets.{Asset, AssetType}

# Get or create tenant (assuming we have the default tenant with id=1)
tenant_id = 1

IO.puts("Creating sites...")

# Create sites using the schema
sites_data = [
  %{
    name: "Main Manufacturing Plant",
    code: "MAIN",
    address: "123 Industrial Blvd, Manufacturing City, MC 12345",
    description: "Primary manufacturing facility",
    tenant_id: tenant_id,
    is_active: true
  },
  %{
    name: "Warehouse Facility",
    code: "WH01",
    address: "456 Storage Rd, Warehouse District, WD 67890",
    description: "Central warehouse and distribution center",
    tenant_id: tenant_id,
    is_active: true
  },
  %{
    name: "Quality Control Lab",
    code: "QC01",
    address: "789 Testing Ave, Lab Complex, LC 11111",
    description: "Quality control and testing laboratory",
    tenant_id: tenant_id,
    is_active: true
  }
]

# Insert sites using changesets
site_records = Enum.map(sites_data, fn site_attrs ->
  %Site{}
  |> Site.changeset(site_attrs)
  |> Repo.insert!()
end)

IO.puts("Created #{length(site_records)} sites")

# Get the first site for assets
main_site = Enum.at(site_records, 0)

IO.puts("Creating asset types...")

# Create asset types first
asset_types_data = [
  %{
    name: "CNC Machine",
    description: "Computer Numerical Control machining equipment",
    code: "CNC",
    category: "Manufacturing Equipment",
    tenant_id: tenant_id
  },
  %{
    name: "Air Compressor",
    description: "Compressed air generation equipment",
    code: "COMP",
    category: "Utilities",
    tenant_id: tenant_id
  },
  %{
    name: "Forklift",
    description: "Material handling equipment",
    code: "FORK",
    category: "Material Handling",
    tenant_id: tenant_id
  },
  %{
    name: "HVAC System",
    description: "Heating, ventilation, and air conditioning equipment",
    code: "HVAC",
    category: "HVAC",
    tenant_id: tenant_id
  },
  %{
    name: "Testing Equipment",
    description: "Quality control and testing machinery",
    code: "TEST",
    category: "Quality Control",
    tenant_id: tenant_id
  },
  %{
    name: "Hydraulic Press",
    description: "Hydraulic forming and pressing equipment",
    code: "PRESS",
    category: "Manufacturing Equipment",
    tenant_id: tenant_id
  },
  %{
    name: "Generator",
    description: "Power generation equipment",
    code: "GEN",
    category: "Power Generation",
    tenant_id: tenant_id
  }
]

# Insert asset types using changesets
asset_type_records = Enum.map(asset_types_data, fn type_attrs ->
  %AssetType{}
  |> AssetType.changeset(type_attrs)
  |> Repo.insert!()
end)

IO.puts("Created #{length(asset_type_records)} asset types")

# Map asset types for easy lookup
asset_types_by_code = Enum.reduce(asset_type_records, %{}, fn type, acc ->
  Map.put(acc, type.code, type)
end)

IO.puts("Creating assets...")

# Create assets using the schema
assets_data = [
  # Manufacturing Equipment
  %{
    name: "CNC Milling Machine #1",
    asset_number: "CNC-001",
    description: "High-precision CNC milling machine for aluminum parts",
    manufacturer: "Haas Automation",
    model: "VF-2SS",
    serial_number: "1234567890",
    status: "operational",
    criticality: "high",
    tenant_id: tenant_id,
    asset_type_id: asset_types_by_code["CNC"].id,
    purchase_cost: 85000.00,
    purchase_date: ~D[2022-03-15],
    commission_date: ~D[2022-04-01],
    warranty_expiry: ~D[2025-03-15]
  },
  %{
    name: "CNC Lathe #2",
    asset_number: "CNC-002",
    description: "Computer-controlled lathe for precision turning operations",
    manufacturer: "Mazak Corporation",
    model: "Quick Turn Nexus 250-II",
    serial_number: "QTN250-987",
    status: "operational",
    criticality: "high",
    tenant_id: tenant_id,
    asset_type_id: asset_types_by_code["CNC"].id,
    purchase_cost: 120000.00,
    purchase_date: ~D[2021-08-10],
    commission_date: ~D[2021-09-01],
    warranty_expiry: ~D[2024-08-10]
  },
  %{
    name: "Air Compressor System",
    asset_number: "COMP-001",
    description: "Industrial air compressor for pneumatic tools",
    manufacturer: "Atlas Copco",
    model: "GA 37 VSD",
    serial_number: "AC37VSD456",
    status: "operational",
    criticality: "medium",
    tenant_id: tenant_id,
    asset_type_id: asset_types_by_code["COMP"].id,
    purchase_cost: 25000.00,
    purchase_date: ~D[2020-06-01],
    commission_date: ~D[2020-06-15],
    warranty_expiry: ~D[2023-06-01]
  },
  %{
    name: "Forklift #1",
    asset_number: "FORK-001",
    description: "Electric forklift for material handling",
    manufacturer: "Toyota Material Handling",
    model: "8FBCU25",
    serial_number: "TY8FB789",
    status: "maintenance",
    criticality: "medium",
    tenant_id: tenant_id,
    asset_type_id: asset_types_by_code["FORK"].id,
    purchase_cost: 28000.00,
    purchase_date: ~D[2019-11-20],
    commission_date: ~D[2019-12-01],
    warranty_expiry: ~D[2022-11-20]
  },
  %{
    name: "HVAC Unit #1",
    asset_number: "HVAC-001",
    description: "Main facility heating and cooling system",
    manufacturer: "Carrier",
    model: "50TCA04",
    serial_number: "CAR50TCA123",
    status: "operational",
    criticality: "high",
    tenant_id: tenant_id,
    asset_type_id: asset_types_by_code["HVAC"].id,
    purchase_cost: 45000.00,
    purchase_date: ~D[2020-01-15],
    commission_date: ~D[2020-02-01],
    warranty_expiry: ~D[2025-01-15]
  },
  %{
    name: "Quality Testing Machine",
    asset_number: "QTM-001",
    description: "Coordinate measuring machine for quality control",
    manufacturer: "Carl Zeiss",
    model: "CONTURA G2",
    serial_number: "CZ-CTG2-555",
    status: "operational",
    criticality: "medium",
    tenant_id: tenant_id,
    asset_type_id: asset_types_by_code["TEST"].id,
    purchase_cost: 150000.00,
    purchase_date: ~D[2022-01-10],
    commission_date: ~D[2022-02-15],
    warranty_expiry: ~D[2027-01-10]
  },
  %{
    name: "Hydraulic Press",
    asset_number: "PRESS-001",
    description: "100-ton hydraulic press for forming operations",
    manufacturer: "Greenerd Press",
    model: "H-Frame 100T",
    serial_number: "GRD-H100-321",
    status: "operational",
    criticality: "medium",
    tenant_id: tenant_id,
    asset_type_id: asset_types_by_code["PRESS"].id,
    purchase_cost: 75000.00,
    purchase_date: ~D[2021-05-01],
    commission_date: ~D[2021-06-01],
    warranty_expiry: ~D[2024-05-01]
  },
  %{
    name: "Industrial Generator",
    asset_number: "GEN-001",
    description: "Backup power generator for emergency operations",
    manufacturer: "Caterpillar",
    model: "C18 ACERT",
    serial_number: "CAT-C18-777",
    status: "operational",
    criticality: "high",
    tenant_id: tenant_id,
    asset_type_id: asset_types_by_code["GEN"].id,
    purchase_cost: 95000.00,
    purchase_date: ~D[2021-03-01],
    commission_date: ~D[2021-04-15],
    warranty_expiry: ~D[2026-03-01]
  }
]

# Insert assets using changesets
asset_records = Enum.map(assets_data, fn asset_attrs ->
  %Asset{}
  |> Asset.changeset(asset_attrs)
  |> Repo.insert!()
end)

IO.puts("Created #{length(asset_records)} assets")

IO.puts("\n=== Test Data Creation Complete ===")
IO.puts("Sites: #{length(site_records)}")
IO.puts("Assets: #{length(asset_records)}")
IO.puts("Ready for testing and development!")
