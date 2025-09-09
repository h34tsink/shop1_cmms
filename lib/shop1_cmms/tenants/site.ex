defmodule Shop1Cmms.Tenants.Site do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "sites" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :address, :string
    field :contact_email, :string
    field :contact_phone, :string
    field :timezone, :string
    field :settings, :map, default: %{}
    field :is_active, :boolean, default: true

    belongs_to :tenant, Shop1Cmms.Tenants.Tenant
    has_many :user_tenant_assignments, Shop1Cmms.Accounts.UserTenantAssignment, foreign_key: :default_site_id

    timestamps(type: :utc_datetime)
  end

  def changeset(site, attrs) do
    site
    |> cast(attrs, [:name, :code, :description, :address, :contact_email, 
                    :contact_phone, :timezone, :settings, :is_active, :tenant_id])
    |> validate_required([:name, :code, :tenant_id])
    |> validate_length(:name, min: 2, max: 100)
    |> validate_length(:code, min: 2, max: 20)
    |> validate_format(:code, ~r/^[A-Z0-9_]+$/, message: "must be uppercase letters, numbers, or underscores")
    |> foreign_key_constraint(:tenant_id)
    |> unique_constraint([:tenant_id, :code], name: :sites_tenant_id_code_index)
    |> validate_email(:contact_email)
  end

  defp validate_email(changeset, field) do
    changeset
    |> validate_format(field, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(field, max: 160)
  end

  # Query helpers
  def active(query \\ __MODULE__) do
    from(s in query, where: s.is_active == true)
  end

  def for_tenant(query \\ __MODULE__, tenant_id) do
    from(s in query, where: s.tenant_id == ^tenant_id)
  end

  def by_code(query \\ __MODULE__, code) do
    from(s in query, where: s.code == ^code)
  end

  def with_tenant(query \\ __MODULE__) do
    from(s in query, preload: :tenant)
  end
end
