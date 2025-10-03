defmodule Shop1CmmsWeb.PmExecutionDetailLive do
  @moduledoc """
  LiveView for displaying completed PM execution details (read-only audit view).
  This view shows what was done during a specific PM execution.
  """
  use Shop1CmmsWeb, :live_view
  alias Shop1Cmms.{Maintenance, Assets, Accounts}
  alias Shop1Cmms.Maintenance.PmExecution

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    tenant_id = socket.assigns.current_tenant_id

    case Maintenance.get_pm_execution(tenant_id, id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "PM execution not found")
         |> push_navigate(to: ~p"/maintenance-history")}

      execution ->
        {:ok,
         socket
         |> assign(:page_title, "PM Execution Details")
         |> assign(:execution, execution)
         |> assign(:read_only, true)}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("back_to_history", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/maintenance-history")}
  end

  def handle_event("view_schedule", _params, socket) do
    schedule_id = socket.assigns.execution.pm_schedule_id

    {:noreply, push_navigate(socket, to: ~p"/pm-schedules/#{schedule_id}")}
  end

  def handle_event("view_equipment", _params, socket) do
    equipment_id = socket.assigns.execution.asset_id

    {:noreply, push_navigate(socket, to: ~p"/assets/#{equipment_id}")}
  end

  # Helper functions

  defp format_datetime(nil), do: "N/A"
  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
  defp format_datetime(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end

  defp format_duration(nil), do: "N/A"
  defp format_duration(minutes) when is_number(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    "#{hours}h #{mins}m"
  end

  defp format_decimal_duration(nil), do: "N/A"
  defp format_decimal_duration(%Decimal{} = hours) do
    hours_int = Decimal.to_integer(hours)
    "#{hours_int}h"
  end
  defp format_decimal_duration(hours) when is_number(hours) do
    "#{hours}h"
  end

  defp format_frequency(%{frequency: frequency, frequency_interval: interval}) do
    frequency_label = case frequency do
      :daily -> "Daily"
      :weekly -> "Weekly"
      :biweekly -> "Bi-weekly"
      :monthly -> "Monthly"
      :quarterly -> "Quarterly"
      :semiannual -> "Semi-annual"
      :annual -> "Annual"
      :biennial -> "Biennial"
      :meter_based -> "Meter-based"
      :condition_based -> "Condition-based"
      _ -> to_string(frequency)
    end

    if interval && interval > 1 do
      "Every #{interval} - #{frequency_label}"
    else
      frequency_label
    end
  end

  defp status_badge_class(status) do
    case status do
      :completed -> "bg-green-100 text-green-800"
      :in_progress -> "bg-blue-100 text-blue-800"
      :incomplete -> "bg-yellow-100 text-yellow-800"
      :cancelled -> "bg-red-100 text-red-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp status_label(status) do
    case status do
      :completed -> "Completed"
      :in_progress -> "In Progress"
      :incomplete -> "Incomplete"
      :cancelled -> "Cancelled"
      _ -> to_string(status)
    end
  end
end
