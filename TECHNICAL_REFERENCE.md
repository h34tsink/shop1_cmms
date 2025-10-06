# Shop1 CMMS - Technical Reference Guide

**Last Updated:** 2025
**Version:** 1.0

## Table of Contents
1. [Database Schema](#database-schema)
2. [Common Issues & Solutions](#common-issues--solutions)
3. [Field Mapping Reference](#field-mapping-reference)
4. [Component Guidelines](#component-guidelines)
5. [Search & Filter Patterns](#search--filter-patterns)

---

## Database Schema

### Core Tables

#### Users & Authentication
- **`users`** - Main user authentication table
  - `id` (UUID, PK)
  - `email` (string, unique)
  - `hashed_password` (string)
  - `confirmed_at` (datetime)
  - `tenant_id` (integer, FK)
  
- **`user_profiles`** - Extended user information
  - `id` (UUID, PK)
  - `user_id` (UUID, FK → users)
  - `first_name` (string)
  - `last_name` (string)
  - `phone` (string)
  - `avatar_url` (string)
  - `job_title` (string)
  - `department_id` (UUID, FK → departments)
  - `employee_id` (string)
  - `is_active` (boolean)
  - `tenant_id` (integer)

- **`user_roles`** - Role assignments
  - `id` (UUID, PK)
  - `user_id` (UUID, FK → users)
  - `role_id` (UUID, FK → roles)
  - `tenant_id` (integer)

- **`roles`** - Available roles
  - `id` (UUID, PK)
  - `name` (string)
  - `description` (string)
  - `tenant_id` (integer)

- **`permissions`** - Available permissions
  - `id` (UUID, PK)
  - `name` (string)
  - `resource` (string)
  - `action` (string)
  - `description` (string)

- **`role_permissions`** - Permission assignments
  - `id` (UUID, PK)
  - `role_id` (UUID, FK → roles)
  - `permission_id` (UUID, FK → permissions)

#### Assets
- **`assets`** - Equipment/machinery
  - `id` (UUID, PK)
  - `asset_number` (string, unique)
  - `name` (string)
  - `description` (text)
  - `serial_number` (string)
  - `model_number` (string)
  - `asset_type_id` (UUID, FK → asset_types)
  - `manufacturer_id` (UUID, FK → manufacturers)
  - `location_id` (UUID, FK → asset_locations)
  - `department_id` (UUID, FK → departments)
  - `purchase_date` (date)
  - `purchase_cost` (decimal)
  - `warranty_expiration` (date)
  - `installation_date` (date)
  - `status` (enum: operational, down, maintenance, retired)
  - `criticality` (enum: low, medium, high, critical)
  - `is_active` (boolean)
  - `tenant_id` (integer)

- **`asset_types`** - Equipment categories
  - `id` (UUID, PK)
  - `name` (string)
  - `description` (text)
  - `code` (string)
  - `tenant_id` (integer)

- **`asset_locations`** - Physical locations
  - `id` (UUID, PK)
  - `name` (string)
  - `code` (string)
  - `description` (text)
  - `tenant_id` (integer)

#### Maintenance
- **`pm_schedules`** - Preventive maintenance schedules
  - `id` (UUID, PK)
  - `schedule_number` (string, unique)
  - `title` (string)
  - `description` (text)
  - `frequency` (enum: daily, weekly, monthly, quarterly, semi_annual, annual, custom)
  - `frequency_interval` (integer) - e.g., every 2 weeks
  - `meter_threshold` (decimal) - for meter-based PM
  - `meter_unit` (string) - e.g., "hours", "cycles"
  - `work_instructions` (text)
  - `estimated_duration` (decimal) - in hours
  - `required_skills` (array of strings)
  - `required_tools` (array of strings)
  - `required_parts` (jsonb)
  - `safety_notes` (text)
  - `ppe_required` (array of strings)
  - `last_completed_date` (datetime)
  - `next_due_date` (datetime)
  - `is_active` (boolean)
  - `asset_id` (UUID, FK → assets)
  - `created_by` (UUID, FK → users)
  - `updated_by` (UUID, FK → users)
  - `tenant_id` (integer)

- **`pm_executions`** - PM execution records
  - `id` (UUID, PK)
  - `execution_number` (string, unique)
  - `pm_schedule_id` (UUID, FK → pm_schedules)
  - `scheduled_date` (date)
  - `completed_date` (datetime)
  - `status` (enum: pending, in_progress, completed, cancelled)
  - `duration` (decimal) - actual hours
  - `notes` (text)
  - `assigned_to` (UUID, FK → users)
  - `completed_by` (UUID, FK → users)
  - `tenant_id` (integer)

- **`pm_tags`** - Skills, tools, and PPE tags
  - `id` (UUID, PK)
  - `name` (string)
  - `tag_type` (enum: skill, tool, ppe)
  - `description` (text)
  - `is_active` (boolean)
  - `usage_count` (integer)
  - `tenant_id` (integer)

- **`work_orders`** - Corrective maintenance
  - `id` (UUID, PK)
  - `work_order_number` (string, unique)
  - `title` (string)
  - `description` (text)
  - `status` (enum: open, in_progress, on_hold, completed, cancelled)
  - `priority` (enum: low, medium, high, urgent)
  - `work_type` (enum: corrective, preventive, inspection, project)
  - `asset_id` (UUID, FK → assets)
  - `requested_by` (UUID, FK → users)
  - `assigned_to` (UUID, FK → users)
  - `due_date` (date)
  - `completed_date` (datetime)
  - `estimated_hours` (decimal)
  - `actual_hours` (decimal)
  - `tenant_id` (integer)

#### Metadata
- **`manufacturers`** - Equipment manufacturers
  - `id` (UUID, PK)
  - `name` (string)
  - `code` (string)
  - `description` (text)
  - `website` (string)
  - `contact_email` (string)
  - `contact_phone` (string)
  - `address` (text)
  - `notes` (text)
  - `is_active` (boolean)
  - `tenant_id` (integer)

- **`departments`** - Organizational departments
  - `id` (UUID, PK)
  - `name` (string)
  - `code` (string)
  - `description` (text)
  - `manager_name` (string)
  - `manager_email` (string)
  - `cost_center` (string)
  - `budget_code` (string)
  - `is_active` (boolean)
  - `tenant_id` (integer)

- **`suppliers`** - Parts/service suppliers
  - Similar structure to manufacturers

- **`priority_codes`** - Work order priorities
- **`maintenance_categories`** - Maintenance type categorization
- **`custom_fields`** - User-defined fields

---

## Common Issues & Solutions

### Issue 1: Template Accessing Non-Existent Fields

**Problem:** Templates try to access fields that don't exist in the schema (e.g., `frequency_value` instead of `frequency`).

**Solution:**
1. Always check the schema definition first
2. Use the correct field names from the database
3. Update templates to match actual schema

**Example:**
```elixir
# ❌ WRONG - These fields don't exist
schedule.frequency_value
schedule.frequency_unit

# ✅ CORRECT - These are the actual fields
schedule.frequency         # enum: :daily, :weekly, etc.
schedule.frequency_interval # integer: 1, 2, 3, etc.
schedule.meter_threshold   # for meter-based PM
schedule.meter_unit       # "hours", "cycles", etc.
```

### Issue 2: LiveView Filter Not Working

**Problem:** Filters in LiveView don't apply when selected.

**Root Causes:**
1. Incorrect parameter extraction from form
2. Missing form wrapper around select element
3. Type mismatch (string vs atom)
4. Handler not matching parameter structure

**Solution:**
```heex
<!-- ✅ CORRECT: Wrap select in form -->
<.form :let={f} for={%{}} as={:filter} phx-change="filter_event">
  <select name="filter_field">
    <option value="value1">Option 1</option>
  </select>
</.form>
```

```elixir
# ✅ CORRECT: Handler extracts from nested params
def handle_event("filter_event", %{"filter" => %{"filter_field" => value}}, socket) do
  # Apply filter
  {:noreply, socket |> assign(:filter, value) |> reload_data()}
end
```

### Issue 3: Modal Won't Close

**Problem:** Modal close button doesn't work.

**Root Causes:**
1. Event handler navigating instead of patching
2. Missing `show_modal` assignment update
3. Incorrect routing

**Solution:**
```elixir
def handle_event("close_modal", _params, socket) do
  {:noreply, push_patch(socket, to: ~p"/configuration/#{socket.assigns.metadata_type}")}
end
```

---

## Field Mapping Reference

### PM Schedule Fields

| Display Name | Schema Field | Type | Notes |
|--------------|--------------|------|-------|
| Frequency | `frequency` | enum | :daily, :weekly, :monthly, :quarterly, :semi_annual, :annual, :custom |
| Interval | `frequency_interval` | integer | How many frequency units between executions |
| Meter Threshold | `meter_threshold` | decimal | For meter-based PM (optional) |
| Meter Unit | `meter_unit` | string | "hours", "cycles", etc. (optional) |
| Skills | `required_skills` | string[] | Array of skill tags |
| Tools | `required_tools` | string[] | Array of tool tags |
| PPE | `ppe_required` | string[] | Array of PPE tags |
| Parts | `required_parts` | jsonb | Key-value pairs |

### Asset Fields

| Display Name | Schema Field | Type | Notes |
|--------------|--------------|------|-------|
| Asset Number | `asset_number` | string | Auto-generated, unique |
| Status | `status` | enum | operational, down, maintenance, retired |
| Criticality | `criticality` | enum | low, medium, high, critical |
| Type | `asset_type_id` | UUID | FK to asset_types |
| Location | `location_id` | UUID | FK to asset_locations |
| Manufacturer | `manufacturer_id` | UUID | FK to manufacturers |

### User Fields

| Display Name | Schema Field | Table | Notes |
|--------------|--------------|-------|-------|
| Email | `email` | users | Authentication |
| Password | `hashed_password` | users | Never display |
| First Name | `first_name` | user_profiles | Display name |
| Last Name | `last_name` | user_profiles | Display name |
| Job Title | `job_title` | user_profiles | |
| Department | `department_id` | user_profiles | FK to departments |
| Active Status | `is_active` | user_profiles | |

**Important:** There is NO `user_details` table. Use `user_profiles` instead.

---

## Component Guidelines

### Editable Forms Pattern

For inline editing (like Asset Details page):

1. **Display Mode:** Show data with light background, no borders
2. **Edit Mode:** 
   - Add `border border-gray-300 bg-white` to inputs
   - Keep layout consistent between modes
   - Use same grid structure
   
```heex
<%= if @editing do %>
  <input 
    type="text" 
    value={@asset.name}
    class="px-3 py-2 border border-gray-300 rounded bg-white"
  />
<% else %>
  <div class="px-3 py-2 bg-gray-50 rounded">
    <%= @asset.name %>
  </div>
<% end %>
```

### Tag Input Pattern

For skills, tools, PPE tags:

1. **Auto-complete:** Show suggestions as user types
2. **Creation:** Auto-create if tag doesn't exist
3. **Multi-select:** Support comma-delimited entry
4. **Display:** Show as colored badges

```heex
<!-- Tag display -->
<div class="flex flex-wrap gap-2">
  <%= for tag <- @tags do %>
    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
      <%= tag %>
      <button phx-click="remove_tag" phx-value-tag={tag} class="ml-1">×</button>
    </span>
  <% end %>
</div>
```

### Work Instructions Pattern

For PM work instructions:

1. **Display:** Numbered list format
2. **Edit:** Individual line items with:
   - Add/remove buttons
   - Drag-to-reorder (future)
   - Rich text editing (future)

---

## Search & Filter Patterns

### Global Search

Searches across multiple entity types:

```elixir
def search(query_string) do
  # Search assets
  assets = Assets.search(query_string)
  
  # Search work orders
  work_orders = Maintenance.search_work_orders(query_string)
  
  # Search PM schedules
  pm_schedules = Maintenance.search_pm_schedules(query_string)
  
  # Combine and return
  %{
    assets: assets,
    work_orders: work_orders,
    pm_schedules: pm_schedules
  }
end
```

### List View Filters

Standard filter pattern:

```elixir
def list_items(tenant_id, opts \\ []) do
  query = base_query(tenant_id)
  
  # Apply search
  query = if opts[:search], do: apply_search(query, opts[:search]), else: query
  
  # Apply type filter
  query = if opts[:type], do: filter_by_type(query, opts[:type]), else: query
  
  # Apply sorting
  query = if opts[:sort_by], do: apply_sort(query, opts[:sort_by], opts[:sort_order]), else: query
  
  # Apply active filter
  query = if opts[:active_only], do: active_only(query), else: query
  
  Repo.all(query)
end
```

### Form Filter Pattern

```heex
<.form :let={f} for={%{}} as={:filter} phx-change="apply_filter">
  <select name="status">
    <option value="">All</option>
    <option value="active">Active</option>
    <option value="inactive">Inactive</option>
  </select>
  
  <select name="type">
    <option value="">All Types</option>
    <option value="skill">Skills</option>
    <option value="tool">Tools</option>
  </select>
</.form>
```

```elixir
def handle_event("apply_filter", %{"filter" => filters}, socket) do
  opts = build_filter_opts(filters)
  items = list_items(socket.assigns.tenant_id, opts)
  {:noreply, assign(socket, :items, items)}
end

defp build_filter_opts(filters) do
  []
  |> maybe_add_opt(:status, filters["status"])
  |> maybe_add_opt(:type, filters["type"])
end

defp maybe_add_opt(opts, _key, nil), do: opts
defp maybe_add_opt(opts, _key, ""), do: opts
defp maybe_add_opt(opts, key, value), do: Keyword.put(opts, key, value)
```

---

## UI/UX Patterns

### Color Scheme

- **Primary:** Blue (#2563EB)
- **Success:** Green (#10B981)
- **Warning:** Yellow (#F59E0B)
- **Danger:** Red (#EF4444)
- **Neutral:** Gray (#6B7280)

### Status Colors

```elixir
def status_color(:operational), do: "green"
def status_color(:down), do: "red"
def status_color(:maintenance), do: "yellow"
def status_color(:retired), do: "gray"
```

### Priority Colors

```elixir
def priority_color(:low), do: "gray"
def priority_color(:medium), do: "blue"
def priority_color(:high), do: "orange"
def priority_color(:urgent), do: "red"
```

### Responsive Breakpoints

- **sm:** 640px
- **md:** 768px
- **lg:** 1024px
- **xl:** 1280px
- **2xl:** 1536px

---

## Testing Checklist

### Before Making Changes

- [ ] Check schema for correct field names
- [ ] Review related context functions
- [ ] Check existing tests
- [ ] Run current tests to establish baseline

### After Making Changes

- [ ] Run affected tests
- [ ] Test in browser (if UI changes)
- [ ] Check console for errors
- [ ] Verify database queries (in logs)
- [ ] Test with different user roles
- [ ] Test on mobile viewport (if UI changes)

---

## Development Workflow

### 1. Understanding the Request

- Identify affected modules (Schema, Context, LiveView, Template)
- Check for existing similar functionality
- Review related documentation

### 2. Making Changes

- Start with smallest possible change
- Update schema if needed (migration)
- Update context functions
- Update LiveView logic
- Update templates
- Test incrementally

### 3. Common Gotchas

- **Atoms vs Strings:** Enums are atoms, form params are strings
- **Nested Params:** Form inputs come nested under form name
- **Preloading:** Don't forget to preload associations
- **Tenant ID:** Always filter by tenant_id
- **Active Filter:** Consider is_active field

---

## Quick Reference Commands

```bash
# Start server
mix phx.server

# Run tests
mix test

# Database console
iex -S mix
Repo.all(Asset)

# Create migration
mix ecto.gen.migration add_field_to_table

# Run migrations
mix ecto.migrate

# Rollback migration
mix ecto.rollback

# Reset database (DEV ONLY!)
mix ecto.reset

# Check routes
mix phx.routes

# Format code
mix format

# Check for issues
mix credo
```

---

## Architecture Decisions

### Multi-Tenancy

- Every table has `tenant_id`
- All queries must filter by tenant
- Tenant set in session/assigns

### Authentication

- Powered by `phx.gen.auth`
- Uses `users` table
- Extended by `user_profiles`
- Role-based access control via `roles` and `permissions`

### Primary Keys

- All tables use UUIDs for IDs
- Business identifiers (asset_number, work_order_number) are separate

### Soft Deletes

- Use `is_active` boolean
- Never hard delete data
- Filter views with `active_only: true` option

---

## Future Enhancements

- [ ] Real-time notifications via Phoenix Channels
- [ ] File attachments for work orders/assets
- [ ] Barcode/QR code scanning
- [ ] Mobile app (Phoenix LiveView Native)
- [ ] Advanced reporting/analytics
- [ ] Integration APIs
- [ ] Audit trail for all changes
- [ ] Work order time tracking
- [ ] Parts inventory management
- [ ] Vendor portal

---

**End of Technical Reference**

*Keep this document updated as the project evolves!*
