alias Shop1Cmms.Assets.{AssetLocation, AssetLocationType}
alias Shop1Cmms.Repo

# First create asset location types
location_types = [
  %{
    name: "Building",
    description: "Building or structure location",
    code: "BLDG",
    tenant_id: 1
  },
  %{
    name: "Area",
    description: "General area or zone",
    code: "AREA",
    tenant_id: 1
  },
  %{
    name: "Workshop",
    description: "Maintenance or production workshop",
    code: "SHOP",
    tenant_id: 1
  },
  %{
    name: "Office",
    description: "Office or administrative space",
    code: "OFF",
    tenant_id: 1
  }
]

# Insert each location type
created_location_types = Enum.map(location_types, fn location_type_attrs ->
  case Repo.insert(%AssetLocationType{} |> AssetLocationType.changeset(location_type_attrs)) do
    {:ok, location_type} ->
      IO.puts("✓ Created location type: #{location_type.name} (#{location_type.code})")
      location_type
    {:error, changeset} ->
      IO.puts("✗ Failed to create location type: #{location_type_attrs.name}")
      IO.inspect(changeset.errors)
      nil
  end
end) |> Enum.filter(& &1)

# Get the first location type ID for general building/area locations
default_location_type_id = if length(created_location_types) > 0 do
  hd(created_location_types).id
else
  IO.puts("No location types created, cannot create locations")
  nil
end

# Sample asset locations for testing
if default_location_type_id do
  locations = [
    %{
      name: "Main Warehouse",
      description: "Primary warehouse storage area",
      code: "WH-01",
      address: "123 Industrial Dr",
      tenant_id: 1,
      location_type_id: default_location_type_id,
      is_active: true
    },
    %{
      name: "Production Floor",
      description: "Manufacturing production area",
      code: "PROD-01",
      address: "123 Industrial Dr - Building A",
      tenant_id: 1,
      location_type_id: default_location_type_id,
      is_active: true
    },
    %{
      name: "Maintenance Shop",
      description: "Equipment maintenance workshop",
      code: "MAINT-01",
      address: "123 Industrial Dr - Building B",
      tenant_id: 1,
      location_type_id: default_location_type_id,
      is_active: true
    },
    %{
      name: "Office Area",
      description: "Administrative offices",
      code: "OFF-01",
      address: "123 Industrial Dr - Front Building",
      tenant_id: 1,
      location_type_id: default_location_type_id,
      is_active: true
    }
  ]

  # Insert each location
  Enum.each(locations, fn location_attrs ->
    case Repo.insert(%AssetLocation{} |> AssetLocation.changeset(location_attrs)) do
      {:ok, location} ->
        IO.puts("✓ Created location: #{location.name} (#{location.code})")
      {:error, changeset} ->
        IO.puts("✗ Failed to create location: #{location_attrs.name}")
        IO.inspect(changeset.errors)
    end
  end)
else
  IO.puts("Skipping location creation - no valid location type available")
end

IO.puts("\nDone creating sample asset locations!")
