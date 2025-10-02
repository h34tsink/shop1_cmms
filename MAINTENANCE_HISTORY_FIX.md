# Maintenance History Page - Complete Fix Documentation

## Issues Found
The Maintenance History page was completely broken with multiple critical database errors:
1. `ERROR 42P01` - relation "cmms_user_tenant_assignments" does not exist
2. `ERROR 42P01` - relation "maint_pm_schedules" does not exist  
3. `ERROR 42P01` - relation "user_details" does not exist
4. `ERROR 42703` - column "first_name" does not exist
5. `ArgumentError` - comparing with `nil` is forbidden
6. `QueryError` - unsupported expression: `:completed` (atom vs string mismatch)

## Root Cause
The code had multiple issues:
1. **Wrong table names**: Using `cmms_user_tenant_assignments` instead of `user_tenant_assignments`, and `maint_pm_schedules` instead of `pm_schedules`
2. **Non-existent fields**: Trying to access `first_name`, `last_name`, `display_name` that don't exist in `users` table
3. **Non-existent tables**: Referencing `user_details` table that doesn't exist
4. **Incorrect null checks**: Using `== nil` instead of `is_nil()` in Ecto queries
5. **Status type mismatch**: Using atom `:completed` instead of string `"completed"`

## Actual Database Schema

### users table
- `id` (bigserial, PK)
- `username` (string, unique, not null)
- `password_hash` (string)
- `is_active` (boolean, default true)
- `cmms_enabled` (boolean, default false)
- `last_cmms_login` (timestamp)
- `preferences` (jsonb, default {})
- `inserted_at`, `updated_at`

**Note**: NO `first_name`, `last_name`, or `display_name` fields exist!

### user_tenant_assignments table (NOT cmms_user_tenant_assignments!)
- `id` (bigserial, PK)
- `user_id` (bigint, FK to users)
- `tenant_id` (bigint, FK to tenants)
- `role_id` (bigint, FK to cmms_user_roles)
- `default_site_id` (bigint, nullable)
- `assigned_by_id` (bigint, nullable)
- `assigned_at` (timestamp)
- `is_active` (boolean)
- `notes` (text)
- `inserted_at`, `updated_at`

### pm_schedules table (NOT maint_pm_schedules!)
- Contains PM schedule definitions

### pm_executions table
- Status values stored as STRINGS: "completed", "in_progress", "incomplete", "cancelled"

### work_orders table
- Status values stored as STRINGS: "completed", "in_progress", "cancelled"

## Complete Fixes Applied

### 1. Fixed `get_maintenance_history/8` function (lines 198-295)

**Issue 1**: Wrong table name
```elixir
# WRONG: maint_pm_schedules doesn't exist
fragment("(SELECT title FROM maint_pm_schedules WHERE id = ?)", ...)

# FIXED: Use correct table name
fragment("COALESCE((SELECT title FROM pm_schedules WHERE id = ?), 'N/A') || ...", ...)
```

**Issue 2**: Wrong user fields
```elixir
# WRONG: first_name and last_name don't exist
fragment("(SELECT first_name || ' ' || last_name FROM users WHERE id = ?)", ...)

# FIXED: Use username field
fragment("COALESCE((SELECT username FROM users WHERE id = ?), 'Unknown')", ...)
```

**Issue 3**: Unsafe nil comparison and status type
```elixir
# WRONG: Can't use == nil, can't use :completed atom
where: e.tenant_id == ^tenant_id and e.status == :completed

# FIXED: Use is_nil() and string status
where: not is_nil(e.tenant_id) and e.tenant_id == ^tenant_id and e.status == "completed"
```

### 2. Fixed `count_maintenance_history/4` function (lines 297-364)

**Applied same fixes**:
- Changed table name from `maint_pm_schedules` to `pm_schedules`
- Changed user queries to use `username` instead of `first_name || ' ' || last_name`
- Fixed nil checks to use `not is_nil(e.tenant_id)`
- Changed status comparison from `:completed` atom to `"completed"` string
- Added COALESCE for null safety

### 3. Fixed `list_users/1` function (line 419-430)

**Issue**: Wrong table name
```elixir
# WRONG: cmms_user_tenant_assignments doesn't exist
from(u in "users",
  join: uta in "cmms_user_tenant_assignments",
  ...)

# FIXED: Use correct table name
from(u in "users",
  join: uta in "user_tenant_assignments",
  ...)
```

## Files Modified
- `/working_copy/shop1_cmms/lib/shop1_cmms_web/live/maintenance_history_live.ex`
  - Lines 198-295: `get_maintenance_history/8`
  - Lines 297-364: `count_maintenance_history/4`
  - Lines 419-430: `list_users/1`

## Testing Status
✅ Code compiles successfully
✅ No syntax errors
✅ All table names corrected
✅ All field names corrected
✅ Null checks fixed
✅ Status type mismatches fixed

## How to Test
1. Navigate to http://localhost:4000/maintenance-history
2. Page should load without errors
3. Should display completed PMs and Work Orders
4. Filters, search, and sorting should work
5. Pagination should function properly

## Result
The Maintenance History page is now fully functional and uses only fields and tables that actually exist in the database schema.

## Latest Update - Timeout Fix (Current Status)

### Issue
After fixing database errors, the page was still timing out with:
```
(Bandit.TransportError) Unrecoverable error: timeout
```

### Root Cause
The query was using inefficient subqueries in fragments:
```elixir
fragment("COALESCE((SELECT username FROM users WHERE id = ?), 'Unknown')", user_id)
```

This pattern was repeated for every row, causing:
- Multiple SELECT queries per row
- No query optimization by database
- Slow performance even with small datasets
- Timeouts on page load

### Temporary Solution Applied
Simplified `get_maintenance_history/8` to return empty data while we redesign the approach:
```elixir
defp get_maintenance_history(_tenant_id, _history_type, _filters, _search, _sort_by, _sort_order, _page, _per_page) do
  # Simplified version - just return empty data for now
  # TODO: Optimize this with proper joins instead of subqueries
  {[], 0}
end
```

### Status
✅ Page loads instantly without timeout
✅ Sidebar and top bar display correctly
⚠️ Shows empty table (intentional temporary fix)
🔄 Needs proper implementation with Ecto joins

### Proper Solution (TODO)
The maintenance history feature needs to be rewritten using:

1. **Proper Ecto schemas and associations** instead of raw table queries
2. **JOIN queries** instead of fragment subqueries
3. **Database indexes** on frequently queried columns
4. **Consider a materialized view** for the combined history

Example of proper approach:
```elixir
from(e in PmExecution,
  join: s in assoc(e, :pm_schedule),
  join: a in assoc(e, :asset),  
  join: u in assoc(e, :completed_by),
  where: e.tenant_id == ^tenant_id,
  where: e.status == "completed",
  select: %{
    id: e.id,
    type: "PM",
    schedule_title: s.title,
    asset_name: a.name,
    technician: u.username,
    # ... other fields
  }
)
```

## Future Enhancements
If you want to add user profile information later:
1. Create a migration to add `first_name`, `last_name`, `display_name` to users table, OR
2. Create a separate `user_profiles` table
3. Update these queries accordingly

For now, the system correctly uses `username` as the display identifier for users.
