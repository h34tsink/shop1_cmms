defmodule Shop1Cmms.Maintenance.PmTag do
  @moduledoc """
  Schema for PM tags configuration (Skills, Tools, PPE).
  These are pre-defined tags that can be used across PM schedules.
  """
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

    timestamps()
  end

  @doc false
  def changeset(pm_tag, attrs) do
    pm_tag
    |> cast(attrs, [:name, :tag_type, :description, :is_active, :tenant_id])
    |> validate_required([:name, :tag_type, :tenant_id])
    |> validate_length(:name, min: 1, max: 100)
    |> validate_inclusion(:tag_type, @tag_types)
    |> unique_constraint([:tenant_id, :tag_type, :name], name: :pm_tags_tenant_type_name_index)
  end

  @doc """
  Returns all tag types.
  """
  def tag_types, do: @tag_types

  @doc """
  Query to filter by tenant.
  """
  def by_tenant(query \\ base_query(), tenant_id) do
    from t in query, where: t.tenant_id == ^tenant_id
  end

  @doc """
  Query to filter by tag type.
  """
  def by_type(query \\ base_query(), type) when type in @tag_types do
    from t in query, where: t.tag_type == ^type
  end
  def by_type(query, _), do: query

  @doc """
  Query to filter active tags only.
  """
  def active_only(query \\ base_query()) do
    from t in query, where: t.is_active == true
  end

  @doc """
  Query to order by usage count (most used first).
  """
  def order_by_usage(query \\ base_query()) do
    from t in query, order_by: [desc: t.usage_count, asc: t.name]
  end

  @doc """
  Query to order by name.
  """
  def order_by_name(query \\ base_query()) do
    from t in query, order_by: [asc: t.name]
  end

  @doc """
  Search tags by name (case-insensitive).
  """
  def search(query \\ base_query(), search_term) when is_binary(search_term) do
    search_pattern = "%#{search_term}%"
    from t in query, where: ilike(t.name, ^search_pattern)
  end
  def search(query, _), do: query

  defp base_query do
    from t in __MODULE__
  end
end
