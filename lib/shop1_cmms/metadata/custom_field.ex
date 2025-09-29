defmodule Shop1Cmms.Metadata.CustomField do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @field_types ~w(text number date boolean select multi_select)
  @entity_types ~w(asset work_order location user maintenance_category)

  schema "custom_fields" do
    field :entity_type, :string
    field :field_name, :string
    field :field_label, :string
    field :field_type, :string
    field :field_options, :map
    field :default_value, :string
    field :is_required, :boolean, default: false
    field :validation_rules, :map
    field :display_order, :integer, default: 0
    field :help_text, :string
    field :is_active, :boolean, default: true

    # Associations
    has_many :custom_field_values, Shop1Cmms.Metadata.CustomFieldValue, foreign_key: :custom_field_id
    belongs_to :tenant, Shop1Cmms.Tenants.Tenant, foreign_key: :tenant_id, type: :integer

    timestamps()
  end

  @doc false
  def changeset(custom_field, attrs) do
    custom_field
    |> cast(attrs, [:entity_type, :field_name, :field_label, :field_type, :field_options, :default_value, :is_required, :validation_rules, :display_order, :help_text, :is_active, :tenant_id])
    |> validate_required([:entity_type, :field_name, :field_label, :field_type, :tenant_id])
    |> validate_length(:field_name, min: 1, max: 100)
    |> validate_length(:field_label, min: 1, max: 255)
    |> validate_format(:field_name, ~r/^[a-z][a-z0-9_]*$/, message: "must start with a letter and contain only lowercase letters, numbers, and underscores")
    |> validate_inclusion(:entity_type, @entity_types, message: "must be one of: #{Enum.join(@entity_types, ", ")}")
    |> validate_inclusion(:field_type, @field_types, message: "must be one of: #{Enum.join(@field_types, ", ")}")
    |> validate_number(:display_order, greater_than_or_equal_to: 0)
    |> validate_field_options()
    |> validate_validation_rules()
    |> unique_constraint([:tenant_id, :entity_type, :field_name], name: :custom_fields_tenant_entity_name_index, message: "Field name already exists for this entity type")
  end

  defp validate_field_options(changeset) do
    field_type = get_field(changeset, :field_type)
    field_options = get_field(changeset, :field_options)

    case field_type do
      type when type in ["select", "multi_select"] ->
        if is_map(field_options) && Map.has_key?(field_options, "options") && is_list(field_options["options"]) && length(field_options["options"]) > 0 do
          changeset
        else
          add_error(changeset, :field_options, "must contain 'options' array with at least one option for select/multi_select fields")
        end

      _ ->
        changeset
    end
  end

  defp validate_validation_rules(changeset) do
    validation_rules = get_field(changeset, :validation_rules)

    if is_map(validation_rules) do
      # Validate common validation rules
      changeset
      |> validate_validation_rule(:min_length, &is_integer/1, "must be an integer")
      |> validate_validation_rule(:max_length, &is_integer/1, "must be an integer")
      |> validate_validation_rule(:min_value, &is_number/1, "must be a number")
      |> validate_validation_rule(:max_value, &is_number/1, "must be a number")
      |> validate_validation_rule(:pattern, &is_binary/1, "must be a string")
    else
      changeset
    end
  end

  defp validate_validation_rule(changeset, rule_key, validator_fn, error_message) do
    validation_rules = get_field(changeset, :validation_rules) || %{}

    case Map.get(validation_rules, to_string(rule_key)) do
      nil -> changeset
      value ->
        if validator_fn.(value) do
          changeset
        else
          add_error(changeset, :validation_rules, "#{rule_key} #{error_message}")
        end
    end
  end

  @doc """
  Returns available field types.
  """
  def field_types, do: @field_types

  @doc """
  Returns available entity types.
  """
  def entity_types, do: @entity_types

  @doc """
  Query helpers for filtering custom fields by tenant.
  """
  def by_tenant(query \\ __MODULE__, tenant_id) do
    from cf in query, where: cf.tenant_id == ^tenant_id
  end

  def active(query \\ __MODULE__) do
    from cf in query, where: cf.is_active == true
  end

  def by_entity_type(query \\ __MODULE__, entity_type) when entity_type in @entity_types do
    from cf in query, where: cf.entity_type == ^entity_type
  end

  def by_field_type(query \\ __MODULE__, field_type) when field_type in @field_types do
    from cf in query, where: cf.field_type == ^field_type
  end

  def required_fields(query \\ __MODULE__) do
    from cf in query, where: cf.is_required == true
  end

  def with_values(query \\ __MODULE__) do
    from cf in query, preload: [:custom_field_values]
  end

  def search(query \\ __MODULE__, term) when is_binary(term) do
    search_term = "%#{term}%"
    from cf in query,
      where: ilike(cf.field_name, ^search_term) or
             ilike(cf.field_label, ^search_term) or
             ilike(cf.help_text, ^search_term)
  end

  def ordered(query \\ __MODULE__, order_by \\ :display_order) do
    from cf in query, order_by: ^order_by
  end

  def ordered_by_display(query \\ __MODULE__) do
    from cf in query, order_by: [asc: :display_order, asc: :field_label]
  end
end
