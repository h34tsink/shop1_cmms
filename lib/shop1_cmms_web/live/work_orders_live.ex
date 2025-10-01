defmodule Shop1CmmsWeb.WorkOrdersLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.WorkOrders
  alias Shop1Cmms.Assets

  @impl true
  def mount(_params, _session, socket) do
    tenant_id = socket.assigns.current_tenant.id

    {:ok,
     socket
     |> assign(:page_title, "Work Orders")
     |> assign(:search_query, "")
     |> assign(:status_filter, "all")
     |> assign(:type_filter, "all")
     |> load_work_orders(tenant_id)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Work Orders")
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Work Order")
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    tenant_id = socket.assigns.current_tenant.id
    work_order = WorkOrders.get_work_order_with_details!(id, tenant_id)

    socket
    |> assign(:page_title, "Edit Work Order")
    |> assign(:work_order, work_order)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Desktop Work Orders Page -->
    <div class="h-full flex flex-col overflow-hidden">
      <!-- Toolbar -->
      <div class="flex-shrink-0 h-10 bg-gray-100 border-b border-gray-300 flex items-center justify-between px-3">
        <!-- Breadcrumb -->
        <nav class="flex items-center text-xs space-x-1">
          <.link href="/" class="text-gray-600 hover:text-gray-900">Home</.link>
          <span class="text-gray-400">/</span>
          <span class="text-gray-900 font-medium">Work Orders</span>
        </nav>
        
        <!-- Actions -->
        <div class="flex items-center space-x-1">
          <.link navigate="/work_orders/new" class="btn-toolbar-primary">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"></path>
            </svg>
            <span>New Work Order</span>
          </.link>
          
          <button class="btn-toolbar">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"></path>
            </svg>
            <span>Export</span>
          </button>
          
          <button class="btn-toolbar">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd"></path>
            </svg>
            <span>Print</span>
          </button>
        </div>
      </div>

      <!-- Filter Bar -->
      <div class="flex-shrink-0 bg-white border-b border-gray-200 p-2">
        <div class="flex items-center space-x-2">
          <!-- Status Filter -->
          <div class="flex space-x-1">
            <button
              phx-click="filter_status"
              phx-value-status="all"
              class={["px-2 py-1 text-xs font-medium rounded transition-colors",
                      if(@status_filter == "all", do: "bg-blue-500 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")]}
            >
              All
            </button>
            <button
              phx-click="filter_status"
              phx-value-status="open"
              class={["px-2 py-1 text-xs font-medium rounded transition-colors",
                      if(@status_filter == "open", do: "bg-blue-500 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")]}
            >
              Open
            </button>
            <button
              phx-click="filter_status"
              phx-value-status="in_progress"
              class={["px-2 py-1 text-xs font-medium rounded transition-colors",
                      if(@status_filter == "in_progress", do: "bg-blue-500 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")]}
            >
              In Progress
            </button>
            <button
              phx-click="filter_status"
              phx-value-status="completed"
              class={["px-2 py-1 text-xs font-medium rounded transition-colors",
                      if(@status_filter == "completed", do: "bg-blue-500 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")]}
            >
              Completed
            </button>
          </div>

          <div class="h-4 w-px bg-gray-300"></div>

          <!-- Type Filter -->
          <div class="flex space-x-1">
            <button
              phx-click="filter_type"
              phx-value-type="all"
              class={["px-2 py-1 text-xs font-medium rounded transition-colors",
                      if(@type_filter == "all", do: "bg-green-500 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")]}
            >
              All Types
            </button>
            <button
              phx-click="filter_type"
              phx-value-type="corrective"
              class={["px-2 py-1 text-xs font-medium rounded transition-colors",
                      if(@type_filter == "corrective", do: "bg-green-500 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")]}
            >
              Corrective
            </button>
            <button
              phx-click="filter_type"
              phx-value-type="preventive"
              class={["px-2 py-1 text-xs font-medium rounded transition-colors",
                      if(@type_filter == "preventive", do: "bg-green-500 text-white", else: "bg-gray-100 text-gray-700 hover:bg-gray-200")]}
            >
              Preventive
            </button>
          </div>

          <div class="flex-1"></div>

          <!-- Search -->
          <div class="w-64">
            <form phx-change="search">
              <div class="relative">
                <input 
                  type="text" 
                  name="query" 
                  value={@search_query}
                  placeholder="Search work orders..." 
                  class="block w-full pl-7 pr-2 py-1 text-xs border-gray-300 rounded focus:ring-blue-500 focus:border-blue-500"
                />
                <svg class="absolute left-2 top-1.5 w-3.5 h-3.5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
              </div>
            </form>
          </div>

          <!-- Result Count -->
          <div class="text-xs text-gray-600 whitespace-nowrap">
            <%= length(@filtered_work_orders) %> orders
          </div>
        </div>
      </div>

      <!-- Dense Table -->
      <div class="flex-1 overflow-auto">
        <%= if length(@filtered_work_orders) > 0 do %>
          <table class="table-dense">
            <thead>
              <tr>
                <th class="w-20">WO#</th>
                <th>Title</th>
                <th>Asset</th>
                <th>Type</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Assigned To</th>
                <th>Due Date</th>
                <th class="w-24">Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for wo <- @filtered_work_orders do %>
                <tr phx-click="select_wo" phx-value-id={wo.id}>
                  <td class="font-mono text-xs font-medium">WO-<%= String.pad_leading("#{wo.id}", 4, "0") %></td>
                  <td class="font-medium text-gray-900"><%= wo.title %></td>
                  <td class="text-gray-600"><%= if wo.asset, do: wo.asset.name, else: "-" %></td>
                  <td><span class="text-xs capitalize"><%= wo.type %></span></td>
                  <td><%= render_priority(assigns, wo.priority) %></td>
                  <td><%= render_status(assigns, wo.status) %></td>
                  <td class="text-gray-600 text-xs"><%= wo.assigned_to_name || "-" %></td>
                  <td class="text-gray-600 text-xs"><%= if wo.scheduled_end_date, do: Calendar.strftime(wo.scheduled_end_date, "%b %d, %Y"), else: "-" %></td>
                  <td>
                    <div class="flex items-center space-x-1">
                      <.link navigate={"/work_orders/#{wo.id}"} class="p-1 hover:bg-gray-200 rounded" title="View">
                        <svg class="w-3.5 h-3.5 text-gray-600" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M10 12a2 2 0 100-4 2 2 0 000 4z"></path>
                          <path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"></path>
                        </svg>
                      </.link>
                      <.link navigate={"/work_orders/#{wo.id}/edit"} class="p-1 hover:bg-gray-200 rounded" title="Edit">
                        <svg class="w-3.5 h-3.5 text-gray-600" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"></path>
                        </svg>
                      </.link>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        <% else %>
          <!-- Empty State -->
          <div class="flex items-center justify-center h-full">
            <div class="text-center py-12">
              <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                </svg>
              </div>
              <h3 class="text-lg font-semibold text-gray-900">No Work Orders found</h3>
              <p class="mt-2 text-sm text-gray-500 max-w-md mx-auto">
                <%= if @search_query != "" or @status_filter != "all" or @type_filter != "all" do %>
                  No work orders match your filters. Try adjusting your criteria.
                <% else %>
                  Get started by creating your first work order.
                <% end %>
              </p>
              <div class="mt-6">
                <%= if @search_query != "" or @status_filter != "all" or @type_filter != "all" do %>
                  <button phx-click="clear_filters" class="btn-toolbar">
                    Clear Filters
                  </button>
                <% else %>
                  <.link navigate="/work_orders/new" class="btn-toolbar-primary">
                    <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"></path>
                    </svg>
                    <span>Create First Work Order</span>
                  </.link>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Table Footer -->
      <%= if length(@filtered_work_orders) > 0 do %>
        <div class="flex-shrink-0 h-8 bg-gray-50 border-t border-gray-300 flex items-center justify-between px-3 text-xs">
          <div class="text-gray-600">
            Showing <%= length(@filtered_work_orders) %> of <%= length(@work_orders) %> work orders
          </div>
          <div class="flex items-center space-x-2">
            <span class="text-gray-500">Page 1 of 1</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions
  defp render_priority(assigns, priority) do
    case priority do
      :critical -> 
        ~H"<span class='inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800'>Critical</span>"
      :high -> 
        ~H"<span class='inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-800'>High</span>"
      :medium -> 
        ~H"<span class='inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800'>Medium</span>"
      :low -> 
        ~H"<span class='inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800'>Low</span>"
      _ -> 
        ~H"<span class='text-xs text-gray-500'>-</span>"
    end
  end

  defp render_status(assigns, status) do
    case status do
      :open -> 
        ~H"<span class='inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800'>Open</span>"
      :in_progress -> 
        ~H"<span class='inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800'>In Progress</span>"
      :completed -> 
        ~H"<span class='inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800'>Completed</span>"
      :cancelled -> 
        ~H"<span class='inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800'>Cancelled</span>"
      _ -> 
        ~H"<span class='text-xs text-gray-500'>-</span>"
    end
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, socket |> assign(:search_query, query) |> apply_filters()}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, socket |> assign(:status_filter, status) |> apply_filters()}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    {:noreply, socket |> assign(:type_filter, type) |> apply_filters()}
  end

  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:search_query, "")
     |> assign(:status_filter, "all")
     |> assign(:type_filter, "all")
     |> apply_filters()}
  end

  def handle_event("select_wo", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: "/work_orders/#{id}")}
  end

  # Private functions
  defp load_work_orders(socket, tenant_id) do
    work_orders = WorkOrders.list_work_orders_with_details(tenant_id, preload: [:asset])

    socket
    |> assign(:work_orders, work_orders)
    |> assign(:filtered_work_orders, work_orders)
  end

  defp apply_filters(socket) do
    filtered =
      socket.assigns.work_orders
      |> filter_by_search(socket.assigns.search_query)
      |> filter_by_status(socket.assigns.status_filter)
      |> filter_by_type(socket.assigns.type_filter)

    assign(socket, :filtered_work_orders, filtered)
  end

  defp filter_by_search(work_orders, ""), do: work_orders
  defp filter_by_search(work_orders, query) do
    query = String.downcase(query)
    Enum.filter(work_orders, fn wo ->
      String.contains?(String.downcase(wo.title || ""), query) or
      (wo.asset && String.contains?(String.downcase(wo.asset.name || ""), query))
    end)
  end

  defp filter_by_status(work_orders, "all"), do: work_orders
  defp filter_by_status(work_orders, status) do
    status_atom = String.to_existing_atom(status)
    Enum.filter(work_orders, &(&1.status == status_atom))
  end

  defp filter_by_type(work_orders, "all"), do: work_orders
  defp filter_by_type(work_orders, type) do
    type_atom = String.to_existing_atom(type)
    Enum.filter(work_orders, &(&1.type == type_atom))
  end
end
