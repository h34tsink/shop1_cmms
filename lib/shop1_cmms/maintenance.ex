defmodule Shop1Cmms.Maintenance do
  @moduledoc """
  The Maintenance context for PM Schedules and Asset Documents.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo

  alias Shop1Cmms.Maintenance.{PmSchedule, PmScheduleComponent, PmChecklistItem, AssetDocument}

  ## PM Schedules

  @doc """
  Returns the list of PM schedules.
  """
  def list_pm_schedules(tenant_id) do
    PmSchedule
    |> where([pm], pm.tenant_id == ^tenant_id)
    |> preload([:asset, :components, :checklist_items])
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
  """
  def complete_pm_schedule(%PmSchedule{} = schedule, completed_at \\ nil) do
    completed_at = completed_at || DateTime.utc_now()
    
    attrs = %{
      last_completed_date: completed_at,
      next_due_date: calculate_next_due_date(%{schedule | last_completed_date: completed_at})
    }
    
    update_pm_schedule(schedule, attrs)
  end
end
