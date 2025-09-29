defmodule Shop1Cmms.Metadata.CustomFieldValue do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "custom_field_values" do
    field :entity_type, :string
    field :entity_id, :binary_id
    field :field_value, :string

    # Associations
    belongs_to :custom_field, Shop1Cmms.Metadata.CustomField, foreign_key: :custom_field_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(custom_field_value, attrs) do
    custom_field_value
    |> cast(attrs, [:custom_field_id, :entity_type, :entity_id, :field_value, :tenant_id])
    |> validate_required([:custom_field_id, :entity_type, :entity_id, :tenant_id])
    |> validate_field_value()
    |> unique_constraint([:custom_field_id, :entity_id], name: :custom_field_values_field_entity_index, message: "Value already exists for this field")
  end

  defp validate_field_value(changeset) do
    # This validation would need to be enhanced based on the custom field's type and validation rules
    # For now, we'll do basic validation
    field_value = get_field(changeset, :field_value)

    if is_nil(field_value) || field_value == "" do
      changeset
    else
      validate_length(changeset, :field_value, max: 10000)
    end
  end

  @doc """
  Query helpers for filtering custom field values.
  """
  def by_tenant(query \\ __MODULE__, tenant_id) do
    from cfv in query, where: cfv.tenant_id == ^tenant_id
  end

  def by_custom_field(query \\ __MODULE__, custom_field_id) do
    from cfv in query, where: cfv.custom_field_id == ^custom_field_id
  end

  def by_entity(query \\ __MODULE__, entity_type, entity_id) do
    from cfv in query,
      where: cfv.entity_type == ^entity_type and cfv.entity_id == ^entity_id
  end

  def by_entity_type(query \\ __MODULE__, entity_type) do
    from cfv in query, where: cfv.entity_type == ^entity_type
  end

  def with_custom_field(query \\ __MODULE__) do
    from cfv in query, preload: [:custom_field]
  end

  def with_non_empty_values(query \\ __MODULE__) do
    from cfv in query, where: not is_nil(cfv.field_value) and cfv.field_value != ""
  end

  def search_values(query \\ __MODULE__, term) when is_binary(term) do
    search_term = "%#{term}%"
    from cfv in query, where: ilike(cfv.field_value, ^search_term)
  end

  def ordered(query \\ __MODULE__, order_by \\ :inserted_at) do
    from cfv in query, order_by: ^order_by
  end
end
