# Filtering System Fix Analysis

## Issue Summary
Filtering is not working across multiple pages in the project. The user reports that filtering functionality needs to be fixed or updated in all instances.

## Affected Pages
1. PM Tags Configuration (`/configuration/pm_tags`)
2. PM Schedules (`/pm-schedules`)
3. Assets (`/assets`)
4. Work Orders (`/work-orders`)
5. User Management (`/user-management`)
6. Maintenance History (`/maintenance-history`)

## Root Cause Analysis

### 1. **PM Tags Configuration**
- Location: `lib/shop1_cmms_web/live/metadata_live.ex`
- Filter event handler exists: `handle_event("filter_tag_type", ...)`
- Backend function supports filtering: `Maintenance.list_pm_tags/2` with `:tag_type` option
- **Issue**: The filter appears to be implemented correctly, need to verify the actual issue

### 2. **PM Schedules**
- Location: `lib/shop1_cmms_web/live/pm_schedules_live.ex`
- Has `filter_schedules/1` function for client-side filtering
- Filter handlers: `filter_frequency` and `filter_status`
- **Issue**: Need to verify if filters are applying correctly

### 3. **Assets**
- Location: `lib/shop1_cmms_web/live/assets_live.ex`
- Has multiple filter handlers: `filter_status`, `filter_type`, `filter_criticality`
- **Issue**: Need to check implementation

## Common Filtering Pattern Issues

### Issue 1: Missing or Incorrect Event Handlers
Some filters may have the UI but no corresponding `handle_event` function.

### Issue 2: Filter Not Updating Assigns
Filters update assigns but don't trigger re-filtering of data.

### Issue 3: Frontend/Backend Mismatch
UI sends different parameter names than backend expects.

### Issue 4: Search Query Not Being Applied
Search functionality may not be filtering results properly.

## Fix Strategy

1. **Audit all filter implementations** across LiveView modules
2. **Standardize filtering pattern** - use consistent approach
3. **Add debugging** to understand what's happening
4. **Test each filter** individually
5. **Document the correct field names** for future reference

## Recommended Filtering Pattern

```elixir
# In mount/3 or handle_params/3
assign(:filters, %{
  search: "",
  status: "all",
  type: "all"
})

# Event handler
def handle_event("filter", %{"field" => field, "value" => value}, socket) do
  filters = Map.put(socket.assigns.filters, String.to_existing_atom(field), value)
  {:noreply, 
   socket
   |> assign(:filters, filters)
   |> apply_filters()}
end

# Apply filters function
defp apply_filters(socket) do
  items = socket.assigns.all_items
  filters = socket.assigns.filters
  
  filtered =
    items
    |> filter_by_search(filters.search)
    |> filter_by_status(filters.status)
    |> filter_by_type(filters.type)
  
  assign(socket, :filtered_items, filtered)
end
```

## Next Steps
1. Check the server logs when filter is clicked
2. Add console.log to see if events are firing
3. Verify the actual parameters being sent
4. Fix each page systematically
