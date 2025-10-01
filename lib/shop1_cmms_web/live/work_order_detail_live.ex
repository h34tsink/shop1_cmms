defmodule Shop1CmmsWeb.WorkOrderDetailLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.WorkOrders
  alias Shop1Cmms.Assets

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    tenant_id = socket.assigns.current_tenant.id
    work_order = WorkOrders.get_work_order_with_details!(id, tenant_id)

    {:ok,
     socket
     |> assign(:work_order, work_order)
     |> assign(:page_title, "Work Order ##{work_order.id}")
     |> assign(:active_tab, "details")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Desktop Work Order Detail Page -->
    <div class="h-full flex flex-col overflow-hidden">
      <!-- Toolbar -->
      <div class="flex-shrink-0 h-10 bg-gray-100 border-b border-gray-300 flex items-center justify-between px-3">
        <!-- Breadcrumb -->
        <nav class="flex items-center text-xs space-x-1">
          <.link href="/" class="text-gray-600 hover:text-gray-900">Home</.link>
          <span class="text-gray-400">/</span>
          <.link href="/work_orders" class="text-gray-600 hover:text-gray-900">Work Orders</.link>
          <span class="text-gray-400">/</span>
          <span class="text-gray-900 font-medium truncate max-w-xs">WO-<%= String.pad_leading("#{@work_order.id}", 4, "0") %></span>
        </nav>
        
        <!-- Actions -->
        <div class="flex items-center space-x-1">
          <.link navigate={"/work_orders/#{@work_order.id}/edit"} class="btn-toolbar-primary">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"></path>
            </svg>
            <span>Edit</span>
          </.link>
          
          <button phx-click="change_status" phx-value-status="in_progress" class="btn-toolbar">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd"></path>
            </svg>
            <span>Start Work</span>
          </button>
          
          <button phx-click="change_status" phx-value-status="completed" class="btn-toolbar">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
            </svg>
            <span>Complete</span>
          </button>
          
          <button class="btn-toolbar">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z"></path>
            </svg>
            <span>Assign</span>
          </button>
          
          <button class="btn-toolbar">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd"></path>
            </svg>
            <span>Print</span>
          </button>
        </div>
      </div>

      <!-- Header Bar with WO Info -->
      <div class="flex-shrink-0 bg-white border-b border-gray-200 px-3 py-2">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3 min-w-0 flex-1">
            <span class="text-xs font-mono text-gray-600 flex-shrink-0">WO-<%= String.pad_leading("#{@work_order.id}", 4, "0") %></span>
            <h1 class="text-lg font-bold text-gray-900 truncate"><%= @work_order.title %></h1>
            <%= render_status(assigns, @work_order.status) %>
            <%= render_priority(assigns, @work_order.priority) %>
          </div>
          
          <div class="flex items-center space-x-2 flex-shrink-0 text-xs text-gray-600">
            <span class="capitalize"><%= @work_order.type %></span>
            <%= if @work_order.asset do %>
              <span class="text-gray-300">|</span>
              <.link navigate={"/assets/#{@work_order.asset.id}"} class="text-blue-600 hover:text-blue-800">
                <%= @work_order.asset.name %>
              </.link>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Compact Tabs -->
      <div class="flex-shrink-0 bg-gray-50 border-b border-gray-200">
        <nav class="flex space-x-1 px-3" aria-label="Tabs">
          <button
            phx-click="change_tab"
            phx-value-tab="details"
            class={[
              "px-3 py-1.5 text-xs font-medium border-b-2 transition-colors",
              if(@active_tab == "details",
                do: "border-blue-500 text-blue-600 bg-white",
                else: "border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300")
            ]}
          >
            Details
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="activity"
            class={[
              "px-3 py-1.5 text-xs font-medium border-b-2 transition-colors",
              if(@active_tab == "activity",
                do: "border-blue-500 text-blue-600 bg-white",
                else: "border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300")
            ]}
          >
            Activity Log
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="parts"
            class={[
              "px-3 py-1.5 text-xs font-medium border-b-2 transition-colors",
              if(@active_tab == "parts",
                do: "border-blue-500 text-blue-600 bg-white",
                else: "border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300")
            ]}
          >
            Parts & Materials
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="time"
            class={[
              "px-3 py-1.5 text-xs font-medium border-b-2 transition-colors",
              if(@active_tab == "time",
                do: "border-blue-500 text-blue-600 bg-white",
                else: "border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300")
            ]}
          >
            Time Tracking
          </button>
        </nav>
      </div>

      <!-- Tab Content -->
      <div class="flex-1 overflow-auto p-3 bg-gray-50">
        <%= case @active_tab do %>
          <% "details" -> %>
            <%= render_details_tab(assigns) %>
          <% "activity" -> %>
            <%= render_activity_tab(assigns) %>
          <% "parts" -> %>
            <%= render_parts_tab(assigns) %>
          <% "time" -> %>
            <%= render_time_tab(assigns) %>
        <% end %>
      </div>
    </div>
    """
  end

  # Helper functions
  defp render_status(assigns, status) do
    case status do
      :open -> 
        ~H"<span class='inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800'>Open</span>"
      :in_progress -> 
        ~H"<span class='inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800'>In Progress</span>"
      :completed -> 
        ~H"<span class='inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800'>Completed</span>"
      :cancelled -> 
        ~H"<span class='inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800'>Cancelled</span>"
      _ -> 
        ~H"<span class='text-xs text-gray-500'>-</span>"
    end
  end

  defp render_priority(assigns, priority) do
    case priority do
      :critical -> 
        ~H"<span class='inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800'>⚠ Critical</span>"
      :high -> 
        ~H"<span class='inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-800'>High</span>"
      :medium -> 
        ~H"<span class='inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800'>Medium</span>"
      :low -> 
        ~H"<span class='inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800'>Low</span>"
      _ -> 
        ~H"<span class='text-xs text-gray-500'>-</span>"
    end
  end

  defp render_details_tab(assigns) do
    ~H"""
    <div class="grid grid-cols-2 gap-3">
      <!-- Left Column -->
      <div class="space-y-3">
        <!-- Work Order Information -->
        <div class="bg-white rounded border border-gray-200 p-3">
          <h3 class="text-sm font-semibold text-gray-900 mb-2">Work Order Information</h3>
          <dl class="space-y-1 text-xs">
            <div class="flex justify-between">
              <dt class="text-gray-600">Title:</dt>
              <dd class="font-medium text-gray-900"><%= @work_order.title %></dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-600">Type:</dt>
              <dd class="capitalize text-gray-900"><%= @work_order.type %></dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-600">Priority:</dt>
              <dd><%= render_priority(assigns, @work_order.priority) %></dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-600">Status:</dt>
              <dd><%= render_status(assigns, @work_order.status) %></dd>
            </div>
          </dl>
        </div>

        <!-- Description -->
        <div class="bg-white rounded border border-gray-200 p-3">
          <h3 class="text-sm font-semibold text-gray-900 mb-2">Description</h3>
          <p class="text-xs text-gray-700 whitespace-pre-wrap"><%= @work_order.description || "No description provided." %></p>
        </div>

        <!-- Asset Information -->
        <%= if @work_order.asset do %>
          <div class="bg-white rounded border border-gray-200 p-3">
            <h3 class="text-sm font-semibold text-gray-900 mb-2">Asset Information</h3>
            <dl class="space-y-1 text-xs">
              <div class="flex justify-between">
                <dt class="text-gray-600">Asset:</dt>
                <dd class="font-medium">
                  <.link navigate={"/assets/#{@work_order.asset.id}"} class="text-blue-600 hover:text-blue-800">
                    <%= @work_order.asset.name %>
                  </.link>
                </dd>
              </div>
              <div class="flex justify-between">
                <dt class="text-gray-600">Code:</dt>
                <dd class="font-mono text-gray-900"><%= @work_order.asset.asset_code %></dd>
              </div>
            </dl>
          </div>
        <% end %>
      </div>

      <!-- Right Column -->
      <div class="space-y-3">
        <!-- Schedule -->
        <div class="bg-white rounded border border-gray-200 p-3">
          <h3 class="text-sm font-semibold text-gray-900 mb-2">Schedule</h3>
          <dl class="space-y-1 text-xs">
            <div class="flex justify-between">
              <dt class="text-gray-600">Created:</dt>
              <dd class="text-gray-900"><%= if @work_order.inserted_at, do: Calendar.strftime(@work_order.inserted_at, "%b %d, %Y %I:%M %p"), else: "-" %></dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-600">Scheduled Start:</dt>
              <dd class="text-gray-900"><%= if @work_order.scheduled_start_date, do: Calendar.strftime(@work_order.scheduled_start_date, "%b %d, %Y"), else: "-" %></dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-600">Due Date:</dt>
              <dd class="text-gray-900"><%= if @work_order.scheduled_end_date, do: Calendar.strftime(@work_order.scheduled_end_date, "%b %d, %Y"), else: "-" %></dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-600">Actual Start:</dt>
              <dd class="text-gray-900"><%= if @work_order.actual_start_date, do: Calendar.strftime(@work_order.actual_start_date, "%b %d, %Y"), else: "-" %></dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-600">Completed:</dt>
              <dd class="text-gray-900"><%= if @work_order.actual_end_date, do: Calendar.strftime(@work_order.actual_end_date, "%b %d, %Y"), else: "-" %></dd>
            </div>
          </dl>
        </div>

        <!-- Assignment -->
        <div class="bg-white rounded border border-gray-200 p-3">
          <h3 class="text-sm font-semibold text-gray-900 mb-2">Assignment</h3>
          <dl class="space-y-1 text-xs">
            <div class="flex justify-between">
              <dt class="text-gray-600">Assigned To:</dt>
              <dd class="text-gray-900"><%= @work_order.assigned_to_name || "Unassigned" %></dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-600">Department:</dt>
              <dd class="text-gray-900"><%= @work_order.department_name || "-" %></dd>
            </div>
          </dl>
        </div>

        <!-- Cost Tracking -->
        <div class="bg-white rounded border border-gray-200 p-3">
          <h3 class="text-sm font-semibold text-gray-900 mb-2">Cost Tracking</h3>
          <dl class="space-y-1 text-xs">
            <div class="flex justify-between">
              <dt class="text-gray-600">Estimated Cost:</dt>
              <dd class="text-gray-900 font-mono">$<%= if @work_order.estimated_cost, do: :erlang.float_to_binary(@work_order.estimated_cost, decimals: 2), else: "0.00" %></dd>
            </div>
            <div class="flex justify-between">
              <dt class="text-gray-600">Actual Cost:</dt>
              <dd class="text-gray-900 font-mono">$<%= if @work_order.actual_cost, do: :erlang.float_to_binary(@work_order.actual_cost, decimals: 2), else: "0.00" %></dd>
            </div>
          </dl>
        </div>
      </div>
    </div>
    """
  end

  defp render_activity_tab(assigns) do
    ~H"""
    <div class="bg-white rounded border border-gray-200 p-4">
      <h3 class="text-sm font-semibold text-gray-900 mb-3">Activity Log</h3>
      <p class="text-xs text-gray-500">Activity tracking coming soon...</p>
    </div>
    """
  end

  defp render_parts_tab(assigns) do
    ~H"""
    <div class="bg-white rounded border border-gray-200 p-4">
      <h3 class="text-sm font-semibold text-gray-900 mb-3">Parts & Materials</h3>
      <p class="text-xs text-gray-500">Parts tracking coming soon...</p>
    </div>
    """
  end

  defp render_time_tab(assigns) do
    ~H"""
    <div class="bg-white rounded border border-gray-200 p-4">
      <h3 class="text-sm font-semibold text-gray-900 mb-3">Time Tracking</h3>
      <p class="text-xs text-gray-500">Time tracking coming soon...</p>
    </div>
    """
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("change_status", %{"status" => status}, socket) do
    status_atom = String.to_existing_atom(status)
    
    case WorkOrders.update_work_order(socket.assigns.work_order, %{status: status_atom}) do
      {:ok, updated_work_order} ->
        {:noreply,
         socket
         |> assign(:work_order, updated_work_order)
         |> put_flash(:info, "Work order status updated to #{status}")}
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update work order status")}
    end
  end
end
