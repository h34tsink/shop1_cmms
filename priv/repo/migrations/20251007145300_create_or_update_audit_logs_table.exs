defmodule Shop1Cmms.Repo.Migrations.CreateOrUpdateAuditLogsTable do
  use Ecto.Migration

  def up do
    # Check if table exists
    table_exists_query = """
    SELECT EXISTS (
      SELECT FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name = 'audit_logs'
    )
    """
    
    table_exists = case repo().query(table_exists_query) do
      {:ok, %{rows: [[true]]}} -> true
      _ -> false
    end
    
    if table_exists do
      # Table exists - update it
      IO.puts("Updating existing audit_logs table...")
      
      rename table(:audit_logs), :user_id, to: :performed_by_id
      rename table(:audit_logs), :timestamp, to: :inserted_at
      rename table(:audit_logs), :action_type, to: :action
      
      alter table(:audit_logs) do
        remove :entity_id
        add :entity_id, :uuid
      end
      
      alter table(:audit_logs) do
        add_if_not_exists :tenant_id, :integer
        add_if_not_exists :changes, :map
        add_if_not_exists :metadata, :map
      end
      
      alter table(:audit_logs) do
        remove_if_exists :field_changed, :text
        remove_if_exists :old_value, :text
        remove_if_exists :new_value, :text
        remove_if_exists :ip_address, :text
      end
      
      execute "ALTER TABLE audit_logs DROP CONSTRAINT audit_logs_pkey"
      execute "ALTER TABLE audit_logs ALTER COLUMN id DROP DEFAULT"
      execute "ALTER TABLE audit_logs ALTER COLUMN id TYPE uuid USING gen_random_uuid()"
      execute "ALTER TABLE audit_logs ALTER COLUMN id SET DEFAULT gen_random_uuid()"
      execute "ALTER TABLE audit_logs ADD PRIMARY KEY (id)"
    else
      # Table doesn't exist - create it from scratch
      IO.puts("Creating new audit_logs table...")
      
      create table(:audit_logs, primary_key: false) do
        add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
        add :entity_type, :string, null: false
        add :entity_id, :uuid
        add :action, :string, null: false
        add :changes, :map
        add :metadata, :map
        add :performed_by_id, references(:users, on_delete: :nilify_all, type: :integer)
        add :tenant_id, :integer
        add :inserted_at, :utc_datetime, null: false
      end
    end

    # Add indexes (works for both cases)
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
    
    drop_if_exists table(:audit_logs)
  end
end
