defmodule Shop1CmmsWeb.PmSchedulesLive.HistoryComponent do
  use Shop1CmmsWeb, :live_component
  alias Shop1Cmms.Maintenance

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:sort_by, :execution_date)
     |> assign(:sort_direction, :desc)
     |> assign(:filter_status, "all")
     |> load_executions()}
  end

  @impl true
  def handle_event("sort", %{"column" => column}, socket) do
    column_atom = String.to_existing_atom(column)
    
    {new_direction, new_sort_by} =
      if socket.assigns.sort_by == column_atom do
        {toggle_direction(socket.assigns.sort_direction), column_atom}
      else
        {:asc, column_atom}
      end

    {:noreply,
     socket
     |> assign(:sort_by, new_sort_by)
     |> assign(:sort_direction, new_direction)
     |> load_executions()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> load_executions()}
  end

  @impl true
  def handle_event("export_csv", _, socket) do
    # TODO: Implement CSV export
    {:noreply, put_flash(socket, :info, "CSV export feature coming soon")}
  end

  defp load_executions(socket) do
    executions =
      Maintenance.list_pm_executions_for_schedule(
        socket.assigns.tenant_id,
        socket.assigns.pm_schedule.id
      )
      |> apply_status_filter(socket.assigns.filter_status)
      |> sort_executions(socket.assigns.sort_by, socket.assigns.sort_direction)

    stats = calculate_stats(executions)

    socket
    |> assign(:executions, executions)
    |> assign(:stats, stats)
  end

  defp apply_status_filter(executions, "all"), do: executions
  defp apply_status_filter(executions, status) do
    status_atom = String.to_existing_atom(status)
    Enum.filter(executions, fn e -> e.status == status_atom end)
  end

  defp sort_executions(executions, sort_by, direction) do
    Enum.sort_by(executions, &Map.get(&1, sort_by), direction)
  end

  defp calculate_stats(executions) do
    total = length(executions)
    completed = Enum.count(executions, fn e -> e.status == :completed end)
    
    avg_duration =
      executions
      |> Enum.filter(fn e -> e.actual_duration_minutes end)
      |> case do
        [] -> 0
        list ->
          sum = Enum.reduce(list, 0, fn e, acc -> acc + e.actual_duration_minutes end)
          trunc(sum / length(list))
      end

    %{
      total: total,
      completed: completed,
      in_progress: Enum.count(executions, fn e -> e.status == :in_progress end),
      incomplete: Enum.count(executions, fn e -> e.status == :incomplete end),
      cancelled: Enum.count(executions, fn e -> e.status == :cancelled end),
      completion_rate: if(total > 0, do: Float.round(completed / total * 100, 1), else: 0),
      avg_duration_minutes: avg_duration
    }
  end

  defp toggle_direction(:asc), do: :desc
  defp toggle_direction(:desc), do: :asc

  defp format_datetime(nil), do: "-"
  defp format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("America/New_York")
    |> Calendar.strftime("%m/%d/%Y %I:%M %p")
  end

  defp format_duration(nil), do: "-"
  defp format_duration(minutes) when is_integer(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    
    cond do
      hours > 0 and mins > 0 -> "#{hours}h #{mins}m"
      hours > 0 -> "#{hours}h"
      true -> "#{mins}m"
    end
  end
  defp format_duration(_), do: "-"

  defp status_badge_class(:completed), do: "bg-green-100 text-green-800"
  defp status_badge_class(:in_progress), do: "bg-blue-100 text-blue-800"
  defp status_badge_class(:incomplete), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class(:cancelled), do: "bg-red-100 text-red-800"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-800"

  defp status_label(:completed), do: "Completed"
  defp status_label(:in_progress), do: "In Progress"
  defp status_label(:incomplete), do: "Incomplete"
  defp status_label(:cancelled), do: "Cancelled"
  defp status_label(status), do: to_string(status)

  defp sort_icon(column, current_sort, current_direction) do
    cond do
      column == current_sort and current_direction == :asc -> "↑"
      column == current_sort and current_direction == :desc -> "↓"
      true -> "↕"
    end
  end
end
