# PM Creation for Components - Implementation Summary

## Overview
Fixed and enhanced the PM (Preventive Maintenance) schedule creation system to properly support creating PMs for equipment components from the asset detail page.

## Changes Made

### 1. Fixed PM Schedule Save Handler
**File:** `lib/shop1_cmms_web/live/pm_schedules_live.ex`

**Issue:** The `save_pm_schedule/3` function only handled `:new` and `:edit` actions, but the system also uses `:new_from_asset` and `:new_from_component` actions.

**Fix:** Updated the function pattern match to handle all three "new" actions:
```elixir
defp save_pm_schedule(socket, action, pm_params) when action in [:new, :new_from_asset, :new_from_component] do
```

### 2. Added Debug Logging
**File:** `lib/shop1_cmms_web/live/pm_schedules_live.ex`

Added comprehensive logging to help diagnose PM creation issues:
- Log when PM schedule creation starts (action type, params, components)
- Log final params before database insert
- Log success with schedule ID and schedule number
- Log errors with changeset details
- Log component linking process with detailed component info

### 3. Enhanced Component Linking
**File:** `lib/shop1_cmms_web/live/pm_schedules_live.ex`

Improved the `create_pm_schedule_components/3` function:
- Added better error handling for component lookups
- Support both map and direct ID references for components
- Added detailed logging for troubleshooting
- Better error messages when components aren't found

### 4. User Feedback Improvement
Enhanced success message to include the generated schedule number:
```elixir
|> put_flash(:info, "PM Schedule created successfully - Schedule ##{pm_schedule.schedule_number}")
```

## How It Works

### PM Creation Flow

1. **User clicks "Schedule PM" button** on a component in the asset detail page
   - Route: `/assets/:asset_id/components/:component_id/schedule-pm`
   - Action: `:new_from_component`

2. **Mount Handler** (`apply_action/3`)
   - Loads the asset and component from database
   - Pre-populates form with asset_id
   - Adds component to the `components` assign (list format: `[%{id: component_id, name: component.name}]`)
   - Sets page title to "Schedule PM for [Component Name] ([Asset Name])"

3. **Form Submission** (`handle_event("save", ...)`)
   - Calls `save_pm_schedule/3` with action `:new_from_component`
   - Combines work instruction lines into single text
   - Adds tags (skills, tools, PPE) to params
   - Creates PM schedule in database

4. **Component Linking** (`create_pm_schedule_components/3`)
   - Iterates through components list
   - Looks up each component in database for full details
   - Creates `pm_schedule_components` records linking PM to components
   - Handles errors gracefully (skips components that don't exist)

5. **Success**
   - Shows success message with schedule number
   - Redirects to PM schedules list (`/pm-schedules`)

## Testing Guide

### Test Case 1: Create PM from Component
1. Navigate to an asset detail page
2. Expand the "Components" section (or it may be visible by default)
3. Click "Schedule PM" button next to a component (calendar icon)
4. Fill in the PM schedule form:
   - Title (required)
   - Description
   - Frequency (required) - select from dropdown
   - Estimated duration
   - Work instructions
   - Required skills, tools, PPE
5. Click "Save"
6. Verify:
   - Success message appears with schedule number
   - Redirected to PM Schedules list
   - New PM appears in the list
   - PM is linked to the correct asset

### Test Case 2: Verify PM Details
1. From PM Schedules list, click on the newly created PM
2. Verify:
   - Asset name is correct
   - Component is listed in the PM details
   - All entered information is displayed correctly

### Test Case 3: Check Database
```sql
-- Get recent PM schedules
SELECT id, schedule_number, title, asset_id, tenant_id, inserted_at 
FROM pm_schedules 
ORDER BY inserted_at DESC 
LIMIT 5;

-- Get components linked to a specific PM
SELECT * 
FROM pm_schedule_components 
WHERE pm_schedule_id = '[your-pm-id]';
```

### Test Case 4: Review Logs
Check the Phoenix server logs for debug output:
- "Creating PM schedule with action: new_from_component"
- "PM schedule created successfully with ID: [id]"
- "Creating PM schedule components for PM [id]"
- "Created PM schedule component: {:ok, %PmScheduleComponent{...}}"

## Current System State

### Routes
- `/pm-schedules` - List all PM schedules
- `/pm-schedules/new` - Create new PM (generic)
- `/pm-schedules/:id` - View PM details
- `/pm-schedules/:id/edit` - Edit PM
- `/assets/:asset_id/components/:component_id/schedule-pm` - Create PM from component

### Database Tables
- `pm_schedules` - Main PM schedule records
- `pm_schedule_components` - Links PM schedules to components
- `components` - Equipment components
- `assets` - Equipment/assets

### Key Files
- `lib/shop1_cmms_web/live/pm_schedules_live.ex` - Main PM schedules LiveView
- `lib/shop1_cmms_web/live/asset_detail_live.ex` - Asset details with components
- `lib/shop1_cmms/maintenance.ex` - Maintenance context (business logic)
- `lib/shop1_cmms/maintenance/pm_schedule.ex` - PM schedule schema
- `lib/shop1_cmms/maintenance/pm_schedule_component.ex` - Component link schema

## Known Issues & Limitations

1. **Component Selection**: When creating a PM from a component, that component is pre-selected but users can't currently add additional components from the form (this would be a future enhancement)

2. **Component Removal**: The pre-selected component should ideally be locked/non-removable in the form when coming from `:new_from_component` action

3. **Validation**: Currently no validation to prevent creating duplicate PMs for the same component with the same frequency

## Next Steps / Future Enhancements

1. **Enhance Component Selection in Form**
   - Allow adding multiple components when creating from component
   - Show component details (status, install date) in selection
   - Add component search/filter

2. **PM Schedule Detail Page Improvements**
   - Show linked components prominently
   - Add "View Component" links
   - Show component-specific maintenance history

3. **Bulk PM Creation**
   - Create PM for all components of an asset at once
   - Create PM templates for common component types

4. **Component-Based PM Scheduling**
   - Calculate next due date based on component install date
   - Support component-specific meter readings
   - Track component replacement history

5. **Testing**
   - Add unit tests for PM creation flow
   - Add integration tests for component linking
   - Add LiveView tests for the UI flow

## Troubleshooting

### Issue: PM not appearing in list
**Check:**
1. Look at server logs for creation confirmation
2. Verify tenant_id matches current session
3. Check filter settings on PM list page (Status: Active/All)
4. Query database directly to confirm record was created

### Issue: Components not linked to PM
**Check:**
1. Server logs for "Creating PM schedule components" message
2. Check if component exists: `SELECT * FROM components WHERE id = '[id]'`
3. Verify component belongs to correct tenant
4. Check `pm_schedule_components` table for records

### Issue: Form validation errors
**Check:**
1. Required fields: schedule_number, title, frequency, asset_id, tenant_id
2. Schedule number should auto-generate if not provided
3. Asset ID must exist and belong to tenant
4. Frequency must be one of the allowed values

## Contact & Support
For issues or questions, review:
- Server logs in `_build/dev/lib/shop1_cmms/logs/`
- Database state with psql or database viewer
- This documentation for expected behavior
