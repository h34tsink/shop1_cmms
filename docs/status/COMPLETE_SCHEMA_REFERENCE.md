# Complete Schema Reference

This document provides a comprehensive reference of all database schemas and their fields to prevent field name mismatches.

## Core User & Authentication Tables

### users
- `id` (bigserial) - Primary key
- `username` (string) - NOT NULL, unique
- `password_hash` (string)
- `is_active` (boolean) - default: true
- `inserted_at`, `updated_at` (timestamps)

**Note**: There is NO `user_details` table. User profile information should reference `user_profiles` or be handled through `user_tenant_assignments`.

### user_tenant_assignments
- `id` (bigserial)
- `user_id` (bigint) → users.id
- `tenant_id` (bigint) → tenants.id
- `role_id` (bigint) → cmms_user_roles.id
- `default_site_id` (bigint) → sites.id (nullable)
- `is_active` (boolean) - default: true
- `inserted_at`, `updated_at`

### cmms_user_roles
- `id` (bigserial)
- `name` (string) - NOT NULL
- `display_name` (string) - NOT NULL
- `description` (text)
- `permissions` (text[]) - array, default: []
- `is_active` (boolean) - default: true
- `inserted_at`, `updated_at`

## Tenancy Tables

### tenants
- `id` (bigserial)
- `name` (string) - NOT NULL
- `display_name` (string)
- `description` (text)
- `address` (text)
- `is_active` (boolean) - default: true
- `inserted_at`, `updated_at`

### sites
- `id` (bigserial)
- `tenant_id` (bigint) → tenants.id
- `name` (string) - NOT NULL
- `display_name` (string)
- `description` (text)
- `address` (text)
- `is_active` (boolean) - default: true
- `inserted_at`, `updated_at`

## Asset Management Tables

### assets
- `id` (binary_id/UUID)
- `asset_number` (string) - NOT NULL, unique per tenant
- `name` (string) - NOT NULL
- `description` (text)
- `manufacturer` (string)
- `model` (string)
- `serial_number` (string)
- `purchase_date` (date)
- `purchase_cost` (decimal)
- `warranty_expiry_date` (date)
- `criticality` (enum: :low, :medium, :high, :critical)
- `status` (enum: :active, :inactive, :maintenance, :retired)
- `notes` (text)
- `is_active` (boolean) - default: true
- `asset_type_id` (binary_id) → asset_types.id
- `asset_location_id` (binary_id) → asset_locations.id
- `parent_asset_id` (binary_id) → assets.id (nullable, for hierarchies)
- `tenant_id` (integer) - NOT NULL
- `created_by` (bigint) → users.id (nullable)
- `updated_by` (bigint) → users.id (nullable)
- `inserted_at`, `updated_at`

### asset_types
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `description` (text)
- `code` (string) - NOT NULL, unique per tenant
- `category` (string) - NOT NULL (e.g., Equipment, Tools, Vehicles)
- `icon` (string)
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### asset_locations
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `description` (text)
- `code` (string) - NOT NULL, unique per tenant
- `address` (text)
- `location_type_id` (binary_id) → asset_location_types.id (nullable)
- `parent_location_id` (binary_id) → asset_locations.id (nullable)
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### asset_location_types
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `description` (text)
- `code` (string) - NOT NULL, unique per tenant
- `icon` (string)
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

## Meter Management Tables

### meter_types
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `description` (text)
- `unit` (string) - NOT NULL (e.g., hours, miles, cycles)
- `data_type` (string) - NOT NULL, default: "integer"
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### asset_meters
- `id` (binary_id/UUID)
- `current_reading` (decimal) - precision: 12, scale: 2, default: 0.0
- `last_reading_date` (utc_datetime)
- `reading_frequency` (integer) - days between readings
- `next_reading_due` (date)
- `is_active` (boolean) - default: true
- `asset_id` (binary_id) → assets.id
- `meter_type_id` (binary_id) → meter_types.id
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### meter_readings
- `id` (binary_id/UUID)
- `reading` (decimal) - precision: 12, scale: 2, NOT NULL
- `reading_date` (utc_datetime) - NOT NULL
- `reading_type` (string) - default: "manual" (manual, automatic, estimated)
- `notes` (text)
- `asset_meter_id` (binary_id) → asset_meters.id
- `recorded_by` (bigint) → users.id (nullable)
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

## PM (Preventive Maintenance) Tables

### pm_schedules
**IMPORTANT**: Fields changed - use `frequency` (enum) and `frequency_interval` (integer)
- `id` (binary_id/UUID)
- `schedule_number` (string) - NOT NULL, unique per tenant (e.g., "PM-0001")
- `title` (string) - NOT NULL
- `description` (text)
- `frequency` (enum) - :daily, :weekly, :monthly, :quarterly, :annual
- `frequency_interval` (integer) - default: 1 (e.g., every 2 weeks = frequency: weekly, frequency_interval: 2)
- `meter_threshold` (decimal) - nullable (for meter-based schedules)
- `meter_unit` (string) - nullable
- `work_instructions` (text)
- `estimated_duration` (decimal) - hours
- `required_skills` (array of strings) - {:array, :string}
- `required_tools` (array of strings) - {:array, :string}
- `required_parts` (map/jsonb) - JSON data
- `safety_notes` (text)
- `ppe_required` (array of strings) - {:array, :string}
- `last_completed_date` (utc_datetime)
- `next_due_date` (utc_datetime)
- `is_active` (boolean) - default: true
- `asset_id` (binary_id) → assets.id
- `created_by` (bigint) → users.id (nullable)
- `updated_by` (bigint) → users.id (nullable)
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

**DO NOT USE**: `frequency_value`, `frequency_unit` - these fields DO NOT EXIST

### pm_tags
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `tag_type` (enum) - :skill, :tool, :ppe
- `description` (string)
- `is_active` (boolean) - default: true
- `usage_count` (integer) - default: 0
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### pm_schedule_components
- `id` (binary_id/UUID)
- `component_name` (string) - NOT NULL
- `component_description` (text)
- `component_location` (string)
- `maintenance_procedure` (text)
- `pm_schedule_id` (binary_id) → pm_schedules.id
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### pm_checklist_items
- `id` (binary_id/UUID)
- `sequence` (integer) - NOT NULL
- `item_description` (text) - NOT NULL
- `expected_result` (text)
- `pass_fail` (boolean) - default: false
- `pm_schedule_id` (binary_id) → pm_schedules.id
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### pm_executions
- `id` (binary_id/UUID)
- `execution_number` (string) - NOT NULL, unique (e.g., "PM-EXE-0001")
- `execution_date` (utc_datetime) - NOT NULL
- `completed_date` (utc_datetime)
- `status` (string) - default: "in_progress" (in_progress, completed, cancelled)
- `notes` (text)
- `actual_duration` (decimal)
- `pm_schedule_id` (binary_id) → pm_schedules.id
- `asset_id` (binary_id) → assets.id
- `performed_by` (bigint) → users.id (nullable)
- `reviewed_by` (bigint) → users.id (nullable)
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

## Work Order Tables

### work_orders
- `id` (binary_id/UUID)
- `work_order_number` (string) - NOT NULL, unique
- `title` (string) - NOT NULL
- `description` (text)
- `status` (enum) - default: :open (:open, :in_progress, :completed, :cancelled)
- `priority` (enum) - default: :medium (:low, :medium, :high, :critical)
- `scheduled_start` (utc_datetime)
- `scheduled_end` (utc_datetime)
- `actual_start` (utc_datetime)
- `actual_end` (utc_datetime)
- `estimated_hours` (decimal)
- `actual_hours` (decimal)
- `notes` (text)
- `asset_id` (binary_id) → assets.id
- `assigned_to` (bigint) → users.id (nullable)
- `created_by` (bigint) → users.id (nullable)
- `pm_schedule_id` (binary_id) → pm_schedules.id (nullable, if PM-generated)
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

## Components & Parts

### components
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `description` (text)
- `component_type` (string)
- `manufacturer` (string)
- `model` (string)
- `serial_number` (string)
- `part_number` (string)
- `specifications` (text)
- `is_active` (boolean) - default: true
- `asset_id` (binary_id) → assets.id (nullable)
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

## Configuration/Metadata Tables

### manufacturers
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `code` (string)
- `description` (text)
- `website` (string)
- `contact_email` (string)
- `contact_phone` (string)
- `address` (text)
- `notes` (text)
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### departments
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `code` (string)
- `description` (text)
- `manager_name` (string)
- `contact_email` (string)
- `contact_phone` (string)
- `cost_center` (string)
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### suppliers
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `code` (string)
- `description` (text)
- `type` (string) - vendor, contractor, service_provider
- `website` (string)
- `contact_name` (string)
- `contact_email` (string)
- `contact_phone` (string)
- `address` (text)
- `notes` (text)
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### priority_codes
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `code` (string)
- `description` (text)
- `level` (integer) - NOT NULL (1=Low, 2=Medium, 3=High, 4=Critical)
- `color` (string)
- `response_time_hours` (integer)
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### maintenance_categories
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `code` (string)
- `description` (text)
- `type` (string) - NOT NULL (preventive, corrective, predictive, emergency, condition_based)
- `icon` (string)
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### custom_fields
- `id` (binary_id/UUID)
- `entity_type` (string) - NOT NULL (asset, work_order, location, etc.)
- `field_name` (string) - NOT NULL
- `field_label` (string) - NOT NULL
- `field_type` (string) - NOT NULL (text, number, date, boolean, select, multi_select)
- `field_options` (text[]) - array for select/multi_select
- `is_required` (boolean) - default: false
- `default_value` (text)
- `help_text` (text)
- `display_order` (integer)
- `is_active` (boolean) - default: true
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

### custom_field_values
- `id` (binary_id/UUID)
- `custom_field_id` (binary_id) → custom_fields.id
- `entity_type` (string) - NOT NULL
- `entity_id` (binary_id) - NOT NULL
- `field_value` (text)
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

## Document Management

### asset_documents
- `id` (binary_id/UUID)
- `name` (string) - NOT NULL
- `description` (text)
- `file_path` (string) - NOT NULL
- `file_size` (integer)
- `file_type` (string)
- `document_type` (string) - manual, schematic, warranty, invoice, etc.
- `version` (string)
- `uploaded_by` (bigint) → users.id (nullable)
- `asset_id` (binary_id) → assets.id (nullable)
- `pm_schedule_id` (binary_id) → pm_schedules.id (nullable)
- `tenant_id` (integer) - NOT NULL
- `inserted_at`, `updated_at`

## Common Patterns & Best Practices

### Primary Keys
- Most tables use `binary_id` (UUID) for primary keys
- User/role/tenant tables use `bigserial` (auto-incrementing integer)
- Always use the appropriate foreign key type when referencing

### Tenant Isolation
- All operational tables have `tenant_id` (integer) - NOT NULL
- Always filter queries by tenant_id for multi-tenancy
- Core auth tables (users, tenants) don't have tenant_id themselves

### Audit Fields
- `created_by`, `updated_by` reference users.id (nullable)
- `inserted_at`, `updated_at` are automatic timestamps
- Use nullable for audit fields to handle system-generated records

### Status/State Fields
- Use Ecto.Enum for defined states (e.g., asset.status, work_order.status)
- Use `is_active` boolean for soft deletes/archiving
- Enums are atoms in Elixir code, strings in DB

### Array Fields
- `required_skills`, `required_tools`, `ppe_required` use {:array, :string}
- Access in templates: `Enum.join(schedule.required_skills, ", ")`
- Use `|>` operator carefully with nil values

### JSON/Map Fields
- `required_parts` in pm_schedules is a map
- Access: `schedule.required_parts["part_key"]`
- Display: iterate with `Enum.map(schedule.required_parts, fn {k, v} -> ...)`

## Common Pitfalls to Avoid

1. **DO NOT** assume `user_details` table exists - it doesn't
2. **DO NOT** use `frequency_value` and `frequency_unit` - use `frequency` and `frequency_interval`
3. **DO NOT** forget to filter by tenant_id in all queries
4. **DO NOT** use integer IDs when table uses binary_id (UUID)
5. **DO NOT** access array/map fields without nil checks
6. **DO NOT** use string values for enum fields in queries (use atoms)
7. **DO NOT** forget that foreign keys must match parent table's primary key type

## Quick Reference: Field Access in Templates

```heex
<!-- Enum field (status, priority, etc) -->
<%= asset.status %> <!-- outputs atom -->

<!-- Array field -->
<%= Enum.join(schedule.required_skills, ", ") %>

<!-- Map field -->
<%= for {part, qty} <- schedule.required_parts do %>
  <div><%= part %>: <%= qty %></div>
<% end %>

<!-- Date/DateTime -->
<%= Calendar.strftime(schedule.next_due_date, "%B %d, %Y") %>

<!-- Association (must be preloaded) -->
<%= schedule.asset.name %>

<!-- Decimal -->
<%= Decimal.to_string(schedule.estimated_duration) %> hours
```

## Testing Field Access

When encountering KeyError:
1. Check this document for correct field name
2. Verify field exists in schema module (lib/shop1_cmms/*/*.ex)
3. Check migration file to confirm DB column name
4. Ensure associations are preloaded if accessing related data
5. Use `IO.inspect(record, label: "Record")` to see actual struct fields
