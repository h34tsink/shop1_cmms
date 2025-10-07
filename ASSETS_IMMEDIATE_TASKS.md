# Assets Page - Immediate Action Items

## 🚀 START HERE - Priority Tasks

### ✅ COMPLETED
1. Fixed PM tags filter dropdown
2. Fixed assets sorting (type consistency)
3. Fixed initial sort application
4. Created comprehensive filter tests (44 passing)
5. Created sorting tests (15 passing)

---

## 🔥 DO NEXT (This Session/Today)

### Task 1: Manual Test Current Sorting ⏱️ 15 min
**Why**: Verify our fixes actually work in the browser
**Steps**:
1. Start Phoenix server: `mix phx.server`
2. Navigate to `/assets` page
3. Check if assets are sorted alphabetically by name
4. Check if down arrow shows next to "Name" column
5. Click "Name" header - verify arrow flips and order reverses
6. Click "Equipment #" header - verify sort changes
7. Click "Status" header - verify sort works
8. Click "Criticality" header - verify sort works
9. Apply a filter, then sort - verify both work together

**Expected Result**: All sorting should work with visual indicators

---

### Task 2: Test Delete Confirmation ⏱️ 30 min
**Why**: Critical safety feature - users shouldn't accidentally delete assets
**Current State**: Delete handler exists but no confirmation
**Implementation**:

```elixir
# Add to assets_live.ex
def handle_event("confirm_delete", %{"id" => id}, socket) do
  asset = Assets.get_asset!(socket.assigns.tenant_id, id)
  
  socket = socket
  |> assign(:delete_confirm_asset, asset)
  |> assign(:show_delete_modal, true)
  
  {:noreply, socket}
end

def handle_event("cancel_delete", _params, socket) do
  socket = socket
  |> assign(:delete_confirm_asset, nil)
  |> assign(:show_delete_modal, false)
  
  {:noreply, socket}
end

def handle_event("delete_asset", %{"id" => id}, socket) do
  asset = Assets.get_asset!(socket.assigns.tenant_id, id)
  
  case Assets.delete_asset(asset) do
    {:ok, _asset} ->
      {:noreply, 
       socket
       |> assign(:show_delete_modal, false)
       |> apply_filters()
       |> put_flash(:info, "Asset deleted successfully")}
    
    {:error, changeset} ->
      {:noreply, put_flash(socket, :error, "Cannot delete asset: #{error_message(changeset)}")}
  end
end
```

**Template Addition**:
```heex
<%= if @show_delete_modal do %>
  <.modal id="delete-confirm" show>
    <div class="p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">
        Delete Asset?
      </h3>
      <p class="text-sm text-gray-600 mb-4">
        Are you sure you want to delete <strong><%= @delete_confirm_asset.name %></strong>?
        This action cannot be undone.
      </p>
      <div class="flex justify-end gap-3">
        <button phx-click="cancel_delete" class="btn-secondary">
          Cancel
        </button>
        <button phx-click="delete_asset" phx-value-id={@delete_confirm_asset.id} class="btn-danger">
          Delete
        </button>
      </div>
    </div>
  </.modal>
<% end %>
```

---

### Task 3: Excel Export Implementation ⏱️ 2 hours
**Why**: Very common user request, CSV alone is limiting
**Steps**:

#### 3.1: Add Dependency
```elixir
# mix.exs
defp deps do
  [
    # ... existing deps
    {:elixlsx, "~> 0.6.0"}
  ]
end
```

Then run: `mix deps.get`

#### 3.2: Create Export Function
```elixir
# lib/shop1_cmms/exports.ex

def export_assets_to_xlsx(assets) do
  # Create workbook
  workbook = %Elixlsx.Workbook{
    sheets: [
      %Elixlsx.Sheet{
        name: "Assets",
        rows: [
          # Header row (bold)
          ["Asset Number", "Name", "Type", "Location", "Manufacturer", 
           "Model", "Status", "Criticality", "Install Date"] 
          |> Enum.map(&%Elixlsx.Cell{value: &1, bold: true})
        ] ++ 
        # Data rows
        Enum.map(assets, fn asset ->
          [
            asset.asset_number,
            asset.name,
            asset.asset_type?.name,
            asset.location?.name,
            asset.manufacturer,
            asset.model,
            format_status(asset.status),
            format_criticality(asset.criticality),
            format_date(asset.install_date)
          ]
        end)
      }
    ]
  }
  
  # Generate binary
  {:ok, content} = Elixlsx.write_to_memory(workbook, "assets.xlsx")
  content
end

defp format_status(status), do: status |> to_string() |> String.capitalize()
defp format_criticality(crit), do: crit |> to_string() |> String.capitalize()
defp format_date(nil), do: ""
defp format_date(date), do: Calendar.strftime(date, "%Y-%m-%d")
```

#### 3.3: Update Event Handler
```elixir
# lib/shop1_cmms_web/live/assets_live.ex

def handle_event("export", %{"format" => "xlsx"}, socket) do
  xlsx_content = Exports.export_assets_to_xlsx(socket.assigns.filtered_assets)
  timestamp = DateTime.utc_now() |> Calendar.strftime("%Y%m%d_%H%M%S")
  filename = "assets_export_#{timestamp}.xlsx"
  
  {:noreply,
   socket
   |> push_event("download", %{
     data: Base.encode64(xlsx_content),
     filename: filename,
     mime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
   })
   |> put_flash(:info, "Exporting #{length(socket.assigns.filtered_assets)} assets to Excel...")}
end
```

#### 3.4: Test
- [ ] Export with all assets
- [ ] Export with filters applied
- [ ] Export with search
- [ ] File opens in Excel
- [ ] All columns present
- [ ] Dates formatted correctly
- [ ] No encoding issues

---

### Task 4: Pagination Implementation ⏱️ 3 hours
**Why**: Performance degrades with 1000+ assets
**Steps**:

#### 4.1: Add Pagination Assigns to Mount
```elixir
socket
|> assign(:page, 1)
|> assign(:page_size, 50)
|> assign(:total_pages, 1)
```

#### 4.2: Update apply_filters Function
```elixir
defp apply_filters(socket) do
  # Get filtered assets (existing logic)
  filtered_assets = socket.assigns.assets
  |> filter_by_status(socket.assigns.selected_status)
  |> filter_by_type(socket.assigns.selected_type)
  |> filter_by_criticality(socket.assigns.selected_criticality)
  |> filter_by_manufacturer(socket.assigns.selected_manufacturer)
  |> filter_by_search(socket.assigns.search_term)
  |> filter_by_date_range(socket.assigns.date_from, socket.assigns.date_to)
  |> sort_assets(socket.assigns.sort_field, socket.assigns.sort_direction)
  
  # Calculate pagination
  total_count = length(filtered_assets)
  page_size = socket.assigns.page_size
  total_pages = ceil(total_count / page_size)
  page = min(socket.assigns.page, max(total_pages, 1))
  
  # Paginate results
  paginated_assets = filtered_assets
  |> Enum.drop((page - 1) * page_size)
  |> Enum.take(page_size)
  
  socket
  |> assign(:filtered_assets, paginated_assets)
  |> assign(:total_assets_count, total_count)
  |> assign(:total_pages, total_pages)
  |> assign(:page, page)
end
```

#### 4.3: Add Event Handlers
```elixir
def handle_event("change_page", %{"page" => page}, socket) do
  {page_num, _} = Integer.parse(page)
  {:noreply, socket |> assign(:page, page_num) |> apply_filters()}
end

def handle_event("change_page_size", %{"size" => size}, socket) do
  {size_num, _} = Integer.parse(size)
  {:noreply, socket |> assign(:page_size, size_num) |> assign(:page, 1) |> apply_filters()}
end

def handle_event("next_page", _, socket) do
  next_page = min(socket.assigns.page + 1, socket.assigns.total_pages)
  {:noreply, socket |> assign(:page, next_page) |> apply_filters()}
end

def handle_event("prev_page", _, socket) do
  prev_page = max(socket.assigns.page - 1, 1)
  {:noreply, socket |> assign(:page, prev_page) |> apply_filters()}
end
```

#### 4.4: Add Pagination UI
```heex
<div class="flex items-center justify-between px-3 py-2 bg-gray-50 border-t">
  <!-- Page size selector -->
  <div class="flex items-center gap-2 text-xs">
    <span class="text-gray-600">Show:</span>
    <select phx-change="change_page_size" name="size" class="text-xs border-gray-300 rounded">
      <option value="25" selected={@page_size == 25}>25</option>
      <option value="50" selected={@page_size == 50}>50</option>
      <option value="100" selected={@page_size == 100}>100</option>
      <option value="200" selected={@page_size == 200}>200</option>
    </select>
    <span class="text-gray-600">per page</span>
  </div>
  
  <!-- Page info -->
  <div class="text-xs text-gray-600">
    Showing <%= (@page - 1) * @page_size + 1 %> to 
    <%= min(@page * @page_size, @total_assets_count) %> of 
    <%= @total_assets_count %> results
  </div>
  
  <!-- Page navigation -->
  <div class="flex items-center gap-2">
    <button 
      phx-click="prev_page" 
      disabled={@page == 1}
      class="btn-toolbar disabled:opacity-50"
    >
      Previous
    </button>
    
    <span class="text-xs text-gray-600">
      Page <%= @page %> of <%= @total_pages %>
    </span>
    
    <button 
      phx-click="next_page" 
      disabled={@page >= @total_pages}
      class="btn-toolbar disabled:opacity-50"
    >
      Next
    </button>
  </div>
</div>
```

---

## 📊 Today's Success Metrics

After completing these 4 tasks, you will have:

✅ **Verified sorting works** (user-tested)
✅ **Safe delete operation** (prevents accidents)
✅ **Excel export** (major user request)
✅ **Pagination** (performance improvement)

**Time Required**: ~6-7 hours
**Impact**: HIGH - These are the most requested features

---

## 🎯 Tomorrow's Tasks (If Time Today)

### Task 5: Import Functionality ⏱️ 4 hours
- CSV file upload
- Preview before import
- Validation and error reporting
- Bulk insert

### Task 6: Bulk Operations ⏱️ 3 hours
- Row selection checkboxes
- Select all functionality
- Bulk delete
- Bulk status change

### Task 7: PDF Export ⏱️ 2 hours
- Install chromic_pdf
- Create PDF template
- Format for print
- Generate and download

---

## 🛠️ Quick Commands Reference

```bash
# Start server
mix phx.server

# Run tests
mix test

# Add new dependency
# 1. Edit mix.exs
# 2. Run:
mix deps.get

# Compile
mix compile

# Check formatting
mix format

# Run specific test file
mix test path/to/test_file.exs

# Run tests with coverage
mix test --cover
```

---

## 📝 Notes & Tips

### When Testing:
- Use Chrome DevTools to check for JavaScript errors
- Check the browser console for LiveView errors
- Monitor the terminal for server errors
- Test with real data (create test assets)

### When Implementing:
- Make small commits after each feature
- Test after each change
- Update this checklist as you complete tasks
- Document any issues or blockers

### Common Gotchas:
- LiveView events need `phx-` prefix
- Modal needs `show` attribute to display
- Downloads need `push_event` for client-side handling
- Pagination affects export (export all, not just page)

---

## ✅ Completion Checklist

Mark items as you complete them:

**Today**:
- [ ] Manual test sorting - all 9 checks pass
- [ ] Delete confirmation implemented
- [ ] Delete confirmation tested
- [ ] Excel export dependency added
- [ ] Excel export function created
- [ ] Excel export tested
- [ ] Pagination logic added
- [ ] Pagination UI added
- [ ] Pagination tested with filters
- [ ] All changes committed

**Tomorrow**:
- [ ] Import UI created
- [ ] Import parser implemented
- [ ] Import tested
- [ ] Bulk operations checkboxes
- [ ] Bulk delete implemented
- [ ] PDF export working
- [ ] All features documented

---

**Ready to start? Begin with Task 1 (Manual Testing) - it only takes 15 minutes and verifies your sorting fix works!**
