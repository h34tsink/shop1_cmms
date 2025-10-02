defmodule Shop1Cmms.Repo.Migrations.EnhancePmTemplatesWithInstructions do
  use Ecto.Migration

  def change do
    # Since we don't have PM templates table, we'll enhance PM schedules instead
    alter table(:pm_schedules) do
      # These fields might already exist, but adding them just in case
      # The work_instructions field already exists according to the schema
      # add :work_instructions, :text  # Already exists
      # add :safety_notes, :string  # Already exists
      
      # Add structured instruction steps
      add_if_not_exists :instruction_steps, :jsonb, default: "[]"
    end
  end
end
