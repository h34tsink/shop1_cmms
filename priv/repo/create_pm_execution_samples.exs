# Script to create sample PM execution history data for testing
# Run with: mix run priv/repo/create_pm_execution_samples.exs

import Ecto.Query
alias Shop1Cmms.{Repo, Maintenance, Assets}
alias Shop1Cmms.Maintenance.{PmSchedule, PmExecution}

IO.puts("Creating sample PM execution history...")

# Get tenant_id (assuming tenant 1)
tenant_id = 1

# Get first PM schedule
pm_schedule = from(s in PmSchedule,
  where: s.tenant_id == ^tenant_id,
  limit: 1
)
|> Repo.one()

if pm_schedule do
  IO.puts("Found PM Schedule: #{pm_schedule.title}")
  IO.puts("Creating 10 past PM executions...")

  # Create 10 past executions
  for i <- 1..10 do
    days_ago = 30 * i
    execution_date = DateTime.add(DateTime.utc_now(), -days_ago * 24 * 60 * 60, :second)
    completed_date = DateTime.add(execution_date, 2 * 60 * 60, :second) # 2 hours later

    attrs = %{
      execution_date: execution_date,
      completed_date: completed_date,
      status: :completed,
      pm_schedule_id: pm_schedule.id,
      asset_id: pm_schedule.asset_id,
      # completed_by_user_id: nil, # Will be set when we have valid user data
      actual_duration_minutes: Enum.random(30..90),
      tech_notes: "Routine maintenance completed. All checks passed.",
      step_results: [
        %{"step" => 1, "description" => "Check fluid levels", "completed" => true, "notes" => "OK"},
        %{"step" => 2, "description" => "Inspect belts", "completed" => true, "notes" => "OK"},
        %{"step" => 3, "description" => "Lubricate moving parts", "completed" => true, "notes" => "OK"}
      ],
      parts_used: [
        %{"part_number" => "OIL-001", "description" => "Hydraulic Oil", "quantity" => 1, "unit" => "qt"},
        %{"part_number" => "GRS-001", "description" => "Grease", "quantity" => 1, "unit" => "lb"}
      ],
      tenant_id: tenant_id
    }

    case Maintenance.create_pm_execution(attrs) do
      {:ok, execution} ->
        IO.puts("  Created execution: #{execution.execution_number} - #{execution.execution_date}")
      {:error, changeset} ->
        IO.puts("  Error creating execution: #{inspect(changeset.errors)}")
    end
  end

  IO.puts("Sample PM execution history created successfully!")
else
  IO.puts("No PM schedules found. Please create a PM schedule first.")
end
