defmodule Shop1Cmms.Factory do
  @moduledoc """
  Test data factory for generating test fixtures
  """
  
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Tenants.Tenant
  alias Shop1Cmms.Accounts.{User, CMMSUserRole, UserTenantAssignment}
  alias Shop1Cmms.Assets.{Asset, AssetType, AssetLocation, AssetLocationType, Component}
  alias Shop1Cmms.Maintenance.{PmSchedule, PmExecution}
  alias Shop1Cmms.WorkOrders.WorkOrder
  alias Shop1Cmms.Metadata.{Manufacturer, Skill, Tool, PpeItem}
  alias Shop1Cmms.AuditLog

  @doc """
  Build a struct with given attributes (not inserted)
  """
  def build(factory_name, attrs \\ %{})
  
  def build(:tenant, attrs) do
    %Tenant{
      name: attrs[:name] || "Test Tenant #{System.unique_integer([:positive])}",
      code: attrs[:code] || "TEST#{System.unique_integer([:positive])}",
      is_active: Map.get(attrs, :is_active, true)
    }
    |> struct!(attrs)
  end

  def build(:user, attrs) do
    %User{
      username: attrs[:username] || "user#{System.unique_integer([:positive])}",
      password_hash: attrs[:password_hash] || Pbkdf2.hash_pwd_salt("password123"),
      is_active: Map.get(attrs, :is_active, true),
      cmms_enabled: Map.get(attrs, :cmms_enabled, true)
    }
    |> struct!(attrs)
  end

  def build(:cmms_user_role, attrs) do
    %CMMSUserRole{
      name: attrs[:name] || "technician",
      display_name: attrs[:display_name] || "Technician",
      description: attrs[:description] || "Test role",
      permissions: attrs[:permissions] || [],
      is_system_role: Map.get(attrs, :is_system_role, false),
      is_active: Map.get(attrs, :is_active, true)
    }
    |> struct!(attrs)
  end

  def build(:user_tenant_assignment, attrs) do
    %UserTenantAssignment{
      user_id: attrs[:user_id],
      tenant_id: attrs[:tenant_id] || 1,
      role_id: attrs[:role_id],
      default_site_id: attrs[:default_site_id],
      assigned_by_id: attrs[:assigned_by_id],
      assigned_at: attrs[:assigned_at] || NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      is_active: Map.get(attrs, :is_active, true),
      notes: attrs[:notes]
    }
    |> struct!(attrs)
  end

  def build(:asset_type, attrs) do
    unique_num = System.unique_integer([:positive])
    %AssetType{
      name: attrs[:name] || "Equipment Type #{unique_num}",
      code: attrs[:code] || "TYPE#{unique_num}",
      category: attrs[:category] || "Equipment",
      description: attrs[:description] || "Test equipment type",
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  def build(:asset_location_type, attrs) do
    unique_num = System.unique_integer([:positive])
    %AssetLocationType{
      name: attrs[:name] || "Location Type #{unique_num}",
      code: attrs[:code] || "LOC#{unique_num}",
      description: attrs[:description],
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  def build(:asset_location, attrs) do
    unique_num = System.unique_integer([:positive])
    %AssetLocation{
      name: attrs[:name] || "Location #{unique_num}",
      code: attrs[:code] || "LOC#{unique_num}",
      description: attrs[:description],
      location_type_id: attrs[:location_type_id],
      tenant_id: attrs[:tenant_id] || 1,
      is_active: Map.get(attrs, :is_active, true)
    }
    |> struct!(attrs)
  end

  def build(:asset, attrs) do
    %Asset{
      asset_number: attrs[:asset_number] || "AST#{System.unique_integer([:positive])}",
      name: attrs[:name] || "Test Asset #{System.unique_integer([:positive])}",
      description: attrs[:description] || "Test asset description",
      status: attrs[:status] || :operational,
      criticality: attrs[:criticality] || :medium,
      tenant_id: attrs[:tenant_id] || 1,
      asset_type_id: attrs[:asset_type_id],
      location_id: attrs[:location_id]
    }
    |> struct!(attrs)
  end

  def build(:component, attrs) do
    %Component{
      name: attrs[:name] || "Component #{System.unique_integer([:positive])}",
      description: attrs[:description],
      component_type: attrs[:component_type] || "Motor",
      manufacturer: attrs[:manufacturer],
      model: attrs[:model],
      serial_number: attrs[:serial_number] || "SN-#{System.unique_integer([:positive])}",
      status: attrs[:status] || :active,
      install_date: attrs[:install_date],
      asset_id: attrs[:asset_id],
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  def build(:pm_schedule, attrs) do
    %PmSchedule{
      schedule_number: attrs[:schedule_number] || "PM#{System.unique_integer([:positive])}",
      title: attrs[:title] || "Test PM Schedule",
      description: attrs[:description] || "Test PM description",
      frequency: attrs[:frequency] || :monthly,
      frequency_interval: attrs[:frequency_interval] || 1,
      estimated_duration: attrs[:estimated_duration] || Decimal.new("1.0"),
      is_active: Map.get(attrs, :is_active, true),
      asset_id: attrs[:asset_id],
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  def build(:pm_execution, attrs) do
    %PmExecution{
      execution_number: attrs[:execution_number] || "EXE#{System.unique_integer([:positive])}",
      execution_date: attrs[:execution_date] || DateTime.utc_now(),
      status: attrs[:status] || :in_progress,
      pm_schedule_id: attrs[:pm_schedule_id],
      asset_id: attrs[:asset_id],
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  def build(:work_order, attrs) do
    %WorkOrder{
      work_order_number: attrs[:work_order_number] || "WO#{System.unique_integer([:positive])}",
      title: attrs[:title] || "Test Work Order",
      description: attrs[:description] || "Test work order description",
      priority: attrs[:priority] || :medium,
      status: attrs[:status] || :open,
      type: attrs[:type] || :corrective,
      asset_id: attrs[:asset_id],
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  def build(:manufacturer, attrs) do
    %Manufacturer{
      name: attrs[:name] || "Manufacturer #{System.unique_integer([:positive])}",
      website: attrs[:website],
      notes: attrs[:notes],
      is_active: Map.get(attrs, :is_active, true),
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  def build(:audit_log, attrs) do
    %AuditLog{
      entity_type: attrs[:entity_type] || "component",
      entity_id: attrs[:entity_id] || Ecto.UUID.generate(),
      action: attrs[:action] || "created",
      changes: attrs[:changes] || %{},
      metadata: attrs[:metadata] || %{},
      performed_by_id: attrs[:performed_by_id],
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  @doc """
  Build and insert into database
  """
  def insert(factory_name, attrs \\ %{})
  
  # Special handling for assets to auto-create dependencies if not provided
  def insert(:asset, attrs) do
    attrs_map = Enum.into(attrs, %{})
    tenant_id = attrs_map[:tenant_id] || 1
    
    # Ensure tenant exists
    ensure_tenant_exists(tenant_id)
    
    # Auto-create asset_type if not provided
    attrs_with_type = if attrs_map[:asset_type_id] do
      attrs_map
    else
      asset_type = insert(:asset_type, tenant_id: tenant_id)
      Map.put(attrs_map, :asset_type_id, asset_type.id)
    end
    
    :asset
    |> build(attrs_with_type)
    |> Repo.insert!()
  end
  
  # Special handling for tenant-dependent types
  def insert(factory_name, attrs) when factory_name in [:asset_type, :asset_location, :asset_location_type] do
    attrs_map = Enum.into(attrs, %{})
    tenant_id = attrs_map[:tenant_id] || 1
    ensure_tenant_exists(tenant_id)
    
    factory_name
    |> build(attrs_map)
    |> Repo.insert!()
  end
  
  # Special handling for component - ensure asset exists
  def insert(:component, attrs) do
    attrs_map = Enum.into(attrs, %{})
    
    # If no asset_id provided, create a default asset
    attrs_with_asset = if attrs_map[:asset_id] do
      attrs_map
    else
      asset = insert(:asset, tenant_id: attrs_map[:tenant_id] || 1)
      Map.put(attrs_map, :asset_id, asset.id)
    end
    
    :component
    |> build(attrs_with_asset)
    |> Repo.insert!()
  end
  
  def insert(factory_name, attrs) do
    attrs_map = Enum.into(attrs, %{})
    factory_name
    |> build(attrs_map)
    |> Repo.insert!()
  end
  
  # Ensure tenant exists before creating tenant-dependent records
  defp ensure_tenant_exists(tenant_id) do
    case Repo.get(Tenant, tenant_id) do
      nil -> 
        %Tenant{id: tenant_id, name: "Test Tenant #{tenant_id}", code: "TEST#{tenant_id}", is_active: true}
        |> Repo.insert!()
      tenant -> 
        tenant
    end
  end

  @doc """
  Insert a list of records
  """
  def insert_list(count, factory_name, attrs \\ %{})
  
  def insert_list(count, _factory_name, _attrs) when count <= 0, do: []
  
  def insert_list(count, factory_name, attrs) do
    Enum.map(1..count, fn _ -> insert(factory_name, attrs) end)
  end

  @doc """
  Build a complete asset with related data
  """
  def insert_asset_with_components(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || 1
    
    asset_type = insert(:asset_type, tenant_id: tenant_id)
    location_type = insert(:asset_location_type, tenant_id: tenant_id)
    location = insert(:asset_location, tenant_id: tenant_id, location_type_id: location_type.id)
    
    asset = insert(:asset,
      tenant_id: tenant_id,
      asset_type_id: asset_type.id,
      location_id: location.id
    )
    
    components = insert_list(
      attrs[:component_count] || 3,
      :component,
      asset_id: asset.id,
      tenant_id: tenant_id
    )
    
    %{asset: asset, components: components, asset_type: asset_type, location: location}
  end

  @doc """
  Build a complete PM schedule with related data
  """
  def insert_pm_schedule_with_asset(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || 1
    
    %{asset: asset} = insert_asset_with_components(tenant_id: tenant_id)
    
    pm_schedule = insert(:pm_schedule,
      asset_id: asset.id,
      tenant_id: tenant_id
    )
    
    %{pm_schedule: pm_schedule, asset: asset}
  end

  @doc """
  Build a work order with asset
  """
  def insert_work_order_with_asset(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || 1
    
    %{asset: asset} = insert_asset_with_components(tenant_id: tenant_id)
    
    work_order = insert(:work_order,
      asset_id: asset.id,
      tenant_id: tenant_id
    )
    
    %{work_order: work_order, asset: asset}
  end

  @doc """
  Get or create a default technician role for testing
  """
  def get_or_create_role(role_name \\ "technician") do
    case Repo.get_by(CMMSUserRole, name: role_name) do
      nil ->
        %CMMSUserRole{
          name: role_name,
          display_name: String.capitalize(role_name),
          description: "Test #{role_name} role",
          permissions: [],
          is_system_role: true,
          is_active: true
        }
        |> Repo.insert!()
      role ->
        role
    end
  end

  @doc """
  Create a user with tenant assignment and role
  """
  def insert_user_with_tenant(attrs \\ %{}) do
    # Convert to map if needed
    attrs = if is_list(attrs), do: Enum.into(attrs, %{}), else: attrs
    
    tenant_id = attrs[:tenant_id] || 1
    role_name = attrs[:role_name] || "technician"
    
    # Ensure tenant and role exist
    ensure_tenant_exists(tenant_id)
    role = get_or_create_role(role_name)
    
    # Create user (remove tenant_id from attrs as it's not a field on User)
    user_attrs = Map.drop(attrs, [:tenant_id, :role_name])
    user = insert(:user, user_attrs)
    
    # Create tenant assignment
    insert(:user_tenant_assignment,
      user_id: user.id,
      tenant_id: tenant_id,
      role_id: role.id,
      is_active: true
    )
    
    # Add tenant_id to user struct for convenience in tests
    Map.put(user, :tenant_id, tenant_id)
  end
end
