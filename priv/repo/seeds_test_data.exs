# Test data seeding script for CMMS development
# Run with: mix run priv/repo/seeds_test_data.exs

alias Shop1Cmms.Repo
alias Shop1Cmms.Assets.Asset
alias Shop1Cmms.Maintenance.{WorkOrder, MaintenanceSchedule}
alias Shop1Cmms.Inventory.{Item, InventoryTransaction}
alias Shop1Cmms.Tenants.Site

# Get the tenant ID (should be 1 based on the logs)
tenant_id = 1

# Create sites first
sites = [
  %{
    name: "Main Manufacturing Plant",
    code: "MAIN",
    address: "123 Industrial Blvd, Manufacturing City, MC 12345",
    description: "Primary manufacturing facility",
    tenant_id: tenant_id,
    is_active: true,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Warehouse Facility",
    code: "WH01",
    address: "456 Storage Rd, Warehouse District, WD 67890",
    description: "Central warehouse and distribution center",
    tenant_id: tenant_id,
    is_active: true,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Quality Control Lab",
    code: "QC01",
    address: "789 Testing Ave, Lab Complex, LC 11111",
    description: "Quality control and testing laboratory",
    tenant_id: tenant_id,
    is_active: true,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  }
]

IO.puts("Creating sites...")
{site_count, site_ids} = Repo.insert_all("sites", sites, returning: [:id])
IO.puts("Created #{site_count} sites")

# Create assets
assets = [
  # Manufacturing Equipment
  %{
    name: "CNC Milling Machine #1",
    asset_tag: "CNC-001",
    description: "High-precision CNC milling machine for aluminum parts",
    manufacturer: "Haas Automation",
    model: "VF-2SS",
    serial_number: "1234567890",
    status: "operational",
    criticality: "high",
    category: "Production Equipment",
    subcategory: "CNC Machines",
    location: "Manufacturing Floor - Bay A",
    purchase_date: ~D[2022-01-15],
    commission_date: ~D[2022-02-01],
    warranty_expiry: ~D[2025-01-15],
    purchase_cost: Decimal.new("125000.00"),
    current_value: Decimal.new("100000.00"),
    site_id: Enum.at(site_ids, 0),
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Industrial Compressor #2",
    asset_tag: "COMP-002",
    description: "High-capacity air compressor for pneumatic systems",
    manufacturer: "Atlas Copco",
    model: "GA 37 VSD",
    serial_number: "AC-2023-4567",
    status: "operational",
    criticality: "high",
    category: "Utilities",
    subcategory: "Compressed Air",
    location: "Utility Room B",
    purchase_date: ~D[2023-03-10],
    commission_date: ~D[2023-03-20],
    warranty_expiry: ~D[2026-03-10],
    purchase_cost: Decimal.new("45000.00"),
    current_value: Decimal.new("38000.00"),
    site_id: Enum.at(site_ids, 0),
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Forklift - Electric",
    asset_tag: "FL-003",
    description: "Electric forklift for warehouse operations",
    manufacturer: "Toyota",
    model: "8FBRE20",
    serial_number: "TOY-2022-8901",
    status: "maintenance",
    criticality: "medium",
    category: "Material Handling",
    subcategory: "Forklifts",
    location: "Warehouse - Zone C",
    purchase_date: ~D[2022-06-01],
    commission_date: ~D[2022-06-05],
    warranty_expiry: ~D[2024-06-01],
    purchase_cost: Decimal.new("32000.00"),
    current_value: Decimal.new("24000.00"),
    site_id: Enum.at(site_ids, 1),
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "HVAC Unit - North Wing",
    asset_tag: "HVAC-004",
    description: "Commercial HVAC system for north wing climate control",
    manufacturer: "Carrier",
    model: "50TCQA06",
    serial_number: "CAR-2021-1122",
    status: "operational",
    criticality: "medium",
    category: "HVAC",
    subcategory: "Rooftop Units",
    location: "Roof - North Wing",
    purchase_date: ~D[2021-08-15],
    commission_date: ~D[2021-09-01],
    warranty_expiry: ~D[2024-08-15],
    purchase_cost: Decimal.new("18500.00"),
    current_value: Decimal.new("12000.00"),
    site_id: Enum.at(site_ids, 0),
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Quality Testing Machine",
    asset_tag: "QTM-005",
    description: "Automated quality testing and measurement system",
    manufacturer: "Zeiss",
    model: "CMM CONTURA G2",
    serial_number: "ZEI-2023-7788",
    status: "operational",
    criticality: "high",
    category: "Quality Control",
    subcategory: "Testing Equipment",
    location: "QC Lab - Station 1",
    purchase_date: ~D[2023-01-20],
    commission_date: ~D[2023-02-15],
    warranty_expiry: ~D[2026-01-20],
    purchase_cost: Decimal.new("85000.00"),
    current_value: Decimal.new("75000.00"),
    site_id: Enum.at(site_ids, 2),
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Conveyor System - Line A",
    asset_tag: "CONV-006",
    description: "Automated conveyor system for production line A",
    manufacturer: "Dorner",
    model: "2200 Series",
    serial_number: "DOR-2022-9955",
    status: "repair",
    criticality: "high",
    category: "Production Equipment",
    subcategory: "Conveyors",
    location: "Production Line A",
    purchase_date: ~D[2022-04-10],
    commission_date: ~D[2022-05-01],
    warranty_expiry: ~D[2025-04-10],
    purchase_cost: Decimal.new("28000.00"),
    current_value: Decimal.new("22000.00"),
    site_id: Enum.at(site_ids, 0),
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Emergency Generator",
    asset_tag: "GEN-007",
    description: "Backup diesel generator for emergency power",
    manufacturer: "Caterpillar",
    model: "C15 ACERT",
    serial_number: "CAT-2020-3344",
    status: "operational",
    criticality: "critical",
    category: "Utilities",
    subcategory: "Power Generation",
    location: "Generator Building",
    purchase_date: ~D[2020-11-30],
    commission_date: ~D[2020-12-15],
    warranty_expiry: ~D[2023-11-30],
    purchase_cost: Decimal.new("95000.00"),
    current_value: Decimal.new("65000.00"),
    site_id: Enum.at(site_ids, 0),
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Welding Station #3",
    asset_tag: "WELD-008",
    description: "MIG welding station with fume extraction",
    manufacturer: "Lincoln Electric",
    model: "Power MIG 360MP",
    serial_number: "LIN-2023-6677",
    status: "operational",
    criticality: "medium",
    category: "Production Equipment",
    subcategory: "Welding Equipment",
    location: "Fabrication Shop - Station 3",
    purchase_date: ~D[2023-05-15],
    commission_date: ~D[2023-05-20],
    warranty_expiry: ~D[2026-05-15],
    purchase_cost: Decimal.new("8500.00"),
    current_value: Decimal.new("7500.00"),
    site_id: Enum.at(site_ids, 0),
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  }
]

IO.puts("Creating assets...")
{asset_count, asset_ids} = Repo.insert_all("assets", assets, returning: [:id])
IO.puts("Created #{asset_count} assets")

# Create inventory items
inventory_items = [
  %{
    name: "Hydraulic Oil - ISO 46",
    sku: "OIL-HYD-46",
    description: "Premium hydraulic oil for industrial equipment",
    category: "Lubricants",
    subcategory: "Hydraulic Fluids",
    unit_of_measure: "Liters",
    cost_per_unit: Decimal.new("8.50"),
    reorder_level: 50,
    max_stock_level: 200,
    current_stock: 125,
    location: "Warehouse - Aisle B-3",
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Air Filter - HEPA",
    sku: "FILT-HEPA-001",
    description: "High-efficiency particulate air filter",
    category: "Filters",
    subcategory: "Air Filters",
    unit_of_measure: "Each",
    cost_per_unit: Decimal.new("45.00"),
    reorder_level: 10,
    max_stock_level: 50,
    current_stock: 25,
    location: "Warehouse - Aisle C-1",
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Industrial Bearing - 6205",
    sku: "BEAR-6205",
    description: "Deep groove ball bearing, 25mm bore",
    category: "Mechanical Parts",
    subcategory: "Bearings",
    unit_of_measure: "Each",
    cost_per_unit: Decimal.new("15.75"),
    reorder_level: 20,
    max_stock_level: 100,
    current_stock: 75,
    location: "Warehouse - Aisle A-5",
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "Safety Gloves - Cut Resistant",
    sku: "PPE-GLOVE-CR",
    description: "Cut-resistant safety gloves, Level 5 protection",
    category: "Safety Equipment",
    subcategory: "Personal Protective Equipment",
    unit_of_measure: "Pairs",
    cost_per_unit: Decimal.new("12.00"),
    reorder_level: 30,
    max_stock_level: 200,
    current_stock: 150,
    location: "Warehouse - Safety Section",
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  },
  %{
    name: "CNC Cutting Tool - End Mill",
    sku: "TOOL-EM-10MM",
    description: "Carbide end mill, 10mm diameter, 4-flute",
    category: "Cutting Tools",
    subcategory: "End Mills",
    unit_of_measure: "Each",
    cost_per_unit: Decimal.new("35.00"),
    reorder_level: 15,
    max_stock_level: 60,
    current_stock: 40,
    location: "Tool Crib - Rack 3",
    tenant_id: tenant_id,
    inserted_at: NaiveDateTime.utc_now(),
    updated_at: NaiveDateTime.utc_now()
  }
]

IO.puts("Creating inventory items...")
{item_count, _item_ids} = Repo.insert_all("inventory_items", inventory_items, returning: [:id])
IO.puts("Created #{item_count} inventory items")

IO.puts("Test data seeding completed!")
IO.puts("Summary:")
IO.puts("- #{site_count} sites created")
IO.puts("- #{asset_count} assets created")
IO.puts("- #{item_count} inventory items created")
