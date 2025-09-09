# User Management & Role-Based Access Control (Shared Users Table)

## Overview

This document outlines the user management system with multi-tenant, role-based access control (RBAC) and site isolation for the CMMS. This version integrates with the existing Shop1FinishLine users table rather than creating a separate user management system.

## Key Integration Points

- **Shared Users Table**: Uses existing users table from Shop1FinishLine CRM ERP
- **CMMS Role System**: Separate role tables for CMMS-specific permissions
- **Selective Access**: Users can have CRM access without CMMS access and vice versa
- **Unified Authentication**: Single sign-on between CRM and CMMS systems

## Role Hierarchy

```
┌─────────────────────┐
│   Super Admin       │  # System-wide access (optional)
└─────────────────────┘
           │
┌─────────────────────┐
│   Tenant Admin      │  # Full tenant access
└─────────────────────┘
           │
┌─────────────────────┐
│ Maintenance Manager │  # All maintenance operations
└─────────────────────┘
           │
┌─────────────────────┐
│    Supervisor       │  # Assign work, approve close-out
└─────────────────────┘
           │
┌─────────────────────┐
│    Technician       │  # Execute work orders
└─────────────────────┘
           │
┌─────────────────────┐
│     Operator        │  # Submit requests, basic readings
└─────────────────────┘
```

## Schema Extensions Required

### Users Table (Existing - to be extended)
```sql
-- Add CMMS-specific columns to existing users table
ALTER TABLE users ADD COLUMN cmms_enabled BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN last_cmms_login TIMESTAMP;
ALTER TABLE users ADD COLUMN default_site_id INTEGER REFERENCES sites(id);
```

### CMMS User Roles (New Table)
```sql
CREATE TABLE cmms_user_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    tenant_id INTEGER NOT NULL REFERENCES tenants(id),
    site_id INTEGER REFERENCES sites(id), -- NULL = access all sites in tenant
    role VARCHAR(50) NOT NULL CHECK (role IN ('tenant_admin', 'maintenance_manager', 'supervisor', 'technician', 'operator')),
    granted_by INTEGER REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_cmms_user_roles_user_tenant ON cmms_user_roles(user_id, tenant_id) WHERE active = true;
CREATE INDEX idx_cmms_user_roles_tenant ON cmms_user_roles(tenant_id) WHERE active = true;

-- Row Level Security
ALTER TABLE cmms_user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY cmms_user_roles_tenant_isolation ON cmms_user_roles
    FOR ALL USING (tenant_id = current_setting('app.current_tenant_id')::integer);
```

## Context Modules

### 1. Accounts Context (lib/shop1_cmms/accounts.ex)

```elixir
defmodule Shop1Cmms.Accounts do
  @moduledoc """
  The Accounts context handles user management, authentication,
  and role-based access control with multi-tenant isolation.
  
  This version integrates with the existing Shop1FinishLine users table.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Accounts.{User, UserToken, UserNotifier, CMMSUserRole, CMMSUserPermission}
  alias Shop1Cmms.Tenants.{Tenant, Site}

  ## Database getters (working with shared users table)

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

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_cmms_user_by_email(email)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_with_tenant!(id) do
    User
    |> where([u], u.id == ^id and u.cmms_enabled == true)
    |> preload([:default_site])
    |> Repo.one!()
  end

  ## CMMS User Management

  def enable_cmms_for_user(user_id, tenant_id, enabling_user_id) do
    user = get_user!(user_id)
    
    Repo.transaction(fn ->
      # Enable CMMS access
      {:ok, updated_user} = user
      |> User.changeset(%{cmms_enabled: true})
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

  def disable_cmms_for_user(user_id) do
    user = get_user!(user_id)
    
    Repo.transaction(fn ->
      # Disable all CMMS roles
      from(r in CMMSUserRole, where: r.user_id == ^user_id)
      |> Repo.update_all(set: [active: false])

      # Disable CMMS access
      user
      |> User.changeset(%{cmms_enabled: false, last_cmms_login: nil})
      |> Repo.update()
    end)
  end

  ## User registration (for new users)

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def register_cmms_user(attrs, tenant_id) do
    attrs = Map.put(attrs, :cmms_enabled, true)
    
    case register_user(attrs) do
      {:ok, user} ->
        # Grant default technician role
        create_user_role(%{
          user_id: user.id,
          tenant_id: tenant_id,
          role: "technician"
        })
        {:ok, user}
      error -> error
    end
  end

  ## Role Management

  def create_user_role(attrs) do
    %CMMSUserRole{}
    |> CMMSUserRole.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_role(user_role_id, new_role, updating_user_id) do
    role = Repo.get!(CMMSUserRole, user_role_id)
    
    with {:ok, _} <- authorize_role_change(updating_user_id, role, new_role) do
      role
      |> CMMSUserRole.changeset(%{role: new_role, granted_by: updating_user_id})
      |> Repo.update()
    end
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

  ## Tenant user management

  def list_tenant_users(tenant_id, opts \\ []) do
    query = from(u in User,
      join: r in CMMSUserRole, on: r.user_id == u.id,
      where: r.tenant_id == ^tenant_id and u.cmms_enabled == true and u.active == true,
      preload: [cmms_user_roles: r],
      distinct: u.id,
      order_by: [u.first_name, u.last_name, u.email]
    )

    case Keyword.get(opts, :site_id) do
      nil -> query
      site_id -> 
        from([u, r] in query, 
          where: is_nil(r.site_id) or r.site_id == ^site_id
        )
    end
    |> Repo.all()
  end

  ## Role-based authorization (updated for new role system)

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
               :view_work_orders, :update_pm_schedules, :view_reports, :manage_inventory]
  end

  defp check_role_permission("technician", action, resource, user, _tenant_id) do
    case action do
      :view_work_orders -> can_view_assigned_or_site_work_orders?(user, resource)
      :update_work_orders -> can_update_assigned_work_order?(user, resource)
      :complete_work_orders -> can_update_assigned_work_order?(user, resource)
      :add_meter_readings -> true
      :view_assets -> can_access_resource?(user, resource)
      _ -> false
    end
  end

  defp check_role_permission("operator", action, resource, user, _tenant_id) do
    case action do
      :create_work_requests -> true
      :add_meter_readings -> true
      :view_assets -> can_access_resource?(user, resource)
      _ -> false
    end
  end

  defp check_role_permission(_role, _action, _resource, _user, _tenant_id), do: false

  ## Permission helpers (updated for shared users table)

  defp can_access_resource?(%User{default_site_id: nil}, _resource), do: true  # No site restriction

  defp can_access_resource?(%User{default_site_id: user_site_id}, %{site_id: resource_site_id}) do
    user_site_id == resource_site_id
  end

  defp can_access_resource?(_user, _resource), do: true  # Default allow if no restrictions

  defp can_view_assigned_or_site_work_orders?(%User{id: user_id, default_site_id: site_id}, %{assigned_to: assigned_to, site_id: wo_site_id}) do
    user_id == assigned_to || site_id == wo_site_id
  end

  defp can_update_assigned_work_order?(%User{id: user_id}, %{assigned_to: assigned_to}) do
    user_id == assigned_to
  end

  ## Authorization functions

  defp authorize_role_change(updating_user_id, target_role, new_role) do
    updating_user = get_user!(updating_user_id)
    updating_user_role = get_user_highest_role(updating_user_id, target_role.tenant_id)
    
    role_hierarchy = %{
      "maintenance_manager" => 4,
      "supervisor" => 3,
      "technician" => 2,
      "operator" => 1
    }
    
    updating_level = Map.get(role_hierarchy, updating_user_role, 0)
    target_level = Map.get(role_hierarchy, new_role, 0)
    
    cond do
      not updating_user.cmms_enabled ->
        {:error, :unauthorized}
      updating_level <= target_level ->
        {:error, :insufficient_permissions}
      true ->
        {:ok, :authorized}
    end
  end

  ## Session management with tenant context (unchanged)

  def create_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    query
    |> join(:inner, [token], user in assoc(token, :user))
    |> where([token, user], user.active == true and user.cmms_enabled == true)
    |> select([token, user], user)
    |> preload([token, user], [:default_site])
    |> Repo.one()
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Multi-tenant user context (updated for shared table)

  def set_user_tenant_context(user_id, tenant_id) do
    user = get_user_with_tenant!(user_id)
    
    # Verify user has access to this tenant
    if user_has_role?(user_id, tenant_id, _any_role = nil) do
      # Set PostgreSQL session variables for RLS
      Ecto.Adapters.SQL.query!(Repo, "SET app.current_user_id = $1", [user.id])
      Ecto.Adapters.SQL.query!(Repo, "SET app.current_tenant_id = $1", [tenant_id])
      
      if user.default_site_id do
        Ecto.Adapters.SQL.query!(Repo, "SET app.current_site_id = $1", [user.default_site_id])
      end
      
      # Update last login
      user
      |> User.changeset(%{last_cmms_login: DateTime.utc_now()})
      |> Repo.update()
      
      user
    else
      {:error, :no_tenant_access}
    end
  end

  ## User preferences and settings (unchanged)

  def update_user_preferences(user, preferences) do
    current_prefs = user.preferences || %{}
    new_prefs = Map.merge(current_prefs, preferences)
    
    update_user(user, %{preferences: new_prefs})
  end

  def get_user_preference(user, key, default \\ nil) do
    get_in(user.preferences || %{}, [key]) || default
  end

  ## Helper function for updating users

  defp update_user(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end
end
```

### 2. User Schema (lib/shop1_cmms/accounts/user.ex)

```elixir
defmodule Shop1Cmms.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Phoenix.Param, key: :id}
  schema "users" do
    # Existing CRM fields
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :first_name, :string
    field :last_name, :string
    field :phone, :string
    field :active, :boolean, default: true
    field :preferences, :map, default: %{}
    
    # CMMS-specific extensions
    field :cmms_enabled, :boolean, default: false
    field :last_cmms_login, :utc_datetime
    
    # Relationships
    belongs_to :default_site, Shop1Cmms.Tenants.Site
    has_many :cmms_user_roles, Shop1Cmms.Accounts.CMMSUserRole
    has_many :user_tokens, Shop1Cmms.Accounts.UserToken
    
    # Audit fields
    timestamps(type: :utc_datetime)
  end

  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :first_name, :last_name, :phone, :cmms_enabled])
    |> validate_email()
    |> validate_password(opts)
    |> validate_required([:first_name, :last_name])
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :phone, :active, :preferences, 
                    :cmms_enabled, :last_cmms_login, :default_site_id])
    |> validate_required([:email, :first_name, :last_name])
    |> validate_email()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Shop1Cmms.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def valid_password?(%Shop1Cmms.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  # Helper functions for CMMS integration
  def full_name(%__MODULE__{first_name: first_name, last_name: last_name}) do
    "#{first_name} #{last_name}"
  end

  def display_name(%__MODULE__{} = user) do
    case full_name(user) do
      " " -> user.email
      name -> name
    end
  end

  def cmms_roles(%__MODULE__{cmms_user_roles: roles}) when is_list(roles) do
    Enum.filter(roles, & &1.active)
  end

  def cmms_roles(%__MODULE__{} = user) do
    # Roles not loaded, return empty list or raise
    []
  end
end
```

### 3. CMMS User Role Schema (lib/shop1_cmms/accounts/cmms_user_role.ex)

```elixir
defmodule Shop1Cmms.Accounts.CMMSUserRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cmms_user_roles" do
    belongs_to :user, Shop1Cmms.Accounts.User
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant
    belongs_to :site, Shop1Cmms.Tenants.Site
    belongs_to :granted_by_user, Shop1Cmms.Accounts.User, foreign_key: :granted_by
    
    field :role, :string
    field :granted_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :active, :boolean, default: true
    
    timestamps(type: :utc_datetime)
  end

  @valid_roles ~w(tenant_admin maintenance_manager supervisor technician operator)

  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :tenant_id, :site_id, :role, :granted_by, :expires_at, :active])
    |> validate_required([:user_id, :tenant_id, :role])
    |> validate_inclusion(:role, @valid_roles)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:site_id)
    |> foreign_key_constraint(:granted_by)
    |> put_granted_at()
  end

  defp put_granted_at(changeset) do
    if get_field(changeset, :granted_at) do
      changeset
    else
      put_change(changeset, :granted_at, DateTime.utc_now())
    end
  end

  def active_roles(query) do
    from(r in query, where: r.active == true)
  end

  def for_tenant(query, tenant_id) do
    from(r in query, where: r.tenant_id == ^tenant_id)
  end

  def for_user(query, user_id) do
    from(r in query, where: r.user_id == ^user_id)
  end

  def for_site(query, site_id) do
    from(r in query, where: is_nil(r.site_id) or r.site_id == ^site_id)
  end

  def with_role(query, role) do
    from(r in query, where: r.role == ^role)
  end

  def unexpired(query) do
    from(r in query, where: is_nil(r.expires_at) or r.expires_at > ^DateTime.utc_now())
  end
end
```

## Integration Examples

### 1. Enable CMMS for Existing CRM User

```elixir
# Enable CMMS access for an existing CRM user
def enable_user_for_cmms(crm_user_id, tenant_id, enabling_admin_id) do
  Shop1Cmms.Accounts.enable_cmms_for_user(crm_user_id, tenant_id, enabling_admin_id)
end
```

### 2. Cross-System User Lookup

```elixir
# Find user across both systems
def find_user_for_both_systems(email) do
  user = Shop1Cmms.Accounts.get_user_by_email(email)
  
  %{
    user: user,
    has_crm_access: user && user.active,
    has_cmms_access: user && user.cmms_enabled,
    cmms_roles: if(user && user.cmms_enabled, do: get_user_roles(user.id), else: [])
  }
end
```

### 3. Authentication Flow

```elixir
def authenticate_user(email, password, system \\ :cmms) do
  case system do
    :cmms ->
      Shop1Cmms.Accounts.get_user_by_email_and_password(email, password)
    
    :crm ->
      Shop1FinishLine.Accounts.get_user_by_email_and_password(email, password)
    
    :both ->
      user = get_user_by_email_and_password(email, password)
      if user && (user.active || user.cmms_enabled), do: user
  end
end
```

## Migration Strategy

### Phase 1: Schema Extensions
1. Add CMMS columns to existing users table
2. Create cmms_user_roles table
3. Update indexes and constraints

### Phase 2: Data Seeding
1. Identify users who need CMMS access
2. Create initial tenant admin roles
3. Assign default roles based on job functions

### Phase 3: Authentication Integration
1. Update authentication to check cmms_enabled
2. Implement role-based access controls
3. Test cross-system functionality

### Phase 4: UI Integration
1. Add CMMS enable/disable controls to CRM user management
2. Create CMMS role assignment interface
3. Implement unified user dashboard

## Security Considerations

1. **Separation of Concerns**: CRM roles ≠ CMMS roles
2. **Audit Trail**: Track who enables/disables CMMS access
3. **Role Expiration**: Support temporary access grants
4. **Site Isolation**: Users can be restricted to specific sites
5. **Cross-System Consistency**: Maintain data integrity between systems

## Testing Strategy

```elixir
# Test user can access both systems
test "user with both CRM and CMMS access" do
  user = create_user_with_both_access()
  
  assert Shop1FinishLine.Accounts.can?(user, :manage_customers)
  assert Shop1Cmms.Accounts.can?(user, :create_work_orders, nil, tenant.id)
end

# Test CMMS-only user cannot access CRM
test "CMMS-only user restrictions" do
  user = create_cmms_only_user()
  
  refute Shop1FinishLine.Accounts.can?(user, :manage_customers)
  assert Shop1Cmms.Accounts.can?(user, :create_work_orders, nil, tenant.id)
end
```

This integration approach provides a clean separation between the CRM and CMMS systems while avoiding duplicate user management and enabling unified authentication.
