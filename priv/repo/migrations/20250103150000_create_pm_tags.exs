defmodule Shop1Cmms.Repo.Migrations.CreatePmTags do
  use Ecto.Migration

  def change do
    create table(:pm_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :tag_type, :string, null: false  # "skill", "tool", "ppe"
      add :description, :text
      add :is_active, :boolean, default: true, null: false
      add :usage_count, :integer, default: 0  # Track how often it's used
      add :tenant_id, :integer, null: false

      timestamps(type: :naive_datetime)
    end

    create index(:pm_tags, [:tenant_id])
    create index(:pm_tags, [:tag_type])
    create index(:pm_tags, [:is_active])
    create unique_index(:pm_tags, [:tenant_id, :tag_type, :name], name: :pm_tags_tenant_type_name_index)
  end
end
