# Database Schema and Field Reference

## Critical Field Mappings

This document tracks the correct field names across the system to prevent schema/template mismatches.

### PM Schedule Fields

#### ✅ Correct Fields (In Schema)
- `frequency` - Ecto.Enum (:daily, :weekly, :biweekly, :monthly, :quarterly, :semi_annual, :annual)
- `frequency_interval` - Integer (e.g., every 2 weeks, every 3 months)
- `meter_threshold` - Decimal (optional, for meter-based scheduling)
- `meter_unit` - String (optional, e.g., "hours", "cycles")
- `estimated_duration` - Decimal (hours)
- `required_skills` - Array of strings
- `required_tools` - Array of strings
- `required_parts` - Map (JSON)
- `ppe_required` - Array of strings
- `work_instructions` - Text
- `safety_notes` - Text

#### ❌ Incorrect Field Names (DO NOT USE)
- `frequency_value` - **DOES NOT EXIST** (use `frequency`)
- `frequency_unit` - **DOES NOT EXIST** (use `frequency`)

### User/Profile Fields

#### ✅ Correct Tables
- `users` - Authentication and basic user data
- `user_profiles` - Extended profile information

#### ❌ Incorrect Table Names (DO NOT USE)
- `user_details` - **DOES NOT EXIST** (use `user_profiles`)

### Assets Fields

#### ✅ Correct Fields (In Schema)
- `asset_number` - String (unique identifier)
- `name` - String
- `status` - Enum (:operational, :maintenance, :repair, :retired, :disposed)
- `criticality` - Enum (:critical, :high, :medium, :low)
- `asset_type_id` - Foreign key to asset_types
- `location_id` - Foreign key to asset_locations
- `manufacturer` - String
- `model` - String
- `serial_number` - String
- `install_date` - Date
- `warranty_expiry` - Date
- `purchase_cost` - Decimal
- `current_value` - Decimal

### Work Orders Fields

#### ✅ Correct Fields (In Schema)
- `work_order_number` - String (auto-generated)
- `title` - String
- `description` - Text
- `status` - Enum (:pending, :in_progress, :on_hold, :completed, :cancelled)
- `priority` - Enum (:low, :medium, :high, :critical)
- `work_type` - Enum (:corrective, :preventive, :inspection, :project)
- `scheduled_start` - DateTime
- `scheduled_end` - DateTime
- `actual_start` - DateTime
- `actual_end` - DateTime
- `assigned_to_id` - Foreign key to users
- `asset_id` - Foreign key to assets

### PM Execution Fields

#### ✅ Correct Fields (In Schema)
- `execution_number` - String (auto-generated)
- `pm_schedule_id` - Foreign key to pm_schedules
- `asset_id` - Foreign key to assets
- `status` - Enum (:scheduled, :in_progress, :completed, :skipped, :cancelled)
- `scheduled_date` - DateTime
- `completed_date` - DateTime
- `completed_by_id` - Foreign key to users
- `duration_hours` - Decimal
- `notes` - Text
- `checklist_results` - Map/JSON

### PM Tags Fields

#### ✅ Correct Fields (In Schema)
- `name` - String (tag name)
- `tag_type` - Enum (:skill, :tool, :ppe)
- `description` - Text
- `is_active` - Boolean
- `usage_count` - Integer
- `tenant_id` - Integer

## Common Patterns

### Filter Parameters

#### Server-Side Filtering (Query Building)
```elixir
opts = [
  search: "search term",           # String
  tag_type: "skill",              # String (converted to atom in query)
  status: "active",               # String
  active_only: true,              # Boolean
  sort_by: "name",                # String
  sort_order: "asc"               # String ("asc" or "desc")
]
```

#### Client-Side Filtering (Enum.filter)
```elixir
assigns = %{
  search_query: "",               # String
  filter_frequency: "all",        # String
  filter_status: "active",        # String
  selected_status: "all",         # String
  selected_type: "all",           # String or Integer
  selected_criticality: "all"     # String
}
```

### Event Handler Patterns

#### Filter Events
```elixir
def handle_event("filter_[field]", %{"[field]" => value}, socket)
def handle_event("search", %{"search" => %{"query" => query}}, socket)
def handle_event("sort", %{"field" => field}, socket)
```

#### CRUD Events
```elixir
def handle_event("new", _params, socket)
def handle_event("edit", %{"id" => id}, socket)
def handle_event("delete", %{"id" => id}, socket)
def handle_event("save", params, socket)
def handle_event("close_modal", _params, socket)
```

### Association Loading

#### Correct Preloading
```elixir
# PM Schedule with associations
pm_schedule = 
  Repo.get!(PmSchedule, id)
  |> Repo.preload([:asset, :created_by_user, :components, :checklist_items])

# Asset with associations  
asset =
  Repo.get!(Asset, id)
  |> Repo.preload([:asset_type, :location, :documents])

# Work Order with associations
work_order =
  Repo.get!(WorkOrder, id)
  |> Repo.preload([:asset, :assigned_to, :priority_code, :category])
```

## Query Builder Functions

### PM Tags
```elixir
PmTag.by_tenant(query, tenant_id)
PmTag.by_type(query, :skill | :tool | :ppe)
PmTag.active_only(query)
PmTag.search(query, "search term")
PmTag.order_by_name(query)
PmTag.order_by_usage(query)
```

### PM Schedules
```elixir
PmSchedule.by_tenant(query, tenant_id)
PmSchedule.by_frequency(query, :daily | :weekly | etc.)
PmSchedule.active_only(query)
PmSchedule.search_text(query, "search term")
PmSchedule.order_by_due_date(query)
```

### Assets
```elixir
Asset.by_tenant(query, tenant_id)
Asset.by_status(query, :operational | :maintenance | etc.)
Asset.by_criticality(query, :critical | :high | :medium | :low)
Asset.search(query, "search term")
```

## Enum Values

### PM Schedule Frequencies
```elixir
:daily
:weekly
:biweekly
:monthly
:quarterly
:semi_annual
:annual
```

### Asset Status
```elixir
:operational
:maintenance
:repair
:retired
:disposed
```

### Asset Criticality
```elixir
:critical
:high
:medium
:low
```

### Work Order Status
```elixir
:pending
:in_progress
:on_hold
:completed
:cancelled
```

### Work Order Priority
```elixir
:low
:medium
:high
:critical
```

### Work Order Type
```elixir
:corrective
:preventive
:inspection
:project
```

### PM Tag Type
```elixir
:skill
:tool
:ppe
```

## Template Helper Functions

### Frequency Display
```elixir
PmSchedule.frequency_label(:daily) # => "Daily"
PmSchedule.frequency_values() # => [:daily, :weekly, ...]
```

### Status Display
```elixir
# Use humanize for displaying enums
String.replace(to_string(status), "_", " ") |> String.capitalize()
# :in_progress => "In progress"
```

## Common Template Patterns

### Select Dropdowns
```heex
<select phx-change="filter_field" name="field" class="...">
  <option value="all">All [Items]</option>
  <%= for value <- @values do %>
    <option value={value} selected={@current_filter == to_string(value)}>
      <%= display_name(value) %>
    </option>
  <% end %>
</select>
```

### Conditional Styling
```heex
<div class={[
  "base-classes",
  if(@condition, do: "active-classes", else: "inactive-classes")
]}>
```

### Results Count
```heex
<div class="text-sm text-gray-600">
  <span class="font-medium"><%= length(@items) %></span>
  <%= if length(@items) == 1, do: "item", else: "items" %>
  <%= if @has_active_filters do %>
    <span class="text-gray-400">filtered</span>
  <% end %>
</div>
```

## Troubleshooting Checklist

When you encounter field-related errors:

1. **Check this document** for correct field names
2. **Inspect the schema** in `lib/shop1_cmms/[context]/[schema].ex`
3. **Check the migration** in `priv/repo/migrations/`
4. **Verify preloads** - are associations loaded?
5. **Check for typos** - `frequency_value` vs `frequency`
6. **Verify enum values** - use atoms not strings in pattern matching
7. **Check template vs assign** - does `@field` exist in socket assigns?

## Update Protocol

When adding new fields:

1. Create migration
2. Update schema
3. Update changeset
4. Update this document
5. Update any query builders
6. Update templates
7. Update tests
8. Update documentation

## Related Documentation

- `TABLE_MAP.md` - Complete database schema
- `FILTERING_FIXES_SUMMARY.md` - Filtering implementation details
- `PM_TAGS_CONFIGURATION_STATUS.md` - PM tags system documentation
- `SCHEMA_FIELD_REFERENCE.md` - This document
