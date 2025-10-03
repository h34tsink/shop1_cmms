# Database Table Mapping Reference

## User-Related Tables

### `users` (Core Authentication)
**Primary Key:** `id` (bigint)
**Purpose:** Core user authentication and account data
**Key Fields:**
- `username` (string) - unique login name
- `password_hash` (string) - hashed password
- `is_active` (boolean) - account status
- `cmms_enabled` (boolean) - CMMS access flag
- `last_cmms_login` (timestamp)
- `preferences` (jsonb)
- `inserted_at`, `updated_at` (timestamps)

**Schema:** `Shop1Cmms.Accounts.User`

### `user_profiles` (Extended Profile)
**Primary Key:** `id` (integer)
**Purpose:** Extended user profile information (Shop1FinishLine integration)
**Key Fields:**
- `first_name`, `last_name`, `display_name`, `full_name` - name fields
- `email`, `phone`, `mobile` - contact info
- `department`, `job_title` - work information
- `avatar_url`, `bio`, `location` - profile details

**Note:** This table is part of the Shop1FinishLine system and provides extended profile data beyond basic authentication

### `user_profile_assignments` (User-Profile Linking)
**Purpose:** Links users to their profiles
**Key Fields:**
- `user_id` (references users)
- `profile_id` (references user_profiles)

### `user_tenant_assignments` (Multi-Tenancy)
**Primary Key:** `id` (bigint)
**Purpose:** Assigns users to tenants with roles
**Key Fields:**
- `user_id` (references users)
- `tenant_id` (references tenants)
- `role_id` (references cmms_user_roles)
- `default_site_id` (references sites)
- `assigned_by_id` (references users)
- `assigned_at` (timestamp)
- `is_active` (boolean)
- `notes` (text)

**Schema:** `Shop1Cmms.Accounts.UserTenantAssignment`

### `cmms_user_roles` (CMMS Roles)
**Primary Key:** `id` (bigint)
**Purpose:** CMMS-specific role definitions
**Key Fields:**
- `name` (string) - unique role identifier (e.g., 'tenant_admin', 'technician')
- `display_name` (string) - human-readable name
- `description` (text)
- `permissions` (text array)
- `is_system_role` (boolean) - system vs custom roles
- `is_active` (boolean)

**Schema:** `Shop1Cmms.Accounts.CmmsUserRole`

**Default Roles:**
- `tenant_admin` - Full access to tenant data and settings
- `maintenance_manager` - Manage assets, PMs, and work orders
- `supervisor` - Supervise work orders and assign tasks
- `technician` - Execute work orders and update asset status
- `operator` - Basic asset interaction and work request creation

### `roles` (General Roles)
**Purpose:** General system roles (Shop1FinishLine integration)
**Note:** Used for overall system permissions, separate from CMMS-specific roles

---

## Equipment (Asset) Tables

### `assets` (Equipment)
**Primary Key:** `id` (UUID)
**Purpose:** Equipment/asset inventory
**Key Fields:**
- `asset_number` (string) - unique identifier
- `name` (string)
- `description` (text)
- `manufacturer`, `model`, `serial_number`
- `barcode`, `qr_code`
- `purchase_date`, `purchase_cost`
- `warranty_expiry`, `install_date`, `commission_date`
- `status` (enum: operational, down, maintenance, retired)
- `criticality` (enum: low, medium, high, critical)
- `specifications` (jsonb)
- `notes` (text)
- `parent_asset_id` (self-reference for hierarchy)
- `location_id` (references asset_locations)
- `asset_type_id` (references asset_types)
- `tenant_id` (references tenants)

**Schema:** `Shop1Cmms.Assets.Asset`

### `asset_types` (Equipment Categories)
**Primary Key:** `id` (UUID)
**Purpose:** Categorize equipment types
**Key Fields:**
- `name`, `description`, `code`, `category`
- `icon`, `color`
- `has_meters`, `has_components`
- `default_pm_frequency`
- `tenant_id`

**Schema:** `Shop1Cmms.Assets.AssetType`

### `asset_locations` (Equipment Locations)
**Primary Key:** `id` (UUID)
**Purpose:** Hierarchical location management
**Key Fields:**
- `name`, `description`, `code`
- `address`, `gps_coordinates`
- `area_size`, `area_unit`
- `is_active`
- `parent_location_id` (self-reference)
- `location_type_id` (references location_types)
- `tenant_id`

**Schema:** `Shop1Cmms.Assets.AssetLocation`

### `asset_location_types` (Location Type Definitions)
**Primary Key:** `id` (UUID)
**Purpose:** Define location type categories
**Key Fields:**
- `name`, `description`, `code`
- `icon`, `color` - for UI display
- `tenant_id` (bigint)

**Schema:** `Shop1Cmms.Assets.AssetLocationType`

### `asset_meters` (Equipment Meters)
**Primary Key:** `id` (UUID)
**Purpose:** Track meter readings for equipment (hours, cycles, etc.)
**Key Fields:**
- `asset_id` (references assets)
- `meter_type_id` (references meter_types)
- `current_reading` (decimal)
- `last_reading_date` (utc_datetime)
- `reading_frequency` (integer) - days between readings
- `next_reading_due` (date)
- `is_active` (boolean)
- `tenant_id` (bigint)

**Schema:** `Shop1Cmms.Assets.AssetMeter`

### `meter_types` (Meter Type Definitions)
**Primary Key:** `id` (UUID)
**Purpose:** Define types of meters that can be tracked
**Key Fields:**
- `name` (string) - e.g., "Operating Hours", "Mileage"
- `description` (text)
- `unit` (string) - e.g., "hours", "miles", "cycles"
- `data_type` (string) - "integer", "decimal", "counter"
- `is_cumulative` (boolean)
- `tenant_id` (bigint)

**Schema:** `Shop1Cmms.Assets.MeterType`

### `meter_readings` (Historical Meter Data)
**Primary Key:** `id` (UUID)
**Purpose:** Store historical meter reading records
**Key Fields:**
- `asset_meter_id` (references asset_meters)
- `reading` (decimal)
- `reading_date` (utc_datetime)
- `reading_type` (string) - "manual", "automatic", "estimated"
- `notes` (text)
- `recorded_by` (references users)
- `tenant_id` (bigint)

**Schema:** `Shop1Cmms.Assets.MeterReading`

### `components`
**Primary Key:** `id` (UUID)
**Purpose:** Track equipment components/parts
**Key Fields:**
- `asset_id` (references assets) - parent equipment
- `name` (string) - component name
- `description` (text)
- `component_type` (string) - type/category
- `manufacturer`, `model`, `serial_number` (string)
- `install_date` (date)
- `status` (string) - default 'active'
- `tenant_id` (integer)

**Schema:** `Shop1Cmms.Assets.Component`

---

## Maintenance Tables

### `pm_schedules` (PM Definitions)
**Primary Key:** `id` (UUID)
**Purpose:** Preventive maintenance schedule definitions
**Key Fields:**
- `schedule_number` (string) - auto-generated (e.g., "PMS-00000001")
- `title` (string) - PM name
- `description` (text)
- `asset_id` (references assets)
- `frequency` (enum) - daily, weekly, biweekly, monthly, quarterly, semiannual, annual, biennial, meter_based, condition_based
- `frequency_interval` (integer) - multiplier for frequency
- `meter_threshold` (decimal) - for meter-based PMs
- `meter_unit` (string) - e.g., "hours", "miles"
- `work_instructions` (text)
- `estimated_duration` (decimal) - hours
- `required_skills` (text array)
- `required_tools` (text array)
- `required_parts` (jsonb)
- `safety_notes` (text)
- `ppe_required` (text array) - personal protective equipment
- `last_completed_date`, `next_due_date` (utc_datetime)
- `is_active` (boolean)
- `created_by`, `updated_by` (references users)
- `tenant_id` (integer)

**Schema:** `Shop1Cmms.Maintenance.PMSchedule`

### `pm_checklist_items` (PM Checklist)
**Primary Key:** `id` (UUID)
**Purpose:** Checklist items for PM schedules
**Key Fields:**
- `pm_schedule_id` (references pm_schedules)
- `sequence` (integer) - order of item
- `item_description` (text) - what to check/do
- `expected_result` (text)
- `pass_fail` (boolean) - is this a pass/fail check?
- `requires_measurement` (boolean)
- `measurement_unit` (string)
- `min_value`, `max_value` (decimal) - acceptable range
- `tenant_id` (integer)

**Schema:** `Shop1Cmms.Maintenance.PmChecklistItem`

### `pm_schedule_components` (PM Component Associations)
**Primary Key:** `id` (UUID)
**Purpose:** Link PM schedules to specific components within an asset
**Key Fields:**
- `pm_schedule_id` (references pm_schedules)
- `component_name` (string)
- `component_description` (text)
- `component_location` (string)
- `tenant_id` (integer)

**Schema:** `Shop1Cmms.Maintenance.PmScheduleComponent`

### `pm_executions` (PM Execution Records)
**Primary Key:** `id` (UUID)
**Purpose:** Track individual PM execution instances
**Key Fields:**
- `execution_number` (string) - auto-generated (e.g., "PMX-00000001")
- `pm_schedule_id` (references pm_schedules)
- `asset_id` (references assets)
- `component_id` (references components) - optional
- `work_order_id` (references work_orders) - optional link
- `execution_date` (utc_datetime) - when PM was/is due
- `status` (string) - "in_progress", "completed", "pending", etc.
- `completed_date` (utc_datetime)
- `completed_by_user_id` (references users - bigint)
- `step_results` (jsonb) - checklist completion data
- `tech_notes` (text)
- `parts_used` (jsonb)
- `actual_duration_minutes` (integer)
- `meter_reading` (decimal)
- `tenant_id` (integer)

**Schema:** `Shop1Cmms.Maintenance.PMExecution`

### `work_orders` (Reactive Maintenance)
**Primary Key:** `id` (UUID)
**Purpose:** Track reactive maintenance work orders
**Key Fields:**
- `work_order_number` (string) - unique identifier
- `title` (string), `description` (text)
- `asset_id` (references assets)
- `status` (enum) - open, assigned, in_progress, on_hold, completed, cancelled
- `priority` (enum) - low, medium, high, urgent
- `type` (enum) - corrective, preventive, emergency, project
- `requested_by`, `assigned_to`, `created_by`, `updated_by` (references users - integer)
- `requested_date`, `scheduled_start_date`, `scheduled_end_date` (utc_datetime)
- `actual_start_date`, `actual_end_date`, `due_date` (utc_datetime)
- `location_description` (string)
- `estimated_hours`, `actual_hours` (decimal)
- `estimated_cost`, `actual_cost` (decimal)
- `completion_notes`, `work_performed`, `failure_reason` (text)
- `parts_used` (jsonb)
- `safety_notes` (text)
- `attachments` (jsonb)
- `tenant_id` (integer)

**Schema:** `Shop1Cmms.WorkOrders.WorkOrder`

### `asset_documents` (Equipment/PM Documents)
**Primary Key:** `id` (UUID)
**Purpose:** Store documents, manuals, certs, etc.
**Key Fields:**
- `asset_id` (references assets) - optional
- `pm_schedule_id` (references pm_schedules) - optional
- `work_order_id` (references work_orders) - optional
- `name`, `title` (string)
- `description` (text)
- `document_number` (string)
- `document_type` (enum) - manual, drawing, specification, procedure, work_instruction, certificate, calibration, warranty, other
- `file_path`, `file_name`, `file_url` (string)
- `file_size` (integer), `file_type`, `mime_type` (string)
- `version`, `revision_date`, `expiry_date` (date)
- `issued_by`, `approved_by` (string)
- `tags` (text array)
- `is_active` (boolean)
- `uploaded_by` (references users - bigint)
- `tenant_id` (bigint)

**Schema:** `Shop1Cmms.Maintenance.AssetDocument`

---

## Organization Tables

### `tenants`
**Primary Key:** `id` (bigint)
**Purpose:** Multi-tenant organization separation
**Key Fields:**
- `name` (string) - unique tenant identifier
- `display_name` (string) - human-readable name
- `description` (text)
- `code` (string) - short code
- `address`, `phone`, `email`, `website` (string)
- `timezone` (string) - default 'America/Chicago'
- `is_active` (boolean)
- `settings` (jsonb)
- `inserted_at`, `updated_at` (timestamp)

**Schema:** `Shop1Cmms.Tenants.Tenant`

### `sites`
**Primary Key:** `id` (bigint)
**Purpose:** Physical site locations within a tenant
**Key Fields:**
- `tenant_id` (references tenants)
- `name`, `display_name` (string)
- `description` (text)
- `address`, `phone`, `email` (string)
- `timezone` (string)
- `is_active` (boolean)
- `settings` (jsonb)
- `inserted_at`, `updated_at` (timestamp)

**Schema:** `Shop1Cmms.Tenants.Site`

---

## Metadata Tables (Supporting Data)

### `departments`
**Purpose:** Department definitions for user organization

### `manufacturers`
**Purpose:** Manufacturer/vendor information

### `suppliers`
**Purpose:** Supplier/parts vendor information

### `priority_codes`
**Purpose:** Priority level definitions

### `maintenance_categories`
**Purpose:** Maintenance work categorization

### `custom_fields`
**Purpose:** Define custom field definitions for extensibility

### `custom_field_values`
**Purpose:** Store custom field values for entities

---

## Shop1FinishLine Integration Tables

The following tables are part of the Shop1FinishLine ERP system and may be accessed for integration:

- `customers` - Customer information
- `contacts` - Contact records
- `orders` - Order/job management
- `job_cards` - Job card tracking
- `parts` - Parts inventory
- `locations` - Warehouse/storage locations
- `shifts` - Shift scheduling
- `audit_logs` - System audit trail
- `event_logs` - Event tracking
- `sessions` - User session management

---

## Common Query Patterns

### Get User Display Name
```elixir
# From users table - use username directly
user.username

# With profile lookup (if needed)
from u in User,
  left_join: pa in assoc(u, :user_profile_assignments),
  left_join: p in assoc(pa, :user_profile),
  select: %{
    username: u.username,
    display_name: coalesce(p.display_name, u.username)
  }
```

### Get Completed Maintenance History
```elixir
# PM Executions
from e in "pm_executions",
  where: not is_nil(e.tenant_id) and e.tenant_id == ^tenant_id,
  where: e.status == :completed

# Work Orders
from w in "work_orders",
  where: not is_nil(w.tenant_id) and w.tenant_id == ^tenant_id,
  where: w.status == :completed
```

---

## Important Notes

1. **NO user_details table/view exists** - Use `user_profiles` for extended user information
2. **ID Type Differences:**
   - `users`, `tenants`, `sites`: use `bigint` (integer) IDs
   - Most CMMS tables (`assets`, `pm_schedules`, `work_orders`, etc.): use `UUID` (binary_id)
3. **Enum values** must match exactly (lowercase, underscored) - check migrations for exact values
4. **Tenant isolation** - ALWAYS filter by `tenant_id` on all queries
5. **Username** is the safest field for user identification across all tables
6. **Foreign Key Types:**
   - References to `users` must use type `:bigint` or `:integer`
   - References to CMMS entities use type `:binary_id` (UUID)
7. **Timestamps:**
   - Some tables use `:utc_datetime`
   - Some tables use `:naive_datetime`
   - Check schema definitions for correct type

---

## Schema Modules Location

- **Accounts:** `lib/shop1_cmms/accounts/`
- **Assets:** `lib/shop1_cmms/assets/`
- **Maintenance:** `lib/shop1_cmms/maintenance/`

---

## Quick Reference: Key Relationships

```
tenants
  ├─ sites
  ├─ user_tenant_assignments ─> users
  ├─ assets
  │   ├─ components
  │   ├─ asset_meters ─> meter_types
  │   │   └─ meter_readings
  │   ├─ pm_schedules
  │   │   ├─ pm_checklist_items
  │   │   ├─ pm_schedule_components
  │   │   ├─ pm_executions
  │   │   └─ asset_documents
  │   ├─ work_orders
  │   └─ asset_documents
  ├─ asset_locations ─> asset_location_types
  └─ asset_types

users
  ├─ user_profile_assignments ─> user_profiles
  └─ user_tenant_assignments ─> tenants
      └─ cmms_user_roles
```

---

Last Updated: 2025-01-31 (Schema verified against actual database)
