defmodule Shop1Cmms.Repo.Migrations.CreateWorkOrders do
  use Ecto.Migration

  def change do
    # Work Orders Status Enum
    execute "CREATE TYPE work_order_status AS ENUM ('open', 'assigned', 'in_progress', 'on_hold', 'completed', 'cancelled')",
            "DROP TYPE work_order_status"

    # Work Orders Priority Enum
    execute "CREATE TYPE work_order_priority AS ENUM ('low', 'medium', 'high', 'urgent')",
            "DROP TYPE work_order_priority"

    # Work Orders Type Enum
    execute "CREATE TYPE work_order_type AS ENUM ('corrective', 'preventive', 'emergency', 'project')",
            "DROP TYPE work_order_type"

    # Work Orders Table
    create table(:work_orders, primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
      add :work_order_number, :string, null: false
      add :title, :string, null: false
      add :description, :text
      add :status, :work_order_status, null: false, default: "open"
      add :priority, :work_order_priority, null: false, default: "medium"
      add :type, :work_order_type, null: false, default: "corrective"

      # Dates
      add :requested_date, :utc_datetime, null: false
      add :scheduled_start_date, :utc_datetime
      add :scheduled_end_date, :utc_datetime
      add :actual_start_date, :utc_datetime
      add :actual_end_date, :utc_datetime
      add :due_date, :utc_datetime

      # Users and Assignment
      add :requested_by, references(:users, on_delete: :nilify_all, type: :integer)
      add :assigned_to, references(:users, on_delete: :nilify_all, type: :integer)
      add :created_by, references(:users, on_delete: :nilify_all, type: :integer)
      add :updated_by, references(:users, on_delete: :nilify_all, type: :integer)

      # Asset and Location
      add :asset_id, references(:assets, on_delete: :nilify_all, type: :binary_id)
      add :location_description, :string

      # Costs and Labor
      add :estimated_hours, :decimal, precision: 8, scale: 2
      add :actual_hours, :decimal, precision: 8, scale: 2
      add :estimated_cost, :decimal, precision: 12, scale: 2
      add :actual_cost, :decimal, precision: 12, scale: 2

      # Additional Fields
      add :completion_notes, :text
      add :work_performed, :text
      add :failure_reason, :text
      add :parts_used, :jsonb
      add :safety_notes, :text
      add :attachments, :jsonb

      # Multi-tenancy
      add :tenant_id, references(:tenants, on_delete: :delete_all, type: :integer), null: false

      timestamps(type: :utc_datetime)
    end

    # Indexes
    create index(:work_orders, [:tenant_id])
    create index(:work_orders, [:asset_id])
    create index(:work_orders, [:assigned_to])
    create index(:work_orders, [:requested_by])
    create index(:work_orders, [:status])
    create index(:work_orders, [:priority])
    create index(:work_orders, [:type])
    create index(:work_orders, [:due_date])
    create index(:work_orders, [:scheduled_start_date])
    create unique_index(:work_orders, [:work_order_number, :tenant_id])

    # RLS Policy
    execute """
    ALTER TABLE work_orders ENABLE ROW LEVEL SECURITY;
    """,
    """
    ALTER TABLE work_orders DISABLE ROW LEVEL SECURITY;
    """

    execute """
    CREATE POLICY work_orders_tenant_isolation ON work_orders
    USING (tenant_id::text = current_setting('app.current_tenant_id', true));
    """,
    """
    DROP POLICY IF EXISTS work_orders_tenant_isolation ON work_orders;
    """
  end
end
