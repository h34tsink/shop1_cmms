# Field Mapping and System Fixes Documentation

## Date: 2025
## Purpose: Document all field mappings, inconsistencies found, and fixes applied

---

## 1. Database Schema vs Code Mismatches

### 1.1 PM Schedule Fields
**Issue:** Templates and code were accessing non-existent fields
- **Wrong fields being accessed:** `frequency_value`, `frequency_unit`
- **Correct fields in schema:** `frequency` (enum), `frequency_interval` (integer)
- **Fixed in:** PM execution detail templates, PM schedule detail templates
- **Status:** ✅ FIXED

### 1.2 User Authentication Tables
**Issue:** Code referenced `user_details` table which doesn't exist
- **Wrong table:** `user_details`
- **Correct table:** `user_profiles`
- **Fields in user_profiles:**
  - `id` (UUID, PK)
  - `user_id` (UUID, FK to users)
  - `tenant_id` (integer, FK to tenants)
  - `full_name` (string)
  - `phone` (string)
  - `title` (string)
  - `department` (string)
  - `bio` (text)
  - `avatar_url` (string)
  - `preferences` (jsonb)
  - `is_active` (boolean)
  - `inserted_at`, `updated_at` (timestamps)
- **Status:** ✅ DOCUMENTED

---

## 2. PM Schedule Schema Reference

### 2.1 Core Fields
```elixir
schema "pm_schedules" do
  field :schedule_number, :string        # Auto-generated: PM-XXXX
  field :title, :string
  field :description, :string
  
  # Frequency fields (NOT frequency_value/frequency_unit)
  field :frequency, Ecto.Enum,          # :daily, :weekly, :monthly, :quarterly, :annual, :biannual
         values: [:daily, :weekly, :monthly, :quarterly, :annual, :biannual, :meter_based]
  field :frequency_interval, :integer    # e.g., every 2 weeks = frequency: :weekly, interval: 2
  
  # Meter-based maintenance
  field :meter_threshold, :decimal
  field :meter_unit, :string            # e.g., "hours", "cycles", "miles"
  
  # Work details
  field :work_instructions, :string     # Multi-line text
  field :estimated_duration, :decimal
  
  # Requirements (arrays)
  field :required_skills, {:array, :string}
  field :required_tools, {:array, :string}
  field :ppe_required, {:array, :string}
  field :required_parts, :map           # JSON object
  
  # Safety
  field :safety_notes, :string
  
  # Dates
  field :last_completed_date, :utc_datetime
  field :next_due_date, :utc_datetime
  
  # Status
  field :is_active, :boolean
  
  # Relationships
  belongs_to :asset, Shop1Cmms.Assets.Asset
  belongs_to :created_by_user, Shop1Cmms.Accounts.User, foreign_key: :created_by
  belongs_to :updated_by_user, Shop1Cmms.Accounts.User, foreign_key: :updated_by
  
  # Tenant
  field :tenant_id, :integer
  
  timestamps()
end
```

### 2.2 Display Logic for Frequency
```elixir
# Correct way to display frequency:
case pm_schedule.frequency do
  :daily -> "Every #{pm_schedule.frequency_interval} day(s)"
  :weekly -> "Every #{pm_schedule.frequency_interval} week(s)"
  :monthly -> "Every #{pm_schedule.frequency_interval} month(s)"
  :quarterly -> "Every #{pm_schedule.frequency_interval} quarter(s)"
  :annual -> "Every #{pm_schedule.frequency_interval} year(s)"
  :biannual -> "Every #{pm_schedule.frequency_interval * 6} months"
  :meter_based -> "Every #{pm_schedule.meter_threshold} #{pm_schedule.meter_unit}"
end
```

---

## 3. Assets Schema Reference

### 3.1 Core Fields
```elixir
schema "assets" do
  field :asset_number, :string          # Auto-generated: AST-XXXX
  field :name, :string
  field :description, :string
  field :serial_number, :string
  field :model_number, :string
  field :barcode, :string
  field :qr_code, :string
  
  # Status and lifecycle
  field :status, Ecto.Enum,             # :active, :inactive, :maintenance, :retired, :disposed
         values: [:active, :inactive, :maintenance, :retired, :disposed]
  field :criticality, Ecto.Enum,        # :critical, :high, :medium, :low
         values: [:critical, :high, :medium, :low]
  
  # Dates
  field :purchase_date, :date
  field :installation_date, :date
  field :warranty_expiry_date, :date
  field :commission_date, :date
  
  # Financial
  field :purchase_price, :decimal
  field :current_value, :decimal
  field :depreciation_rate, :decimal
  
  # Specifications
  field :specifications, :map           # JSON object
  field :custom_fields, :map            # JSON object
  
  # Operational
  field :operating_hours, :decimal
  field :last_meter_reading, :decimal
  field :meter_unit, :string
  
  # Location
  field :location_details, :string
  
  # Images
  field :image_urls, {:array, :string}
  
  # Relationships
  belongs_to :asset_type, Shop1Cmms.Assets.AssetType
  belongs_to :location, Shop1Cmms.Assets.AssetLocation
  belongs_to :manufacturer, Shop1Cmms.Metadata.Manufacturer
  belongs_to :parent_asset, Shop1Cmms.Assets.Asset
  belongs_to :department, Shop1Cmms.Metadata.Department
  
  # Tenant
  field :tenant_id, :integer
  
  timestamps()
end
```

---

## 4. PM Tags System

### 4.1 PM Tags Schema
```elixir
schema "pm_tags" do
  field :name, :string
  field :tag_type, Ecto.Enum, values: [:skill, :tool, :ppe]
  field :description, :string
  field :usage_count, :integer, default: 0
  field :is_active, :boolean, default: true
  field :tenant_id, :integer
  
  timestamps()
end
```

### 4.2 Tag Types
- **skill**: Required skills/certifications (e.g., "LOTO Certified", "Electrical", "Welding")
- **tool**: Required tools/equipment (e.g., "Torque Wrench", "Multimeter", "Hydraulic Jack")
- **ppe**: Required personal protective equipment (e.g., "Safety Glasses", "Hard Hat", "Arc Flash Suit")

### 4.3 Configuration Location
- Path: `/configuration/pm_tags`
- Features:
  - Add/edit/delete tags
  - Filter by tag type (skill/tool/ppe)
  - Sort by name, type, or usage count
  - Search functionality
  - Usage count tracking (auto-incremented when tag is used in PM schedules)

---

## 5. Modal and UI Fixes

### 5.1 Modal Close Issue
**Problem:** Modal overlay phx-click events conflicting, prevent_close causing issues
**Solution:**
- Removed `phx-click="close_modal"` from outer modal overlay div
- Added `phx-click="close_modal"` to backdrop div only
- Removed `phx-click="prevent_close"` from modal panel
- Removed unused `handle_event("prevent_close")` handler
**Files affected:**
- `lib/shop1_cmms_web/live/metadata_live.html.heex`
- `lib/shop1_cmms_web/live/metadata_live.ex`

### 5.2 Filter Dropdown Issue
**Problem:** Filter dropdown not sending proper params to event handler
**Solution:**
- Ensured select element has proper `name="type"` attribute
- Added `selected` attributes for proper state display
- Simplified event handler to just match `%{"type" => type}`
**Files affected:**
- `lib/shop1_cmms_web/live/metadata_live.ex`

---

## 6. Search and Filter Functionality

### 6.1 Current Search Implementation
All list pages should implement:
- Text search via `phx-change="search"` event
- Filter dropdowns via specific filter events
- Sort headers via `phx-click="sort"` with `phx-value-field`

### 6.2 Pages with Search/Filter
- ✅ Assets list
- ✅ PM Schedules list
- ✅ Work Orders list
- ✅ Maintenance History
- ✅ Configuration pages (Metadata)
- ✅ PM Tags configuration

### 6.3 Tag Search
Tags can be searched in:
- Global search (searches tag names)
- PM schedule filters (filter by required skills/tools/PPE)
- Asset filters (if tags are associated with assets)

---

## 7. Forms and Editability

### 7.1 Asset Detail Page
- Layout: Two-column with info on left, stats on right
- Edit mode: In-place editing with bordered input fields (light gray borders)
- All fields editable except: asset_number, timestamps
- Cancel/Save buttons at bottom

### 7.2 PM Schedule Detail Page
- Layout: Similar to assets - info on left, status/stats on right
- Work Instructions: Line-by-line editable list with add/remove/reorder
- Requirements: Displayed as tags on right side
- Edit mode: In-place with bordered fields
- All fields editable except: schedule_number, timestamps

### 7.3 PM Creation/Edit Form
- Tag input fields with autocomplete
- Suggestions from configuration lists
- Can add new tags on-the-fly (auto-creates in database)
- Comma-delimited input with fuzzy matching

---

## 8. Authentication and Permissions

### 8.1 Tables Involved
```
users (Phoenix auth)
├── id, email, hashed_password, confirmed_at, etc.
└── has_many user_profiles

user_profiles
├── user_id, tenant_id, full_name, phone, title, etc.
└── belongs_to user, tenant

user_tenant_assignments
├── user_id, tenant_id, role_id, is_active
└── Links users to tenants with roles

cmms_user_roles
├── name, display_name, permissions, is_system_role
└── Defines what actions users can perform

tenants
└── Multi-tenant organization data
```

### 8.2 Permission Check Flow
1. User logs in → creates session
2. Session contains `current_user` and `current_tenant`
3. For each request, check `user_tenant_assignments` for active assignment
4. Load `cmms_user_roles` to get permissions array
5. Check if required permission exists in user's role permissions
6. Grant/deny access to feature

### 8.3 Common Permissions
- `view_assets`, `create_assets`, `edit_assets`, `delete_assets`
- `view_work_orders`, `create_work_orders`, `edit_work_orders`, etc.
- `view_pm_schedules`, `create_pm_schedules`, `edit_pm_schedules`, etc.
- `view_reports`, `export_data`
- `manage_users`, `manage_settings`, `manage_tenants`

---

## 9. Known Issues and TODOs

### 9.1 Console Errors
- [ ] `view.js:926 Cannot read properties of null (reading 'getAttribute')` - investigate phx-input targeting
- [ ] WebSocket connection warnings in console - check live reload config
- [ ] Multiple clause default value warnings - refactor query builders

### 9.2 Missing Functionality
- [ ] Exports module implementation for maintenance history CSV export
- [ ] Number.Currency for asset value formatting
- [ ] File upload for asset images
- [ ] Document attachment system for PM schedules
- [ ] Audit log for all entity changes

### 9.3 Code Quality
- [ ] Remove unused imports and aliases (warnings during compilation)
- [ ] Add tests for PM tag autocomplete
- [ ] Add tests for modal interactions
- [ ] Add tests for filter functionality

---

## 10. Development Guidelines

### 10.1 When Adding New Fields
1. Create migration with proper field types
2. Update schema in model file
3. Update changesets to include new fields
4. Update forms/templates to display/edit fields
5. Update this documentation
6. Add tests

### 10.2 When Adding New Features
1. Check if similar feature exists elsewhere
2. Follow existing patterns for consistency
3. Use existing components (CoreComponents)
4. Update navigation if needed
5. Add permissions checks
6. Document in this file

### 10.3 Before Deploying
1. Run `mix compile --warnings-as-errors` to catch issues
2. Run `mix test` to ensure no regressions
3. Check browser console for JavaScript errors
4. Test all CRUD operations
5. Test with different user roles
6. Test with multiple tenants

---

## Document History
- Initial creation: January 2025
- Last updated: January 2025
- Maintained by: Development Team
