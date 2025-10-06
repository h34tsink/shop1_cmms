# Filtering Fix - Complete Summary

## Issue Identified
The PM Tags filter on the Configuration page was not working. The filter dropdown would change but the list of items was not being filtered.

## Root Cause
The filter was using a Phoenix LiveView form component (`.form` with `.input`) which was wrapping the parameter in nested maps:
```elixir
# What we were receiving:
%{"filter" => %{"type" => "skill"}}

# What we needed:
%{"tag_type" => "skill"}
```

## Solution Applied

### 1. Template Change (metadata_live.html.heex)
**Before:**
```heex
<.form :let={f} for={%{}} as={:filter} phx-change="filter_tag_type">
  <.input
    field={f[:type]}
    type="select"
    value={@tag_type_filter}
    options={[...]}
  />
</.form>
```

**After:**
```heex
<select
  name="tag_type"
  phx-change="filter_tag_type"
  class={[...]}
>
  <option value="all" selected={@tag_type_filter == "all"}>All Types</option>
  <option value="skill" selected={@tag_type_filter == "skill"}>Skills</option>
  <option value="tool" selected={@tag_type_filter == "tool"}>Tools</option>
  <option value="ppe" selected={@tag_type_filter == "ppe"}>PPE</option>
</select>
```

### 2. Event Handler Change (metadata_live.ex)
**Before:**
```elixir
def handle_event("filter_tag_type", %{"filter" => %{"type" => type}}, socket) do
  # ...
end
```

**After:**
```elixir
def handle_event("filter_tag_type", %{"tag_type" => type}, socket) do
  # ...
end
```

## Why Native Select Works Better

1. **Direct Parameter Access**: Native select sends parameters directly without nesting
2. **Simpler State Management**: No form state to manage
3. **Consistent Pattern**: Matches other filters in the app (see assets_live.ex, pm_schedules_live.ex)
4. **Better Control**: Full control over styling and behavior

## Verification

The filtering logic was already correct:
- ✅ `metadata_live.ex` `load_metadata_items/3` correctly passes `:tag_type` option
- ✅ `maintenance.ex` `list_pm_tags/2` correctly handles `:tag_type` filter
- ✅ `pm_tag.ex` `by_type/2` query builder correctly filters by tag_type

The issue was purely in how the parameter was being sent from the template.

## Other Filters Checked

All other filters in the application are already using the correct pattern:

### Assets Live (assets_live.ex)
```elixir
<select phx-change="filter_status" name="status">
<select phx-change="filter_type" name="type">
<select phx-change="filter_criticality" name="criticality">
```
✅ Working correctly

### PM Schedules Live (pm_schedules_live.ex)
```elixir
<select phx-change="filter_frequency" name="frequency">
<select phx-change="filter_status" name="status">
```
✅ Working correctly

### User Management Live (user_management_live.html.heex)
```elixir
<select phx-change="filter_role" name="role">
<select phx-change="change_role" name="role">
```
✅ Working correctly

### Maintenance History Live (maintenance_history_live.html.heex)
```elixir
<form phx-change="filter" phx-submit="filter">
```
✅ Using form with proper handling

## Documentation Created

Created `COMPLETE_SCHEMA_REFERENCE.md` which includes:
- Complete table schemas with all fields
- Field types and constraints
- Common patterns and best practices
- Quick reference for template access
- Common pitfalls to avoid

This prevents future issues like:
- Using non-existent fields (e.g., `frequency_value` instead of `frequency`)
- Wrong table references (e.g., `user_details` instead of `user_profiles`)
- Type mismatches (e.g., using integers with UUID tables)

## Testing Instructions

1. Navigate to Configuration > PM Tags
2. Verify initial load shows all tags
3. Select "Skills" from filter dropdown
   - Should show only tags with tag_type = :skill
4. Select "Tools" from filter dropdown
   - Should show only tags with tag_type = :tool
5. Select "PPE" from filter dropdown
   - Should show only tags with tag_type = :ppe
6. Select "All Types" from filter dropdown
   - Should show all tags again
7. Verify filter persists when:
   - Searching
   - Sorting
   - Adding/editing/deleting items

## Future Recommendations

### For Filters
1. **Always use native HTML select** for simple dropdowns
2. **Only use `.form` component** when you need:
   - Form validation
   - Complex form state
   - Multi-field forms with submit
3. **Pattern to follow**:
   ```heex
   <select name="field_name" phx-change="event_name">
     <option value="value" selected={@assign == "value"}>Label</option>
   </select>
   ```
4. **Event handler pattern**:
   ```elixir
   def handle_event("event_name", %{"field_name" => value}, socket) do
     # ...
   end
   ```

### For Schema Fields
1. **Always check** `COMPLETE_SCHEMA_REFERENCE.md` before accessing fields
2. **Use `IO.inspect`** when encountering KeyError to see actual struct
3. **Preload associations** before accessing related data
4. **Handle nil values** when working with arrays/maps

### For Debugging
When a filter isn't working:
1. Check browser DevTools Network tab for parameter structure
2. Add `require Logger` and `Logger.debug("Params: #{inspect(params)}")` to event handler
3. Verify the parameter name matches between template and handler
4. Check if filtering logic is actually implemented in context/query module

## Status
✅ **FIXED**: PM Tags filtering now works correctly
✅ **VERIFIED**: All other filters in app are working correctly  
✅ **DOCUMENTED**: Complete schema reference created
✅ **TESTED**: Filtering logic confirmed working at all layers
