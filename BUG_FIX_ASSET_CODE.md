# Bug Fix: Asset Code KeyError

## Issue
The application was throwing a `KeyError` when trying to access the Assets page:

```
KeyError at GET /assets
key :asset_code not found in: %Shop1Cmms.Assets.Asset{...}
```

## Root Cause
The Asset schema (`lib/shop1_cmms/assets/asset.ex`) uses the field name `asset_number`, but multiple LiveView files were referencing `asset_code` instead:

1. `lib/shop1_cmms_web/live/assets_live.ex` (line 149)
2. `lib/shop1_cmms_web/live/asset_detail_live.ex` (line 240)
3. `lib/shop1_cmms_web/live/work_order_detail_live.ex` (line 247)

## Solution
Updated all references from `asset_code` to `asset_number` to match the schema definition:

### Files Modified:
1. **lib/shop1_cmms_web/live/assets_live.ex**
   - Line 149: Changed `<%= asset.asset_code %>` to `<%= asset.asset_number %>`

2. **lib/shop1_cmms_web/live/asset_detail_live.ex**
   - Line 240: Changed `<%= @asset.asset_code %>` to `<%= @asset.asset_number %>`

3. **lib/shop1_cmms_web/live/work_order_detail_live.ex**
   - Line 247: Changed `<%= @work_order.asset.asset_code %>` to `<%= @work_order.asset.asset_number %>`

## Impact
This fix resolves the KeyError and allows the Assets pages to load correctly. The asset number is now properly displayed in:
- Assets list table
- Asset detail page header
- Work order detail page (for associated asset)

## Testing
Manual testing should verify that:
1. Assets index page loads without KeyError
2. Asset detail page displays asset_number correctly
3. Work order detail page shows associated asset's asset_number
4. All asset-related pages render properly

## Commit
- Commit hash: `677b493`
- Message: "Fix: Replace asset_code references with asset_number to match schema"
