defmodule Shop1Cmms.Repo.Migrations.UpdateSitesTableStructure do
  use Ecto.Migration

  def change do
    # Check if sites table needs the code column and other missing fields
    alter table(:sites) do
      add_if_not_exists :code, :string
    end

    # Ensure proper indexes
    create_if_not_exists unique_index(:sites, [:tenant_id, :code], name: :sites_tenant_id_code_index)
  end
end
