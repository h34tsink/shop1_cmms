# Schedule PM from Asset Detail - Implementation Summary

## Changes Made

### 1. Router Update (`lib/shop1_cmms_web/router.ex`)
- Added new route: `live "/assets/:asset_id/schedule-pm", PmSchedulesLive, :new_from_asset`
- This route captures the asset_id and passes it to the PM schedules live view with action `:new_from_asset`

### 2. Asset Detail Page Update (`lib/shop1_cmms_web/live/asset_detail_live.ex`)
- Changed "Schedule PM" button from plain `<button>` to `<.link navigate={...}>`
- The link navigates to `/assets/:asset_id/schedule-pm` with the current asset's ID

### 3. PM Schedules Live View Update (`lib/shop1_cmms_web/live/pm_schedules_live.ex`)

#### Added to `mount/3`:
- New assign: `:preselected_asset_id` initialized to `nil`

#### New `apply_action/3` clause for `:new_from_asset`:
- Extracts `asset_id` from URL params
- Loads the asset to verify it exists and belongs to the tenant
- Creates a changeset with pre-populated `asset_id`
- Sets page title to "Schedule PM for [Asset Name]"
- Sets `preselected_asset_id` assign for potential UI enhancements
- Displays flash message: "Creating PM schedule for [Asset Name]"

## How It Works

1. User views an asset detail page (e.g., `/assets/123`)
2. User clicks "Schedule PM" button
3. System navigates to `/assets/123/schedule-pm`
4. Router invokes `PmSchedulesLive` with action `:new_from_asset` and params `%{"asset_id" => "123"}`
5. `handle_params/3` calls `apply_action(socket, :new_from_asset, %{"asset_id" => "123"})`
6. The function:
   - Loads asset #123
   - Creates a new PM schedule changeset with `asset_id: 123`
   - Opens the PM schedule form with asset pre-selected
7. User fills in remaining fields (title, frequency, etc.)
8. User submits form
9. PM schedule is created with the asset association

## Testing Checklist

### Basic Functionality
- [ ] Navigate to any asset detail page
- [ ] Click "Schedule PM" button
- [ ] Verify navigation to PM schedule creation page
- [ ] Verify asset is pre-selected in dropdown
- [ ] Verify page title shows "Schedule PM for [Asset Name]"
- [ ] Verify flash message appears

### Form Submission
- [ ] Fill out all required PM schedule fields
- [ ] Submit the form
- [ ] Verify PM schedule is created successfully
- [ ] Verify asset_id is correctly associated
- [ ] Verify redirect behavior

### Edge Cases
- [ ] Try with invalid asset_id in URL (should error gracefully)
- [ ] Try with asset from different tenant (should fail authorization)
- [ ] Try without permissions to create PM schedules
- [ ] Cancel form and verify return to appropriate page

### UI/UX
- [ ] Asset field clearly shows pre-selected asset
- [ ] Asset search still works if user wants to change
- [ ] All other form fields work normally
- [ ] Validation works as expected

## Future Enhancements (Optional)

1. Add breadcrumb: Assets > [Asset Name] > New PM Schedule
2. Make asset field read-only when coming from asset detail
3. Add "Back to Asset" button that returns to asset detail page
4. Pre-fill schedule number pattern based on asset number
5. Show asset details summary in the form
