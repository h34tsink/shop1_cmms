# PM Execution "Not Found" Fix - Summary

## Issue
When clicking on a PM execution record from the Maintenance History page, users were getting a "PM execution not found" error message and being redirected back to the history page.

## Root Cause
In `lib/shop1_cmms_web/live/maintenance_history_live.ex`, the query building PM execution history records was incorrectly setting the `reference_id` field to `pm_schedule_id` instead of the execution's own `id`:

```elixir
# BEFORE (incorrect):
reference_id: fragment("?::varchar", e.pm_schedule_id)

# AFTER (correct):
reference_id: fragment("?::varchar", e.id)
```

## How It Works
1. The Maintenance History page displays a list of completed PMs and Work Orders
2. Each row has a `phx-click="view_detail"` event with `phx-value-id={item.reference_id}` and `phx-value-type={item.type}`
3. The `view_detail` handler routes to the appropriate detail page:
   - For "PM" type → `/pm-executions/#{id}`
   - For "Work Order" type → `/work_orders/#{id}`
4. The PM Execution Detail page then looks up the execution by that ID

## What Was Fixed
- **File**: `lib/shop1_cmms_web/live/maintenance_history_live.ex`
- **Line**: 271
- **Change**: Changed `reference_id` from `e.pm_schedule_id` to `e.id` in the PM executions query

## Testing
- Created test fixture for PM executions in `test/support/fixtures/maintenance_fixtures.ex`
- Created comprehensive tests in `test/shop1_cmms_web/live/pm_execution_detail_live_test.exs`
- Verified compilation without errors
- The fix ensures that clicking on a PM execution in the history properly navigates to its detail view

## Impact
- ✅ PM executions can now be viewed from the history page
- ✅ No changes to database schema or other components required  
- ✅ Work order history navigation was already correct and unaffected
- ✅ The `reference_id` now correctly points to the execution record itself

## Files Changed
1. `lib/shop1_cmms_web/live/maintenance_history_live.ex` - Fixed query
2. `test/support/fixtures/maintenance_fixtures.ex` - Added pm_execution_fixture
3. `test/shop1_cmms_web/live/pm_execution_detail_live_test.exs` - Added tests
