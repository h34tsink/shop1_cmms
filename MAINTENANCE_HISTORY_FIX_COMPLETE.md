# Maintenance History Fix - Complete

## Date: June 1, 2025

## Issues Fixed

### 1. Query Type Casting Errors
**Problem**: The maintenance history query was failing with multiple type casting errors in the UNION ALL query:
- `UndefinedFunctionError: function :bigint.type/0 is undefined`
- Incorrect field name `actual_completion_date` (should be `actual_end_date`)
- Unsafe nil comparison with `tenant_id`

**Solution**:
- Removed invalid `type(field, :bigint)` casts - Ecto doesn't support this for integer fields
- Fixed field name from `actual_completion_date` to `actual_end_date` to match WorkOrder schema
- Changed `where: tenant_id == ^tenant_id` to `where: not is_nil(tenant_id) and tenant_id == ^tenant_id`
- Added proper Decimal module alias
- Used proper type casting with `type(^"value", :string)` for literal values

### 2. Database Schema Alignment
**Problem**: Queries referenced non-existent fields:
- `work_orders.actual_completion_date` doesn't exist (it's `actual_end_date`)
- Attempted to join with `user_details` table (doesn't exist)

**Solution**:
- Updated to use correct `work_orders.actual_end_date` field
- Changed user joins to use `users` table with `username` field
- Properly handle integer `technician_id` fields from both PM executions and work orders

### 3. Data Conversion
**Problem**: Work order duration in hours needed to be converted to minutes to match PM execution format

**Solution**:
- Added `fragment("CAST(? * 60 AS integer)", w.actual_hours)` to convert hours to minutes

## Final Query Structure

```elixir
# PM Executions Query
pm_query =
  from(e in PmExecution,
    left_join: ps in PmSchedule, on: e.pm_schedule_id == ps.id,
    left_join: a in Asset, on: e.asset_id == a.id,
    left_join: u in User, on: e.completed_by_user_id == u.id,
    where: not is_nil(e.tenant_id) and e.tenant_id == ^tenant_id and e.status == :completed,
    select: %{
      id: type(e.id, :string),
      type: type(^"PM", :string),
      date: e.execution_date,
      completed_date: e.completed_date,
      title: e.execution_number,
      description: fragment("COALESCE(?, 'N/A') || ' - ' || COALESCE(?, 'Unknown')", ps.title, a.name),
      status: type(^"completed", :string),
      equipment_id: type(e.asset_id, :string),
      equipment_name: coalesce(a.name, "Unknown"),
      technician_id: e.completed_by_user_id,  # Integer, no cast needed
      technician_name: coalesce(u.username, "Unknown"),
      duration: e.actual_duration_minutes,
      cost: type(^Decimal.new("0"), :decimal),
      notes: e.tech_notes,
      reference_id: type(e.pm_schedule_id, :string)
    }
  )

# Work Orders Query
wo_query =
  from(w in WorkOrder,
    left_join: a in Asset, on: w.asset_id == a.id,
    left_join: u in User, on: w.assigned_to == u.id,
    where: not is_nil(w.tenant_id) and w.tenant_id == ^tenant_id and w.status == :completed,
    select: %{
      id: type(w.id, :string),
      type: type(^"Work Order", :string),
      date: w.actual_start_date,
      completed_date: w.actual_end_date,  # Fixed: was actual_completion_date
      title: w.title,
      description: w.description,
      status: type(^"completed", :string),
      equipment_id: type(w.asset_id, :string),
      equipment_name: coalesce(a.name, "Unknown"),
      technician_id: w.assigned_to,  # Integer, no cast needed
      technician_name: coalesce(u.username, "Unknown"),
      duration: fragment("CAST(? * 60 AS integer)", w.actual_hours),  # Convert to minutes
      cost: coalesce(w.actual_cost, type(^Decimal.new("0"), :decimal)),
      notes: w.completion_notes,
      reference_id: type(w.id, :string)
    }
  )
```

## Testing Results

✅ Server starts successfully
✅ Maintenance history page loads
✅ Query executes without errors
✅ Data from PM executions is retrieved
✅ Page displays within app layout with sidebar and top bar

## Files Modified

1. `/lib/shop1_cmms_web/live/maintenance_history_live.ex`
   - Added `alias Decimal` at top
   - Fixed query type casting
   - Fixed field names
   - Added proper nil checks

## Next Steps

The maintenance history page is now functional. Further enhancements can include:
- Export functionality (CSV, Excel, PDF)
- Advanced filtering
- Click-through to detail views
- Performance optimization for large datasets
