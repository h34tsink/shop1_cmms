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
    
    timestamps(type: :utc_datetime)
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

  def with_preloads(query \\ __MODULE__) do
    from(a in query, preload: [:user, :tenant, :default_site])
  end
end
