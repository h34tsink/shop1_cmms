# Schema Field Reference Guide

**Purpose:** Quick reference for developers to look up correct field names when working with schemas  
**Last Updated:** 2025-01-31  
**Status:** ✅ Verified against actual database

---

## Quick Field Lookup

### Common Mistakes to Avoid

❌ **WRONG** → ✅ **CORRECT**

| Wrong Field Name | Correct Field Name | Table/Schema |
|-----------------|-------------------|--------------|
| `frequency_value` | `frequency` (enum) + `frequency_interval` (integer) | `pm_schedules` |
| `frequency_unit` | `frequency_interval` | `pm_schedules` |
| `priority` | Does NOT exist on `pm_schedules` | `pm_schedules` |
| `component_id` | Does NOT exist (use join table) | `pm_schedules` |
| `user_details` | Table does NOT exist (use `user_profiles`) | N/A |

---

## User & Authentication Schemas

### `users` Table
**Schema:** `Shop1Cmms.Accounts.User`  
**Primary Key:** `id` (bigint)

#### Core Fields
```elixir
field :username, :string              # Unique login name
field :password_hash, :string         # Hashed password (redacted)
field :is_active, :boolean            # Account status
```

#### CMMS Fields
```elixir
field :cmms_enabled, :boolean         # CMMS access flag
field :last_cmms_login, :naive_datetime
field :preferences, :map              # JSONB preferences
```

#### Virtual Fields (not in DB)
```elixir
field :password, :string, virtual: true
field :password_confirmation, :string, virtual: true
```

#### Timestamps
```elixir
timestamps(type: :naive_datetime)     # inserted_at, updated_at
```

### `user_profiles` Table
**Schema:** Shop1FinishLine (external)  
**Note:** Part of Shop1FinishLine system, linked via `user_profile_assignments`

#### Profile Fields (reference only)
```elixir
# These fields are in user_profiles table, not users table
first_name, last_name, display_name, full_name
email, phone, mobile
department, job_title
avatar_url, bio, location
```

### `cmms_user_roles` Table
**Schema:** `Shop1Cmms.Accounts.CMMSUserRole` ⚠️ Note: CMMSUserRole (all caps)  
**Primary Key:** `id` (bigint)

```elixir
field :name, :string                  # Role identifier (e.g., 'tenant_admin')
field :display_name, :string          # Human-readable name
field :description, :string
field :permissions, {:array, :string} # Array of permission strings
field :is_system_role, :boolean       # System vs custom roles
field :is_active, :boolean
```

### `user_tenant_assignments` Table
**Schema:** `Shop1Cmms.Accounts.UserTenantAssignment`  
**Primary Key:** `id` (bigint)

```elixir
belongs_to :user, User                # References users(id) - bigint
belongs_to :tenant, Tenant            # References tenants(id) - bigint
belongs_to :role, CMMSUserRole        # References cmms_user_roles(id)
belongs_to :default_site, Site        # References sites(id)

field :assigned_at, :naive_datetime
field :is_active, :boolean
field :notes, :string
```

---

## Equipment (Assets) Schemas

### `assets` Table
**Schema:** `Shop1Cmms.Assets.Asset`  
**Primary Key:** `id` (UUID/binary_id)

#### Identification
```elixir
field :asset_number, :string          # Unique identifier (e.g., "EQP-001")
field :name, :string                  # Display name
field :description, :string
```

#### Details
```elixir
field :manufacturer, :string
field :model, :string
field :serial_number, :string
field :barcode, :string
field :qr_code, :string
```

#### Dates & Costs
```elixir
field :purchase_date, :date
field :purchase_cost, :decimal
field :warranty_expiry, :date
field :install_date, :date
field :commission_date, :date
```

#### Status & Classification
```elixir
field :status, Ecto.Enum              # Enum values:
  # :operational, :maintenance, :repair, :retired, :disposed
field :criticality, Ecto.Enum         # Enum values:
  # :low, :medium, :high, :critical
```

#### Additional
```elixir
field :specifications, :map           # JSONB for custom specs
field :notes, :string
```

#### Associations
```elixir
belongs_to :asset_type, AssetType, type: :binary_id
belongs_to :location, AssetLocation, type: :binary_id
belongs_to :parent_asset, Asset, type: :binary_id  # For hierarchy

field :tenant_id, :integer            # Note: integer, not binary_id
```

### `asset_types` Table
**Schema:** `Shop1Cmms.Assets.AssetType`  
**Primary Key:** `id` (UUID/binary_id)

```elixir
field :name, :string
field :description, :string
field :code, :string
field :category, :string              # "Equipment", "Tools", "Vehicles", etc.
field :icon, :string
field :color, :string
field :has_meters, :boolean
field :has_components, :boolean
field :default_pm_frequency, :integer # Days

field :tenant_id, :integer
```

### `asset_locations` Table
**Schema:** `Shop1Cmms.Assets.AssetLocation`  
**Primary Key:** `id` (UUID/binary_id)

```elixir
field :name, :string
field :description, :string
field :code, :string
field :address, :string
field :gps_coordinates, :string
field :area_size, :decimal
field :area_unit, :string             # "sqft", "sqm", etc.
field :is_active, :boolean

belongs_to :parent_location, AssetLocation, type: :binary_id
belongs_to :location_type, AssetLocationType, type: :binary_id

field :tenant_id, :integer
```

### `components` Table
**Schema:** `Shop1Cmms.Assets.Component`  
**Primary Key:** `id` (UUID/binary_id)

```elixir
field :name, :string
field :description, :string
field :component_type, :string
field :manufacturer, :string
field :model, :string
field :serial_number, :string
field :install_date, :date
field :status, Ecto.Enum              # :active, :inactive, :maintenance, :failed

belongs_to :asset, Asset, type: :binary_id
has_many :pm_executions, PmExecution  # ✅ Valid association

# ❌ REMOVED: has_many :pm_schedules - Invalid, use pm_schedule_components join table

field :tenant_id, :integer
timestamps(type: :naive_datetime)
```

---

## Preventive Maintenance Schemas

### `pm_schedules` Table
**Schema:** `Shop1Cmms.Maintenance.PmSchedule`  
**Primary Key:** `id` (UUID/binary_id)

#### Identification
```elixir
field :schedule_number, :string       # Auto-generated: "PMS-00000001"
field :title, :string
field :description, :string
```

#### ⚠️ FREQUENCY FIELDS - IMPORTANT!
```elixir
# ✅ CORRECT FIELDS:
field :frequency, Ecto.Enum           # Enum values:
  # :daily, :weekly, :biweekly, :monthly, :quarterly, 
  # :semiannual, :annual, :biennial, :meter_based, :condition_based

field :frequency_interval, :integer   # How often (default: 1)
  # Example: frequency = :weekly, frequency_interval = 2 → "Every 2 weeks"

# ❌ WRONG - These fields DO NOT EXIST:
# field :frequency_value - DOES NOT EXIST
# field :frequency_unit - DOES NOT EXIST
```

#### Meter-Based PMs
```elixir
field :meter_threshold, :decimal      # For meter_based frequency
field :meter_unit, :string            # "hours", "miles", "cycles"
```

#### Work Details
```elixir
field :work_instructions, :string     # Full text instructions
field :estimated_duration, :decimal   # Hours (e.g., 2.5 for 2.5 hours)
field :required_skills, {:array, :string}
field :required_tools, {:array, :string}
field :required_parts, :map           # JSONB
```

#### Safety
```elixir
field :safety_notes, :string
field :ppe_required, {:array, :string}
```

#### Scheduling
```elixir
field :last_completed_date, :utc_datetime
field :next_due_date, :utc_datetime
field :is_active, :boolean
```

#### Associations
```elixir
belongs_to :asset, Asset, type: :binary_id
belongs_to :created_by_user, User, foreign_key: :created_by  # Note: bigint foreign key
belongs_to :updated_by_user, User, foreign_key: :updated_by

has_many :components, PmScheduleComponent
has_many :checklist_items, PmChecklistItem
has_many :documents, AssetDocument, foreign_key: :pm_schedule_id

field :tenant_id, :integer
timestamps(type: :utc_datetime)       # Note: utc_datetime, not naive
```

#### ❌ Fields that DO NOT EXIST on pm_schedules
```elixir
# priority - DOES NOT EXIST (priority is on work_orders only)
# component_id - DOES NOT EXIST (use pm_schedule_components join table)
```

### `pm_executions` Table
**Schema:** `Shop1Cmms.Maintenance.PmExecution`  
**Primary Key:** `id` (UUID/binary_id)

```elixir
field :execution_number, :string      # Auto-generated: "PMX-00000001"
field :execution_date, :utc_datetime  # When PM is/was due
field :completed_date, :utc_datetime
field :status, :string                # "pending", "in_progress", "completed", etc.

belongs_to :pm_schedule, PmSchedule, type: :binary_id
belongs_to :asset, Asset, type: :binary_id
belongs_to :component, Component, type: :binary_id  # Optional
belongs_to :work_order, WorkOrder, type: :binary_id  # Optional link
belongs_to :completed_by_user, User, foreign_key: :completed_by_user_id  # bigint

field :step_results, :map             # JSONB - checklist completion data
field :tech_notes, :string
field :parts_used, :map               # JSONB
field :actual_duration_minutes, :integer
field :meter_reading, :decimal

field :tenant_id, :integer
timestamps(type: :naive_datetime)
```

### `pm_checklist_items` Table
**Schema:** `Shop1Cmms.Maintenance.PmChecklistItem`  
**Primary Key:** `id` (UUID/binary_id)

```elixir
field :sequence, :integer             # Order of item
field :item_description, :string
field :expected_result, :string
field :pass_fail, :boolean
field :requires_measurement, :boolean
field :measurement_unit, :string
field :min_value, :decimal
field :max_value, :decimal

belongs_to :pm_schedule, PmSchedule, type: :binary_id

field :tenant_id, :integer
timestamps(type: :utc_datetime)
```

### `pm_schedule_components` Table (Join Table)
**Schema:** `Shop1Cmms.Maintenance.PmScheduleComponent`  
**Purpose:** Links PM schedules to specific components (many-to-many)

```elixir
field :component_name, :string
field :component_description, :string
field :component_location, :string

belongs_to :pm_schedule, PmSchedule, type: :binary_id

field :tenant_id, :integer
timestamps(type: :utc_datetime)
```

---

## Work Order Schema

### `work_orders` Table
**Schema:** `Shop1Cmms.WorkOrders.WorkOrder`  
**Primary Key:** `id` (UUID/binary_id)

#### Identification
```elixir
field :work_order_number, :string     # Unique identifier
field :title, :string
field :description, :string
```

#### Status & Classification
```elixir
field :status, Ecto.Enum              # Enum values:
  # :open, :assigned, :in_progress, :on_hold, :completed, :cancelled

field :priority, Ecto.Enum            # Enum values:
  # :low, :medium, :high, :urgent

field :type, Ecto.Enum                # Enum values:
  # :corrective, :preventive, :emergency, :project
```

#### Dates
```elixir
field :requested_date, :utc_datetime
field :scheduled_start_date, :utc_datetime
field :scheduled_end_date, :utc_datetime
field :actual_start_date, :utc_datetime
field :actual_end_date, :utc_datetime
field :due_date, :utc_datetime
```

#### Users (Note: These are integer foreign keys, not associations)
```elixir
field :requested_by, :integer         # User ID
field :assigned_to, :integer          # User ID
field :created_by, :integer           # User ID
field :updated_by, :integer           # User ID
```

#### Asset & Location
```elixir
belongs_to :asset, Asset, type: :binary_id
field :location_description, :string
```

#### Costs & Labor
```elixir
field :estimated_hours, :decimal
field :actual_hours, :decimal
field :estimated_cost, :decimal
field :actual_cost, :decimal
```

#### Additional
```elixir
field :completion_notes, :string
field :work_performed, :string
field :failure_reason, :string
field :parts_used, :map               # JSONB
field :safety_notes, :string
field :attachments, :map              # JSONB

field :tenant_id, :integer
timestamps(type: :naive_datetime)
```

---

## Organization Schemas

### `tenants` Table
**Schema:** `Shop1Cmms.Tenants.Tenant`  
**Primary Key:** `id` (bigint)

```elixir
field :name, :string
field :code, :string                  # Unique short code
field :description, :string
field :email, :string
field :phone, :string
field :address, :string
field :timezone, :string
field :settings, :map                 # JSONB
field :is_active, :boolean

has_many :sites, Site
has_many :user_tenant_assignments, UserTenantAssignment
has_many :users, through: [:user_tenant_assignments, :user]

timestamps(type: :naive_datetime)
```

### `sites` Table
**Schema:** `Shop1Cmms.Tenants.Site`  
**Primary Key:** `id` (bigint)

```elixir
field :name, :string
field :description, :string
field :address, :string
field :phone, :string
field :email, :string
field :timezone, :string
field :settings, :map
field :is_active, :boolean

belongs_to :tenant, Tenant            # bigint foreign key

timestamps(type: :naive_datetime)
```

---

## Document Schema

### `asset_documents` Table
**Schema:** `Shop1Cmms.Maintenance.AssetDocument`  
**Primary Key:** `id` (UUID/binary_id)

```elixir
field :name, :string
field :title, :string
field :description, :string
field :document_number, :string

field :document_type, Ecto.Enum       # Enum values:
  # :manual, :drawing, :specification, :procedure, :work_instruction,
  # :certificate, :calibration, :warranty, :other

field :file_path, :string
field :file_name, :string
field :file_url, :string
field :file_size, :integer
field :file_type, :string
field :mime_type, :string

field :version, :string
field :revision_date, :date
field :expiry_date, :date
field :issued_by, :string
field :approved_by, :string

field :tags, {:array, :string}
field :is_active, :boolean

belongs_to :asset, Asset, type: :binary_id         # Optional
belongs_to :pm_schedule, PmSchedule, type: :binary_id  # Optional
belongs_to :work_order, WorkOrder, type: :binary_id    # Optional
belongs_to :uploaded_by_user, User, foreign_key: :uploaded_by  # bigint

field :tenant_id, :bigint
timestamps(type: :utc_datetime)
```

---

## Important Data Type Notes

### ID Types
- **Users, Tenants, Sites:** Use `bigint` (integer) IDs
- **Most CMMS tables:** Use `UUID` (binary_id) IDs

### Timestamp Types
- **Some tables:** Use `:utc_datetime` (pm_schedules, asset_documents, pm_checklist_items)
- **Most tables:** Use `:naive_datetime` (users, components, work_orders, tenants)

### Foreign Key Types
⚠️ **Critical:** When referencing users from UUID tables:
```elixir
# ✅ CORRECT - User references are always integer/bigint
belongs_to :created_by_user, User, foreign_key: :created_by  # No type specified = integer
field :assigned_to, :integer  # Direct integer field

# ❌ WRONG
belongs_to :created_by_user, User, type: :binary_id  # Users use bigint, not binary_id
```

---

## Common Query Patterns

### Displaying Frequency
```elixir
# ✅ CORRECT
def format_frequency(%{frequency: freq, frequency_interval: interval}) do
  label = frequency_label(freq)  # e.g., "Weekly"
  if interval > 1 do
    "Every #{interval} - #{label}"
  else
    label
  end
end

# ❌ WRONG - These fields don't exist
schedule.frequency_value
schedule.frequency_unit
```

### Accessing User Display Name
```elixir
# ✅ CORRECT - username always exists
user.username

# ⚠️ For full name, query user_profiles
from u in User,
  left_join: upa in assoc(u, :user_profile_assignments),
  left_join: p in assoc(upa, :user_profile),
  select: %{username: u.username, display_name: p.display_name}
```

### Checking PM Priority
```elixir
# ❌ WRONG - PM schedules don't have priority
@schedule.priority

# ✅ Use work order priority instead (if linked)
@execution.work_order.priority

# ✅ Or display estimated duration
@schedule.estimated_duration
```

---

## Quick Cheat Sheet

### Before Writing Code:
1. ✅ Check this document for correct field names
2. ✅ Check DATABASE_TABLE_MAP.md for schema structure
3. ✅ Look at schema file: `lib/shop1_cmms/<context>/<schema>.ex`
4. ✅ Verify field exists in migration files

### When Adding New Fields:
1. Create migration
2. Update schema file
3. Update this documentation
4. Update DATABASE_TABLE_MAP.md

### When You're Unsure:
```elixir
# Check schema fields programmatically
YourSchema.__schema__(:fields)

# Or query database directly
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'your_table';
```

---

**Last Verified:** 2025-01-31  
**Database Schema Version:** Current production
