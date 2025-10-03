defmodule Shop1Cmms.Metadata do
  @moduledoc """
  The Metadata context for managing manufacturers, departments, suppliers,
  priority codes, maintenance categories, PM tags (skills, tools, PPE), and custom fields.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo

  alias Shop1Cmms.Metadata.{
    Manufacturer, Department, Supplier, PriorityCode,
    MaintenanceCategory, CustomField, CustomFieldValue, PmTag
  }

  ## Manufacturers

  @doc """
  Returns the list of manufacturers for a tenant.
  """
  def list_manufacturers(tenant_id, opts \\ []) do
    query = Manufacturer
    |> Manufacturer.by_tenant(tenant_id)
    |> Manufacturer.ordered()

    query = if opts[:active_only], do: Manufacturer.active(query), else: query
    query = if search_term = opts[:search], do: Manufacturer.search(query, search_term), else: query

    Repo.all(query)
  end

  @doc """
  Gets a single manufacturer.
  """
  def get_manufacturer!(id), do: Repo.get!(Manufacturer, id)

  @doc """
  Gets a single manufacturer for a tenant.
  """
  def get_manufacturer!(tenant_id, id) do
    Manufacturer
    |> Manufacturer.by_tenant(tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a manufacturer.
  """
  def create_manufacturer(attrs \\ %{}) do
    %Manufacturer{}
    |> Manufacturer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a manufacturer.
  """
  def update_manufacturer(%Manufacturer{} = manufacturer, attrs) do
    manufacturer
    |> Manufacturer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a manufacturer.
  """
  def delete_manufacturer(%Manufacturer{} = manufacturer) do
    Repo.delete(manufacturer)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking manufacturer changes.
  """
  def change_manufacturer(%Manufacturer{} = manufacturer, attrs \\ %{}) do
    Manufacturer.changeset(manufacturer, attrs)
  end

  ## Departments

  @doc """
  Returns the list of departments for a tenant.
  """
  def list_departments(tenant_id, opts \\ []) do
    query = Department
    |> Department.by_tenant(tenant_id)
    |> Department.ordered()

    query = if opts[:active_only], do: Department.active(query), else: query
    query = if opts[:root_only], do: Department.root_departments(query), else: query
    query = if opts[:with_parent], do: Department.with_parent(query), else: query
    query = if opts[:with_children], do: Department.with_children(query), else: query
    query = if search_term = opts[:search], do: Department.search(query, search_term), else: query

    Repo.all(query)
  end

  @doc """
  Gets a single department.
  """
  def get_department!(id), do: Repo.get!(Department, id)

  @doc """
  Gets a single department for a tenant.
  """
  def get_department!(tenant_id, id) do
    Department
    |> Department.by_tenant(tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a department.
  """
  def create_department(attrs \\ %{}) do
    %Department{}
    |> Department.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a department.
  """
  def update_department(%Department{} = department, attrs) do
    department
    |> Department.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a department.
  """
  def delete_department(%Department{} = department) do
    Repo.delete(department)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking department changes.
  """
  def change_department(%Department{} = department, attrs \\ %{}) do
    Department.changeset(department, attrs)
  end

  ## Suppliers

  @doc """
  Returns the list of suppliers for a tenant.
  """
  def list_suppliers(tenant_id, opts \\ []) do
    query = Supplier
    |> Supplier.by_tenant(tenant_id)
    |> Supplier.ordered()

    query = if opts[:active_only], do: Supplier.active(query), else: query
    query = if type = opts[:type], do: Supplier.by_type(query, type), else: query
    query = if search_term = opts[:search], do: Supplier.search(query, search_term), else: query

    Repo.all(query)
  end

  @doc """
  Gets a single supplier.
  """
  def get_supplier!(id), do: Repo.get!(Supplier, id)

  @doc """
  Gets a single supplier for a tenant.
  """
  def get_supplier!(tenant_id, id) do
    Supplier
    |> Supplier.by_tenant(tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a supplier.
  """
  def create_supplier(attrs \\ %{}) do
    %Supplier{}
    |> Supplier.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a supplier.
  """
  def update_supplier(%Supplier{} = supplier, attrs) do
    supplier
    |> Supplier.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a supplier.
  """
  def delete_supplier(%Supplier{} = supplier) do
    Repo.delete(supplier)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking supplier changes.
  """
  def change_supplier(%Supplier{} = supplier, attrs \\ %{}) do
    Supplier.changeset(supplier, attrs)
  end

  ## Priority Codes

  @doc """
  Returns the list of priority codes for a tenant.
  """
  def list_priority_codes(tenant_id, opts \\ []) do
    query = PriorityCode
    |> PriorityCode.by_tenant(tenant_id)
    |> PriorityCode.ordered_by_level()

    query = if opts[:active_only], do: PriorityCode.active(query), else: query
    query = if opts[:with_escalation], do: PriorityCode.with_escalation(query), else: query
    query = if search_term = opts[:search], do: PriorityCode.search(query, search_term), else: query

    Repo.all(query)
  end

  @doc """
  Gets a single priority code.
  """
  def get_priority_code!(id), do: Repo.get!(PriorityCode, id)

  @doc """
  Gets a single priority code for a tenant.
  """
  def get_priority_code!(tenant_id, id) do
    PriorityCode
    |> PriorityCode.by_tenant(tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a priority code.
  """
  def create_priority_code(attrs \\ %{}) do
    %PriorityCode{}
    |> PriorityCode.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a priority code.
  """
  def update_priority_code(%PriorityCode{} = priority_code, attrs) do
    priority_code
    |> PriorityCode.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a priority code.
  """
  def delete_priority_code(%PriorityCode{} = priority_code) do
    Repo.delete(priority_code)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking priority code changes.
  """
  def change_priority_code(%PriorityCode{} = priority_code, attrs \\ %{}) do
    PriorityCode.changeset(priority_code, attrs)
  end

  ## Maintenance Categories

  @doc """
  Returns the list of maintenance categories for a tenant.
  """
  def list_maintenance_categories(tenant_id, opts \\ []) do
    query = MaintenanceCategory
    |> MaintenanceCategory.by_tenant(tenant_id)
    |> MaintenanceCategory.ordered()

    query = if opts[:active_only], do: MaintenanceCategory.active(query), else: query
    query = if type = opts[:type], do: MaintenanceCategory.by_type(query, type), else: query
    query = if opts[:root_only], do: MaintenanceCategory.root_categories(query), else: query
    query = if opts[:with_parent], do: MaintenanceCategory.with_parent(query), else: query
    query = if opts[:with_children], do: MaintenanceCategory.with_children(query), else: query
    query = if opts[:requires_shutdown], do: MaintenanceCategory.requires_shutdown(query), else: query
    query = if search_term = opts[:search], do: MaintenanceCategory.search(query, search_term), else: query

    Repo.all(query)
  end

  @doc """
  Gets a single maintenance category.
  """
  def get_maintenance_category!(id), do: Repo.get!(MaintenanceCategory, id)

  @doc """
  Gets a single maintenance category for a tenant.
  """
  def get_maintenance_category!(tenant_id, id) do
    MaintenanceCategory
    |> MaintenanceCategory.by_tenant(tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a maintenance category.
  """
  def create_maintenance_category(attrs \\ %{}) do
    %MaintenanceCategory{}
    |> MaintenanceCategory.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a maintenance category.
  """
  def update_maintenance_category(%MaintenanceCategory{} = maintenance_category, attrs) do
    maintenance_category
    |> MaintenanceCategory.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a maintenance category.
  """
  def delete_maintenance_category(%MaintenanceCategory{} = maintenance_category) do
    Repo.delete(maintenance_category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking maintenance category changes.
  """
  def change_maintenance_category(%MaintenanceCategory{} = maintenance_category, attrs \\ %{}) do
    MaintenanceCategory.changeset(maintenance_category, attrs)
  end

  ## Custom Fields

  @doc """
  Returns the list of custom fields for a tenant and entity type.
  """
  def list_custom_fields(tenant_id, entity_type \\ nil, opts \\ []) do
    query = CustomField
    |> CustomField.by_tenant(tenant_id)
    |> CustomField.ordered_by_display()

    query = if entity_type, do: CustomField.by_entity_type(query, entity_type), else: query
    query = if opts[:active_only], do: CustomField.active(query), else: query
    query = if opts[:required_only], do: CustomField.required_fields(query), else: query
    query = if opts[:with_values], do: CustomField.with_values(query), else: query
    query = if search_term = opts[:search], do: CustomField.search(query, search_term), else: query

    Repo.all(query)
  end

  @doc """
  Gets a single custom field.
  """
  def get_custom_field!(id), do: Repo.get!(CustomField, id)

  @doc """
  Gets a single custom field for a tenant.
  """
  def get_custom_field!(tenant_id, id) do
    CustomField
    |> CustomField.by_tenant(tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a custom field.
  """
  def create_custom_field(attrs \\ %{}) do
    %CustomField{}
    |> CustomField.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a custom field.
  """
  def update_custom_field(%CustomField{} = custom_field, attrs) do
    custom_field
    |> CustomField.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a custom field.
  """
  def delete_custom_field(%CustomField{} = custom_field) do
    Repo.delete(custom_field)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking custom field changes.
  """
  def change_custom_field(%CustomField{} = custom_field, attrs \\ %{}) do
    CustomField.changeset(custom_field, attrs)
  end

  ## Custom Field Values

  @doc """
  Returns the list of custom field values for an entity.
  """
  def list_custom_field_values(tenant_id, entity_type, entity_id) do
    CustomFieldValue
    |> CustomFieldValue.by_tenant(tenant_id)
    |> CustomFieldValue.by_entity(entity_type, entity_id)
    |> CustomFieldValue.with_custom_field()
    |> Repo.all()
  end

  @doc """
  Gets a single custom field value.
  """
  def get_custom_field_value!(id), do: Repo.get!(CustomFieldValue, id)

  @doc """
  Gets or creates a custom field value for an entity and field.
  """
  def get_or_create_custom_field_value(tenant_id, custom_field_id, entity_type, entity_id) do
    case Repo.get_by(CustomFieldValue,
           custom_field_id: custom_field_id,
           entity_type: entity_type,
           entity_id: entity_id) do
      nil ->
        create_custom_field_value(%{
          tenant_id: tenant_id,
          custom_field_id: custom_field_id,
          entity_type: entity_type,
          entity_id: entity_id,
          field_value: nil
        })
      value -> {:ok, value}
    end
  end

  @doc """
  Creates a custom field value.
  """
  def create_custom_field_value(attrs \\ %{}) do
    %CustomFieldValue{}
    |> CustomFieldValue.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a custom field value.
  """
  def update_custom_field_value(%CustomFieldValue{} = custom_field_value, attrs) do
    custom_field_value
    |> CustomFieldValue.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a custom field value.
  """
  def delete_custom_field_value(%CustomFieldValue{} = custom_field_value) do
    Repo.delete(custom_field_value)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking custom field value changes.
  """
  def change_custom_field_value(%CustomFieldValue{} = custom_field_value, attrs \\ %{}) do
    CustomFieldValue.changeset(custom_field_value, attrs)
  end

  @doc """
  Saves custom field values for an entity.
  """
  def save_custom_field_values(tenant_id, entity_type, entity_id, field_values) when is_map(field_values) do
    Repo.transaction(fn ->
      for {custom_field_id, field_value} <- field_values do
        case get_or_create_custom_field_value(tenant_id, custom_field_id, entity_type, entity_id) do
          {:ok, cfv} ->
            update_custom_field_value(cfv, %{field_value: field_value})
          {:error, error} ->
            Repo.rollback(error)
        end
      end
    end)
  end

  ## Utility functions

  @doc """
  Returns available supplier types.
  """
  def supplier_types, do: Supplier.supplier_types()

  @doc """
  Returns available maintenance types.
  """
  def maintenance_types, do: MaintenanceCategory.maintenance_types()

  @doc """
  Returns available custom field types.
  """
  def custom_field_types, do: CustomField.field_types()

  @doc """
  Returns available entity types for custom fields.
  """
  def custom_field_entity_types, do: CustomField.entity_types()

  ## PM Tags (Skills, Tools, PPE)

  @doc """
  Returns the list of PM tags for a tenant, optionally filtered by type.
  """
  def list_pm_tags(tenant_id, opts \\ []) do
    query = PmTag
    |> PmTag.by_tenant(tenant_id)
    |> PmTag.ordered()

    query = if type = opts[:type], do: PmTag.by_type(query, type), else: query
    query = if opts[:active_only], do: PmTag.active(query), else: query
    query = if search_term = opts[:search], do: PmTag.search(query, search_term), else: query

    Repo.all(query)
  end

  @doc """
  Gets a single PM tag.
  """
  def get_pm_tag!(id), do: Repo.get!(PmTag, id)

  @doc """
  Gets a single PM tag for a tenant.
  """
  def get_pm_tag!(tenant_id, id) do
    PmTag
    |> PmTag.by_tenant(tenant_id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a PM tag.
  """
  def create_pm_tag(attrs \\ %{}) do
    %PmTag{}
    |> PmTag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a PM tag.
  """
  def update_pm_tag(%PmTag{} = pm_tag, attrs) do
    pm_tag
    |> PmTag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PM tag.
  """
  def delete_pm_tag(%PmTag{} = pm_tag) do
    Repo.delete(pm_tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking PM tag changes.
  """
  def change_pm_tag(%PmTag{} = pm_tag, attrs \\ %{}) do
    PmTag.changeset(pm_tag, attrs)
  end

  @doc """
  Gets or creates a PM tag by name and type.
  Auto-creates if it doesn't exist and increments usage count.
  """
  def get_or_create_pm_tag(tenant_id, tag_name, tag_type) do
    tag_name = String.trim(tag_name)
    
    case Repo.get_by(PmTag, tenant_id: tenant_id, tag_type: tag_type, name: tag_name) do
      nil ->
        # Create new tag
        create_pm_tag(%{
          name: tag_name,
          tag_type: tag_type,
          tenant_id: tenant_id,
          usage_count: 1
        })
      
      tag ->
        # Increment usage count
        update_pm_tag(tag, %{usage_count: tag.usage_count + 1})
    end
  end

  @doc """
  Returns available PM tag types.
  """
  def pm_tag_types, do: PmTag.tag_types()
end
