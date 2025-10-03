# PM Tags Configuration - Fixes and Improvements

## Date: 2025-10-03

## Issues Fixed

### 1. Modal Closing Issue
**Problem**: The modal was closing immediately when clicking anywhere, including inside the modal itself.

**Solution**: 
- Moved the `phx-click="close_modal"` from the outer container to only the backdrop overlay
- Added `phx-click="prevent_close"` to the modal content area to prevent event bubbling
- Added a close button (X) in the modal header for better UX
- Made the modal panel `z-10 relative` to ensure it's above the backdrop

**Files Changed**:
- `lib/shop1_cmms_web/live/metadata_live.html.heex` - Lines 424-478
- `lib/shop1_cmms_web/live/metadata_live.ex` - Added `handle_event("prevent_close", ...)` handler

### 2. Missing Sorting Functionality
**Problem**: PM Tags table had no sorting capability.

**Solution**:
- Added sortable headers for Name, Type, and Usage Count columns
- Headers now show sort direction indicators (▲/▼)
- Clicking a header toggles between ascending and descending order
- Visual feedback with hover effects on sortable headers

**Files Changed**:
- `lib/shop1_cmms_web/live/metadata_live.html.heex` - Lines 135-160
- `lib/shop1_cmms_web/live/metadata_live.ex` - Added `handle_event("sort", ...)` handler and sort state tracking

### 3. Missing Filtering Functionality
**Problem**: No ability to filter PM tags by type (Skills, Tools, PPE).

**Solution**:
- Added type filter dropdown in the search bar area
- Filter options: All Types, Skills, Tools, PPE
- Filter persists across searches
- Works in combination with search functionality

**Files Changed**:
- `lib/shop1_cmms_web/live/metadata_live.html.heex` - Lines 63-80
- `lib/shop1_cmms_web/live/metadata_live.ex` - Added `handle_event("filter_tag_type", ...)` handler

### 4. Enhanced list_pm_tags Function
**Problem**: The function didn't support all the filtering and sorting options needed.

**Solution**:
- Added support for `:tag_type` filter (string or atom)
- Added support for `:search` option with text search
- Added support for `:sort_by` and `:sort_order` options
- Maintained backward compatibility with existing `:type` and `:order_by` options

**Files Changed**:
- `lib/shop1_cmms/maintenance.ex` - Updated `list_pm_tags/2` function (Lines 14-68)

## Database Population

### Seeded PM Tags
The system has been populated with comprehensive PM tags:
- **46 Skills**: Including certifications, technical skills (mechanical, electrical, specialized), inspection methods, and maintenance procedures
- **70 Tools**: Including hand tools, power tools, measurement instruments, diagnostic equipment, and specialized tools
- **32 PPE Items**: Including eye/face, hand, foot, head, hearing, respiratory, body, and fall protection

**Seed File**: `priv/repo/seed_pm_tags.exs`

## Testing Notes

### How to Test

1. **Navigate to Configuration Page**:
   - Go to `/configuration/pm_tags`
   - You should see a table with all seeded PM tags

2. **Test Filtering**:
   - Select "Skills" from the filter dropdown - should show only skills
   - Select "Tools" - should show only tools
   - Select "PPE" - should show only PPE items
   - Select "All Types" - should show everything

3. **Test Sorting**:
   - Click "Name" header - should sort alphabetically
   - Click again - should reverse the sort
   - Click "Type" header - should sort by type (PPE, Skill, Tool)
   - Click "Usage" header - should sort by usage count

4. **Test Search**:
   - Type "wrench" in search box - should filter to tools with "wrench" in name
   - Type "safety" - should show items with "safety" in name
   - Clear search - should show all items (respecting type filter)

5. **Test Modal**:
   - Click "New pm_tag" button - modal should open
   - Click inside the modal - should NOT close
   - Click outside the modal (on backdrop) - should close
   - Click the X button - should close
   - Click "Cancel" button - should close
   - Fill in form and click "Create" - should create and close

6. **Test Create/Edit**:
   - Create a new tag with name, type, and description
   - Edit an existing tag
   - Verify changes are saved
   - Verify validation works (required fields)

## Configuration UI Features

### Current Features
- ✅ List all PM tags with pagination
- ✅ Search tags by name
- ✅ Filter by tag type (Skill, Tool, PPE)
- ✅ Sort by name, type, or usage count
- ✅ Create new tags
- ✅ Edit existing tags
- ✅ Delete tags (with confirmation)
- ✅ Display usage count for each tag
- ✅ Active/Inactive status badges
- ✅ Responsive design
- ✅ Proper modal behavior

### Tag Types and Colors
- **Skills**: Blue badge (`bg-blue-100 text-blue-800`)
- **Tools**: Purple badge (`bg-purple-100 text-purple-800`)
- **PPE**: Orange badge (`bg-orange-100 text-orange-800`)

## Architecture

### Context Structure
```
Shop1Cmms.Maintenance
├── list_pm_tags/2          # List with filtering, sorting, search
├── search_pm_tags/3        # Legacy search function
├── get_pm_tag!/1           # Get single tag by ID
├── get_or_create_pm_tag/3  # Get or create tag (for PM schedules)
├── create_pm_tag/1         # Create new tag
├── update_pm_tag/2         # Update existing tag
├── delete_pm_tag/1         # Delete tag
├── increment_pm_tag_usage/1 # Track usage
└── change_pm_tag/2         # Get changeset for forms
```

### Schema: PmTag
```elixir
field :name, :string          # Tag name (e.g., "LOTO Certified")
field :tag_type, Ecto.Enum    # :skill, :tool, or :ppe
field :description, :string   # Optional description
field :is_active, :boolean    # Active/inactive status
field :usage_count, :integer  # Tracks how many PMs use this tag
field :tenant_id, :integer    # Multi-tenancy support
```

### Query Helpers (in PmTag schema)
- `by_tenant/2` - Filter by tenant
- `by_type/2` - Filter by tag type
- `active_only/1` - Only active tags
- `order_by_usage/1` - Sort by usage (most used first)
- `order_by_name/1` - Sort alphabetically
- `search/2` - Case-insensitive name search

## Integration with PM Schedules

PM tags are designed to be used in PM schedules for:
1. **Required Skills**: Certifications and skills needed to perform the PM
2. **Required Tools**: Tools and equipment needed
3. **Required PPE**: Personal protective equipment required

When tags are used in PM schedules:
- The `usage_count` is automatically incremented
- This helps identify commonly used tags
- Tags can be reused across multiple PM schedules

## Future Enhancements

### Potential Improvements
1. **Bulk Operations**: Select and edit/delete multiple tags at once
2. **Tag Categories**: Group similar tags together
3. **Tag Aliases**: Allow multiple names for the same tag
4. **Tag Suggestions**: Auto-suggest based on PM type or asset
5. **Usage Analytics**: Reports showing which tags are most/least used
6. **Tag Dependencies**: Some tools require certain skills
7. **Export/Import**: Bulk import tags from spreadsheet
8. **Tag Hierarchy**: Parent-child relationships (e.g., "Electrical" parent of "PLC Programming")

## Related Files

### LiveView
- `lib/shop1_cmms_web/live/metadata_live.ex`
- `lib/shop1_cmms_web/live/metadata_live.html.heex`

### Context & Schema
- `lib/shop1_cmms/maintenance.ex`
- `lib/shop1_cmms/maintenance/pm_tag.ex`

### Database
- `priv/repo/migrations/*_create_pm_tags.exs`
- `priv/repo/seed_pm_tags.exs`

### Documentation
- `docs/PM_TAGS_CONFIGURATION.md`
- `docs/PM_TAGS_IMPLEMENTATION_SUMMARY.md`
- `docs/PM_TAGS_FIXES_SUMMARY.md` (this file)

## Compatibility

### Browser Support
- Modern browsers (Chrome, Firefox, Safari, Edge)
- Requires JavaScript enabled for LiveView functionality
- Responsive design works on mobile devices

### Database
- PostgreSQL with UUID support
- Tenant-based isolation
- Supports concurrent access

## Performance Notes

### Optimizations
- Database indexes on:
  - `tenant_id` for tenant filtering
  - `tag_type` for type filtering
  - `name` for searching
  - Composite unique index on `[tenant_id, tag_type, name]`
- LiveView minimizes server round-trips
- Efficient query composition using Ecto
- Search uses case-insensitive ILIKE with pattern matching

### Scaling Considerations
- Tags are cached in LiveView socket state
- Filtering and sorting happen in the database
- Usage count updates are batched (not real-time critical)
- Consider adding pagination for very large tag lists (100+ tags per type)
