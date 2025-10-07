defmodule Shop1Cmms.Repo.Migrations.UpdateAuditLogsTable do
  use Ecto.Migration

  def up do
    # Check if columns exist and add them if they don't
    alter table(:audit_logs) do
      # Add action column if it doesn't exist
      add_if_not_exists :action, :string
      
      # Add performed_by_id if it doesn't exist (bigint to match users table)
      add_if_not_exists :performed_by_id, references(:users, on_delete: :nilify_all, type: :bigint)
    end

    # Add indexes if they don't exist
    create_if_not_exists index(:audit_logs, [:entity_type, :entity_id])
    create_if_not_exists index(:audit_logs, [:entity_type, :tenant_id])
    create_if_not_exists index(:audit_logs, [:performed_by_id])
    create_if_not_exists index(:audit_logs, [:tenant_id, :inserted_at])
    create_if_not_exists index(:audit_logs, [:action])
  end

  def down do
    drop_if_exists index(:audit_logs, [:action])
    drop_if_exists index(:audit_logs, [:tenant_id, :inserted_at])
    drop_if_exists index(:audit_logs, [:performed_by_id])
    drop_if_exists index(:audit_logs, [:entity_type, :tenant_id])
    drop_if_exists index(:audit_logs, [:entity_type, :entity_id])
    
    alter table(:audit_logs) do
      remove_if_exists :performed_by_id, references(:users, on_delete: :nilify_all, type: :bigint)
      remove_if_exists :action, :string
    end
  end
end
