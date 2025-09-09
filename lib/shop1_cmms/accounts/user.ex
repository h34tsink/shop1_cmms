defmodule Shop1Cmms.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @derive {Phoenix.Param, key: :id}
  schema "users" do
    # Existing Shop1FinishLine fields
    field :username, :string
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
    belongs_to :role, Shop1Cmms.Accounts.Role
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

  defp get_user_details(_user) do
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
