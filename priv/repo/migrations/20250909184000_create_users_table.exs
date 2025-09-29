defmodule Shop1Cmms.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false
      add :password_hash, :string
      add :is_active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end
