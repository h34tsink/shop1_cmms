defmodule Shop1Cmms.Factory do
  @moduledoc """
  Test data factory for generating test fixtures
  """
  
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Tenants.Tenant
  alias Shop1Cmms.Accounts.User
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
      password_hash: attrs[:password_hash] || Bcrypt.hash_pwd_salt("password123"),
      is_active: Map.get(attrs, :is_active, true),
      cmms_enabled: Map.get(attrs, :cmms_enabled, true)
    }
    |> struct!(attrs)
  end

  def build(:asset_type, attrs) do
    %AssetType{
      name: attrs[:name] || "Equipment Type #{System.unique_integer([:positive])}",
      description: attrs[:description] || "Test equipment type",
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  def build(:asset_location_type, attrs) do
    %AssetLocationType{
      name: attrs[:name] || "Location Type #{System.unique_integer([:positive])}",
      description: attrs[:description],
      tenant_id: attrs[:tenant_id] || 1
    }
    |> struct!(attrs)
  end

  def build(:asset_location, attrs) do
    %AssetLocation{
      name: attrs[:name] || "Location #{System.unique_integer([:positive])}",
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
      asset_type_id: attrs[:asset_type_id]
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
  def insert(factory_name, attrs \\ %{}) do
    factory_name
    |> build(attrs)
    |> Repo.insert!()
  end

  @doc """
  Insert a list of records
  """
  def insert_list(count, factory_name, attrs \\ %{}) when count > 0 do
    Enum.map(1..count, fn _ -> insert(factory_name, attrs) end)
  end

  @doc """
  Build a complete asset with related data
  """
  def insert_asset_with_components(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || 1
    
    asset_type = insert(:asset_type, tenant_id: tenant_id)
    location = insert(:asset_location, tenant_id: tenant_id)
    
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
end
