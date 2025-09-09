defmodule Shop1Cmms.Tenants do
  @moduledoc """
  The Tenants context manages tenants (companies) and their sites
  in the multi-tenant CMMS system.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Tenants.{Tenant, Site}
  alias Shop1Cmms.Accounts.UserTenantAssignment

  ## Tenant Management

  def list_tenants do
    Tenant
    |> Tenant.active()
    |> Repo.all()
  end

  def get_tenant!(id) do
    Repo.get!(Tenant, id)
  end

  def get_tenant_by_name(name) do
    Tenant
    |> Tenant.by_name(name)
    |> Tenant.active()
    |> Repo.one()
  end

  def create_tenant(attrs \\ %{}) do
    %Tenant{}
    |> Tenant.changeset(attrs)
    |> Repo.insert()
  end

  def update_tenant(%Tenant{} = tenant, attrs) do
    tenant
    |> Tenant.changeset(attrs)
    |> Repo.update()
  end

  def delete_tenant(%Tenant{} = tenant) do
    tenant
    |> Tenant.changeset(%{is_active: false})
    |> Repo.update()
  end

  ## Site Management

  def list_sites(tenant_id) do
    Site
    |> Site.for_tenant(tenant_id)
    |> Site.active()
    |> Repo.all()
  end

  def list_all_active_sites do
    Site
    |> Site.active()
    |> preload(:tenant)
    |> Repo.all()
  end

  def get_site!(id) do
    Repo.get!(Site, id)
  end

  def get_site_with_tenant(id) do
    Site
    |> preload(:tenant)
    |> Repo.get(id)
  end

  def get_site_by_code(tenant_id, site_code) do
    Site
    |> Site.for_tenant(tenant_id)
    |> Site.by_code(site_code)
    |> Site.active()
    |> Repo.one()
  end

  def create_site(attrs \\ %{}) do
    %Site{}
    |> Site.changeset(attrs)
    |> Repo.insert()
  end

  def update_site(%Site{} = site, attrs) do
    site
    |> Site.changeset(attrs)
    |> Repo.update()
  end

  def delete_site(%Site{} = site) do
    site
    |> Site.changeset(%{is_active: false})
    |> Repo.update()
  end

  ## Site statistics and user access

  def get_site_user_count(site_id) do
    UserTenantAssignment
    |> UserTenantAssignment.for_site(site_id)
    |> UserTenantAssignment.active()
    |> Repo.aggregate(:count, :user_id)
  end

  def get_tenant_user_count(tenant_id) do
    UserTenantAssignment
    |> UserTenantAssignment.for_tenant(tenant_id)
    |> UserTenantAssignment.active()
    |> Repo.aggregate(:count, :user_id)
  end

  ## User access to tenants and sites

  def list_user_tenants(user_id) do
    Tenant
    |> Tenant.for_user(user_id)
    |> Tenant.active()
    |> Repo.all()
  end

  def list_user_sites(user_id, tenant_id \\ nil) do
    query = from(s in Site,
      join: uta in UserTenantAssignment, on: uta.tenant_id == s.tenant_id,
      where: uta.user_id == ^user_id and uta.is_active == true and s.is_active == true,
      select: s,
      distinct: true,
      order_by: s.name
    )

    case tenant_id do
      nil -> query
      tid -> from(s in query, where: s.tenant_id == ^tid)
    end
    |> Repo.all()
  end

  def get_user_default_site(user_id, tenant_id) do
    assignment = UserTenantAssignment
    |> UserTenantAssignment.for_user(user_id)
    |> UserTenantAssignment.for_tenant(tenant_id)
    |> UserTenantAssignment.active()
    |> Repo.one()

    case assignment do
      nil -> nil
      %{default_site_id: nil} -> nil
      %{default_site_id: site_id} -> get_site!(site_id)
    end
  end

  def set_user_default_site(user_id, tenant_id, site_id) do
    case UserTenantAssignment
         |> UserTenantAssignment.for_user(user_id)
         |> UserTenantAssignment.for_tenant(tenant_id)
         |> UserTenantAssignment.active()
         |> Repo.one() do
      nil -> 
        {:error, :assignment_not_found}
      assignment ->
        assignment
        |> UserTenantAssignment.changeset(%{default_site_id: site_id})
        |> Repo.update()
    end
  end

  ## Tenant and site context setting for RLS

  def set_tenant_context(tenant_id) do
    Repo.query!("SET app.current_tenant_id = $1", [tenant_id])
  end

  def set_site_context(site_id) do
    Repo.query!("SET app.current_site_id = $1", [site_id])
  end

  def clear_context do
    Repo.query!("RESET app.current_tenant_id", [])
    Repo.query!("RESET app.current_site_id", [])
    Repo.query!("RESET app.current_user_id", [])
  end

  ## Tenant creation with initial setup

  def create_tenant_with_setup(tenant_attrs, initial_admin_user_id) do
    Repo.transaction(fn ->
      # Create the tenant
      {:ok, tenant} = create_tenant(tenant_attrs)

      # Create a default "Main" site
      {:ok, main_site} = create_site(%{
        tenant_id: tenant.id,
        name: "Main Site",
        site_code: "MAIN",
        description: "Default main site for #{tenant.name}",
        is_primary: true
      })

      # Assign the admin user to this tenant
      {:ok, _assignment} = %UserTenantAssignment{}
      |> UserTenantAssignment.changeset(%{
        user_id: initial_admin_user_id,
        tenant_id: tenant.id,
        assigned_by: initial_admin_user_id,
        default_site_id: main_site.id,
        is_primary: true
      })
      |> Repo.insert()

      # Grant tenant admin role
      {:ok, _role} = %Shop1Cmms.Accounts.CMMSUserRole{}
      |> Shop1Cmms.Accounts.CMMSUserRole.changeset(%{
        user_id: initial_admin_user_id,
        tenant_id: tenant.id,
        role: "tenant_admin",
        granted_by: initial_admin_user_id
      })
      |> Repo.insert()

      %{tenant: tenant, main_site: main_site}
    end)
  end

  ## Bulk operations for tenant management

  def import_sites_for_tenant(tenant_id, sites_data) do
    Repo.transaction(fn ->
      sites_data
      |> Enum.map(fn site_attrs ->
        site_attrs
        |> Map.put(:tenant_id, tenant_id)
        |> then(&create_site/1)
      end)
    end)
  end

  ## Validation helpers

  def tenant_code_available?(code, excluding_id \\ nil) do
    query = Tenant
    |> Tenant.by_code(code)
    |> Tenant.active()

    query = case excluding_id do
      nil -> query
      id -> from(t in query, where: t.id != ^id)
    end

    not Repo.exists?(query)
  end

  def site_code_available?(tenant_id, code, excluding_id \\ nil) do
    query = Site
    |> Site.for_tenant(tenant_id)
    |> Site.by_code(code)
    |> Site.active()

    query = case excluding_id do
      nil -> query
      id -> from(s in query, where: s.id != ^id)
    end

    not Repo.exists?(query)
  end

  ## Tenant summary information

  def get_tenant_summary(tenant_id) do
    %{
      tenant: get_tenant!(tenant_id),
      site_count: Repo.aggregate(Site |> Site.for_tenant(tenant_id) |> Site.active(), :count),
      user_count: get_tenant_user_count(tenant_id),
      sites: list_sites(tenant_id)
    }
  end
end
