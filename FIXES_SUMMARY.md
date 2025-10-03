# Fixes Applied - Modal Closing and Filtering Issues

## Issues Fixed

### 1. Modal Not Closing Properly
**Problem:** Cancel/Close buttons in configuration modals did not close the modal.

**Fix:** Updated `apply_action/3` for :index to reset modal state:
```elixir
defp apply_action(socket, :index, _params) do
  socket
  |> assign(:show_modal, false)
  |> assign(:selected_item, nil)
end
```

### 2. Filtering Not Working  
**Problem:** Tag type filter dropdown did not filter results.

**Root Cause:** Select element with `phx-change` was not wrapped in a form.

**Fix:** Wrapped select in form and updated event handler:
```heex
<.form :let={f} for={%{}} as={:filter} phx-change="filter_tag_type">
  <select name="type">...</select>
</.form>
```

```elixir
def handle_event("filter_tag_type", %{"filter" => %{"type" => type}}, socket)
```

## Files Modified
1. lib/shop1_cmms_web/live/metadata_live.ex
2. lib/shop1_cmms_web/live/metadata_live.html.heex

## Testing
- Modal closing: Click Cancel, X button, or backdrop - modal should close
- Filtering: Select Skills/Tools/PPE from dropdown - list should filter accordingly

