## Fixed: Assets Page Loading Error

### Issue
The assets page was failing to load with an ArgumentError:
'ranges (first..last) expect both sides to be integers, got: 1..:high'

### Root Cause
In the assets table, we were trying to display criticality as stars using a range:
``
<%= for _ <- 1..asset.criticality do %>
``

The problem is that sset.criticality is an atom (:high, :medium, :low, etc.) 
not an integer, so Elixir couldn't create a range with it.

### Solution
Added a helper function criticality_to_number/1 that converts criticality atoms to integers:
- :critical → 5 stars
- :high → 4 stars
- :medium → 3 stars
- :low → 2 stars
- :minimal → 1 star
- any other value → 0 stars

Updated the template to use:
``
<%= for _ <- 1..criticality_to_number(asset.criticality) do %>
``

### What to Test
1. Navigate to /assets page - it should now load without errors
2. Check that assets display the correct number of stars based on their criticality:
   - Critical assets should show 5 stars
   - High criticality assets should show 4 stars
   - Medium criticality assets should show 3 stars
   - Low criticality assets should show 2 stars
3. Verify filtering by criticality still works
4. Test creating/editing assets with different criticality levels

### Next Steps
The fix is committed. You can now:
1. Test the assets page to verify it loads correctly
2. Continue with Phase 2 implementation for other pages
3. Let me know if you encounter any other issues with the page loading
