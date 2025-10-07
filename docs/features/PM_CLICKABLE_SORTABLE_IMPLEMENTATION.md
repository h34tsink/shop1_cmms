# PM Schedules: Clickable Rows & Sortable Headers Implementation

## Date: January 31, 2025

## Overview
Implemented clickable table rows and sortable column headers for the PM Schedules list page, improving usability and navigation.

## Changes Made

### 1. **Clickable Table Rows**

#### Added Event Handler
```elixir
def handle_event("view_schedule", %{"id" => id}, socket) do
  {:noreply, push_navigate(socket, to: ~p"/pm-schedules/#{id}")}
end
```

#### Updated Table Row
- Made entire row clickable by adding `phx-click="view_schedule"` and `phx-value-id`
- Added `cursor-pointer` class and hover effects
- Action buttons in the last column use `onclick="event.stopPropagation()"` to prevent row click when clicking buttons

### 2. **Sortable Column Headers**

#### Added Sort State to Mount
```elixir
|> assign(:sort_by, :schedule_number)
|> assign(:sort_direction, :asc)
```

#### Created Sort Handler
```elixir
def handle_event("sort", %{"by" => field}, socket) do
  field_atom = String.to_existing_atom(field)
  
  {sort_direction, sort_by} = 
    if socket.assigns.sort_by == field_atom do
      # Toggle direction if same field
      new_direction = if socket.assigns.sort_direction == :asc, do: :desc, else: :asc
      {new_direction, field_atom}
    else
      # New field, default to ascending
      {:asc, field_atom}
    end
  
  {:noreply, 
   socket
   |> assign(:sort_by, sort_by)
   |> assign(:sort_direction, sort_direction)
   |> filter_schedules()}
end
```

#### Created Sortable Header Component
```elixir
defp sortable_header(assigns) do
  ~H"""
  <th 
    scope="col" 
    phx-click="sort" 
    phx-value-by={@field}
    class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 transition-colors select-none"
  >
    <div class="flex items-center gap-1">
      <span><%= @label %></span>
      <%= if @current_sort == @field do %>
        <%= if @direction == :asc do %>
          <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"/>
          </svg>
        <% else %>
          <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
          </svg>
        <% end %>
      <% else %>
        <svg class="w-4 h-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4"/>
        </svg>
      <% end %>
    </div>
  </th>
  """
end
```

#### Updated Filter Function with Sorting
```elixir
defp filter_schedules(socket) do
  schedules = socket.assigns.schedules
  search_query = socket.assigns.search_query |> String.downcase()
  frequency = socket.assigns.filter_frequency
  status = socket.assigns.filter_status
  sort_by = socket.assigns.sort_by
  sort_direction = socket.assigns.sort_direction
  
  filtered =
    schedules
    |> Enum.filter(fn schedule ->
      # ... existing filter logic ...
    end)
    |> Enum.sort_by(
      fn schedule ->
        case sort_by do
          :schedule_number -> schedule.schedule_number || ""
          :title -> schedule.title || ""
          :asset -> if schedule.asset, do: schedule.asset.name, else: ""
          :frequency -> schedule.frequency
          :last_completed -> schedule.last_completed_date || ~U[1970-01-01 00:00:00Z]
          :next_due -> schedule.next_due_date || ~U[9999-12-31 23:59:59Z]
          :status -> schedule.is_active
          _ -> schedule.schedule_number || ""
        end
      end,
      sort_direction
    )
  
  assign(socket, :filtered_schedules, filtered)
end
```

### 3. **Updated Table Headers**
Replaced static `<th>` tags with sortable header components:
```heex
<.sortable_header field={:schedule_number} label="Schedule #" current_sort={@sort_by} direction={@sort_direction} />
<.sortable_header field={:title} label="Title" current_sort={@sort_by} direction={@sort_direction} />
<.sortable_header field={:asset} label="Equipment" current_sort={@sort_by} direction={@sort_direction} />
<.sortable_header field={:frequency} label="Frequency" current_sort={@sort_by} direction={@sort_direction} />
<.sortable_header field={:last_completed} label="Last Completed" current_sort={@sort_by} direction={@sort_direction} />
<.sortable_header field={:next_due} label="Next Due" current_sort={@sort_by} direction={@sort_direction} />
<.sortable_header field={:status} label="Status" current_sort={@sort_by} direction={@sort_direction} />
```

## Features

### Clickable Rows
- ✅ Click anywhere on a PM schedule row to view details
- ✅ Hover effect shows the row is interactive
- ✅ Action buttons (Complete, View, Edit, Delete) still work independently
- ✅ Smooth navigation to detail page

### Sortable Headers
- ✅ Click column headers to sort
- ✅ Visual indicator (arrow icon) shows current sort column and direction
- ✅ Toggle between ascending and descending by clicking the same header
- ✅ Hover effect on headers indicates they are clickable
- ✅ Sortable fields:
  - Schedule Number
  - Title
  - Equipment (Asset)
  - Frequency
  - Last Completed Date
  - Next Due Date
  - Status (Active/Inactive)

### Visual Indicators
- **Active Sort**: Blue arrow (up or down) next to column name
- **Inactive Columns**: Grey double arrow icon
- **Hover State**: Light grey background on headers
- **Row Hover**: Light grey background with smooth transition

## User Experience Improvements

1. **Faster Navigation**: Users can quickly open PM schedule details with a single click
2. **Better Organization**: Sort by any column to find schedules more easily
3. **Visual Feedback**: Clear indicators of current sort and clickable elements
4. **Intuitive Interface**: Follows common data table patterns users are familiar with
5. **Preserved Actions**: Individual action buttons still work as expected

## Testing Recommendations

1. **Manual Testing**:
   - Click on various PM schedule rows to verify navigation
   - Click different column headers to test sorting
   - Toggle sort direction by clicking the same header twice
   - Test action buttons to ensure they don't trigger row click
   - Verify hover effects work correctly

2. **Browser Testing**:
   - Test in different browsers (Chrome, Firefox, Edge)
   - Verify on different screen sizes
   - Check that cursor changes appropriately

3. **Data Testing**:
   - Test with empty lists
   - Test with schedules that have null values
   - Verify sort works correctly with various data types

## Files Modified

1. `lib/shop1_cmms_web/live/pm_schedules_live.ex`:
   - Added sort state to mount
   - Added `view_schedule` handler
   - Added `sort` handler
   - Created `sortable_header/1` helper function
   - Enhanced `filter_schedules/1` with sorting logic
   - Updated table row template with click handler
   - Updated table headers with sortable component

## Future Enhancements

1. **Multi-column Sort**: Allow sorting by multiple columns
2. **Remember Sort Preference**: Save user's sort preference in session/local storage
3. **Keyboard Navigation**: Add keyboard shortcuts for navigation (Enter to open)
4. **Quick Preview**: Show preview on hover without full navigation
5. **Batch Actions**: Select multiple rows with checkboxes for bulk operations

## Notes

- The implementation uses LiveView's built-in event handling for smooth, real-time updates
- No page reload required when sorting or navigating
- Sort state is maintained during filtering and searching
- Default sort is by Schedule Number in ascending order
