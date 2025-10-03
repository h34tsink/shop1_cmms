defmodule Shop1Cmms.Maintenance do
  @moduledoc """
  The Maintenance context for PM Schedules and Asset Documents.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo

  alias Shop1Cmms.Maintenance.{PmSchedule, PmScheduleComponent, PmChecklistItem, AssetDocument, PmExecution}
  alias Shop1Cmms.Accounts.User

  ## PM Schedules

  @doc """
  Returns the list of PM schedules.
  """
  def list_pm_schedules(tenant_id) do
    PmSchedule
    |> where([pm], pm.tenant_id == ^tenant_id)
    |> preload([:asset, :components, :checklist_items, :documents])
    |> order_by([pm], [desc: pm.inserted_at])
    |> Repo.all()
  end

  @doc """
  Returns the list of active PM schedules for a specific asset.
  """
  def list_active_pm_schedules_for_asset(tenant_id, asset_id) do
    PmSchedule
    |> where([pm], pm.tenant_id == ^tenant_id and pm.asset_id == ^asset_id and pm.is_active == true)
    |> preload([:components, :checklist_items, :documents])
    |> order_by([pm], [asc: pm.next_due_date])
    |> Repo.all()
  end

  @doc """
  Returns the list of overdue PM schedules.
  """
  def list_overdue_pm_schedules(tenant_id) do
    now = DateTime.utc_now()
    
    PmSchedule
    |> where([pm], pm.tenant_id == ^tenant_id)
    |> where([pm], pm.is_active == true)
    |> where([pm], pm.next_due_date < ^now)
    |> preload([:asset])
    |> order_by([pm], [asc: pm.next_due_date])
    |> Repo.all()
  end

  @doc """
  Returns the list of PM schedules due soon.
  """
  def list_due_soon_pm_schedules(tenant_id, days \\ 30) do
    now = DateTime.utc_now()
    future = DateTime.add(now, days * 24 * 60 * 60, :second)
    
    PmSchedule
    |> where([pm], pm.tenant_id == ^tenant_id)
    |> where([pm], pm.is_active == true)
    |> where([pm], pm.next_due_date >= ^now and pm.next_due_date <= ^future)
    |> preload([:asset])
    |> order_by([pm], [asc: pm.next_due_date])
    |> Repo.all()
  end

  @doc """
  Gets a single PM schedule.
  """
  def get_pm_schedule!(tenant_id, id) do
    PmSchedule
    |> where([pm], pm.tenant_id == ^tenant_id and pm.id == ^id)
    |> preload([:asset, :components, :checklist_items, :documents])
    |> Repo.one!()
  end

  @doc """
  Creates a PM schedule.
  """
  def create_pm_schedule(attrs \\ %{}) do
    %PmSchedule{}
    |> PmSchedule.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a PM schedule.
  """
  def update_pm_schedule(%PmSchedule{} = pm_schedule, attrs) do
    pm_schedule
    |> PmSchedule.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PM schedule.
  """
  def delete_pm_schedule(%PmSchedule{} = pm_schedule) do
    Repo.delete(pm_schedule)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking PM schedule changes.
  """
  def change_pm_schedule(%PmSchedule{} = pm_schedule, attrs \\ %{}) do
    PmSchedule.changeset(pm_schedule, attrs)
  end

  ## PM Schedule Components

  @doc """
  Creates a PM schedule component.
  """
  def create_pm_schedule_component(attrs \\ %{}) do
    %PmScheduleComponent{}
    |> PmScheduleComponent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a PM schedule component.
  """
  def update_pm_schedule_component(%PmScheduleComponent{} = component, attrs) do
    component
    |> PmScheduleComponent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PM schedule component.
  """
  def delete_pm_schedule_component(%PmScheduleComponent{} = component) do
    Repo.delete(component)
  end

  ## PM Checklist Items

  @doc """
  Lists checklist items for a PM schedule.
  """
  def list_pm_checklist_items(tenant_id, schedule_id) do
    PmChecklistItem
    |> where([item], item.tenant_id == ^tenant_id and item.pm_schedule_id == ^schedule_id)
    |> order_by([item], [asc: item.sequence])
    |> Repo.all()
  end

  @doc """
  Creates a PM checklist item.
  """
  def create_pm_checklist_item(attrs \\ %{}) do
    %PmChecklistItem{}
    |> PmChecklistItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a PM checklist item.
  """
  def update_pm_checklist_item(%PmChecklistItem{} = item, attrs) do
    item
    |> PmChecklistItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a PM checklist item.
  """
  def delete_pm_checklist_item(%PmChecklistItem{} = item) do
    Repo.delete(item)
  end

  ## Asset Documents

  @doc """
  Returns the list of documents for an asset.
  """
  def list_asset_documents(tenant_id, asset_id) do
    AssetDocument
    |> where([doc], doc.tenant_id == ^tenant_id and doc.asset_id == ^asset_id)
    |> where([doc], doc.is_active == true)
    |> order_by([doc], [desc: doc.inserted_at])
    |> Repo.all()
  end

  @doc """
  Returns the list of documents for a PM schedule.
  """
  def list_pm_schedule_documents(tenant_id, schedule_id) do
    AssetDocument
    |> where([doc], doc.tenant_id == ^tenant_id and doc.pm_schedule_id == ^schedule_id)
    |> where([doc], doc.is_active == true)
    |> order_by([doc], [desc: doc.inserted_at])
    |> Repo.all()
  end

  @doc """
  Returns the list of expiring documents.
  """
  def list_expiring_documents(tenant_id, days \\ 30) do
    future = Date.add(Date.utc_today(), days)
    
    AssetDocument
    |> where([doc], doc.tenant_id == ^tenant_id)
    |> where([doc], doc.is_active == true)
    |> where([doc], not is_nil(doc.expiry_date) and doc.expiry_date <= ^future)
    |> preload([:asset, :pm_schedule])
    |> order_by([doc], [asc: doc.expiry_date])
    |> Repo.all()
  end

  @doc """
  Gets a single document.
  """
  def get_asset_document!(tenant_id, id) do
    AssetDocument
    |> where([doc], doc.tenant_id == ^tenant_id and doc.id == ^id)
    |> preload([:asset, :pm_schedule, :work_order])
    |> Repo.one!()
  end

  @doc """
  Creates a document.
  """
  def create_asset_document(attrs \\ %{}) do
    %AssetDocument{}
    |> AssetDocument.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a document.
  """
  def update_asset_document(%AssetDocument{} = document, attrs) do
    document
    |> AssetDocument.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a document.
  """
  def delete_asset_document(%AssetDocument{} = document) do
    Repo.delete(document)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking document changes.
  """
  def change_asset_document(%AssetDocument{} = document, attrs \\ %{}) do
    AssetDocument.changeset(document, attrs)
  end

  @doc """
  Calculates the next due date for a PM schedule based on frequency.
  """
  def calculate_next_due_date(%PmSchedule{} = schedule) do
    base_date = schedule.last_completed_date || DateTime.utc_now()
    
    case schedule.frequency do
      :daily -> DateTime.add(base_date, schedule.frequency_interval * 1, :day)
      :weekly -> DateTime.add(base_date, schedule.frequency_interval * 7, :day)
      :biweekly -> DateTime.add(base_date, schedule.frequency_interval * 14, :day)
      :monthly -> DateTime.add(base_date, schedule.frequency_interval * 30, :day)
      :quarterly -> DateTime.add(base_date, schedule.frequency_interval * 90, :day)
      :semiannual -> DateTime.add(base_date, schedule.frequency_interval * 180, :day)
      :annual -> DateTime.add(base_date, schedule.frequency_interval * 365, :day)
      :biennial -> DateTime.add(base_date, schedule.frequency_interval * 730, :day)
      :meter_based -> nil  # Calculated based on meter readings
      :condition_based -> nil  # Determined by condition monitoring
      _ -> nil
    end
  end

  @doc """
  Marks a PM schedule as completed and updates the next due date.
  Creates a PM execution record for the history.
  """
  def complete_pm_schedule(%PmSchedule{} = schedule, completed_at \\ nil, user_id \\ nil) do
    require Logger
    completed_at = completed_at || DateTime.utc_now()
    
    Logger.info("Starting PM completion for schedule #{schedule.id}")
    
    # Convert estimated_duration to integer minutes
    duration_minutes = case schedule.estimated_duration do
      nil -> 0
      %Decimal{} = d -> Decimal.to_integer(d)
      n when is_number(n) -> trunc(n)
      _ -> 0
    end
    
    Repo.transaction(fn ->
      # Create PM execution record for history
      execution_attrs = %{
        execution_number: generate_pm_execution_number(schedule.tenant_id),
        execution_date: completed_at,
        completed_date: completed_at,
        status: :completed,
        pm_schedule_id: schedule.id,
        asset_id: schedule.asset_id,
        completed_by_user_id: user_id,
        tenant_id: schedule.tenant_id,
        tech_notes: "PM completed via schedule",
        actual_duration_minutes: duration_minutes
      }
      
      Logger.debug("Creating PM execution with attrs: #{inspect(execution_attrs)}")
      
      case create_pm_execution(execution_attrs) do
        {:ok, execution} ->
          Logger.info("PM execution #{execution.id} created successfully")
          # Update schedule with new dates
          next_due = calculate_next_due_date(%{schedule | last_completed_date: completed_at})
          attrs = %{
            last_completed_date: completed_at,
            next_due_date: next_due
          }
          
          Logger.debug("Updating PM schedule with attrs: #{inspect(attrs)}")
          
          case update_pm_schedule(schedule, attrs) do
            {:ok, updated_schedule} -> 
              Logger.info("PM schedule #{schedule.id} updated successfully")
              updated_schedule
            {:error, changeset} -> 
              Logger.error("Failed to update PM schedule: #{inspect(changeset.errors)}")
              Repo.rollback(changeset)
          end
          
        {:error, changeset} ->
          Logger.error("Failed to create PM execution: #{inspect(changeset.errors)}")
          Repo.rollback(changeset)
      end
    end)
  end

  ## PM Executions

  @doc """
  Returns the list of PM executions for a tenant.
  
  ## Options
    * `:schedule_id` - Filter by PM schedule
    * `:asset_id` - Filter by asset
    * `:status` - Filter by status
    * `:from_date` - Filter executions after this date
    * `:to_date` - Filter executions before this date
  """
  def list_pm_executions(tenant_id, filters \\ %{}) do
    query = from(e in PmExecution,
      where: e.tenant_id == ^tenant_id,
      preload: [:pm_schedule, :asset, :component, :completed_by_user],
      order_by: [desc: e.execution_date]
    )

    query
    |> apply_pm_execution_filters(filters)
    |> Repo.all()
  end

  defp apply_pm_execution_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:schedule_id, schedule_id}, query when not is_nil(schedule_id) ->
        where(query, [e], e.pm_schedule_id == ^schedule_id)
      
      {:asset_id, asset_id}, query when not is_nil(asset_id) ->
        where(query, [e], e.asset_id == ^asset_id)
      
      {:status, status}, query when not is_nil(status) ->
        where(query, [e], e.status == ^status)
      
      {:from_date, from_date}, query when not is_nil(from_date) ->
        where(query, [e], e.execution_date >= ^from_date)
      
      {:to_date, to_date}, query when not is_nil(to_date) ->
        where(query, [e], e.execution_date <= ^to_date)
      
      _, query -> query
    end)
  end

  @doc """
  Returns the list of PM executions for a specific PM schedule.
  """
  def list_pm_executions_for_schedule(tenant_id, schedule_id) do
    from(e in PmExecution,
      where: e.tenant_id == ^tenant_id and e.pm_schedule_id == ^schedule_id,
      preload: [:completed_by_user, :asset, :component],
      order_by: [desc: e.execution_date]
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of PM executions for a specific asset.
  """
  def list_pm_executions_for_asset(tenant_id, asset_id) do
    from(e in PmExecution,
      where: e.tenant_id == ^tenant_id and e.asset_id == ^asset_id,
      preload: [:pm_schedule, :completed_by_user, :component],
      order_by: [desc: e.execution_date]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single PM execution.
  """
  def get_pm_execution(tenant_id, id) do
    from(e in PmExecution,
      where: e.tenant_id == ^tenant_id and e.id == ^id,
      preload: [:pm_schedule, :asset, :component, :completed_by_user, :work_order]
    )
    |> Repo.one()
  end

  def get_pm_execution!(tenant_id, id) do
    from(e in PmExecution,
      where: e.tenant_id == ^tenant_id and e.id == ^id,
      preload: [:pm_schedule, :asset, :component, :completed_by_user, :work_order]
    )
    |> Repo.one!()
  end

  @doc """
  Creates a PM execution record.
  Generates the next execution number automatically.
  """
  def create_pm_execution(attrs \\ %{}) do
    attrs = Map.put_new_lazy(attrs, :execution_number, fn ->
      generate_pm_execution_number(attrs[:tenant_id])
    end)

    %PmExecution{}
    |> PmExecution.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a PM execution.
  """
  def update_pm_execution(%PmExecution{} = execution, attrs) do
    execution
    |> PmExecution.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Completes a PM execution and updates related PM schedule statistics.
  """
  def complete_pm_execution(%PmExecution{} = execution, attrs) do
    Repo.transaction(fn ->
      # Update execution with completion data
      case execution
           |> PmExecution.completion_changeset(attrs)
           |> Repo.update() do
        {:ok, updated_execution} ->
          # Update PM schedule statistics
          update_pm_schedule_stats(updated_execution.pm_schedule_id)
          
          # Update PM schedule last completed date and next due date
          schedule = Repo.get!(PmSchedule, updated_execution.pm_schedule_id)
          complete_pm_schedule(schedule, updated_execution.completed_date)
          
          updated_execution
        
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Deletes a PM execution.
  """
  def delete_pm_execution(%PmExecution{} = execution) do
    Repo.delete(execution)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking PM execution changes.
  """
  def change_pm_execution(%PmExecution{} = execution, attrs \\ %{}) do
    PmExecution.changeset(execution, attrs)
  end

  @doc """
  Generates the next PM execution number.
  Format: PMX-NNNNNNNN
  """
  def generate_pm_execution_number(tenant_id) do
    # Get the last execution number for this tenant
    last_execution = from(e in PmExecution,
      where: e.tenant_id == ^tenant_id,
      select: e.execution_number,
      order_by: [desc: e.execution_number],
      limit: 1
    )
    |> Repo.one()

    case last_execution do
      nil ->
        "PMX-00000001"
      
      last_number ->
        # Extract number part and increment
        number_part = last_number |> String.replace("PMX-", "") |> String.to_integer()
        next_number = number_part + 1
        "PMX-#{String.pad_leading("#{next_number}", 8, "0")}"
    end
  end

  @doc """
  Gets PM execution statistics for a PM schedule.
  Returns completion rate, average duration, etc.
  """
  def get_pm_execution_stats(tenant_id, schedule_id) do
    executions = list_pm_executions_for_schedule(tenant_id, schedule_id)
    
    total_count = length(executions)
    completed_count = Enum.count(executions, fn e -> e.status == :completed end)
    
    avg_duration = if completed_count > 0 do
      executions
      |> Enum.filter(fn e -> e.status == :completed && e.actual_duration_minutes end)
      |> Enum.map(fn e -> e.actual_duration_minutes end)
      |> case do
        [] -> 0
        durations -> Enum.sum(durations) / length(durations)
      end
    else
      0
    end

    %{
      total_executions: total_count,
      completed: completed_count,
      in_progress: Enum.count(executions, fn e -> e.status == :in_progress end),
      incomplete: Enum.count(executions, fn e -> e.status == :incomplete end),
      cancelled: Enum.count(executions, fn e -> e.status == :cancelled end),
      completion_rate: if(total_count > 0, do: completed_count / total_count * 100, else: 0),
      average_duration_minutes: trunc(avg_duration)
    }
  end

  @doc """
  Updates PM schedule statistics based on execution history.
  """
  def update_pm_schedule_stats(schedule_id) do
    schedule = Repo.get!(PmSchedule, schedule_id)
    stats = get_pm_execution_stats(schedule.tenant_id, schedule_id)
    
    update_pm_schedule(schedule, %{
      total_completions: stats.completed,
      completion_rate: Decimal.from_float(stats.completion_rate)
    })
  end

  @doc """
  Gets combined maintenance history for an asset (PM executions + Work Orders).
  Returns a unified timeline of all maintenance activities.
  """
  def get_asset_maintenance_history(tenant_id, asset_id) do
    # PM Executions
    pm_executions = from(e in PmExecution,
      where: e.tenant_id == ^tenant_id and e.asset_id == ^asset_id,
      join: s in assoc(e, :pm_schedule),
      left_join: u in assoc(e, :completed_by_user),
      select: %{
        type: "PM Execution",
        date: e.execution_date,
        completed_date: e.completed_date,
        title: s.title,
        identifier: e.execution_number,
        status: e.status,
        technician: u.name,
        technician_id: e.completed_by_user_id,
        duration_minutes: e.actual_duration_minutes,
        notes: e.tech_notes,
        id: e.id,
        record_type: "pm_execution"
      }
    )
    |> Repo.all()

    # Work Orders (we'll add this when we implement work order history)
    # For now, just return PM executions
    pm_executions
    |> Enum.sort_by(fn item -> item.date end, {:desc, DateTime})
  end
end

