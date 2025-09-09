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

  # Query helpers
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
