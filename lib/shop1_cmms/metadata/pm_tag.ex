defmodule Shop1Cmms.Metadata.PmTag do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @tag_types [:skill, :tool, :ppe]

  schema "pm_tags" do
    field :name, :string
    field :tag_type, Ecto.Enum, values: @tag_types
    field :description, :string
    field :is_active, :boolean, default: true
    field :usage_count, :integer, default: 0
    field :tenant_id, :integer

    timestamps(type: :naive_datetime)
  end

  @doc false
  def changeset(pm_tag, attrs) do
    pm_tag
    |> cast(attrs, [:name, :tag_type, :description, :is_active, :usage_count, :tenant_id])
    |> validate_required([:name, :tag_type, :tenant_id])
    |> validate_inclusion(:tag_type, @tag_types)
    |> validate_length(:name, min: 1, max: 100)
    |> unique_constraint([:tenant_id, :tag_type, :name], name: :pm_tags_tenant_type_name_index)
  end

  ## Query Helpers

  def by_tenant(query \\ __MODULE__, tenant_id) do
    from t in query, where: t.tenant_id == ^tenant_id
  end

  def by_type(query \\ __MODULE__, tag_type) do
    from t in query, where: t.tag_type == ^tag_type
  end

  def active(query \\ __MODULE__) do
    from t in query, where: t.is_active == true
  end

  def ordered(query \\ __MODULE__) do
    from t in query, order_by: [desc: t.usage_count, asc: t.name]
  end

  def search(query \\ __MODULE__, search_term) do
    search_pattern = "%#{search_term}%"
    from t in query, where: ilike(t.name, ^search_pattern)
  end

  def tag_types, do: @tag_types
  
  def tag_type_label(:skill), do: "Skill"
  def tag_type_label(:tool), do: "Tool"
  def tag_type_label(:ppe), do: "PPE"
  def tag_type_label(_), do: "Unknown"
end
