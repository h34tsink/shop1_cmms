defmodule Shop1Cmms.Repo.Migrations.CreatePmSchedulesAndDocuments do
  use Ecto.Migration

  def change do
    # PM Schedule frequency enum
    execute "CREATE TYPE pm_frequency AS ENUM ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'semiannual', 'annual', 'biennial', 'meter_based', 'condition_based')",
            "DROP TYPE pm_frequency"

    # Document type enum
    execute "CREATE TYPE document_type AS ENUM ('manual', 'drawing', 'specification', 'procedure', 'work_instruction', 'certificate', 'calibration', 'warranty', 'other')",
            "DROP TYPE document_type"

    # PM Schedules Table
    create table(:pm_schedules, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :schedule_number, :string, null: false
      add :title, :string, null: false
      add :description, :text
      
      # Scheduling
      add :frequency, :pm_frequency, null: false
      add :frequency_interval, :integer, default: 1
      add :meter_threshold, :decimal, precision: 12, scale: 2
      add :meter_unit, :string
      
      # Work Instructions
      add :work_instructions, :text
      add :estimated_duration, :decimal, precision: 8, scale: 2
      add :required_skills, {:array, :string}, default: []
      add :required_tools, {:array, :string}, default: []
      add :required_parts, :jsonb, default: "[]"
      
      # Safety
      add :safety_notes, :text
      add :ppe_required, {:array, :string}, default: []
      
      # Scheduling info
      add :last_completed_date, :utc_datetime
      add :next_due_date, :utc_datetime
      add :is_active, :boolean, default: true
      
      # References
      add :asset_id, references(:assets, on_delete: :delete_all, type: :binary_id), null: false
      add :created_by, references(:users, on_delete: :nilify_all, type: :integer)
      add :updated_by, references(:users, on_delete: :nilify_all, type: :integer)
      
      # Multi-tenancy
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :integer), null: false
      
      timestamps(type: :utc_datetime)
    end

    create index(:pm_schedules, [:tenant_id])
    create index(:pm_schedules, [:asset_id])
    create index(:pm_schedules, [:next_due_date])
    create index(:pm_schedules, [:is_active])
    create unique_index(:pm_schedules, [:schedule_number, :tenant_id])

    # PM Schedule Components Table (for multiple schedules per asset component)
    create table(:pm_schedule_components, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :component_name, :string, null: false
      add :component_description, :text
      add :component_location, :string
      
      add :pm_schedule_id, references(:pm_schedules, on_delete: :delete_all, type: :binary_id), null: false
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :integer), null: false
      
      timestamps(type: :utc_datetime)
    end

    create index(:pm_schedule_components, [:pm_schedule_id])
    create index(:pm_schedule_components, [:tenant_id])

    # Asset Documents Table - Alter existing table to add new fields
    alter table(:asset_documents) do
      add_if_not_exists :document_number, :string
      add_if_not_exists :title, :string
      add_if_not_exists :file_name, :string
      add_if_not_exists :mime_type, :string
      add_if_not_exists :file_url, :string
      add_if_not_exists :version, :string
      add_if_not_exists :revision_date, :date
      add_if_not_exists :expiry_date, :date
      add_if_not_exists :issued_by, :string
      add_if_not_exists :approved_by, :string
      add_if_not_exists :tags, {:array, :string}, default: []
      add_if_not_exists :is_active, :boolean, default: true
      add_if_not_exists :pm_schedule_id, references(:pm_schedules, on_delete: :delete_all, type: :binary_id)
      add_if_not_exists :work_order_id, references(:work_orders, on_delete: :delete_all, type: :binary_id)
    end

    create_if_not_exists index(:asset_documents, [:pm_schedule_id])
    create_if_not_exists index(:asset_documents, [:work_order_id])
    create_if_not_exists index(:asset_documents, [:is_active])

    # PM Schedule Checklist Items Table
    create table(:pm_checklist_items, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :sequence, :integer, null: false
      add :item_description, :text, null: false
      add :expected_result, :text
      add :pass_fail, :boolean, default: false
      add :requires_measurement, :boolean, default: false
      add :measurement_unit, :string
      add :min_value, :decimal, precision: 12, scale: 4
      add :max_value, :decimal, precision: 12, scale: 4
      
      add :pm_schedule_id, references(:pm_schedules, on_delete: :delete_all, type: :binary_id), null: false
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :integer), null: false
      
      timestamps(type: :utc_datetime)
    end

    create index(:pm_checklist_items, [:pm_schedule_id])
    create index(:pm_checklist_items, [:tenant_id])

    # RLS Policies
    execute """
    ALTER TABLE pm_schedules ENABLE ROW LEVEL SECURITY;
    """,
    """
    ALTER TABLE pm_schedules DISABLE ROW LEVEL SECURITY;
    """

    execute """
    CREATE POLICY pm_schedules_tenant_isolation ON pm_schedules
    USING (tenant_id::text = current_setting('app.current_tenant_id', true));
    """,
    """
    DROP POLICY IF EXISTS pm_schedules_tenant_isolation ON pm_schedules;
    """

    execute """
    ALTER TABLE pm_schedule_components ENABLE ROW LEVEL SECURITY;
    """,
    """
    ALTER TABLE pm_schedule_components DISABLE ROW LEVEL SECURITY;
    """

    execute """
    CREATE POLICY pm_schedule_components_tenant_isolation ON pm_schedule_components
    USING (tenant_id::text = current_setting('app.current_tenant_id', true));
    """,
    """
    DROP POLICY IF EXISTS pm_schedule_components_tenant_isolation ON pm_schedule_components;
    """

    execute """
    ALTER TABLE pm_checklist_items ENABLE ROW LEVEL SECURITY;
    """,
    """
    ALTER TABLE pm_checklist_items DISABLE ROW LEVEL SECURITY;
    """

    execute """
    CREATE POLICY pm_checklist_items_tenant_isolation ON pm_checklist_items
    USING (tenant_id::text = current_setting('app.current_tenant_id', true));
    """,
    """
    DROP POLICY IF EXISTS pm_checklist_items_tenant_isolation ON pm_checklist_items;
    """
  end
end
