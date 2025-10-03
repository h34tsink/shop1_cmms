defmodule Shop1Cmms.Exports do
  @moduledoc """
  Handles exporting data to various formats (CSV, Excel-compatible CSV, PDF placeholder)
  """

  @doc """
  Exports assets to CSV format
  """
  def export_assets_to_csv(assets) do
    headers = ["Asset Number", "Name", "Type", "Location", "Manufacturer", "Model", "Status", "Criticality", "Install Date"]
    
    rows = Enum.map(assets, fn asset ->
      [
        asset.asset_number || "",
        asset.name || "",
        get_in(asset, [Access.key(:asset_type), Access.key(:name)]) || "",
        get_in(asset, [Access.key(:location), Access.key(:name)]) || "",
        asset.manufacturer || "",
        asset.model || "",
        format_status(asset.status),
        format_criticality(asset.criticality),
        format_date(asset.install_date)
      ]
    end)
    
    csv_content = [headers | rows]
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")
    
    csv_content
  end

  @doc """
  Exports work orders to CSV format
  """
  def export_work_orders_to_csv(work_orders) do
    headers = ["WO Number", "Title", "Equipment", "Type", "Priority", "Status", "Assigned To", "Due Date", "Description"]
    
    rows = Enum.map(work_orders, fn wo ->
      [
        "WO-#{String.pad_leading("#{wo.id}", 4, "0")}",
        escape_csv(wo.title || ""),
        get_in(wo, [Access.key(:asset), Access.key(:name)]) || "",
        format_atom(wo.type),
        format_atom(wo.priority),
        format_atom(wo.status),
        wo.assigned_to_name || "",
        format_date(wo.scheduled_end_date),
        escape_csv(wo.description || "")
      ]
    end)
    
    csv_content = [headers | rows]
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")
    
    csv_content
  end

  @doc """
  Exports PM schedules to CSV format
  """
  def export_pm_schedules_to_csv(schedules) do
    headers = ["Schedule Number", "Title", "Equipment", "Frequency", "Last Completed", "Next Due", "Status", "Description"]
    
    rows = Enum.map(schedules, fn schedule ->
      [
        schedule.schedule_number || "",
        escape_csv(schedule.title || ""),
        get_in(schedule, [Access.key(:asset), Access.key(:name)]) || "",
        format_frequency(schedule.frequency),
        format_datetime(schedule.last_completed_date),
        format_datetime(schedule.next_due_date),
        if(schedule.is_active, do: "Active", else: "Inactive"),
        escape_csv(schedule.description || "")
      ]
    end)
    
    csv_content = [headers | rows]
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")
    
    csv_content
  end

  @doc """
  Exports maintenance history to CSV format
  """
  def export_maintenance_history_to_csv(history) do
    headers = ["Date", "Type", "Title", "Equipment", "Technician", "Duration", "Status", "Notes"]
    
    rows = Enum.map(history, fn record ->
      [
        format_date(record.date),
        record.type || "",
        escape_csv(record.title || ""),
        record.equipment_name || "",
        record.technician_name || "",
        format_duration(record.duration),
        record.status || "",
        escape_csv(record.notes || "")
      ]
    end)
    
    csv_content = [headers | rows]
    |> Enum.map(&Enum.join(&1, ","))
    |> Enum.join("\n")
    
    csv_content
  end

  # Helper functions

  defp escape_csv(value) when is_binary(value) do
    # Escape commas and quotes in CSV values
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"#{String.replace(value, "\"", "\"\"")}\""
    else
      value
    end
  end
  defp escape_csv(_), do: ""

  defp format_status(status) when is_atom(status) do
    status
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
  defp format_status(_), do: ""

  defp format_criticality(criticality) when is_atom(criticality) do
    criticality
    |> Atom.to_string()
    |> String.capitalize()
  end
  defp format_criticality(_), do: ""

  defp format_atom(atom) when is_atom(atom) do
    atom
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
  defp format_atom(_), do: ""

  defp format_frequency(frequency) when is_atom(frequency) do
    case frequency do
      :daily -> "Daily"
      :weekly -> "Weekly"
      :biweekly -> "Bi-weekly"
      :monthly -> "Monthly"
      :quarterly -> "Quarterly"
      :semiannually -> "Semi-annually"
      :annually -> "Annually"
      :custom -> "Custom"
      _ -> Atom.to_string(frequency) |> String.capitalize()
    end
  end
  defp format_frequency(_), do: ""

  defp format_date(nil), do: ""
  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%Y-%m-%d")
  end
  defp format_date(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d")
  end
  defp format_date(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d")
  end
  defp format_date(_), do: ""

  defp format_datetime(nil), do: ""
  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
  defp format_datetime(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
  defp format_datetime(%Date{} = date) do
    format_date(date)
  end
  defp format_datetime(_), do: ""

  defp format_duration(nil), do: ""
  defp format_duration(minutes) when is_number(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    "#{hours}h #{mins}m"
  end
  defp format_duration(_), do: ""
end
