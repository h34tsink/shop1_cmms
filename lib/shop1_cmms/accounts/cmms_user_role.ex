defmodule Shop1Cmms.Accounts.CMMSUserRole do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "cmms_user_roles" do
    field :name, :string
    field :display_name, :string
    field :description, :string
    field :permissions, {:array, :string}, default: []
    field :is_system_role, :boolean, default: false
    field :is_active, :boolean, default: true

    # Use existing database column names instead of Phoenix defaults
    timestamps(inserted_at: :inserted_at, updated_at: :updated_at, type: :naive_datetime)
  end

  @valid_roles ~w(tenant_admin maintenance_manager supervisor technician operator)

  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:name, :display_name, :description, :permissions, :is_system_role, :is_active])
    |> validate_required([:name, :display_name])
    |> validate_inclusion(:name, @valid_roles)
    |> unique_constraint(:name)
    |> foreign_key_constraint(:granted_by)
    |> put_granted_at()
  end

  defp put_granted_at(changeset) do
    if get_field(changeset, :granted_at) do
      changeset
    else
      put_change(changeset, :granted_at, DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second))
    end
  end

  # Query helpers
  def active_roles(query \\ __MODULE__) do
    from(r in query, where: r.is_active == true)
  end

  # Note: CMMSUserRole doesn't have tenant_id or user_id fields
  # Users are connected to roles through UserTenantAssignment table

  def for_site(query \\ __MODULE__, site_id) do
    from(r in query, where: is_nil(r.site_id) or r.site_id == ^site_id)
  end

  def with_name(query \\ __MODULE__, role_name) do
    from(r in query, where: r.name == ^role_name)
  end

  def current(query \\ __MODULE__) do
    query
    |> active_roles()
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
