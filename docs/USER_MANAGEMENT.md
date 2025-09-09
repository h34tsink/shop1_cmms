# User Management & Role-Based Access Control

## Overview

This document outlines the user management system with multi-tenant, role-based access control (RBAC) and site isolation for the CMMS.

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

## Context Modules

### 1. Accounts Context (lib/shop1_cmms/accounts.ex)

```elixir
defmodule Shop1Cmms.Accounts do
  @moduledoc """
  The Accounts context handles user management, authentication,
  and role-based access control with multi-tenant isolation.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Accounts.{User, UserToken, UserNotifier, UserPermission}
  alias Shop1Cmms.Tenants.{Tenant, Site}

  ## Database getters

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  def get_user_with_tenant!(id) do
    User
    |> where([u], u.id == ^id)
    |> preload([:tenant, :site])
    |> Repo.one!()
  end

  ## User registration

  def register_user(attrs, tenant_id \\ nil) do
    attrs = if tenant_id, do: Map.put(attrs, :tenant_id, tenant_id), else: attrs
    
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  ## User management for tenant admins

  def list_tenant_users(tenant_id, opts \\ []) do
    query = User
    |> where([u], u.tenant_id == ^tenant_id)
    |> order_by([u], [u.role, u.email])

    case Keyword.get(opts, :site_id) do
      nil -> query
      site_id -> where(query, [u], u.site_id == ^site_id)
    end
    |> case Keyword.get(opts, :active_only) do
      true -> where([u], u.active == true)
      _ -> query
    end
    |> Repo.all()
  end

  def create_tenant_user(attrs, tenant_id, creating_user_id) do
    # Verify creating user has permission
    with {:ok, _} <- authorize_user_creation(creating_user_id, tenant_id),
         {:ok, user} <- register_user(attrs, tenant_id) do
      {:ok, user}
    else
      error -> error
    end
  end

  def update_user_role(user_id, new_role, updating_user_id) do
    user = get_user!(user_id)
    
    with {:ok, _} <- authorize_role_change(updating_user_id, user, new_role),
         {:ok, updated_user} <- update_user(user, %{role: new_role}) do
      {:ok, updated_user}
    else
      error -> error
    end
  end

  def deactivate_user(user_id, deactivating_user_id) do
    user = get_user!(user_id)
    
    with {:ok, _} <- authorize_user_deactivation(deactivating_user_id, user),
         {:ok, updated_user} <- update_user(user, %{active: false}) do
      {:ok, updated_user}
    else
      error -> error
    end
  end

  ## Role-based authorization

  def can?(user, action, resource \\ nil)

  def can?(%User{role: "tenant_admin"}, _action, _resource), do: true

  def can?(%User{role: "maintenance_manager"} = user, action, resource) do
    case action do
      :manage_users -> false  # Only tenant admin
      :manage_pm_templates -> true
      :manage_assets -> true
      :create_work_orders -> true
      :assign_work_orders -> true
      :approve_work_orders -> true
      :manage_inventory -> true
      :view_reports -> true
      _ -> can_access_resource?(user, resource)
    end
  end

  def can?(%User{role: "supervisor"} = user, action, resource) do
    case action do
      :assign_work_orders -> true
      :approve_work_orders -> true
      :create_work_orders -> true
      :view_work_orders -> true
      :update_pm_schedules -> true
      :manage_inventory -> false  # Read only
      :view_reports -> true
      _ -> can_access_resource?(user, resource)
    end
  end

  def can?(%User{role: "technician"} = user, action, resource) do
    case action do
      :view_work_orders -> can_view_assigned_or_site_work_orders?(user, resource)
      :update_work_orders -> can_update_assigned_work_order?(user, resource)
      :complete_work_orders -> can_update_assigned_work_order?(user, resource)
      :add_meter_readings -> true
      :view_assets -> can_access_resource?(user, resource)
      _ -> false
    end
  end

  def can?(%User{role: "operator"} = user, action, resource) do
    case action do
      :create_work_requests -> true
      :add_meter_readings -> true
      :view_assets -> can_access_resource?(user, resource)
      _ -> false
    end
  end

  def can?(_user, _action, _resource), do: false

  ## Permission helpers

  defp can_access_resource?(%User{site_id: nil}, _resource), do: true  # No site restriction

  defp can_access_resource?(%User{site_id: user_site_id}, %{site_id: resource_site_id}) do
    user_site_id == resource_site_id
  end

  defp can_access_resource?(%User{tenant_id: user_tenant_id}, %{tenant_id: resource_tenant_id}) do
    user_tenant_id == resource_tenant_id
  end

  defp can_access_resource?(_user, _resource), do: true  # Default allow if no restrictions

  defp can_view_assigned_or_site_work_orders?(%User{id: user_id, site_id: site_id}, %{assigned_to: assigned_to, site_id: wo_site_id}) do
    user_id == assigned_to || site_id == wo_site_id
  end

  defp can_update_assigned_work_order?(%User{id: user_id}, %{assigned_to: assigned_to}) do
    user_id == assigned_to
  end

  ## Authorization functions

  defp authorize_user_creation(creating_user_id, tenant_id) do
    creating_user = get_user!(creating_user_id)
    
    cond do
      creating_user.tenant_id != tenant_id ->
        {:error, :unauthorized}
      can?(creating_user, :manage_users) ->
        {:ok, :authorized}
      true ->
        {:error, :insufficient_permissions}
    end
  end

  defp authorize_role_change(updating_user_id, target_user, new_role) do
    updating_user = get_user!(updating_user_id)
    
    cond do
      updating_user.tenant_id != target_user.tenant_id ->
        {:error, :unauthorized}
      not can?(updating_user, :manage_users) ->
        {:error, :insufficient_permissions}
      new_role == "tenant_admin" and updating_user.role != "tenant_admin" ->
        {:error, :cannot_create_admin}
      true ->
        {:ok, :authorized}
    end
  end

  defp authorize_user_deactivation(deactivating_user_id, target_user) do
    deactivating_user = get_user!(deactivating_user_id)
    
    cond do
      deactivating_user.tenant_id != target_user.tenant_id ->
        {:error, :unauthorized}
      deactivating_user.id == target_user.id ->
        {:error, :cannot_deactivate_self}
      not can?(deactivating_user, :manage_users) ->
        {:error, :insufficient_permissions}
      true ->
        {:ok, :authorized}
    end
  end

  ## Session management with tenant context

  def create_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    query
    |> join(:inner, [token], user in assoc(token, :user))
    |> where([token, user], user.active == true)
    |> select([token, user], user)
    |> preload([token, user], [:tenant, :site])
    |> Repo.one()
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Multi-tenant user context

  def set_user_tenant_context(user_id) do
    user = get_user_with_tenant!(user_id)
    
    # Set PostgreSQL session variables for RLS
    Ecto.Adapters.SQL.query!(Repo, "SET app.current_user_id = $1", [user.id])
    Ecto.Adapters.SQL.query!(Repo, "SET app.current_tenant_id = $1", [user.tenant_id])
    
    if user.site_id do
      Ecto.Adapters.SQL.query!(Repo, "SET app.current_site_id = $1", [user.site_id])
    end
    
    user
  end

  ## User preferences and settings

  def update_user_preferences(user, preferences) do
    current_prefs = user.preferences || %{}
    new_prefs = Map.merge(current_prefs, preferences)
    
    update_user(user, %{preferences: new_prefs})
  end

  def get_user_preference(user, key, default \\ nil) do
    get_in(user.preferences || %{}, [key]) || default
  end
end
```

### 2. Enhanced User Schema (lib/shop1_cmms/accounts/user.ex)

```elixir
defmodule Shop1Cmms.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @roles ~w(tenant_admin maintenance_manager supervisor technician operator)

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :confirmed_at, :naive_datetime
    field :role, :string, default: "technician"
    field :active, :boolean, default: true
    field :phone, :string
    field :employee_id, :string
    field :first_name, :string
    field :last_name, :string
    field :preferences, :map, default: %{}

    belongs_to :tenant, Shop1Cmms.Tenants.Tenant
    belongs_to :site, Shop1Cmms.Tenants.Site

    has_many :user_permissions, Shop1Cmms.Accounts.UserPermission
    has_many :assigned_work_orders, Shop1Cmms.Work.WorkOrder, foreign_key: :assigned_to
    has_many :requested_work_orders, Shop1Cmms.Work.WorkOrder, foreign_key: :requested_by

    timestamps()
  end

  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :role, :tenant_id, :site_id, 
                    :phone, :employee_id, :first_name, :last_name])
    |> validate_email()
    |> validate_password(opts)
    |> validate_role()
    |> validate_tenant_membership()
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

  defp validate_role(changeset) do
    changeset
    |> validate_required([:role])
    |> validate_inclusion(:role, @roles)
  end

  defp validate_tenant_membership(changeset) do
    tenant_id = get_field(changeset, :tenant_id)
    site_id = get_field(changeset, :site_id)

    changeset = validate_required(changeset, [:tenant_id])

    if tenant_id && site_id do
      # Validate site belongs to tenant
      case Shop1Cmms.Tenants.get_site(site_id) do
        nil -> add_error(changeset, :site_id, "does not exist")
        site -> 
          if site.tenant_id == tenant_id do
            changeset
          else
            add_error(changeset, :site_id, "does not belong to this tenant")
          end
      end
    else
      changeset
    end
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

  def full_name(%__MODULE__{first_name: first, last_name: last}) do
    case {first, last} do
      {nil, nil} -> nil
      {first, nil} -> first
      {nil, last} -> last
      {first, last} -> "#{first} #{last}"
    end
  end

  def role_display_name(role) do
    case role do
      "tenant_admin" -> "Tenant Administrator"
      "maintenance_manager" -> "Maintenance Manager"
      "supervisor" -> "Supervisor"
      "technician" -> "Technician"
      "operator" -> "Operator"
      _ -> String.capitalize(role)
    end
  end

  def can_manage_role?(user_role, target_role) do
    role_hierarchy = %{
      "tenant_admin" => 5,
      "maintenance_manager" => 4,
      "supervisor" => 3,
      "technician" => 2,
      "operator" => 1
    }

    user_level = Map.get(role_hierarchy, user_role, 0)
    target_level = Map.get(role_hierarchy, target_role, 0)

    user_level > target_level
  end
end
```

### 3. User Permission Schema (lib/shop1_cmms/accounts/user_permission.ex)

```elixir
defmodule Shop1Cmms.Accounts.UserPermission do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "user_permissions" do
    field :permission, :string
    field :resource, :string
    
    belongs_to :user, Shop1Cmms.Accounts.User
    belongs_to :site, Shop1Cmms.Tenants.Site

    timestamps(inserted_at: :inserted_at, updated_at: false)
  end

  def changeset(user_permission, attrs) do
    user_permission
    |> cast(attrs, [:user_id, :permission, :resource, :site_id])
    |> validate_required([:user_id, :permission])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:site_id)
  end
end
```

## LiveView Authentication Plug

### Auth Context Plug (lib/shop1_cmms_web/plugs/tenant_context.ex)

```elixir
defmodule Shop1CmmsWeb.Plugs.TenantContext do
  @moduledoc """
  Sets tenant context for authenticated users and enforces RLS.
  """
  
  import Plug.Conn
  import Phoenix.Controller
  
  alias Shop1Cmms.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.assigns[:current_user] do
      nil -> 
        conn
      user ->
        # Set database context for RLS
        Accounts.set_user_tenant_context(user.id)
        
        # Add tenant info to assigns
        conn
        |> assign(:current_tenant, user.tenant)
        |> assign(:current_site, user.site)
        |> assign(:user_permissions, load_user_permissions(user))
    end
  end

  defp load_user_permissions(user) do
    # Cache user permissions for the session
    # This could be optimized with ETS or other caching
    %{
      can_manage_users: Accounts.can?(user, :manage_users),
      can_manage_assets: Accounts.can?(user, :manage_assets),
      can_assign_work_orders: Accounts.can?(user, :assign_work_orders),
      can_manage_inventory: Accounts.can?(user, :manage_inventory),
      role: user.role
    }
  end
end
```

## LiveView Authorization Helpers

### Authorization Helper (lib/shop1_cmms_web/live/live_helpers.ex)

```elixir
defmodule Shop1CmmsWeb.LiveHelpers do
  @moduledoc """
  Helper functions for LiveView authorization and common operations.
  """
  
  import Phoenix.LiveView
  alias Shop1Cmms.Accounts

  def require_permission(socket, permission, resource \\ nil) do
    user = socket.assigns.current_user
    
    if Accounts.can?(user, permission, resource) do
      socket
    else
      socket
      |> put_flash(:error, "You don't have permission to perform this action.")
      |> redirect(to: "/dashboard")
    end
  end

  def authorize_resource_access(socket, resource) do
    user = socket.assigns.current_user
    
    cond do
      user.tenant_id != resource.tenant_id ->
        unauthorized_redirect(socket)
      user.site_id && user.site_id != resource.site_id ->
        unauthorized_redirect(socket)
      true ->
        socket
    end
  end

  defp unauthorized_redirect(socket) do
    socket
    |> put_flash(:error, "You don't have access to this resource.")
    |> redirect(to: "/dashboard")
  end

  def user_can?(socket, permission, resource \\ nil) do
    Accounts.can?(socket.assigns.current_user, permission, resource)
  end

  def filter_by_user_access(query, user, resource_type) do
    # Apply user-specific filters based on role and site
    case {user.role, user.site_id} do
      {"technician", site_id} when not is_nil(site_id) ->
        # Technicians only see their site's resources
        where(query, [r], r.site_id == ^site_id)
      {"operator", site_id} when not is_nil(site_id) ->
        # Operators only see their site's resources
        where(query, [r], r.site_id == ^site_id)
      _ ->
        # Managers and supervisors see all tenant resources
        where(query, [r], r.tenant_id == ^user.tenant_id)
    end
  end
end
```

## Usage Examples

### In LiveView Modules

```elixir
defmodule Shop1CmmsWeb.WorkOrderLive.Index do
  use Shop1CmmsWeb, :live_view
  import Shop1CmmsWeb.LiveHelpers

  def mount(_params, _session, socket) do
    socket = require_permission(socket, :view_work_orders)
    
    work_orders = 
      Shop1Cmms.Work.list_work_orders(socket.assigns.current_user.tenant_id)
      |> filter_by_user_access(socket.assigns.current_user, :work_order)
    
    {:ok, assign(socket, work_orders: work_orders)}
  end

  def handle_event("assign_work_order", %{"id" => id, "user_id" => user_id}, socket) do
    socket = require_permission(socket, :assign_work_orders)
    
    # Handle assignment logic...
    {:noreply, socket}
  end
end
```

This user management system provides:
- Multi-tenant isolation
- Role-based permissions
- Site-level access control  
- Secure session management
- Database-level security with RLS
- LiveView integration helpers

The system is designed to scale with your business needs while maintaining security and proper access control.
