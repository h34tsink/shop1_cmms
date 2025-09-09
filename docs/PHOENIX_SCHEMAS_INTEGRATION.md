# Phoenix Schemas for Shop1FinishLine CMMS Integration

## User Schema (lib/shop1_cmms/accounts/user.ex)

```elixir
defmodule Shop1Cmms.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @derive {Phoenix.Param, key: :id}
  schema "users" do
    # Existing Shop1FinishLine fields
    field :username, :string  # Note: This is USER-DEFINED type in DB
    field :password_hash, :string, redact: true
    field :last_login, :utc_datetime
    field :failed_logins, :integer, default: 0
    field :is_active, :boolean, default: true
    
    # CMMS extensions (added by migration)
    field :cmms_enabled, :boolean, default: false
    field :last_cmms_login, :utc_datetime
    field :cmms_preferences, :map, default: %{}
    
    # Virtual field for password changes
    field :password, :string, virtual: true, redact: true
    
    # Relationships
    belongs_to :role, Shop1Cmms.Accounts.Role # Existing CRM role
    has_many :cmms_user_roles, Shop1Cmms.Accounts.CMMSUserRole
    has_many :user_tenant_assignments, Shop1Cmms.Accounts.UserTenantAssignment
    has_many :tenants, through: [:user_tenant_assignments, :tenant]
    
    # Timestamps (existing)
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :is_active, :cmms_enabled, :last_cmms_login, :cmms_preferences, :role_id])
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 50)
    |> unique_constraint(:username)
  end

  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:username, :password, :cmms_enabled, :role_id])
    |> validate_required([:username, :password])
    |> validate_password(opts)
  end

  def cmms_changeset(user, attrs) do
    user
    |> cast(attrs, [:cmms_enabled, :last_cmms_login, :cmms_preferences])
    |> validate_required([:cmms_enabled])
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
      |> put_change(:password_hash, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def valid_password?(%__MODULE__{password_hash: password_hash}, password)
      when is_binary(password_hash) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, password_hash)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  # Helper functions for CMMS integration
  def display_name(%__MODULE__{} = user) do
    # Try to get display name from user_details, fallback to username
    case get_user_details(user) do
      %{display_name: name} when is_binary(name) and name != "" -> name
      %{full_name: name} when is_binary(name) and name != "" -> name
      _ -> user.username
    end
  end

  defp get_user_details(user) do
    # This would query the user_details view/table
    # Implementation depends on how user_details is structured
    %{}
  end

  # Query helpers
  def active(query \\ __MODULE__) do
    from(u in query, where: u.is_active == true)
  end

  def cmms_enabled(query \\ __MODULE__) do
    from(u in query, where: u.cmms_enabled == true)
  end

  def with_role(query \\ __MODULE__, role_id) do
    from(u in query, where: u.role_id == ^role_id)
  end

  def by_username(query \\ __MODULE__, username) do
    from(u in query, where: u.username == ^username)
  end
end
```

## User Details Schema (lib/shop1_cmms/accounts/user_details.ex)

```elixir
defmodule Shop1Cmms.Accounts.UserDetails do
  use Ecto.Schema
  import Ecto.Query

  @primary_key {:id, :integer, autogenerate: false}
  schema "user_details" do
    # Core user info
    field :username, :string
    field :user_is_active, :boolean
    field :last_login, :utc_datetime
    field :user_created_at, :utc_datetime
    
    # Role information (from join)
    field :role_id, :integer
    field :role_name, :string
    field :role_description, :string
    
    # Profile information
    field :profile_id, :integer
    field :first_name, :string
    field :last_name, :string
    field :display_name, :string
    field :full_name, :string
    field :email, :string
    field :phone, :string
    field :mobile, :string
    field :department, :string
    field :job_title, :string
    field :avatar_url, :string
    field :bio, :string
    field :location, :string
  end

  # This is a read-only view, so no changesets needed
  
  def by_user_id(query \\ __MODULE__, user_id) do
    from(ud in query, where: ud.id == ^user_id)
  end

  def active_users(query \\ __MODULE__) do
    from(ud in query, where: ud.user_is_active == true)
  end

  def by_email(query \\ __MODULE__, email) do
    from(ud in query, where: ud.email == ^email)
  end

  def by_department(query \\ __MODULE__, department) do
    from(ud in query, where: ud.department == ^department)
  end

  def search_by_name(query \\ __MODULE__, search_term) do
    search_pattern = "%#{search_term}%"
    from(ud in query, 
      where: ilike(ud.full_name, ^search_pattern) or 
             ilike(ud.display_name, ^search_pattern) or
             ilike(ud.first_name, ^search_pattern) or
             ilike(ud.last_name, ^search_pattern)
    )
  end
end
```

## Role Schema (lib/shop1_cmms/accounts/role.ex)

```elixir
defmodule Shop1Cmms.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "roles" do
    field :name, :string
    field :description, :string
    field :permissions, {:array, :string}
    field :code, :string
    field :is_system, :boolean, default: false
    field :is_active, :boolean, default: true
    field :priority, :integer

    has_many :users, Shop1Cmms.Accounts.User
    
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
  end

  def changeset(role, attrs) do
    role
    |> cast(attrs, [:name, :description, :permissions, :code, :is_system, :is_active, :priority])
    |> validate_required([:name, :code])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:code, min: 2, max: 50)
    |> unique_constraint(:code)
  end

  # Query helpers
  def active(query \\ __MODULE__) do
    from(r in query, where: r.is_active == true)
  end

  def system_roles(query \\ __MODULE__) do
    from(r in query, where: r.is_system == true)
  end

  def by_code(query \\ __MODULE__, code) do
    from(r in query, where: r.code == ^code)
  end

  def with_permission(query \\ __MODULE__, permission) do
    from(r in query, where: ^permission in r.permissions)
  end
end
```

## CMMS User Role Schema (lib/shop1_cmms/accounts/cmms_user_role.ex)

```elixir
defmodule Shop1Cmms.Accounts.CMMSUserRole do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "cmms_user_roles" do
    belongs_to :user, Shop1Cmms.Accounts.User
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant
    belongs_to :site, Shop1Cmms.Tenants.Site
    belongs_to :granted_by_user, Shop1Cmms.Accounts.User, foreign_key: :granted_by
    
    field :role, :string
    field :granted_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :is_active, :boolean, default: true
    
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
  end

  @valid_roles ~w(tenant_admin maintenance_manager supervisor technician operator)

  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :tenant_id, :site_id, :role, :granted_by, :expires_at, :is_active])
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

  # Query helpers
  def active_roles(query \\ __MODULE__) do
    from(r in query, where: r.is_active == true)
  end

  def for_tenant(query \\ __MODULE__, tenant_id) do
    from(r in query, where: r.tenant_id == ^tenant_id)
  end

  def for_user(query \\ __MODULE__, user_id) do
    from(r in query, where: r.user_id == ^user_id)
  end

  def for_site(query \\ __MODULE__, site_id) do
    from(r in query, where: is_nil(r.site_id) or r.site_id == ^site_id)
  end

  def with_role(query \\ __MODULE__, role) do
    from(r in query, where: r.role == ^role)
  end

  def unexpired(query \\ __MODULE__) do
    from(r in query, where: is_nil(r.expires_at) or r.expires_at > ^DateTime.utc_now())
  end

  def current(query \\ __MODULE__) do
    query
    |> active_roles()
    |> unexpired()
  end
end
```

## User Tenant Assignment Schema (lib/shop1_cmms/accounts/user_tenant_assignment.ex)

```elixir
defmodule Shop1Cmms.Accounts.UserTenantAssignment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "user_tenant_assignments" do
    belongs_to :user, Shop1Cmms.Accounts.User
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant
    belongs_to :default_site, Shop1Cmms.Tenants.Site
    belongs_to :assigned_by_user, Shop1Cmms.Accounts.User, foreign_key: :assigned_by
    
    field :is_primary, :boolean, default: false
    field :assigned_at, :utc_datetime
    field :is_active, :boolean, default: true
    
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:user_id, :tenant_id, :default_site_id, :is_primary, :assigned_by, :is_active])
    |> validate_required([:user_id, :tenant_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:default_site_id)
    |> foreign_key_constraint(:assigned_by)
    |> unique_constraint([:user_id, :tenant_id])
    |> put_assigned_at()
  end

  defp put_assigned_at(changeset) do
    if get_field(changeset, :assigned_at) do
      changeset
    else
      put_change(changeset, :assigned_at, DateTime.utc_now())
    end
  end

  # Query helpers
  def active(query \\ __MODULE__) do
    from(a in query, where: a.is_active == true)
  end

  def for_user(query \\ __MODULE__, user_id) do
    from(a in query, where: a.user_id == ^user_id)
  end

  def for_tenant(query \\ __MODULE__, tenant_id) do
    from(a in query, where: a.tenant_id == ^tenant_id)
  end

  def primary_assignments(query \\ __MODULE__) do
    from(a in query, where: a.is_primary == true)
  end

  def with_site(query \\ __MODULE__, site_id) do
    from(a in query, where: a.default_site_id == ^site_id)
  end
end
```

## Enhanced Accounts Context (lib/shop1_cmms/accounts.ex)

```elixir
defmodule Shop1Cmms.Accounts do
  @moduledoc """
  The Accounts context handles user management, authentication,
  and role-based access control with integration to existing Shop1FinishLine users.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Accounts.{User, UserDetails, Role, CMMSUserRole, UserTenantAssignment}
  alias Shop1Cmms.Tenants.{Tenant, Site}

  ## Database getters (working with existing Shop1FinishLine structure)

  def get_user_by_username(username) when is_binary(username) do
    User
    |> User.active()
    |> User.by_username(username)
    |> Repo.one()
  end

  def get_cmms_user_by_username(username) when is_binary(username) do
    User
    |> User.active()
    |> User.cmms_enabled()
    |> User.by_username(username)
    |> Repo.one()
  end

  def get_user_by_username_and_password(username, password)
      when is_binary(username) and is_binary(password) do
    user = get_cmms_user_by_username(username)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_with_details(id) do
    case Repo.get(User, id) do
      nil -> nil
      user ->
        details = UserDetails
        |> UserDetails.by_user_id(id)
        |> Repo.one()
        
        Map.put(user, :details, details)
    end
  end

  def get_user_details(user_id) do
    UserDetails
    |> UserDetails.by_user_id(user_id)
    |> Repo.one()
  end

  ## CMMS User Management

  def enable_cmms_for_user(user_id, tenant_id, enabling_user_id) do
    user = get_user!(user_id)
    
    Repo.transaction(fn ->
      # Enable CMMS access
      {:ok, updated_user} = 
        user
        |> User.cmms_changeset(%{cmms_enabled: true})
        |> Repo.update()

      # Create tenant assignment
      {:ok, _assignment} = create_user_tenant_assignment(%{
        user_id: user_id,
        tenant_id: tenant_id,
        assigned_by: enabling_user_id,
        is_primary: true
      })

      # Grant default technician role
      {:ok, _role} = create_cmms_user_role(%{
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
      CMMSUserRole
      |> CMMSUserRole.for_user(user_id)
      |> Repo.update_all(set: [is_active: false, updated_at: DateTime.utc_now()])

      # Disable all tenant assignments
      UserTenantAssignment
      |> UserTenantAssignment.for_user(user_id)
      |> Repo.update_all(set: [is_active: false, updated_at: DateTime.utc_now()])

      # Disable CMMS access
      user
      |> User.cmms_changeset(%{cmms_enabled: false, last_cmms_login: nil})
      |> Repo.update()
    end)
  end

  ## Role Management

  def create_cmms_user_role(attrs) do
    %CMMSUserRole{}
    |> CMMSUserRole.changeset(attrs)
    |> Repo.insert()
  end

  def create_user_tenant_assignment(attrs) do
    %UserTenantAssignment{}
    |> UserTenantAssignment.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_cmms_roles(user_id, tenant_id) do
    CMMSUserRole
    |> CMMSUserRole.for_user(user_id)
    |> CMMSUserRole.for_tenant(tenant_id)
    |> CMMSUserRole.current()
    |> Repo.all()
  end

  def get_user_highest_cmms_role(user_id, tenant_id) do
    # Use the PostgreSQL function we created
    case Repo.query("SELECT get_user_highest_cmms_role($1, $2)", [user_id, tenant_id]) do
      {:ok, %{rows: [[role]]}} -> role
      _ -> "operator"
    end
  end

  def user_has_cmms_access?(user_id, tenant_id) do
    # Use the PostgreSQL function we created
    case Repo.query("SELECT user_has_cmms_access($1, $2)", [user_id, tenant_id]) do
      {:ok, %{rows: [[true]]}} -> true
      _ -> false
    end
  end

  ## Tenant user management

  def list_tenant_users(tenant_id, opts \\ []) do
    query = from(u in User,
      join: uta in UserTenantAssignment, on: uta.user_id == u.id,
      left_join: ud in UserDetails, on: ud.id == u.id,
      where: uta.tenant_id == ^tenant_id and uta.is_active == true and u.is_active == true,
      select: %{user: u, details: ud, assignment: uta},
      order_by: [ud.full_name, ud.display_name, u.username]
    )

    case Keyword.get(opts, :site_id) do
      nil -> query
      site_id -> 
        from([u, uta, ud] in query, 
          where: is_nil(uta.default_site_id) or uta.default_site_id == ^site_id
        )
    end
    |> case Keyword.get(opts, :cmms_enabled_only) do
      true -> from([u, uta, ud] in query, where: u.cmms_enabled == true)
      _ -> query
    end
    |> Repo.all()
  end

  ## Role-based authorization (updated for integration)

  def can?(user, action, resource \\ nil, tenant_id) do
    if not user.cmms_enabled do
      false
    else
      highest_role = get_user_highest_cmms_role(user.id, tenant_id)
      check_role_permission(highest_role, action, resource, user, tenant_id)
    end
  end

  defp check_role_permission("tenant_admin", _action, _resource, _user, _tenant_id), do: true

  defp check_role_permission("maintenance_manager", action, _resource, _user, _tenant_id) do
    action in [:manage_assets, :manage_pm_templates, :create_work_orders, 
               :assign_work_orders, :approve_work_orders, :manage_inventory, 
               :view_reports, :manage_users]
  end

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

  ## Permission helpers

  defp can_access_resource?(user, resource) do
    # Implementation based on site restrictions
    true  # Simplified for now
  end

  defp can_view_assigned_or_site_work_orders?(user, resource) do
    # Implementation based on work order assignment
    true  # Simplified for now
  end

  defp can_update_assigned_work_order?(user, resource) do
    # Implementation based on work order assignment
    true  # Simplified for now
  end

  ## Session management

  def set_user_tenant_context(user_id, tenant_id) do
    # Verify user has access to this tenant
    if user_has_cmms_access?(user_id, tenant_id) do
      # Set PostgreSQL session variables for RLS
      Repo.query!("SET app.current_user_id = $1", [user_id])
      Repo.query!("SET app.current_tenant_id = $1", [tenant_id])
      
      # Update last CMMS login
      user = get_user!(user_id)
      user
      |> User.cmms_changeset(%{last_cmms_login: DateTime.utc_now()})
      |> Repo.update()
      
      {:ok, user}
    else
      {:error, :no_tenant_access}
    end
  end

  ## User preferences and settings

  def update_user_cmms_preferences(user, preferences) do
    current_prefs = user.cmms_preferences || %{}
    new_prefs = Map.merge(current_prefs, preferences)
    
    user
    |> User.cmms_changeset(%{cmms_preferences: new_prefs})
    |> Repo.update()
  end

  def get_user_cmms_preference(user, key, default \\ nil) do
    get_in(user.cmms_preferences || %{}, [key]) || default
  end
end
```

## Integration Usage Examples

```elixir
# Enable CMMS for existing Shop1FinishLine user
user = Accounts.get_user_by_username("john.doe")
Accounts.enable_cmms_for_user(user.id, tenant_id, admin_user_id)

# Authenticate user for CMMS
case Accounts.get_user_by_username_and_password("john.doe", "password123") do
  %User{cmms_enabled: true} = user ->
    {:ok, user} = Accounts.set_user_tenant_context(user.id, tenant_id)
    # User is now authenticated for CMMS
  %User{cmms_enabled: false} ->
    # User exists but doesn't have CMMS access
  nil ->
    # Invalid credentials
end

# Check user permissions
if Accounts.can?(user, :create_work_orders, nil, tenant_id) do
  # User can create work orders
end

# Get user with rich profile data
user_with_details = Accounts.get_user_with_details(user_id)
user_details = user_with_details.details
full_name = user_details.full_name
department = user_details.department
```

This integration preserves your existing Shop1FinishLine user structure while cleanly adding CMMS functionality. The schemas work with your existing database columns and the new CMMS-specific tables we'll add.
