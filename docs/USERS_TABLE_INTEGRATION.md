# CMMS Integration with Existing Shop1FinishLine Users Table

## Overview

This document outlines how to integrate the CMMS system with your existing Shop1FinishLine CRM ERP users table, avoiding duplication and maintaining consistency across both systems.

## Integration Approach

### Option 1: Shared Users Table (Recommended)
Use your existing users table and extend it with CMMS-specific fields through additional tables.

### Option 2: User Synchronization
Keep separate user tables but synchronize them via background jobs.

### Option 3: Microservice Approach
Create a shared authentication service that both systems use.

## Option 1: Shared Users Table Implementation

### 1. Extend Existing Users Table

Assuming your current users table structure, we'll add CMMS-specific fields:

```sql
-- Add CMMS-specific columns to existing users table
-- (Adjust column names based on your existing structure)

-- If you don't have these fields, add them:
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS employee_id VARCHAR(50);
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_name VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;

-- CMMS-specific fields (new)
ALTER TABLE users ADD COLUMN IF NOT EXISTS cmms_enabled BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS default_site_id BIGINT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_cmms_login TIMESTAMPTZ;

-- Add foreign key to sites table (will be created)
-- ALTER TABLE users ADD CONSTRAINT fk_users_default_site 
--   FOREIGN KEY (default_site_id) REFERENCES sites(id);
```

### 2. CMMS User Roles Table

Instead of adding role directly to users table, create a separate roles system:

```sql
-- CMMS-specific user roles (many-to-many relationship)
CREATE TABLE cmms_user_roles (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL, -- 'maintenance_manager', 'supervisor', 'technician', 'operator'
  site_id BIGINT REFERENCES sites(id), -- Optional site restriction
  granted_by BIGINT REFERENCES users(id),
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  active BOOLEAN DEFAULT true,
  
  UNIQUE(user_id, tenant_id, role, site_id)
);

CREATE INDEX idx_cmms_user_roles_user_tenant ON cmms_user_roles(user_id, tenant_id);
CREATE INDEX idx_cmms_user_roles_site ON cmms_user_roles(site_id);

-- CMMS permissions (more granular than roles)
CREATE TABLE cmms_user_permissions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  permission VARCHAR(100) NOT NULL, -- 'manage_assets', 'create_work_orders', etc.
  resource_type VARCHAR(50), -- 'asset', 'work_order', 'site', etc.
  resource_id BIGINT, -- Specific resource ID if applicable
  site_id BIGINT REFERENCES sites(id), -- Site restriction
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ, -- Optional expiration
  active BOOLEAN DEFAULT true
);

CREATE INDEX idx_cmms_permissions_user_tenant ON cmms_user_permissions(user_id, tenant_id);
CREATE INDEX idx_cmms_permissions_lookup ON cmms_user_permissions(user_id, permission, resource_type);
```

### 3. Modified Phoenix User Schema

Update the Phoenix user schema to work with your existing table:

```elixir
# lib/shop1_cmms/accounts/user.ex
defmodule Shop1Cmms.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  # Map to your existing users table
  schema "users" do
    # Existing CRM/ERP fields (adjust based on your structure)
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :employee_id, :string
    field :active, :boolean, default: true
    
    # CMMS-specific fields (newly added)
    field :cmms_enabled, :boolean, default: false
    field :preferences, :map, default: %{}
    field :last_cmms_login, :utc_datetime
    
    # Relationships
    belongs_to :default_site, Shop1Cmms.Tenants.Site
    has_many :cmms_user_roles, Shop1Cmms.Accounts.CMMSUserRole
    has_many :cmms_user_permissions, Shop1Cmms.Accounts.CMMSUserPermission
    
    # CMMS work relationships
    has_many :assigned_work_orders, Shop1Cmms.Work.WorkOrder, foreign_key: :assigned_to
    has_many :requested_work_orders, Shop1Cmms.Work.WorkOrder, foreign_key: :requested_by

    # Existing CRM/ERP timestamps (adjust field names as needed)
    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :phone, :employee_id, 
                    :active, :cmms_enabled, :preferences, :default_site_id])
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:email, max: 160)
    |> unique_constraint(:email)
  end

  def cmms_registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_password()
    |> put_cmms_enabled()
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password()
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp put_cmms_enabled(changeset) do
    put_change(changeset, :cmms_enabled, true)
  end

  # Helper functions
  def full_name(%__MODULE__{first_name: first, last_name: last}) do
    case {first, last} do
      {nil, nil} -> nil
      {first, nil} -> first
      {nil, last} -> last
      {first, last} -> "#{first} #{last}"
    end
  end

  def has_cmms_access?(%__MODULE__{cmms_enabled: enabled, active: active}) do
    enabled && active
  end
end
```

### 4. CMMS User Role Schema

```elixir
# lib/shop1_cmms/accounts/cmms_user_role.ex
defmodule Shop1Cmms.Accounts.CMMSUserRole do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(maintenance_manager supervisor technician operator)

  schema "cmms_user_roles" do
    field :role, :string
    field :active, :boolean, default: true
    field :granted_at, :utc_datetime

    belongs_to :user, Shop1Cmms.Accounts.User
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant
    belongs_to :site, Shop1Cmms.Tenants.Site
    belongs_to :granted_by, Shop1Cmms.Accounts.User

    timestamps(inserted_at: false, updated_at: false)
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:user_id, :tenant_id, :role, :site_id, :granted_by, :active])
    |> validate_required([:user_id, :tenant_id, :role])
    |> validate_inclusion(:role, @roles)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tenant_id)
    |> unique_constraint([:user_id, :tenant_id, :role, :site_id])
  end
end
```

### 5. Updated Accounts Context

```elixir
# lib/shop1_cmms/accounts.ex
defmodule Shop1Cmms.Accounts do
  @moduledoc """
  Accounts context that works with existing Shop1FinishLine users table
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Accounts.{User, CMMSUserRole, CMMSUserPermission}

  ## User Management (working with existing table)

  def get_user_by_email(email) when is_binary(email) do
    from(u in User, where: u.email == ^email and u.active == true)
    |> Repo.one()
  end

  def get_cmms_user_by_email(email) when is_binary(email) do
    from(u in User, 
      where: u.email == ^email and u.active == true and u.cmms_enabled == true
    )
    |> Repo.one()
  end

  def enable_cmms_for_user(user_id, tenant_id, enabling_user_id) do
    user = Repo.get!(User, user_id)
    
    Repo.transaction(fn ->
      # Enable CMMS access
      {:ok, updated_user} = user
      |> User.changeset(%{cmms_enabled: true, default_site_id: nil})
      |> Repo.update()

      # Grant default technician role
      {:ok, _role} = create_user_role(%{
        user_id: user_id,
        tenant_id: tenant_id,
        role: "technician",
        granted_by: enabling_user_id
      })

      updated_user
    end)
  end

  def list_cmms_users(tenant_id) do
    from(u in User,
      join: r in CMMSUserRole, on: r.user_id == u.id,
      where: r.tenant_id == ^tenant_id and u.cmms_enabled == true and u.active == true,
      preload: [cmms_user_roles: r],
      distinct: u.id
    )
    |> Repo.all()
  end

  ## Role Management

  def create_user_role(attrs) do
    %CMMSUserRole{}
    |> CMMSUserRole.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_roles(user_id, tenant_id) do
    from(r in CMMSUserRole,
      where: r.user_id == ^user_id and r.tenant_id == ^tenant_id and r.active == true
    )
    |> Repo.all()
  end

  def user_has_role?(user_id, tenant_id, role_name) do
    from(r in CMMSUserRole,
      where: r.user_id == ^user_id and 
             r.tenant_id == ^tenant_id and 
             r.role == ^role_name and 
             r.active == true
    )
    |> Repo.exists?()
  end

  def get_user_highest_role(user_id, tenant_id) do
    role_hierarchy = %{
      "maintenance_manager" => 4,
      "supervisor" => 3,
      "technician" => 2,
      "operator" => 1
    }

    roles = get_user_roles(user_id, tenant_id)
    
    roles
    |> Enum.map(& &1.role)
    |> Enum.max_by(&Map.get(role_hierarchy, &1, 0), fn -> "operator" end)
  end

  ## Authorization (updated for role-based system)

  def can?(user, action, resource \\ nil, tenant_id) do
    if not user.cmms_enabled do
      false
    else
      highest_role = get_user_highest_role(user.id, tenant_id)
      check_role_permission(highest_role, action, resource, user, tenant_id)
    end
  end

  defp check_role_permission("maintenance_manager", _action, _resource, _user, _tenant_id), do: true

  defp check_role_permission("supervisor", action, _resource, _user, _tenant_id) do
    action in [:assign_work_orders, :approve_work_orders, :create_work_orders, 
               :view_work_orders, :update_pm_schedules, :view_reports]
  end

  defp check_role_permission("technician", action, resource, user, _tenant_id) do
    case action do
      :view_work_orders -> can_view_assigned_work_orders?(user, resource)
      :update_work_orders -> can_update_assigned_work_order?(user, resource)
      :complete_work_orders -> can_update_assigned_work_order?(user, resource)
      :add_meter_readings -> true
      :view_assets -> true
      _ -> false
    end
  end

  defp check_role_permission("operator", action, _resource, _user, _tenant_id) do
    action in [:create_work_requests, :add_meter_readings, :view_assets]
  end

  defp check_role_permission(_role, _action, _resource, _user, _tenant_id), do: false

  # Helper functions remain the same...
  defp can_view_assigned_work_orders?(user, %{assigned_to: assigned_to}) do
    user.id == assigned_to
  end

  defp can_update_assigned_work_order?(user, %{assigned_to: assigned_to}) do
    user.id == assigned_to
  end
end
```

## Database Migration Strategy

### 1. Preparation Steps

```sql
-- 1. Backup your existing users table
CREATE TABLE users_backup AS SELECT * FROM users;

-- 2. Add CMMS columns (adjust based on your existing structure)
ALTER TABLE users ADD COLUMN IF NOT EXISTS cmms_enabled BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS default_site_id BIGINT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferences JSONB DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_cmms_login TIMESTAMPTZ;

-- 3. Create CMMS-specific tables
-- (Run the tenant, sites, and role tables from the previous schema)
```

### 2. Configuration Updates

Update your Phoenix configuration to work with the shared database:

```elixir
# config/config.exs or config/dev.exs
config :shop1_cmms, Shop1Cmms.Repo,
  # Use the same database as Shop1FinishLine
  database: "shop1finishline_db", # Adjust to your actual database name
  hostname: "localhost",
  port: 5433,
  # ... other config
```

## Benefits of This Approach

1. **Single Source of Truth**: One users table for both systems
2. **Consistent Authentication**: Users can use the same credentials
3. **Unified User Management**: Manage users in one place
4. **Data Integrity**: No synchronization issues between systems
5. **Scalability**: Easy to add more systems using the same user base

## Implementation Steps

1. **Review your existing users table structure** and share it with me
2. **Plan the column additions** based on what you already have
3. **Update the Phoenix schemas** to match your existing structure
4. **Create the CMMS-specific role tables**
5. **Migrate existing users** to have CMMS access as needed
6. **Test the integration** thoroughly

Could you please share:
1. Your current users table structure (column names and types)
2. How authentication currently works in Shop1FinishLine
3. Whether both systems will use the same database
4. Any existing role/permission system you have

This will help me provide more specific integration guidance!
