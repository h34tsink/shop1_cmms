# Modal Close Fix - Configuration Page

## Issue
The modal windows on the PM Tags configuration page were not closing properly when clicking:
- The Cancel button
- The X close button in the header
- The backdrop (clicking outside the modal)

## Root Cause
The modal had event handling conflicts:
1. The backdrop had `phx-click="close_modal"` which was correct
2. The modal panel had `phx-click="prevent_close"` to prevent closing when clicking inside
3. However, event propagation was not being stopped, causing the events to bubble up incorrectly

## Solution
Updated `/lib/shop1_cmms_web/live/metadata_live.html.heex`:

### Before
```heex
<div class="fixed inset-0 z-50 overflow-y-auto">
  <div class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:p-0">
    <div 
      class="fixed inset-0 transition-opacity" 
      aria-hidden="true"
      phx-click="close_modal"
    >
      <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
    </div>
    <div 
      class="inline-block align-middle bg-white rounded-lg..."
      phx-click="prevent_close"
    >
```

### After
```heex
<div class="fixed inset-0 z-50 overflow-y-auto" id="modal-overlay">
  <div class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:p-0" phx-click="close_modal">
    <div 
      class="fixed inset-0 transition-opacity" 
      aria-hidden="true"
    >
      <div class="absolute inset-0 bg-gray-500 opacity-75"></div>
    </div>
    <div 
      class="inline-block align-middle bg-white rounded-lg..."
      onclick="event.stopPropagation()"
    >
```

## Changes Made
1. **Moved the `phx-click="close_modal"` handler** from the backdrop to the container div
2. **Replaced PhoenixLiveView event handler** with vanilla JavaScript `onclick="event.stopPropagation()"` on the modal panel
3. This ensures:
   - Clicking outside the modal (on the backdrop) triggers the close event
   - Clicking inside the modal stops propagation and doesn't trigger the close event
   - The Cancel and X buttons still work as they have their own `phx-click="close_modal"` handlers

## Testing
✅ Modal now closes when:
- Clicking the Cancel button
- Clicking the X button in the header
- Clicking outside the modal (on the backdrop/overlay)

✅ Modal stays open when:
- Clicking inside the modal content area
- Interacting with form fields

## Files Modified
- `/lib/shop1_cmms_web/live/metadata_live.html.heex`

## Related Functions
The `handle_event("close_modal", ...)` function in `/lib/shop1_cmms_web/live/metadata_live.ex` was already correctly implemented:

```elixir
def handle_event("close_modal", _params, socket) do
  {:noreply, push_patch(socket, to: ~p"/configuration/#{socket.assigns.metadata_type}")}
end
```

This function uses `push_patch/2` which updates the URL and triggers a re-render without a full page reload, effectively closing the modal by setting `@show_modal` to `false` through the `apply_action/3` function.
