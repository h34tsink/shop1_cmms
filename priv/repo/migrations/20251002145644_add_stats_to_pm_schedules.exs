defmodule Shop1Cmms.Repo.Migrations.AddStatsToPmSchedules do
  use Ecto.Migration

  def change do
    alter table(:pm_schedules) do
      add :total_completions, :integer, default: 0
      add :on_time_completions, :integer, default: 0
      add :completion_rate, :decimal, precision: 5, scale: 2
      
      # Also add component_id reference for PMs that target specific components
      add :component_id, references(:components, type: :binary_id, on_delete: :nilify_all)
    end
    
    create index(:pm_schedules, [:component_id])
  end
end
