# Script to add test components to all existing assets
# Run with: mix run priv/repo/seed_test_components.exs

alias Shop1Cmms.Repo
alias Shop1Cmms.Assets
alias Shop1Cmms.Assets.{Asset, Component}

IO.puts("Starting to seed test components for all assets...")

# Get all assets from all tenants
assets = Repo.all(Asset) |> Repo.preload(:asset_type)

IO.puts("Found #{length(assets)} assets to process")

# Component templates - different types of components commonly found on equipment
component_templates = [
  # Motors and Drives
  %{
    name: "Main Drive Motor",
    component_type: "Motor",
    manufacturer: "Siemens",
    model: "1LA7",
    status: :active,
    description: "Primary electric motor for main drive system"
  },
  %{
    name: "Variable Frequency Drive",
    component_type: "VFD",
    manufacturer: "ABB",
    model: "ACS580",
    status: :active,
    description: "VFD controlling main motor speed"
  },
  
  # Pumps and Hydraulics
  %{
    name: "Hydraulic Pump",
    component_type: "Pump",
    manufacturer: "Parker",
    model: "PV140",
    status: :active,
    description: "Main hydraulic system pump"
  },
  %{
    name: "Cooling Pump",
    component_type: "Pump",
    manufacturer: "Grundfos",
    model: "CR 5-12",
    status: :active,
    description: "Cooling system circulation pump"
  },
  
  # Bearings and Mechanical
  %{
    name: "Front Bearing Assembly",
    component_type: "Bearing",
    manufacturer: "SKF",
    model: "6310",
    status: :active,
    description: "Front main shaft bearing"
  },
  %{
    name: "Rear Bearing Assembly",
    component_type: "Bearing",
    manufacturer: "SKF",
    model: "6312",
    status: :active,
    description: "Rear main shaft bearing"
  },
  
  # Belts and Chains
  %{
    name: "Drive Belt",
    component_type: "Belt",
    manufacturer: "Gates",
    model: "5VX",
    status: :active,
    description: "Main drive transmission belt"
  },
  
  # Filters
  %{
    name: "Oil Filter",
    component_type: "Filter",
    manufacturer: "Baldwin",
    model: "PT9237",
    status: :active,
    description: "Hydraulic oil filter cartridge"
  },
  %{
    name: "Air Filter",
    component_type: "Filter",
    manufacturer: "Donaldson",
    model: "P181050",
    status: :active,
    description: "Intake air filter element"
  },
  
  # Sensors and Controls
  %{
    name: "Temperature Sensor",
    component_type: "Sensor",
    manufacturer: "Honeywell",
    model: "TD4A",
    status: :active,
    description: "Oil temperature monitoring sensor"
  },
  %{
    name: "Pressure Sensor",
    component_type: "Sensor",
    manufacturer: "Wika",
    model: "S-20",
    status: :active,
    description: "Hydraulic pressure transducer"
  },
  
  # Electrical
  %{
    name: "Control Panel",
    component_type: "Electrical",
    manufacturer: "Schneider Electric",
    model: "VW3A3",
    status: :active,
    description: "Main electrical control cabinet"
  },
  %{
    name: "Power Supply",
    component_type: "Electrical",
    manufacturer: "Phoenix Contact",
    model: "QUINT",
    status: :active,
    description: "24V DC power supply unit"
  }
]

# Track statistics
stats = %{
  assets_processed: 0,
  components_created: 0,
  components_skipped: 0,
  errors: 0
}

Enum.each(assets, fn asset ->
  IO.puts("\nProcessing asset: #{asset.name} (#{asset.asset_number})")
  
  # Determine how many components to add based on asset type or randomize
  num_components = Enum.random(3..7)  # Random 3-7 components per asset
  
  # Randomly select components from templates
  selected_templates = Enum.take_random(component_templates, num_components)
  
  Enum.each(selected_templates, fn template ->
    # Generate install date (sometime in the past year)
    days_ago = Enum.random(1..365)
    install_date = Date.add(Date.utc_today(), -days_ago)
    
    # Add some variation to serial numbers
    serial_suffix = :crypto.strong_rand_bytes(4) |> Base.encode16() |> binary_part(0, 6)
    
    component_attrs = template
    |> Map.put(:asset_id, asset.id)
    |> Map.put(:tenant_id, asset.tenant_id)
    |> Map.put(:install_date, install_date)
    |> Map.put(:serial_number, "SN-#{serial_suffix}")
    
    case Assets.create_component(component_attrs) do
      {:ok, component} ->
        IO.puts("  ✓ Created: #{component.name} (#{component.component_type})")
        stats = Map.update!(stats, :components_created, &(&1 + 1))
        
      {:error, changeset} ->
        IO.puts("  ✗ Failed to create #{template.name}: #{inspect(changeset.errors)}")
        stats = Map.update!(stats, :errors, &(&1 + 1))
    end
  end)
  
  stats = Map.update!(stats, :assets_processed, &(&1 + 1))
end)

IO.puts("\n" <> String.duplicate("=", 60))
IO.puts("Component Seeding Complete!")
IO.puts(String.duplicate("=", 60))
IO.puts("Assets Processed:     #{stats.assets_processed}")
IO.puts("Components Created:   #{stats.components_created}")
IO.puts("Errors:               #{stats.errors}")
IO.puts(String.duplicate("=", 60))

# Show sample of created components
IO.puts("\nSample of created components:")
components = Repo.all(Component) 
  |> Repo.preload(:asset)
  |> Enum.take(10)

Enum.each(components, fn c ->
  IO.puts("  • #{c.name} (#{c.component_type}) on #{c.asset.name}")
end)

IO.puts("\n✓ All done! Components are ready for testing.")
