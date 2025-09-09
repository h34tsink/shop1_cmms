# Data Migration Guide

This guide covers importing data from your existing Odoo and COGZ systems into the new CMMS.

## Migration Scripts Structure

```
data_migration/
├── odoo/
│   ├── odoo_extractor.py      # Extract data from Odoo
│   ├── odoo_mapper.exs        # Elixir mapping logic
│   └── sample_exports/        # Sample CSV exports
├── cogz/
│   ├── cogz_extractor.sql     # SQL queries for COGZ
│   ├── cogz_mapper.exs        # Elixir mapping logic
│   └── sample_exports/        # Sample exports
└── import_runner.exs          # Main import orchestrator
```

## Odoo Data Extraction

### 1. Assets and Equipment
Export from Odoo's `maintenance.equipment` model:

```python
# odoo_extractor.py
import csv
from odoo import api, fields, models

def export_equipment():
    equipment = env['maintenance.equipment'].search([])
    
    with open('equipment_export.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([
            'id', 'name', 'serial_no', 'model', 'category', 
            'location', 'partner_id', 'assign_date', 'cost',
            'warranty_date', 'color', 'scrap_date', 'note'
        ])
        
        for eq in equipment:
            writer.writerow([
                eq.id, eq.name, eq.serial_no, eq.model,
                eq.category_id.name if eq.category_id else '',
                eq.location, eq.partner_id.name if eq.partner_id else '',
                eq.assign_date, eq.cost, eq.warranty_date,
                eq.color, eq.scrap_date, eq.note or ''
            ])
```

### 2. Maintenance Requests
Export from `maintenance.request`:

```python
def export_maintenance_requests():
    requests = env['maintenance.request'].search([])
    
    with open('maintenance_requests.csv', 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow([
            'id', 'name', 'description', 'request_date', 'schedule_date',
            'close_date', 'equipment_id', 'equipment_name', 'stage_id',
            'priority', 'maintenance_type', 'owner_user_id', 'user_id',
            'duration', 'kanban_state'
        ])
        
        for req in requests:
            writer.writerow([
                req.id, req.name, req.description, req.request_date,
                req.schedule_date, req.close_date, req.equipment_id.id,
                req.equipment_id.name, req.stage_id.name, req.priority,
                req.maintenance_type, req.owner_user_id.id if req.owner_user_id else '',
                req.user_id.id if req.user_id else '', req.duration, req.kanban_state
            ])
```

## COGZ Data Extraction

### Sample SQL queries for COGZ database:

```sql
-- cogz_extractor.sql

-- Export Equipment/Assets
SELECT 
    EquipmentID,
    EquipmentName,
    EquipmentNumber,
    SerialNumber,
    Model,
    Manufacturer,
    Location,
    CriticalityLevel,
    Status,
    InstallDate,
    WarrantyDate,
    Notes
FROM Equipment
WHERE Active = 1;

-- Export Work Orders
SELECT 
    WorkOrderID,
    WorkOrderNumber,
    EquipmentID,
    Description,
    WorkType, -- PM, Repair, etc.
    Priority,
    Status,
    RequestedBy,
    AssignedTo,
    RequestDate,
    ScheduledDate,
    StartDate,
    CompletionDate,
    EstimatedHours,
    ActualHours,
    Comments
FROM WorkOrders
WHERE CreatedDate >= '2020-01-01'; -- Adjust date range as needed

-- Export PM Schedules
SELECT 
    ScheduleID,
    EquipmentID,
    TaskDescription,
    FrequencyDays,
    FrequencyType, -- Days, Hours, Miles, etc.
    FrequencyValue,
    LastCompleted,
    NextDue,
    Active,
    AssignedTo
FROM PMSchedules
WHERE Active = 1;

-- Export Parts/Inventory
SELECT 
    PartID,
    PartNumber,
    Description,
    Location,
    UnitOfMeasure,
    MinQuantity,
    MaxQuantity,
    CurrentQuantity,
    UnitCost,
    VendorName
FROM Parts
WHERE Active = 1;
```

## Elixir Import Scripts

### Odoo Mapping Logic

```elixir
# odoo_mapper.exs
defmodule DataMigration.OdooMapper do
  @moduledoc """
  Maps Odoo maintenance data to new CMMS schema
  """
  
  alias Shop1Cmms.{Assets, Maintenance, Work, Accounts}
  alias Shop1Cmms.Repo
  
  def import_equipment(csv_path, tenant_id, site_id) do
    csv_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.map(&map_equipment(&1, tenant_id, site_id))
    |> Enum.each(&create_asset/1)
  end
  
  defp map_equipment(row, tenant_id, site_id) do
    %{
      tenant_id: tenant_id,
      site_id: site_id,
      name: row["name"],
      tag: row["serial_no"] || "MIGRATED-#{row["id"]}",
      location: row["location"],
      manufacturer: extract_manufacturer(row["model"]),
      model: row["model"],
      serial_number: row["serial_no"],
      installation_date: parse_date(row["assign_date"]),
      warranty_expires: parse_date(row["warranty_date"]),
      status: map_status(row["color"]),
      criticality: map_criticality(row["category"]),
      notes: row["note"]
    }
  end
  
  defp map_status(color) do
    case color do
      "0" -> "active"      # Green in Odoo
      "1" -> "maintenance" # Yellow
      "2" -> "broken"      # Red
      _ -> "active"
    end
  end
  
  defp map_criticality(category) do
    case String.downcase(category || "") do
      s when s =~ "critical" -> 1
      s when s =~ "high" -> 2
      s when s =~ "medium" -> 3
      s when s =~ "low" -> 4
      _ -> 3
    end
  end
  
  def import_maintenance_requests(csv_path, tenant_id) do
    csv_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.map(&map_work_order(&1, tenant_id))
    |> Enum.each(&create_work_order/1)
  end
  
  defp map_work_order(row, tenant_id) do
    asset = find_asset_by_odoo_id(row["equipment_id"], tenant_id)
    
    %{
      tenant_id: tenant_id,
      site_id: asset && asset.site_id,
      number: "MIGRATED-#{row["id"]}",
      title: row["name"],
      description: row["description"],
      work_type: map_work_type(row["maintenance_type"]),
      priority: map_priority(row["priority"]),
      status: map_wo_status(row["stage_id"]),
      asset_id: asset && asset.id,
      due_date: parse_date(row["schedule_date"]),
      actual_start: parse_datetime(row["request_date"]),
      actual_completion: parse_datetime(row["close_date"]),
      estimated_hours: parse_float(row["duration"]),
      # Map users based on email or create placeholders
      requested_by: find_or_create_user(row["owner_user_id"], tenant_id),
      assigned_to: find_or_create_user(row["user_id"], tenant_id)
    }
  end
  
  # Helper functions
  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil
  defp parse_date(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} -> date
      _ -> nil
    end
  end
  
  defp find_asset_by_odoo_id(odoo_id, tenant_id) do
    # You'll need to track Odoo IDs during asset import
    # or match by serial number/name
    Assets.get_asset_by_tag("MIGRATED-#{odoo_id}", tenant_id)
  end
end
```

### COGZ Mapping Logic

```elixir
# cogz_mapper.exs
defmodule DataMigration.CogzMapper do
  @moduledoc """
  Maps COGZ maintenance data to new CMMS schema
  """
  
  def import_equipment(csv_path, tenant_id, site_id) do
    csv_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.map(&map_cogz_equipment(&1, tenant_id, site_id))
    |> Enum.each(&create_asset/1)
  end
  
  defp map_cogz_equipment(row, tenant_id, site_id) do
    %{
      tenant_id: tenant_id,
      site_id: site_id,
      name: row["EquipmentName"],
      tag: row["EquipmentNumber"],
      location: row["Location"],
      manufacturer: row["Manufacturer"],
      model: row["Model"],
      serial_number: row["SerialNumber"],
      installation_date: parse_date(row["InstallDate"]),
      warranty_expires: parse_date(row["WarrantyDate"]),
      status: map_cogz_status(row["Status"]),
      criticality: String.to_integer(row["CriticalityLevel"] || "3"),
      notes: row["Notes"]
    }
  end
  
  def import_pm_schedules(csv_path, tenant_id) do
    csv_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.each(&create_pm_schedule(&1, tenant_id))
  end
  
  defp create_pm_schedule(row, tenant_id) do
    # First create PM template if it doesn't exist
    template_attrs = %{
      tenant_id: tenant_id,
      name: row["TaskDescription"],
      frequency_days: parse_frequency_to_days(row["FrequencyType"], row["FrequencyValue"]),
      description: row["TaskDescription"]
    }
    
    {:ok, template} = Maintenance.create_or_find_pm_template(template_attrs)
    
    # Find the asset
    asset = find_asset_by_cogz_id(row["EquipmentID"], tenant_id)
    
    if asset do
      schedule_attrs = %{
        tenant_id: tenant_id,
        asset_id: asset.id,
        pm_template_id: template.id,
        last_completed_at: parse_datetime(row["LastCompleted"]),
        active: row["Active"] == "1"
      }
      
      Maintenance.create_pm_schedule(schedule_attrs)
    end
  end
  
  defp parse_frequency_to_days("Days", value), do: String.to_integer(value)
  defp parse_frequency_to_days("Weeks", value), do: String.to_integer(value) * 7
  defp parse_frequency_to_days("Months", value), do: String.to_integer(value) * 30
  defp parse_frequency_to_days("Years", value), do: String.to_integer(value) * 365
  defp parse_frequency_to_days(_, value), do: String.to_integer(value) # Default to days
end
```

## Import Runner Script

```elixir
# import_runner.exs
defmodule DataMigration.ImportRunner do
  @moduledoc """
  Orchestrates the data migration process
  """
  
  def run_full_migration() do
    tenant = get_or_create_tenant()
    main_site = get_or_create_main_site(tenant.id)
    
    IO.puts("Starting data migration for tenant: #{tenant.name}")
    
    # Import order is important due to foreign key constraints
    import_steps = [
      {"Users (if needed)", &import_users/2},
      {"Assets from Odoo", &import_odoo_assets/2},
      {"Assets from COGZ", &import_cogz_assets/2},
      {"PM Templates and Schedules", &import_pm_data/2},
      {"Work Orders", &import_work_orders/2},
      {"Parts/Inventory", &import_inventory/2}
    ]
    
    Enum.each(import_steps, fn {step_name, step_func} ->
      IO.puts("Running: #{step_name}...")
      step_func.(tenant.id, main_site.id)
      IO.puts("✓ Completed: #{step_name}")
    end)
    
    IO.puts("Migration completed successfully!")
  end
  
  defp get_or_create_tenant() do
    case Shop1Cmms.Tenants.get_tenant_by_slug("shop1") do
      nil -> 
        {:ok, tenant} = Shop1Cmms.Tenants.create_tenant(%{
          name: "Shop1 Manufacturing",
          slug: "shop1"
        })
        tenant
      tenant -> tenant
    end
  end
end
```

## Usage Instructions

1. **Prepare Export Files**: Export data from Odoo and COGZ using the provided scripts
2. **Review Data**: Check the exported CSV files for completeness and data quality
3. **Run Migration**: Execute the import runner script
4. **Verify Results**: Check imported data in the new system
5. **Data Cleanup**: Handle any mapping issues or missing data

## Data Validation Checklist

- [ ] All critical assets imported with correct tags
- [ ] PM schedules properly linked to assets
- [ ] Work order history preserved with correct statuses
- [ ] User accounts created and properly assigned
- [ ] Inventory quantities and locations accurate
- [ ] No orphaned records (check foreign key constraints)

## Common Issues and Solutions

1. **Duplicate Asset Tags**: Add suffixes or prefixes to resolve conflicts
2. **Missing Users**: Create placeholder users or map to existing accounts
3. **Date Format Issues**: Standardize date formats in CSV preprocessing
4. **Character Encoding**: Ensure UTF-8 encoding for special characters
5. **Large Datasets**: Process in batches to avoid memory issues
