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

    # Use existing database column names instead of Phoenix defaults
    timestamps(inserted_at: :created_at, updated_at: :updated_at, type: :utc_datetime)
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

  def valid_roles, do: @valid_roles

  def role_hierarchy do
    %{
      "tenant_admin" => 5,
      "maintenance_manager" => 4,
      "supervisor" => 3,
      "technician" => 2,
      "operator" => 1
    }
  end

  def role_priority(role) do
    Map.get(role_hierarchy(), role, 0)
  end
end
