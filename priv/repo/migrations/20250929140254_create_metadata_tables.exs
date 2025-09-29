defmodule Shop1Cmms.Repo.Migrations.CreateMetadataTables do
  use Ecto.Migration

  def change do
    # Manufacturers table
    create table(:manufacturers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :code, :string
      add :description, :text
      add :website, :string
      add :contact_email, :string
      add :contact_phone, :string
      add :address, :text
      add :notes, :text
      add :is_active, :boolean, default: true, null: false
      add :tenant_id, references(:tenants, type: :integer, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:manufacturers, [:tenant_id, :name], name: :manufacturers_tenant_name_index)
    create unique_index(:manufacturers, [:tenant_id, :code], where: "code IS NOT NULL", name: :manufacturers_tenant_code_index)
    create index(:manufacturers, [:tenant_id, :is_active])
    create index(:manufacturers, [:name])

    # Departments table
    create table(:departments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :code, :string
      add :description, :text
      add :manager_name, :string
      add :manager_email, :string
      add :cost_center, :string
      add :budget_code, :string
      add :parent_department_id, references(:departments, type: :binary_id, on_delete: :nilify_all)
      add :is_active, :boolean, default: true, null: false
      add :tenant_id, references(:tenants, type: :integer, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:departments, [:tenant_id, :name], name: :departments_tenant_name_index)
    create unique_index(:departments, [:tenant_id, :code], where: "code IS NOT NULL", name: :departments_tenant_code_index)
    create index(:departments, [:tenant_id, :is_active])
    create index(:departments, [:parent_department_id])
    create index(:departments, [:name])

    # Suppliers table
    create table(:suppliers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :code, :string
      add :description, :text
      add :type, :string # vendor, contractor, service_provider
      add :contact_name, :string
      add :contact_email, :string
      add :contact_phone, :string
      add :address, :text
      add :website, :string
      add :tax_id, :string
      add :payment_terms, :string
      add :credit_rating, :string
      add :notes, :text
      add :is_active, :boolean, default: true, null: false
      add :tenant_id, references(:tenants, type: :integer, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:suppliers, [:tenant_id, :name], name: :suppliers_tenant_name_index)
    create unique_index(:suppliers, [:tenant_id, :code], where: "code IS NOT NULL", name: :suppliers_tenant_code_index)
    create index(:suppliers, [:tenant_id, :is_active])
    create index(:suppliers, [:type])
    create index(:suppliers, [:name])

    # Priority codes table
    create table(:priority_codes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :code, :string
      add :description, :text
      add :level, :integer, null: false # 1=Low, 2=Medium, 3=High, 4=Critical
      add :color, :string # hex color code for UI
      add :sla_hours, :integer # service level agreement in hours
      add :auto_escalate, :boolean, default: false
      add :escalation_hours, :integer
      add :is_active, :boolean, default: true, null: false
      add :tenant_id, references(:tenants, type: :integer, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:priority_codes, [:tenant_id, :name], name: :priority_codes_tenant_name_index)
    create unique_index(:priority_codes, [:tenant_id, :code], where: "code IS NOT NULL", name: :priority_codes_tenant_code_index)
    create unique_index(:priority_codes, [:tenant_id, :level], name: :priority_codes_tenant_level_index)
    create index(:priority_codes, [:tenant_id, :is_active])
    create index(:priority_codes, [:level])

    # Maintenance categories table
    create table(:maintenance_categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :code, :string
      add :description, :text
      add :type, :string, null: false # preventive, corrective, predictive, emergency, condition_based
      add :default_frequency_days, :integer # default PM frequency
      add :requires_shutdown, :boolean, default: false
      add :skill_requirements, :text
      add :safety_requirements, :text
      add :parent_category_id, references(:maintenance_categories, type: :binary_id, on_delete: :nilify_all)
      add :is_active, :boolean, default: true, null: false
      add :tenant_id, references(:tenants, type: :integer, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:maintenance_categories, [:tenant_id, :name], name: :maintenance_categories_tenant_name_index)
    create unique_index(:maintenance_categories, [:tenant_id, :code], where: "code IS NOT NULL", name: :maintenance_categories_tenant_code_index)
    create index(:maintenance_categories, [:tenant_id, :is_active])
    create index(:maintenance_categories, [:type])
    create index(:maintenance_categories, [:parent_category_id])
    create index(:maintenance_categories, [:name])

    # Custom fields table for extensible metadata
    create table(:custom_fields, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_type, :string, null: false # asset, work_order, location, etc.
      add :field_name, :string, null: false
      add :field_label, :string, null: false
      add :field_type, :string, null: false # text, number, date, boolean, select, multi_select
      add :field_options, :map # for select fields: %{"options" => ["option1", "option2"]}
      add :default_value, :text
      add :is_required, :boolean, default: false
      add :validation_rules, :map # %{"min_length" => 5, "max_length" => 100, "pattern" => "regex"}
      add :display_order, :integer, default: 0
      add :help_text, :text
      add :is_active, :boolean, default: true, null: false
      add :tenant_id, references(:tenants, type: :integer, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:custom_fields, [:tenant_id, :entity_type, :field_name], name: :custom_fields_tenant_entity_name_index)
    create index(:custom_fields, [:tenant_id, :entity_type, :is_active])
    create index(:custom_fields, [:entity_type])
    create index(:custom_fields, [:display_order])

    # Custom field values table
    create table(:custom_field_values, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :custom_field_id, references(:custom_fields, type: :binary_id, on_delete: :delete_all), null: false
      add :entity_type, :string, null: false
      add :entity_id, :binary_id, null: false
      add :field_value, :text
      add :tenant_id, references(:tenants, type: :integer, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:custom_field_values, [:custom_field_id, :entity_id], name: :custom_field_values_field_entity_index)
    create index(:custom_field_values, [:entity_type, :entity_id])
    create index(:custom_field_values, [:tenant_id])

    # Add RLS policies for all tables
    execute "ALTER TABLE manufacturers ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE departments ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE priority_codes ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE maintenance_categories ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE custom_fields ENABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE custom_field_values ENABLE ROW LEVEL SECURITY"

    # Create RLS policies for tenant isolation
    execute "CREATE POLICY manufacturers_tenant_policy ON manufacturers FOR ALL TO postgres USING (tenant_id = current_setting('app.current_tenant_id', true)::integer)"
    execute "CREATE POLICY departments_tenant_policy ON departments FOR ALL TO postgres USING (tenant_id = current_setting('app.current_tenant_id', true)::integer)"
    execute "CREATE POLICY suppliers_tenant_policy ON suppliers FOR ALL TO postgres USING (tenant_id = current_setting('app.current_tenant_id', true)::integer)"
    execute "CREATE POLICY priority_codes_tenant_policy ON priority_codes FOR ALL TO postgres USING (tenant_id = current_setting('app.current_tenant_id', true)::integer)"
    execute "CREATE POLICY maintenance_categories_tenant_policy ON maintenance_categories FOR ALL TO postgres USING (tenant_id = current_setting('app.current_tenant_id', true)::integer)"
    execute "CREATE POLICY custom_fields_tenant_policy ON custom_fields FOR ALL TO postgres USING (tenant_id = current_setting('app.current_tenant_id', true)::integer)"
    execute "CREATE POLICY custom_field_values_tenant_policy ON custom_field_values FOR ALL TO postgres USING (tenant_id = current_setting('app.current_tenant_id', true)::integer)"
  end
end
