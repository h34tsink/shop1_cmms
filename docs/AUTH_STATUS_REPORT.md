# Authentication & Authorization Status Report

**Date:** 2025-01-31  
**Status:** ⚠️ PARTIALLY CONFORMANT - Requires Fixes

## Executive Summary

The authentication system is **functional but has inconsistencies** with the actual database schema. The code acknowledges that `user_details` table doesn't exist (with comments) but uses workarounds rather than proper implementation.

## Current Issues

### 1. ❌ `user_details` Table Reference
**Location:** `lib/shop1_cmms/accounts/user_details.ex`  
**Problem:** Schema file exists for a table that doesn't exist in the database  
**Impact:** Confusion for developers, dead code  
**Recommendation:** DELETE this file

### 2. ⚠️ Mock User Details Implementation
**Location:** `lib/shop1_cmms/accounts.ex:37-55`  
**Problem:** `get_user_with_details/1` creates mock details instead of querying actual data
```elixir
def get_user_with_details(id) do
  case Repo.get(User, id) do
    nil -> nil
    user ->
      # For now, create mock details since user_details view doesn't exist
      details = %{
        username: user.username,
        user_is_active: user.is_active,
        first_name: nil,  # <- All profile data is nil
        last_name: nil,
        display_name: user.username,
        full_name: user.username,
        email: nil
      }
      Map.put(user, :details, details)
  end
end
```
**Impact:** Profile information (names, email, etc.) is not displayed anywhere in the UI  
**Recommendation:** Either:
- Option A: Query `user_profiles` through `user_profile_assignments` 
- Option B: If profile data isn't needed, simplify to just return the User struct

### 3. ⚠️ `get_user_details/1` Returns Empty Map
**Location:** `lib/shop1_cmms/accounts.ex:57-61`  
**Problem:** Always returns `%{}` with a TODO comment
**Impact:** Any code trying to use this function gets no data  
**Recommendation:** DELETE this function or implement properly

## What's Working ✅

### Core Authentication Flow
1. **Login** - `Auth.authenticate_user/2` ✅
   - Validates username/password against `users` table
   - Checks `cmms_enabled` flag
   - Uses correct `User` schema

2. **Session Management** ✅
   - Stores `user_id` and `tenant_id` in session
   - Sets PostgreSQL session variables for RLS
   - Proper session renewal on login/logout

3. **Tenant Access Control** ✅
   - `validate_tenant_access/2` checks `user_tenant_assignments`
   - Uses correct table relationships
   - Proper RLS context establishment

4. **Role-Based Authorization** ✅
   - `get_user_cmms_roles/2` queries actual tables
   - `can?/4` implements role-based permissions
   - Uses `cmms_user_roles` and `user_tenant_assignments` correctly

5. **LiveView Integration** ✅
   - `on_mount` callbacks properly authenticate
   - Session context re-established on each request
   - Navigation authorization pre-calculated

## Database Schema Conformance

### Tables Used Correctly ✅
- ✅ `users` - Primary authentication
- ✅ `user_tenant_assignments` - Tenant access control
- ✅ `cmms_user_roles` - Role definitions
- ✅ `tenants` - Tenant data
- ✅ `sites` - Site assignments

### Tables Referenced But Not Used Properly ⚠️
- ⚠️ `user_profiles` - Should be used but currently ignored
- ⚠️ `user_profile_assignments` - Should link users to profiles but not used

### Tables Referenced But Don't Exist ❌
- ❌ `user_details` - Schema file exists, table doesn't

## Required Permissions for Auth

The following database tables MUST be accessible for authentication to work:

| Table | Purpose | Required Operations | Status |
|-------|---------|---------------------|--------|
| `users` | Core auth | SELECT, UPDATE (last_login) | ✅ Working |
| `user_tenant_assignments` | Tenant access | SELECT | ✅ Working |
| `cmms_user_roles` | Role definitions | SELECT | ✅ Working |
| `tenants` | Tenant info | SELECT | ✅ Working |
| `sites` | Site assignments | SELECT | ✅ Working |
| `user_profiles` | Extended profile data | SELECT | ⚠️ Not queried |
| `user_profile_assignments` | User-profile link | SELECT | ⚠️ Not queried |

## Recommendations

### Immediate Actions (Critical)

1. **DELETE `lib/shop1_cmms/accounts/user_details.ex`**
   - This file references a non-existent table
   - Causes confusion and compilation warnings

2. **Fix `get_user_with_details/1`** - Choose one approach:
   
   **Option A: Query user_profiles (recommended if profile data is needed)**
   ```elixir
   def get_user_with_details(id) do
     from(u in User,
       left_join: upa in assoc(u, :user_profile_assignments),
       left_join: p in assoc(upa, :user_profile),
       where: u.id == ^id,
       preload: [user_profile_assignments: {upa, user_profile: p}]
     )
     |> Repo.one()
   end
   ```
   
   **Option B: Simplify if profile data not needed (simpler)**
   ```elixir
   def get_user_with_details(id) do
     Repo.get(User, id)
   end
   ```

3. **DELETE `get_user_details/1`**
   - Currently returns empty map
   - Not useful in current state
   - Remove or implement properly

### Short-term Improvements

4. **Add User Profile Display** (if needed)
   - If user profiles should be shown, add proper queries
   - Update UI to display first_name, last_name, email from `user_profiles`
   - Otherwise, remove all profile-related code

5. **Update User.display_name/1**
   - Currently tries to query user_details (which doesn't exist)
   - Either query user_profiles or just use username

### Long-term Enhancements

6. **Consider Creating user_details VIEW** (optional)
   - If you want a unified view of user + profile data
   - Create a PostgreSQL VIEW that joins users, user_profiles, user_profile_assignments
   - This would match the schema file that currently exists

## Testing Recommendations

Test these authentication flows:

1. ✅ Login with valid credentials
2. ✅ Login with invalid credentials
3. ✅ Login with user that has cmms_enabled=false
4. ✅ Tenant selection and switching
5. ✅ Role-based permission checks
6. ⚠️ Profile data display (currently broken)
7. ✅ Session persistence across requests
8. ✅ Logout functionality

## Conclusion

**Authentication is working** for login, session management, and role-based access control. However:

- Dead code exists (user_details schema)
- Profile data is mocked/ignored
- Functions return empty data or mock data

The system will function for basic auth but **profile information will not display** until the profile query issue is fixed.

**Risk Level:** LOW for auth functionality, MEDIUM for user experience (no profile data shown)

**Effort to Fix:** 2-4 hours to clean up and implement proper profile queries
