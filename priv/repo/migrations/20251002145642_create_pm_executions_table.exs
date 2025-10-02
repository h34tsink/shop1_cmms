defmodule Shop1Cmms.Repo.Migrations.CreatePmExecutionsTable do
  use Ecto.Migration

  def change do
    create table(:pm_executions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :execution_number, :string, null: false
      add :execution_date, :utc_datetime, null: false
      add :completed_date, :utc_datetime
      add :status, :string, null: false, default: "in_progress"
      
      # References
      add :pm_schedule_id, references(:pm_schedules, type: :binary_id, on_delete: :delete_all), null: false
      add :work_order_id, references(:work_orders, type: :binary_id, on_delete: :nilify_all)
      add :completed_by_user_id, references(:users, type: :bigint)  # Users table uses bigint
      add :asset_id, references(:assets, type: :binary_id), null: false
      add :component_id, references(:components, type: :binary_id)
      
      # Execution data
      add :step_results, :jsonb, default: "[]"
      add :tech_notes, :text
      add :parts_used, :jsonb, default: "[]"
      add :actual_duration_minutes, :integer
      add :meter_reading, :decimal
      
      # Multi-tenancy
      add :tenant_id, :integer, null: false
      
      timestamps(type: :naive_datetime)
    end
    
    create unique_index(:pm_executions, [:execution_number])
    create index(:pm_executions, [:pm_schedule_id])
    create index(:pm_executions, [:status])
    create index(:pm_executions, [:asset_id])
    create index(:pm_executions, [:component_id])
    create index(:pm_executions, [:tenant_id])
    create index(:pm_executions, [:execution_date])
  end
end
