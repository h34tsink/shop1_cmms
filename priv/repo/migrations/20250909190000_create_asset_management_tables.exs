defmodule Shop1Cmms.Repo.Migrations.CreateAssetManagementTables do
  use Ecto.Migration

  def up do
    # Create asset_location_types table
    create table(:asset_location_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :code, :string, null: false
      add :icon, :string
      add :color, :string
      add :tenant_id, references(:tenants, type: :bigint, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:asset_location_types, [:tenant_id, :code])
    create index(:asset_location_types, [:tenant_id])

    # Enable RLS on asset_location_types
    execute "ALTER TABLE asset_location_types ENABLE ROW LEVEL SECURITY"
    execute "CREATE POLICY asset_location_types_tenant_isolation ON asset_location_types USING (tenant_id = current_setting('app.current_tenant')::bigint)"

    # Create asset_locations table
    create table(:asset_locations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :code, :string, null: false
      add :address, :text
      add :gps_coordinates, :string
      add :area_size, :decimal, precision: 10, scale: 2
      add :area_unit, :string, default: "sqft"
      add :parent_location_id, references(:asset_locations, type: :binary_id, on_delete: :nilify_all)
      add :location_type_id, references(:asset_location_types, type: :binary_id, on_delete: :restrict), null: false
      add :is_active, :boolean, default: true, null: false
      add :tenant_id, references(:tenants, type: :bigint, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:asset_locations, [:tenant_id, :code])
    create index(:asset_locations, [:tenant_id])
    create index(:asset_locations, [:tenant_id, :parent_location_id])
    create index(:asset_locations, [:tenant_id, :location_type_id])
    create index(:asset_locations, [:tenant_id, :is_active])

    # Enable RLS on asset_locations
    execute "ALTER TABLE asset_locations ENABLE ROW LEVEL SECURITY"
    execute "CREATE POLICY asset_locations_tenant_isolation ON asset_locations USING (tenant_id = current_setting('app.current_tenant')::bigint)"

    # Create asset_types table
    create table(:asset_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :code, :string, null: false
      add :category, :string, null: false  # Equipment, Tools, Vehicles, Infrastructure, etc.
      add :icon, :string
      add :color, :string
      add :has_meters, :boolean, default: false, null: false
      add :has_components, :boolean, default: false, null: false
      add :default_pm_frequency, :integer  # days
      add :tenant_id, references(:tenants, type: :bigint, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:asset_types, [:tenant_id, :code])
    create index(:asset_types, [:tenant_id])
    create index(:asset_types, [:tenant_id, :category])

    # Enable RLS on asset_types
    execute "ALTER TABLE asset_types ENABLE ROW LEVEL SECURITY"
    execute "CREATE POLICY asset_types_tenant_isolation ON asset_types USING (tenant_id = current_setting('app.current_tenant')::bigint)"

    # Create asset_status enum type
    execute "CREATE TYPE asset_status AS ENUM ('operational', 'maintenance', 'repair', 'retired', 'disposed')"

    # Create asset_criticality enum type
    execute "CREATE TYPE asset_criticality AS ENUM ('low', 'medium', 'high', 'critical')"

    # Create assets table
    create table(:assets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :asset_number, :string, null: false
      add :name, :string, null: false
      add :description, :text
      add :manufacturer, :string
      add :model, :string
      add :serial_number, :string
      add :barcode, :string
      add :qr_code, :string
      add :purchase_date, :date
      add :purchase_cost, :decimal, precision: 12, scale: 2
      add :warranty_expiry, :date
      add :install_date, :date
      add :commission_date, :date
      add :status, :asset_status, null: false, default: "operational"
      add :criticality, :asset_criticality, null: false, default: "medium"
      add :specifications, :map  # JSON field for custom specifications
      add :notes, :text
      add :parent_asset_id, references(:assets, type: :binary_id, on_delete: :nilify_all)
      add :location_id, references(:asset_locations, type: :binary_id, on_delete: :restrict)
      add :asset_type_id, references(:asset_types, type: :binary_id, on_delete: :restrict), null: false
      add :tenant_id, references(:tenants, type: :bigint, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:assets, [:tenant_id, :asset_number])
    create index(:assets, [:tenant_id])
    create index(:assets, [:tenant_id, :asset_type_id])
    create index(:assets, [:tenant_id, :location_id])
    create index(:assets, [:tenant_id, :parent_asset_id])
    create index(:assets, [:tenant_id, :status])
    create index(:assets, [:tenant_id, :criticality])
    create index(:assets, [:serial_number])
    create index(:assets, [:barcode])

    # Enable RLS on assets
    execute "ALTER TABLE assets ENABLE ROW LEVEL SECURITY"
    execute "CREATE POLICY assets_tenant_isolation ON assets USING (tenant_id = current_setting('app.current_tenant')::bigint)"

    # Create meter_types table
    create table(:meter_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :unit, :string, null: false  # hours, miles, cycles, etc.
      add :data_type, :string, null: false, default: "integer"  # integer, decimal, counter
      add :is_cumulative, :boolean, default: true, null: false
      add :tenant_id, references(:tenants, type: :bigint, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:meter_types, [:tenant_id, :name])
    create index(:meter_types, [:tenant_id])

    # Enable RLS on meter_types
    execute "ALTER TABLE meter_types ENABLE ROW LEVEL SECURITY"
    execute "CREATE POLICY meter_types_tenant_isolation ON meter_types USING (tenant_id = current_setting('app.current_tenant')::bigint)"

    # Create asset_meters table
    create table(:asset_meters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :current_reading, :decimal, precision: 12, scale: 2, default: 0.0, null: false
      add :last_reading_date, :utc_datetime
      add :reading_frequency, :integer  # days between readings
      add :next_reading_due, :date
      add :is_active, :boolean, default: true, null: false
      add :asset_id, references(:assets, type: :binary_id, on_delete: :delete_all), null: false
      add :meter_type_id, references(:meter_types, type: :binary_id, on_delete: :restrict), null: false
      add :tenant_id, references(:tenants, type: :bigint, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:asset_meters, [:asset_id, :meter_type_id])
    create index(:asset_meters, [:tenant_id])
    create index(:asset_meters, [:tenant_id, :asset_id])
    create index(:asset_meters, [:tenant_id, :is_active])
    create index(:asset_meters, [:next_reading_due])

    # Enable RLS on asset_meters
    execute "ALTER TABLE asset_meters ENABLE ROW LEVEL SECURITY"
    execute "CREATE POLICY asset_meters_tenant_isolation ON asset_meters USING (tenant_id = current_setting('app.current_tenant')::bigint)"

    # Create meter_readings table
    create table(:meter_readings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :reading, :decimal, precision: 12, scale: 2, null: false
      add :reading_date, :utc_datetime, null: false
      add :reading_type, :string, null: false, default: "manual"  # manual, automatic, estimated
      add :notes, :text
      add :recorded_by, references(:users, type: :bigint, on_delete: :nilify_all)
      add :asset_meter_id, references(:asset_meters, type: :binary_id, on_delete: :delete_all), null: false
      add :tenant_id, references(:tenants, type: :bigint, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:meter_readings, [:tenant_id])
    create index(:meter_readings, [:tenant_id, :asset_meter_id])
    create index(:meter_readings, [:reading_date])
    create index(:meter_readings, [:recorded_by])

    # Enable RLS on meter_readings
    execute "ALTER TABLE meter_readings ENABLE ROW LEVEL SECURITY"
    execute "CREATE POLICY meter_readings_tenant_isolation ON meter_readings USING (tenant_id = current_setting('app.current_tenant')::bigint)"

    # Create asset_documents table for file attachments
    create table(:asset_documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :file_path, :string, null: false
      add :file_size, :integer
      add :file_type, :string
      add :document_type, :string, null: false  # manual, photo, drawing, certificate, etc.
      add :uploaded_by, references(:users, type: :bigint, on_delete: :nilify_all)
      add :asset_id, references(:assets, type: :binary_id, on_delete: :delete_all), null: false
      add :tenant_id, references(:tenants, type: :bigint, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:asset_documents, [:tenant_id])
    create index(:asset_documents, [:tenant_id, :asset_id])
    create index(:asset_documents, [:document_type])
    create index(:asset_documents, [:uploaded_by])

    # Enable RLS on asset_documents
    execute "ALTER TABLE asset_documents ENABLE ROW LEVEL SECURITY"
    execute "CREATE POLICY asset_documents_tenant_isolation ON asset_documents USING (tenant_id = current_setting('app.current_tenant')::bigint)"

    # Insert default location types
    location_type_id_1 = Ecto.UUID.generate()
    location_type_id_2 = Ecto.UUID.generate()
    location_type_id_3 = Ecto.UUID.generate()
    location_type_id_4 = Ecto.UUID.generate()

    # Insert default asset types
    asset_type_id_1 = Ecto.UUID.generate()
    asset_type_id_2 = Ecto.UUID.generate()
    asset_type_id_3 = Ecto.UUID.generate()
    asset_type_id_4 = Ecto.UUID.generate()

    # Insert default meter types
    meter_type_id_1 = Ecto.UUID.generate()
    meter_type_id_2 = Ecto.UUID.generate()
    meter_type_id_3 = Ecto.UUID.generate()

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Get Shop1 tenant ID for seeding
    shop1_tenant_result = repo().query("SELECT id FROM tenants WHERE name = 'Shop1' LIMIT 1")
    shop1_tenant = case shop1_tenant_result do
      {:ok, %{rows: [[id]]}} -> id
      _ -> nil
    end

    if shop1_tenant do
      # Seed default location types for Shop1
      repo().insert_all("asset_location_types", [
        %{
          id: location_type_id_1,
          name: "Building",
          description: "Main building or structure",
          code: "BUILDING",
          icon: "building",
          color: "#2563eb",
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        },
        %{
          id: location_type_id_2,
          name: "Room",
          description: "Room within a building",
          code: "ROOM",
          icon: "room",
          color: "#059669",
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        },
        %{
          id: location_type_id_3,
          name: "Outdoor Area",
          description: "Outdoor location or yard",
          code: "OUTDOOR",
          icon: "outdoor",
          color: "#dc2626",
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        },
        %{
          id: location_type_id_4,
          name: "Storage",
          description: "Storage area or warehouse",
          code: "STORAGE",
          icon: "storage",
          color: "#7c3aed",
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        }
      ])

      # Seed default asset types for Shop1
      repo().insert_all("asset_types", [
        %{
          id: asset_type_id_1,
          name: "Production Equipment",
          description: "Machinery used in production processes",
          code: "PROD_EQUIP",
          category: "Equipment",
          icon: "cog",
          color: "#2563eb",
          has_meters: true,
          has_components: true,
          default_pm_frequency: 30,
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        },
        %{
          id: asset_type_id_2,
          name: "Vehicle",
          description: "Company vehicles and mobile equipment",
          code: "VEHICLE",
          category: "Vehicle",
          icon: "truck",
          color: "#dc2626",
          has_meters: true,
          has_components: true,
          default_pm_frequency: 90,
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        },
        %{
          id: asset_type_id_3,
          name: "Hand Tool",
          description: "Portable tools and instruments",
          code: "HAND_TOOL",
          category: "Tools",
          icon: "tool",
          color: "#059669",
          has_meters: false,
          has_components: false,
          default_pm_frequency: 180,
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        },
        %{
          id: asset_type_id_4,
          name: "Infrastructure",
          description: "Building systems and infrastructure",
          code: "INFRA",
          category: "Infrastructure",
          icon: "building",
          color: "#7c3aed",
          has_meters: true,
          has_components: true,
          default_pm_frequency: 365,
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        }
      ])

      # Seed default meter types for Shop1
      repo().insert_all("meter_types", [
        %{
          id: meter_type_id_1,
          name: "Operating Hours",
          description: "Total hours of operation",
          unit: "hours",
          data_type: "decimal",
          is_cumulative: true,
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        },
        %{
          id: meter_type_id_2,
          name: "Mileage",
          description: "Total miles or kilometers driven",
          unit: "miles",
          data_type: "decimal",
          is_cumulative: true,
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        },
        %{
          id: meter_type_id_3,
          name: "Cycle Count",
          description: "Number of operational cycles",
          unit: "cycles",
          data_type: "integer",
          is_cumulative: true,
          tenant_id: shop1_tenant,
          inserted_at: now,
          updated_at: now
        }
      ])
    end
  end

  def down do
    drop table(:meter_readings)
    drop table(:asset_documents)
    drop table(:asset_meters)
    drop table(:meter_types)
    drop table(:assets)
    drop table(:asset_types)
    drop table(:asset_locations)
    drop table(:asset_location_types)

    execute "DROP TYPE IF EXISTS asset_status"
    execute "DROP TYPE IF EXISTS asset_criticality"
  end
end
