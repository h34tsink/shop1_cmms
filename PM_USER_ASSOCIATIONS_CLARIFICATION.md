# PM System User Associations Clarification

## Date: 2025-01-XX

## Summary

This document clarifies the proper use of user references in the PM (Preventive Maintenance) system schemas. The PM system correctly uses the existing `public.users` table and does NOT create its own user table.

## Database Structure

### Users Table
- **Table**: `public.users`
- **Primary Key**: `id` (integer, auto-increment)
- **Created By**: Migration `20250909184000_create_users_table.exs`
- **Fields**:
  - `id` - integer (PK)
  - `username` - string, unique, not null
  - `password_hash` - string
  - `is_active` - boolean, default true
  - `cmms_enabled` - boolean (added later)
  - `last_cmms_login` - naive_datetime
  - `preferences` - jsonb

### PM Schedules Table
- **Table**: `public.pm_schedules`
- **Primary Key**: `id` (binary_id/UUID)
- **Created By**: Migration `20251001183708_create_pm_schedules_and_documents.exs`
- **User References**:
  - `created_by` - integer, references `users(id)`
  - `updated_by` - integer, references `users(id)`

### Asset Documents Table
- **Table**: `public.asset_documents`
- **Primary Key**: `id` (binary_id/UUID)
- **User References**:
  - `uploaded_by` - integer, references `users(id)`

## Ecto Schema Associations

### Before (Plain Fields)
```elixir
# PM Schedule
field :created_by, :integer
field :updated_by, :integer

# Asset Document
field :uploaded_by, :integer
```

### After (Proper Associations)
```elixir
# PM Schedule
belongs_to :created_by_user, Shop1Cmms.Accounts.User, foreign_key: :created_by
belongs_to :updated_by_user, Shop1Cmms.Accounts.User, foreign_key: :updated_by

# Asset Document
belongs_to :uploaded_by_user, Shop1Cmms.Accounts.User, foreign_key: :uploaded_by
```

## Benefits of Using belongs_to

1. **Easier Preloading**: Can use Ecto's preload mechanism
   ```elixir
   Repo.preload(pm_schedule, [:created_by_user, :updated_by_user])
   ```

2. **Type Safety**: Ecto knows the association type
3. **Better Documentation**: Schema clearly shows relationships
4. **Query Helpers**: Can use association queries more easily

## Migration References

The migration `20251001183708_create_pm_schedules_and_documents.exs` correctly sets up foreign keys:

```elixir
# Line 44-45
add :created_by, references(:users, on_delete: :nilify_all, type: :integer)
add :updated_by, references(:users, on_delete: :nilify_all, type: :integer)
```

Note: The `type: :integer` parameter is crucial as it specifies the foreign key type matches the users table's integer primary key.

## Important Notes

1. **No Separate User Tables**: The PM system uses the shared `users` table
2. **Integer Foreign Keys**: User references use integer type (not binary_id)
3. **Nilify on Delete**: User deletions set references to null (don't cascade delete)
4. **Multi-Tenant**: User assignments are tenant-scoped via `user_tenant_assignments` table

## Testing

The server starts successfully with these associations:
- Compilation: ✅ Success (warnings only, no errors)
- Server Start: ✅ Success
- PM Schedules Loading: ✅ Success
- Dashboard Access: ✅ Success

## Related Files

- `lib/shop1_cmms/maintenance/pm_schedule.ex` - PmSchedule schema
- `lib/shop1_cmms/maintenance/asset_document.ex` - AssetDocument schema
- `lib/shop1_cmms/accounts/user.ex` - User schema
- `priv/repo/migrations/20250909184000_create_users_table.exs` - Users table migration
- `priv/repo/migrations/20251001183708_create_pm_schedules_and_documents.exs` - PM tables migration

## Commit

Changes committed in: `feat: add proper belongs_to associations for user references in PM schedules and documents`

---

**Status**: ✅ VERIFIED AND WORKING
