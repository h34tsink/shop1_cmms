# Protocol Safe Rendering Guidelines

## Issue Summary
Fixed `Protocol.UndefinedError` in asset detail view where `Shop1Cmms.Assets.AssetLocation` struct was being rendered directly in Phoenix templates.

**Error:** `protocol Phoenix.HTML.Safe not implemented for type Shop1Cmms.Assets.AssetLocation`

## Root Cause
Phoenix LiveView templates expect HTML-safe values when using `<%= %>`. Structs are not automatically converted to HTML-safe strings and must be explicitly handled.

## The Fix
**Before (Problematic):**
```elixir
<%= @asset.location || "N/A" %>
```

**After (Fixed):**
```elixir
<%= if @asset.location, do: @asset.location.name, else: "N/A" %>
```

## Patterns to Watch For

### 1. Direct Struct Rendering
**❌ Avoid:**
```elixir
<%= @asset.location %>
<%= @asset.asset_type %>
<%= @work_order.assigned_user %>
<%= @user.tenant %>
```

**✅ Use Instead:**
```elixir
<%= if @asset.location, do: @asset.location.name, else: "N/A" %>
<%= @asset.asset_type.name %>
<%= @work_order.assigned_user.username %>
<%= @user.tenant.name %>
```

### 2. Association Fields That Are Structs
Be especially careful with Ecto associations that return structs:

**Common Associations to Check:**
- `belongs_to` relationships (location, asset_type, user, tenant)
- `has_one` relationships 
- Any preloaded association

### 3. Safe Patterns for Optional Associations
```elixir
# For required associations
<%= @asset.asset_type.name %>

# For optional associations (can be nil)
<%= if @asset.location, do: @asset.location.name, else: "N/A" %>
<%= @asset.location&.name || "N/A" %>

# For displaying multiple fields
<%= if @asset.location do %>
  <%= @asset.location.name %> (<%= @asset.location.code %>)
<% else %>
  N/A
<% end %>
```

## Files to Monitor

### High-Risk Files
These files commonly render association data and should be checked when modifying:

1. **Asset-related LiveViews:**
   - `lib/shop1_cmms_web/live/asset_detail_live.ex` ✅ Fixed
   - `lib/shop1_cmms_web/live/assets_live.ex`
   - `lib/shop1_cmms_web/live/asset_form_live.ex`

2. **Work Order LiveViews:**
   - `lib/shop1_cmms_web/live/work_order_*_live.ex`
   - Look for: `assigned_to`, `created_by`, `asset`, `location`

3. **User Management:**
   - `lib/shop1_cmms_web/live/user_*_live.ex`
   - Look for: `tenant`, `roles`, `assignments`

### Schema Associations to Watch
Based on the codebase, these associations are commonly rendered:

```elixir
# Asset schema associations
belongs_to :location, Shop1Cmms.Assets.AssetLocation
belongs_to :asset_type, Shop1Cmms.Assets.AssetType
belongs_to :parent_asset, __MODULE__
belongs_to :tenant, Shop1Cmms.Tenants.Tenant

# User schema associations  
belongs_to :tenant, Shop1Cmms.Tenants.Tenant
has_many :user_tenant_assignments

# Work Order schema associations
belongs_to :asset, Shop1Cmms.Assets.Asset
belongs_to :assigned_to, Shop1Cmms.Accounts.User
```

## Debugging Checklist

When encountering `Protocol.UndefinedError`:

1. **Identify the struct type** from the error message
2. **Find the template line** mentioned in the error
3. **Check if you're rendering a struct directly** with `<%= %>`
4. **Replace with specific field access** like `.name`, `.title`, `.username`
5. **Handle nil cases** with conditional rendering or safe navigation

## Prevention Strategies

### 1. Code Review Checklist
- [ ] Are all `<%= %>` expressions rendering primitive types (string, number, boolean)?
- [ ] Are struct associations accessed via specific fields (`.name`, `.title`)?
- [ ] Are optional associations handled with nil checks?

### 2. Testing
- [ ] Test with both populated and nil associations
- [ ] Verify pages load without protocol errors
- [ ] Check edge cases where associations might not be preloaded

### 3. Linting Rules (Future)
Consider adding custom linting rules to catch:
- Direct struct rendering in templates
- Missing nil checks for optional associations

## Related Phoenix HTML.Safe Implementations
Phoenix automatically implements `Phoenix.HTML.Safe` for:
- Atom, BitString, Date, DateTime, Decimal, Float, Integer, List
- NaiveDateTime, Time, Tuple, URI
- Phoenix-specific types (LiveComponent.CID, LiveView.Component, etc.)

**Custom structs do NOT automatically implement this protocol.**

## Examples from Our Fix

The fix in `asset_detail_live.ex` line 213:
```elixir
# Before: Would cause Protocol.UndefinedError
<dd class="mt-1 text-sm text-gray-900"><%= @asset.location || "N/A" %></dd>

# After: Safe rendering
<dd class="mt-1 text-sm text-gray-900"><%= if @asset.location, do: @asset.location.name, else: "N/A" %></dd>
```

This change ensures we render the location's name (a string) rather than the entire AssetLocation struct.