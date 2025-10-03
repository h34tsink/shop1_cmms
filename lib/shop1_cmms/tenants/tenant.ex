defmodule Shop1Cmms.Tenants.Tenant do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "tenants" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :email, :string
    field :phone, :string
    field :address, :string
    field :timezone, :string, default: "UTC"
    field :settings, :map, default: %{}
    field :is_active, :boolean, default: true

    has_many :sites, Shop1Cmms.Tenants.Site
    has_many :user_tenant_assignments, Shop1Cmms.Accounts.UserTenantAssignment
    has_many :users, through: [:user_tenant_assignments, :user]

    # Use existing database column names instead of Phoenix defaults
    # Use naive_datetime to match database timestamp without timezone
    timestamps(inserted_at: :inserted_at, updated_at: :updated_at, type: :naive_datetime)
  end

  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :code, :description, :email, :phone,
                    :address, :timezone, :settings, :is_active])
    |> validate_required([:name, :code])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:code, min: 2, max: 20)
    |> validate_format(:code, ~r/^[A-Z0-9_]+$/, message: "must be uppercase letters, numbers, or underscores")
    |> unique_constraint(:code)
    |> validate_email(:email)
  end

  defp validate_email(changeset, field) do
    changeset
    |> validate_format(field, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(field, max: 160)
  end

  # Query helpers
  def active(query \\ __MODULE__) do
    from(t in query, where: t.is_active == true)
  end

  def by_code(query \\ __MODULE__, code) do
    from(t in query, where: t.code == ^code)
  end

  def by_name(query \\ __MODULE__, name) do
    from(t in query, where: t.name == ^name)
  end

  def with_sites(query \\ __MODULE__) do
    from(t in query, preload: :sites)
  end

  def for_user(query \\ __MODULE__, user_id) do
    from(t in query,
      join: uta in assoc(t, :user_tenant_assignments),
      where: uta.user_id == ^user_id and uta.is_active == true
    )
  end
end
