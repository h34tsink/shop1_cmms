defmodule Shop1Cmms.Accounts do
  @moduledoc """
  The Accounts context handles user management, authentication,
  and role-based access control with integration to existing Shop1FinishLine users.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Accounts.{User, UserDetails, CMMSUserRole, UserTenantAssignment}
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
    roles = get_user_cmms_roles(user_id, tenant_id)
    
    roles
    |> Enum.map(& &1.role)
    |> Enum.max_by(&CMMSUserRole.role_priority/1, fn -> "operator" end)
  end

  def user_has_cmms_access?(user_id, tenant_id) do
    UserTenantAssignment
    |> UserTenantAssignment.for_user(user_id)
    |> UserTenantAssignment.for_tenant(tenant_id)
    |> UserTenantAssignment.active()
    |> Repo.exists?()
  end

  def get_user_tenants(user_id) do
    Tenant
    |> Tenant.for_user(user_id)
    |> Tenant.active()
    |> Repo.all()
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

    query = case Keyword.get(opts, :site_id) do
      nil -> query
      site_id -> 
        from([u, uta, ud] in query, 
          where: is_nil(uta.default_site_id) or uta.default_site_id == ^site_id
        )
    end

    query = case Keyword.get(opts, :cmms_enabled_only) do
      true -> from([u, uta, ud] in query, where: u.cmms_enabled == true)
      _ -> query
    end

    Repo.all(query)
  end

  ## Role-based authorization

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

  defp can_access_resource?(_user, _resource) do
    # Implementation based on site restrictions
    true  # Simplified for now
  end

  defp can_view_assigned_or_site_work_orders?(_user, _resource) do
    # Implementation based on work order assignment
    true  # Simplified for now
  end

  defp can_update_assigned_work_order?(_user, _resource) do
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
