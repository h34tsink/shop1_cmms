defmodule Shop1Cmms.Repo.Migrations.AddCodeToTenants do
  use Ecto.Migration

  def change do
    alter table(:tenants) do
      add_if_not_exists :code, :string
    end

    create_if_not_exists unique_index(:tenants, [:code])
  end
end
