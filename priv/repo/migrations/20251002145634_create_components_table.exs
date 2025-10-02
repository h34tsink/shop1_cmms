defmodule Shop1Cmms.Repo.Migrations.CreateComponentsTable do
  use Ecto.Migration

  def change do
    create table(:components, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :component_type, :string
      add :manufacturer, :string
      add :model, :string
      add :serial_number, :string
      add :install_date, :date
      add :status, :string, null: false, default: "active"
      
      # Parent Equipment
      add :asset_id, references(:assets, type: :binary_id, on_delete: :delete_all), null: false
      
      # Multi-tenancy
      add :tenant_id, :integer, null: false
      
      timestamps(type: :naive_datetime)
    end
    
    create index(:components, [:asset_id])
    create index(:components, [:tenant_id])
    create index(:components, [:status])
    create index(:components, [:component_type])
  end
end
