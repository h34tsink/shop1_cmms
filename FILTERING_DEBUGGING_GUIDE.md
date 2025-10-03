# Filtering Debugging Guide

## How to Debug Filtering Issues

### Step 1: Verify Event is Firing
Add temporary debugging to the event handler:

```elixir
def handle_event("filter_tag_type", %{"type" => type}, socket) do
  IO.inspect(type, label: "Filter type received")
  IO.inspect(socket.assigns.tag_type_filter, label: "Current filter")
  
  result = assign(socket, :tag_type_filter, type) 
    |> load_metadata_items(socket.assigns.current_tenant.id, socket.assigns.search_query)
  
  IO.inspect(length(result.assigns.items), label: "Items after filter")
  
  {:noreply, result}
end
```

### Step 2: Check Browser Console
Open browser dev tools and watch for:
- Errors in console
- Network tab showing the websocket message
- Phoenix LiveView events

### Step 3: Verify Query Building
Check that opts are being passed correctly:

```elixir
defp load_metadata_items(socket, tenant_id, search_query \\ "") do
  opts = [active_only: true]
  
  IO.inspect(search_query, label: "Search query")
  IO.inspect(socket.assigns.tag_type_filter, label: "Tag type filter")
  
  opts = if search_query != "", do: Keyword.put(opts, :search, search_query), else: opts
  
  opts = if socket.assigns.metadata_type == "pm_tags" and socket.assigns.tag_type_filter != "all" do
    IO.puts("Adding tag_type filter: #{socket.assigns.tag_type_filter}")
    Keyword.put(opts, :tag_type, socket.assigns.tag_type_filter)
  else
    opts
  end
  
  IO.inspect(opts, label: "Final opts")
  
  # ... rest of function
end
```

### Step 4: Verify Context Function
Check the context function receives and processes opts:

```elixir
def list_pm_tags(tenant_id, opts \\ []) do
  IO.inspect(opts, label: "list_pm_tags opts")
  
  query = PmTag.by_tenant(tenant_id)
  
  query =
    case opts[:tag_type] do
      type when type in ["skill", "tool", "ppe"] -> 
        IO.puts("Filtering by tag_type string: #{type}")
        PmTag.by_type(query, String.to_existing_atom(type))
      type when type in [:skill, :tool, :ppe] -> 
        IO.puts("Filtering by tag_type atom: #{type}")
        PmTag.by_type(query, type)
      _ -> 
        IO.puts("No tag_type filter")
        query
    end
  
  # ... rest of function
end
```

## Common Issues and Solutions

### Issue 1: Filter Value Not Being Passed
**Symptom**: Event fires but assigns don't update
**Solution**: Check the form element has correct `name` attribute
```html
<select phx-change="filter_tag_type" name="type">
```

### Issue 2: Wrong Parameter Name
**Symptom**: Pattern match error in handle_event
**Solution**: Match parameter name to the HTML `name` attribute
```elixir
# If HTML has name="status"
def handle_event("filter", %{"status" => status}, socket)

# NOT
def handle_event("filter", %{"value" => status}, socket)
```

### Issue 3: Filter State Not Persisting
**Symptom**: Filter works but resets on other actions
**Solution**: Ensure filter assigns are maintained through all code paths

### Issue 4: Context Function Ignores Options
**Symptom**: opts are passed but query doesn't change
**Solution**: Check that query is being piped through all conditions
```elixir
# GOOD:
query = base_query()
query = if condition, do: apply_filter(query), else: query
query = if condition2, do: apply_filter2(query), else: query

# BAD:
query = base_query()
if condition, do: apply_filter(query)  # Returns new query but doesn't assign
if condition2, do: apply_filter2(query)  # Works on original query!
```

## Testing Checklist

- [ ] Event shows in browser console (LiveView debug mode)
- [ ] Event handler is called (add IO.inspect)
- [ ] Assigns are updated correctly
- [ ] Query opts are built correctly
- [ ] Context function receives opts
- [ ] Query is modified by opts
- [ ] Results are filtered
- [ ] UI updates with filtered results
- [ ] Filter persists after other actions
- [ ] Multiple filters work together

## Browser Testing Commands

```javascript
// In browser console, enable LiveView debug
window.liveSocket.enableDebug()

// Watch for events
window.addEventListener('phx:filter_tag_type', (e) => console.log('Filter event:', e))
```
