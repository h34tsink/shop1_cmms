# Schedule PM Feature - Testing Guide

## Implementation Complete ✓

All code changes have been implemented and compiled successfully.

## Quick Test Steps

### Test 1: Basic Flow (Happy Path)
1. Start the application: `mix phx.server`
2. Navigate to Equipment list page: `/assets`
3. Click on any asset to view details
4. Look for the "Schedule PM" button in the toolbar (top section)
5. Click "Schedule PM" button
6. **Expected Result:**
   - Navigate to PM schedule creation form
   - Page title should be "Schedule PM for [Asset Name]"
   - Flash message: "Creating PM schedule for [Asset Name]"
   - Asset dropdown should have the asset pre-selected
   - All other fields should be empty

### Test 2: Form Submission
1. After completing Test 1, fill in the form:
   - Title: "Monthly Inspection for [Asset Name]"
   - Frequency: Select "Monthly"
   - Estimated Duration: 2 (hours)
   - Work Instructions: Add some text
2. Click "Save" or submit button
3. **Expected Result:**
   - PM schedule is created successfully
   - Asset is correctly associated
   - Redirects to PM schedules list or detail page

### Test 3: Asset Selection Verification
1. Complete Test 1 to get to the form with pre-selected asset
2. Check the Equipment dropdown
3. **Expected Result:**
   - The equipment should be pre-selected (not showing "Select equipment" prompt)
   - You should be able to see the asset name in the dropdown
   - You can still search for and change to a different asset if needed

### Test 4: URL Direct Access
1. Get an asset ID from the database (e.g., from URL when viewing an asset)
2. Navigate directly to: `/assets/[ASSET_ID]/schedule-pm`
3. **Expected Result:**
   - Same behavior as clicking the button
   - Asset should be pre-selected

### Test 5: Edge Case - Invalid Asset ID
1. Navigate to: `/assets/00000000-0000-0000-0000-000000000000/schedule-pm`
2. **Expected Result:**
   - Should show an error (likely 404 or "Asset not found")
   - Should not crash the application

### Test 6: Multiple Assets
1. Create PM schedule from Asset A
2. Without submitting, navigate back
3. Go to Asset B and click "Schedule PM"
4. **Expected Result:**
   - Asset B should be pre-selected (not Asset A)
   - Each asset gets its own context

## Visual Verification Checklist

- [ ] "Schedule PM" button appears in asset detail toolbar
- [ ] Button has calendar icon
- [ ] Button styling matches other toolbar buttons (btn-toolbar class)
- [ ] Clicking button shows loading/navigation state
- [ ] Form opens in full page (not modal)
- [ ] Page title updates correctly
- [ ] Flash message appears and is informative
- [ ] Asset dropdown shows selected asset clearly
- [ ] Asset search box still works
- [ ] All other form fields are present and functional

## Database Verification

After creating a PM schedule through the new flow:

```sql
-- Check that the PM schedule was created with correct asset_id
SELECT id, schedule_number, title, asset_id, created_at 
FROM pm_schedules 
ORDER BY created_at DESC 
LIMIT 5;

-- Verify the asset association
SELECT ps.title as pm_title, a.name as asset_name, a.asset_number
FROM pm_schedules ps
JOIN assets a ON ps.asset_id = a.id
WHERE ps.id = '[PM_SCHEDULE_ID]';
```

## Common Issues to Check

1. **Asset not pre-selected:**
   - Check browser console for errors
   - Verify asset_id is in the changeset: Look at form data in browser dev tools
   - Check that asset exists in tenant

2. **Navigation doesn't work:**
   - Verify route is in router.ex
   - Check for JavaScript errors in console
   - Verify .link component is properly closed

3. **Permission errors:**
   - Verify user has permission to create PM schedules
   - Check tenant_id matches between asset and user

4. **Form validation errors:**
   - Check that only required fields trigger errors
   - Asset_id should be valid (pre-selected)

## Success Criteria

✓ User can click "Schedule PM" from asset detail page
✓ PM creation form opens with asset pre-selected
✓ User can complete and submit the form
✓ PM schedule is created with correct asset association
✓ All fields work as expected
✓ No JavaScript errors in console
✓ No Elixir errors in server logs

## Next Steps After Testing

Once basic functionality is confirmed:
1. Consider adding "Back to Asset" button in PM form
2. Consider making asset field read-only when coming from asset
3. Add breadcrumb navigation
4. Consider pre-filling schedule number pattern
