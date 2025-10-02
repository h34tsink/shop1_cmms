defmodule Shop1CmmsWeb.MaintenanceHistoryLive do
  use Shop1CmmsWeb, :live_view
  alias Shop1Cmms.{Assets, Accounts, Maintenance, WorkOrders}
  alias Shop1Cmms.Repo
  import Ecto.Query
  alias Decimal

  @impl true
  def mount(_params, _session, socket) do
    # The on_mount hooks have already set current_user, current_tenant, etc.
    # We just need to use what's already in socket.assigns

    socket =
      socket
      |> assign(:page_title, "Maintenance History")
      |> assign(:history_type, "all")
      |> assign(:filters, default_filters())
      |> assign(:sort_by, "date")
      |> assign(:sort_order, "desc")
      |> assign(:search_query, "")
      |> assign(:page, 1)
      |> assign(:per_page, 50)
      |> load_history()
      |> load_filter_options()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    history_type = params["type"] || "all"

    socket =
      socket
      |> assign(:history_type, history_type)
      |> apply_params(params)
      |> load_history()

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    filters = Map.merge(socket.assigns.filters, atomize_keys(filter_params))

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:page, 1)
      |> load_history()

    {:noreply, socket}
  end

  def handle_event("search", %{"search" => query}, socket) do
    socket =
      socket
      |> assign(:search_query, query)
      |> assign(:page, 1)
      |> load_history()

    {:noreply, socket}
  end

  def handle_event("sort", %{"column" => column}, socket) do
    current_sort = socket.assigns.sort_by
    new_order =
      if current_sort == column && socket.assigns.sort_order == "asc", do: "desc", else: "asc"

    socket =
      socket
      |> assign(:sort_by, column)
      |> assign(:sort_order, new_order)
      |> load_history()

    {:noreply, socket}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {page_num, _} = Integer.parse(page)

    socket =
      socket
      |> assign(:page, page_num)
      |> load_history()

    {:noreply, socket}
  end

  def handle_event("export", %{"format" => format}, socket) do
    # TODO: Implement export functionality
    {:noreply, put_flash(socket, :info, "Export to #{format} coming soon")}
  end

  def handle_event("view_detail", %{"id" => id, "type" => type}, socket) do
    # Redirect to detail page based on type
    path =
      case type do
        "PM" -> ~p"/pm-schedules/#{id}"
        "Work Order" -> ~p"/work_orders/#{id}"
        _ -> ~p"/maintenance-history"
      end

    {:noreply, push_navigate(socket, to: path)}
  end

  # Private Functions

  defp load_history(socket) do
    tenant_id = socket.assigns.current_tenant_id
    filters = socket.assigns.filters
    search = socket.assigns.search_query
    sort_by = socket.assigns.sort_by
    sort_order = socket.assigns.sort_order
    page = socket.assigns.page
    per_page = socket.assigns.per_page

    {history, total_count} =
      get_maintenance_history(
        tenant_id,
        socket.assigns.history_type,
        filters,
        search,
        sort_by,
        sort_order,
        page,
        per_page
      )

    total_pages = ceil(total_count / per_page)

    socket
    |> assign(:history, history)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
  end

  defp load_filter_options(socket) do
    tenant_id = socket.assigns.current_tenant_id

    # Load filter options from database
    equipment = Assets.list_assets(tenant_id)
    technicians = Shop1Cmms.Accounts.list_tenant_users(tenant_id)
                  |> Enum.map(fn %{user: user} -> user end)

    socket
    |> assign(:equipment_options, equipment)
    |> assign(:technician_options, technicians)
  end

  defp apply_params(socket, params) do
    filters = socket.assigns.filters

    filters =
      Enum.reduce(params, filters, fn {key, value}, acc ->
        case key do
          "equipment_id" -> Map.put(acc, :equipment_id, value)
          "technician_id" -> Map.put(acc, :technician_id, value)
          "date_from" -> Map.put(acc, :date_from, value)
          "date_to" -> Map.put(acc, :date_to, value)
          "status" -> Map.put(acc, :status, value)
          _ -> acc
        end
      end)

    assign(socket, :filters, filters)
  end

  defp default_filters do
    %{
      equipment_id: nil,
      technician_id: nil,
      date_from: nil,
      date_to: nil,
      status: nil
    }
  end

  defp atomize_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp get_maintenance_history(
         tenant_id,
         history_type,
         filters,
         search,
         sort_by,
         sort_order,
         page,
         per_page
       ) do
    # Build PM executions query using joins for better performance
    pm_query =
      from(e in Shop1Cmms.Maintenance.PmExecution,
        left_join: ps in Shop1Cmms.Maintenance.PmSchedule,
        on: e.pm_schedule_id == ps.id,
        left_join: a in Shop1Cmms.Assets.Asset,
        on: e.asset_id == a.id,
        left_join: u in Shop1Cmms.Accounts.User,
        on: e.completed_by_user_id == u.id,
        where: not is_nil(e.tenant_id) and e.tenant_id == ^tenant_id and e.status == :completed,
        select: %{
          id: type(e.id, :string),
          type: type(^"PM", :string),
          date: e.execution_date,
          completed_date: e.completed_date,
          title: e.execution_number,
          description: fragment("COALESCE(?, 'N/A') || ' - ' || COALESCE(?, 'Unknown')", ps.title, a.name),
          status: type(^"completed", :string),
          equipment_id: type(e.asset_id, :string),
          equipment_name: coalesce(a.name, "Unknown"),
          technician_id: e.completed_by_user_id,
          technician_name: coalesce(u.username, "Unknown"),
          duration: e.actual_duration_minutes,
          cost: type(^Decimal.new("0"), :decimal),
          notes: e.tech_notes,
          reference_id: type(e.pm_schedule_id, :string)
        }
      )

    # Build work orders query using joins
    wo_query =
      from(w in WorkOrders.WorkOrder,
        left_join: a in Shop1Cmms.Assets.Asset,
        on: w.asset_id == a.id,
        left_join: u in Shop1Cmms.Accounts.User,
        on: w.assigned_to == u.id,
        where: not is_nil(w.tenant_id) and w.tenant_id == ^tenant_id and w.status == :completed,
        select: %{
          id: type(w.id, :string),
          type: type(^"Work Order", :string),
          date: w.actual_start_date,
          completed_date: w.actual_end_date,
          title: w.title,
          description: w.description,
          status: type(^"completed", :string),
          equipment_id: type(w.asset_id, :string),
          equipment_name: coalesce(a.name, "Unknown"),
          technician_id: w.assigned_to,
          technician_name: coalesce(u.username, "Unknown"),
          duration: fragment("CAST(? * 60 AS integer)", w.actual_hours),
          cost: coalesce(w.actual_cost, type(^Decimal.new("0"), :decimal)),
          notes: w.completion_notes,
          reference_id: type(w.id, :string)
        }
      )

    # Combine queries using union_all
    combined_query =
      pm_query
      |> union_all(^wo_query)

    base_query =
      from(s in subquery(combined_query),
        as: :history
      )

    # Apply filters
    query = apply_filters(base_query, filters, search, history_type)

    # Apply sorting
    query = apply_sorting(query, sort_by, sort_order)

    # Get total count
    total_count = Repo.aggregate(query, :count, :id)

    # Apply pagination
    offset = (page - 1) * per_page

    history =
      query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    {history, total_count}
  end

  defp apply_filters(query, filters, search, history_type) do
    query
    |> filter_by_type(history_type)
    |> filter_by_equipment(filters[:equipment_id])
    |> filter_by_technician(filters[:technician_id])
    |> filter_by_date_range(filters[:date_from], filters[:date_to])
    |> filter_by_search(search)
  end

  defp filter_by_type(query, "all"), do: query

  defp filter_by_type(query, "pm") do
    from([history: h] in query, where: h.type == "PM")
  end

  defp filter_by_type(query, "work_orders") do
    from([history: h] in query, where: h.type == "Work Order")
  end

  defp filter_by_equipment(query, nil), do: query

  defp filter_by_equipment(query, equipment_id) when equipment_id != "" do
    from([history: h] in query, where: h.equipment_id == ^equipment_id)
  end

  defp filter_by_equipment(query, _), do: query

  defp filter_by_technician(query, nil), do: query

  defp filter_by_technician(query, technician_id) when technician_id != "" do
    {tech_id, _} = Integer.parse(technician_id)
    from([history: h] in query, where: h.technician_id == ^tech_id)
  end

  defp filter_by_technician(query, _), do: query

  defp filter_by_date_range(query, nil, nil), do: query

  defp filter_by_date_range(query, date_from, nil) when date_from != "" and not is_nil(date_from) do
    {:ok, from_date} = Date.from_iso8601(date_from)
    from([history: h] in query, where: fragment("?::date", h.date) >= ^from_date)
  end

  defp filter_by_date_range(query, nil, date_to) when date_to != "" and not is_nil(date_to) do
    {:ok, to_date} = Date.from_iso8601(date_to)
    from([history: h] in query, where: fragment("?::date", h.date) <= ^to_date)
  end

  defp filter_by_date_range(query, date_from, date_to)
       when date_from != "" and date_to != "" and not is_nil(date_from) and not is_nil(date_to) do
    {:ok, from_date} = Date.from_iso8601(date_from)
    {:ok, to_date} = Date.from_iso8601(date_to)

    from([history: h] in query,
      where: fragment("?::date", h.date) >= ^from_date and fragment("?::date", h.date) <= ^to_date
    )
  end

  defp filter_by_date_range(query, _, _), do: query

  defp filter_by_search(query, nil), do: query
  defp filter_by_search(query, ""), do: query

  defp filter_by_search(query, search) when is_binary(search) do
    search_pattern = "%#{search}%"

    from([history: h] in query,
      where:
        ilike(h.title, ^search_pattern) or
          ilike(h.description, ^search_pattern) or
          ilike(h.equipment_name, ^search_pattern) or
          ilike(h.technician_name, ^search_pattern)
    )
  end

  defp apply_sorting(query, "date", "desc") do
    from([history: h] in query, order_by: [desc: h.date])
  end

  defp apply_sorting(query, "date", "asc") do
    from([history: h] in query, order_by: [asc: h.date])
  end

  defp apply_sorting(query, "type", "desc") do
    from([history: h] in query, order_by: [desc: h.type, desc: h.date])
  end

  defp apply_sorting(query, "type", "asc") do
    from([history: h] in query, order_by: [asc: h.type, desc: h.date])
  end

  defp apply_sorting(query, "equipment", "desc") do
    from([history: h] in query, order_by: [desc: h.equipment_name, desc: h.date])
  end

  defp apply_sorting(query, "equipment", "asc") do
    from([history: h] in query, order_by: [asc: h.equipment_name, desc: h.date])
  end

  defp apply_sorting(query, "technician", "desc") do
    from([history: h] in query, order_by: [desc: h.technician_name, desc: h.date])
  end

  defp apply_sorting(query, "technician", "asc") do
    from([history: h] in query, order_by: [asc: h.technician_name, desc: h.date])
  end

  defp apply_sorting(query, _, _) do
    from([history: h] in query, order_by: [desc: h.date])
  end

  # Helper Functions for Template

  defp type_badge_color("PM"), do: "bg-blue-100 text-blue-800"
  defp type_badge_color("Work Order"), do: "bg-green-100 text-green-800"
  defp type_badge_color(_), do: "bg-gray-100 text-gray-800"

  defp status_badge_color("completed"), do: "bg-green-100 text-green-800"
  defp status_badge_color(_), do: "bg-gray-100 text-gray-800"

  defp format_datetime(nil), do: "N/A"
  defp format_datetime(datetime) when is_binary(datetime), do: datetime
  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
  defp format_datetime(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
  end
  defp format_datetime(%Date{} = date) do
    Calendar.strftime(date, "%Y-%m-%d")
  end

  defp format_duration(nil), do: "N/A"
  defp format_duration(minutes) when is_number(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    "#{hours}h #{mins}m"
  end
  defp format_duration(_), do: "N/A"

  defp humanize_status(status) when is_binary(status) do
    status
    |> String.replace("_", " ")
    |> String.capitalize()
  end
  defp humanize_status(_), do: "Unknown"
end