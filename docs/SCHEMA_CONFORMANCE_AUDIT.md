# Schema Conformance Audit Report

**Date:** 2025-01-31  
**Audit Type:** Systematic Field Mismatch Detection

## Executive Summary

This audit checks for inconsistencies between:
1. Database schema definitions (Ecto schemas)
2. Template/LiveView field access
3. Actual database columns

## Issues Found

### 1. ❌ CRITICAL: Component Schema Association Error

**Location:** `lib/shop1_cmms/assets/component.ex:23`  
**Issue:** Invalid association defined
```elixir
has_many :pm_schedules, Shop1Cmms.Maintenance.PmSchedule
```
**Problem:** `pm_schedules` table does NOT have a `component_id` field  
**Compiler Warning:**
```
warning: invalid association `pm_schedules` in schema Shop1Cmms.Assets.Component: 
associated schema Shop1Cmms.Maintenance.PmSchedule does not have field `component_id`
```

**Impact:** This association will fail at runtime if used  
**Fix:** Either:
- Remove the association (if components don't have PM schedules)
- Add `component_id` to `pm_schedules` table via migration
- Use `pm_schedule_components` join table instead

**Recommendation:** Review if components should have direct PM relationships. The database has `pm_schedule_components` as a join table, suggesting many-to-many relationship.

---

### 2. ⚠️ Module Name Mismatch: CmmsUserRole vs CMMSUserRole

**Location:** Multiple files reference `CmmsUserRole`  
**Actual Module:** `Shop1Cmms.Accounts.CMMSUserRole` (all caps)

**Files Affected:**
- References in code may use `CmmsUserRole` (CamelCase)
- Module is actually named `CMMSUserRole` (all caps CMMS)

**Impact:** Can cause module not found errors  
**Status:** Need to verify all references use correct name

---

### 3. ⚠️ User Schema Missing Database Columns

**Schema:** `Shop1Cmms.Accounts.User`  
**Table:** `users`

**Columns in DB but NOT in schema:**
- `created_at` - timestamp
- `failed_logins` - login attempt tracking
- `last_login` - last login timestamp  
- `role_id` - Shop1FinishLine role reference

**Impact:** These fields cannot be queried through Ecto  
**Recommendation:** 
- Add these fields to schema if needed for Shop1FinishLine integration
- Or document that these are legacy fields not used in CMMS

---

### 4. ✅ FIXED: PM Execution Detail Template

**Location:** `lib/shop1_cmms_web/live/pm_execution_detail_live.html.heex`  
**Issue:** Referenced non-existent fields:
- `frequency_value` ❌
- `frequency_unit` ❌
- `priority` ❌ (not on pm_schedules)

**Status:** ✅ **FIXED** in commit 9557f71

---

### 5. ⚠️ Missing Helper Function: UserTenantAssignment.for_site/2

**Location:** `lib/shop1_cmms/tenants.ex:105`  
**Problem:** Calls undefined function
```elixir
|> UserTenantAssignment.for_site(site_id)
```

**Error:**
```
Shop1Cmms.Accounts.UserTenantAssignment.for_site/2 is undefined or private
```

**Available alternatives:**
- `for_tenant/1`
- `for_tenant/2`
- `for_user/1`
- `for_user/2`

**Impact:** `get_site_user_count/1` function will crash  
**Fix:** Either implement `for_site/2` or use `default_site_id` field filtering

---

### 6. ⚠️ Missing Helper Function: Tenant.by_name/2

**Location:** `lib/shop1_cmms/tenants.ex:26`  
**Problem:** Calls undefined function
```elixir
|> Tenant.by_name(name)
```

**Impact:** `get_tenant_by_name/1` function will crash  
**Fix:** Add `by_name/2` query helper to Tenant schema

---

### 7. ℹ️ Deprecated UserDetails Schema

**Location:** `lib/shop1_cmms/accounts/user_details.ex`  
**Issue:** Schema exists for table that doesn't exist in database  
**Status:** Not actively used, but should be deleted for clarity  
**Recommendation:** DELETE this file as documented in AUTH_STATUS_REPORT.md

---

### 8. ℹ️ Unused Alias: Exports Module

**Location:** `lib/shop1_cmms_web/live/maintenance_history_live.ex:146`  
**Issue:** References `Exports` without full module name
```elixir
csv_content = Exports.export_maintenance_history_to_csv(socket.assigns.history)
```

**Should be:**
```elixir
csv_content = Shop1Cmms.Exports.export_maintenance_history_to_csv(socket.assigns.history)
```

**Impact:** Low - works but generates warning  
**Status:** Already fixed in recent commits

---

## Field Access Patterns Checked

### Assets
✅ `@asset.asset_type.name` - Correct
✅ `@asset.location.name` - Correct  
✅ `@asset.asset_number` - Correct
✅ `@asset.criticality` - Correct (enum field exists)
✅ `@asset.status` - Correct (enum field exists)

### Work Orders
✅ `@work_order.asset.name` - Correct
✅ `@work_order.asset.asset_number` - Correct
✅ `@work_order.status` - Correct (enum field exists)
✅ `@work_order.priority` - Correct (enum field exists)
✅ `@work_order.type` - Correct (enum field exists)

### PM Schedules
✅ `@schedule.asset.name` - Correct
✅ `@schedule.asset.asset_number` - Correct
✅ `@schedule.frequency` - Correct (enum field exists)
✅ `@schedule.frequency_interval` - Correct (integer field exists)
✅ `@schedule.estimated_duration` - Correct (decimal field exists)

### PM Executions
✅ `@execution.pm_schedule` - Correct association
✅ `@execution.status` - Correct (string field exists)
✅ `@execution.execution_date` - Correct (utc_datetime exists)
✅ `@execution.completed_date` - Correct (utc_datetime exists)

---

## Schema-to-Database Mapping Status

| Schema | Table | Status |
|--------|-------|--------|
| User | users | ⚠️ Missing some DB columns in schema |
| CMMSUserRole | cmms_user_roles | ✅ Matches |
| UserTenantAssignment | user_tenant_assignments | ⚠️ Missing helper functions |
| Asset | assets | ✅ Matches |
| AssetType | asset_types | ✅ Matches |
| AssetLocation | asset_locations | ✅ Matches |
| Component | components | ⚠️ Invalid association |
| PmSchedule | pm_schedules | ✅ Matches |
| PmExecution | pm_executions | ✅ Matches |
| WorkOrder | work_orders | ✅ Matches |
| Tenant | tenants | ⚠️ Missing helper function |
| Site | sites | ✅ Matches |

---

## Action Items

### High Priority (Breaks Functionality)

1. **Fix Component.pm_schedules association** (or remove it)
   - Location: `lib/shop1_cmms/assets/component.ex:23`
   - Either remove line 23 or add `component_id` to `pm_schedules`

2. **Implement UserTenantAssignment.for_site/2**
   - Location: `lib/shop1_cmms/accounts/user_tenant_assignment.ex`
   - Add query helper function

3. **Implement Tenant.by_name/2**
   - Location: `lib/shop1_cmms/tenants/tenant.ex`
   - Add query helper function

### Medium Priority (Causes Warnings)

4. **Fix CmmsUserRole naming consistency**
   - Verify all references use `CMMSUserRole` (all caps)

5. **Delete user_details.ex schema file**
   - This references a table that doesn't exist

### Low Priority (Enhancements)

6. **Add Shop1FinishLine columns to User schema** (optional)
   - Add: `created_at`, `failed_logins`, `last_login`, `role_id`
   - Only if needed for integration

---

## Testing Checklist

After fixes, test these critical paths:

- [ ] View asset detail page
- [ ] View work order detail page  
- [ ] View PM schedule detail page
- [ ] View PM execution detail page (TESTED ✅)
- [ ] View maintenance history page
- [ ] Export maintenance history
- [ ] Get site user count (`get_site_user_count/1`)
- [ ] Get tenant by name (`get_tenant_by_name/1`)

---

## Conclusion

**Overall Status:** 🟡 **MOSTLY CONFORMANT**

The codebase is generally well-structured with proper schema definitions. The main issues are:

1. One invalid association (Component -> PmSchedule)
2. Two missing query helper functions
3. One deprecated schema file

**Estimated Fix Time:** 1-2 hours  
**Risk Level:** LOW - Most issues cause warnings, not crashes  
**Critical Issues:** 3 (invalid association, 2 missing functions)
