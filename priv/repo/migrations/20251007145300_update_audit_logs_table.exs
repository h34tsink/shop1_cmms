defmodule Shop1Cmms.Repo.Migrations.UpdateAuditLogsTable do
  use Ecto.Migration

  def up do
    # Rename existing columns to match our schema
    rename table(:audit_logs), :user_id, to: :performed_by_id
    rename table(:audit_logs), :timestamp, to: :inserted_at
    rename table(:audit_logs), :action_type, to: :action
    
    # Change entity_id from integer to uuid
    alter table(:audit_logs) do
      # Remove old integer entity_id
      remove :entity_id
      # Add new uuid entity_id
      add :entity_id, :uuid
    end
    
    # Add missing columns
    alter table(:audit_logs) do
      add_if_not_exists :tenant_id, :integer
      add_if_not_exists :changes, :map
      add_if_not_exists :metadata, :map
    end
    
    # Remove columns we don't need
    alter table(:audit_logs) do
      remove_if_exists :field_changed, :text
      remove_if_exists :old_value, :text
      remove_if_exists :new_value, :text
      remove_if_exists :ip_address, :text
    end
    
    # Change id from integer to uuid - need to drop default first
    execute "ALTER TABLE audit_logs DROP CONSTRAINT audit_logs_pkey"
    execute "ALTER TABLE audit_logs ALTER COLUMN id DROP DEFAULT"
    execute "ALTER TABLE audit_logs ALTER COLUMN id TYPE uuid USING gen_random_uuid()"
    execute "ALTER TABLE audit_logs ALTER COLUMN id SET DEFAULT gen_random_uuid()"
    execute "ALTER TABLE audit_logs ADD PRIMARY KEY (id)"

    # Add indexes
    create_if_not_exists index(:audit_logs, [:entity_type, :entity_id])
    create_if_not_exists index(:audit_logs, [:entity_type, :tenant_id])
    create_if_not_exists index(:audit_logs, [:performed_by_id])
    create_if_not_exists index(:audit_logs, [:tenant_id, :inserted_at])
    create_if_not_exists index(:audit_logs, [:action])
  end

  def down do
    # This is destructive, but provides a path back if needed
    drop_if_exists index(:audit_logs, [:action])
    drop_if_exists index(:audit_logs, [:tenant_id, :inserted_at])
    drop_if_exists index(:audit_logs, [:performed_by_id])
    drop_if_exists index(:audit_logs, [:entity_type, :tenant_id])
    drop_if_exists index(:audit_logs, [:entity_type, :entity_id])
    
    # Restore old columns
    alter table(:audit_logs) do
      add_if_not_exists :field_changed, :text
      add_if_not_exists :old_value, :text
      add_if_not_exists :new_value, :text
      add_if_not_exists :ip_address, :text
    end
    
    alter table(:audit_logs) do
      remove_if_exists :metadata, :map
      remove_if_exists :changes, :map
      remove_if_exists :tenant_id, :integer
    end
    
    # Change entity_id back to integer
    alter table(:audit_logs) do
      remove :entity_id
      add :entity_id, :integer
    end
    
    # Rename columns back
    rename table(:audit_logs), :action, to: :action_type
    rename table(:audit_logs), :inserted_at, to: :timestamp
    rename table(:audit_logs), :performed_by_id, to: :user_id
  end
end
