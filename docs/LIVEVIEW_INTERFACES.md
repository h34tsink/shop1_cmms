# LiveView Interface Implementation

## Overview

This document outlines the LiveView interfaces for the CMMS, focusing on PM scheduling, work order management, and technician-friendly mobile-responsive design.

## Interface Structure

```
lib/shop1_cmms_web/live/
├── dashboard_live/
│   └── index.ex                    # Main dashboard
├── pm_live/
│   ├── calendar.ex                 # PM calendar view
│   ├── template_index.ex           # PM template management
│   ├── template_form.ex            # PM template form
│   └── schedule_index.ex           # PM schedule management
├── work_order_live/
│   ├── index.ex                    # Work order kanban/list
│   ├── show.ex                     # Work order details
│   ├── form.ex                     # Work order creation/editing
│   └── components/
│       ├── kanban_card.ex          # Work order cards
│       └── task_list.ex            # Task management
├── asset_live/
│   ├── index.ex                    # Asset listing
│   ├── show.ex                     # Asset details
│   └── meter_readings.ex           # Meter reading interface
└── components/
    ├── navigation.ex               # Main navigation
    ├── mobile_nav.ex               # Mobile navigation
    └── notification_badge.ex       # Real-time notifications
```

## 1. Dashboard LiveView

### Main Dashboard (lib/shop1_cmms_web/live/dashboard_live/index.ex)

```elixir
defmodule Shop1CmmsWeb.DashboardLive.Index do
  use Shop1CmmsWeb, :live_view
  import Shop1CmmsWeb.LiveHelpers

  alias Shop1Cmms.{Maintenance, Work, Assets}

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to real-time updates
      Phoenix.PubSub.subscribe(Shop1Cmms.PubSub, "tenant:#{socket.assigns.current_user.tenant_id}")
    end

    socket =
      socket
      |> assign_dashboard_data()
      |> assign(:page_title, "Dashboard")

    {:ok, socket}
  end

  def handle_info({:work_order_updated, work_order}, socket) do
    # Real-time work order updates
    {:noreply, update_work_order_counts(socket)}
  end

  def handle_info({:pm_overdue, count}, socket) do
    # Real-time PM overdue updates
    {:noreply, assign(socket, :overdue_pms, count)}
  end

  defp assign_dashboard_data(socket) do
    user = socket.assigns.current_user
    tenant_id = user.tenant_id

    # Get dashboard metrics based on user role and site access
    work_orders = get_work_orders_for_user(user)
    overdue_pms = get_overdue_pms_for_user(user)
    low_stock_parts = get_low_stock_parts_for_user(user)
    recent_meter_readings = get_recent_meter_readings_for_user(user)

    socket
    |> assign(:work_order_counts, calculate_work_order_counts(work_orders))
    |> assign(:overdue_pms, overdue_pms)
    |> assign(:low_stock_parts, low_stock_parts)
    |> assign(:recent_work_orders, Enum.take(work_orders, 5))
    |> assign(:recent_meter_readings, recent_meter_readings)
    |> assign(:user_role, user.role)
  end

  defp get_work_orders_for_user(user) do
    case user.role do
      "technician" ->
        Work.list_work_orders_assigned_to(user.id)
      "operator" ->
        Work.list_work_orders_requested_by(user.id)
      _ ->
        Work.list_work_orders(user.tenant_id, site_id: user.site_id)
    end
  end

  defp get_overdue_pms_for_user(user) do
    case user.role do
      role when role in ["technician", "operator"] ->
        Maintenance.count_overdue_pms(user.tenant_id, site_id: user.site_id)
      _ ->
        Maintenance.count_overdue_pms(user.tenant_id)
    end
  end

  defp calculate_work_order_counts(work_orders) do
    Enum.reduce(work_orders, %{}, fn wo, acc ->
      Map.update(acc, wo.status, 1, &(&1 + 1))
    end)
  end
end
```

### Dashboard Template (lib/shop1_cmms_web/live/dashboard_live/index.html.heex)

```heex
<div class="min-h-screen bg-gray-50">
  <!-- Mobile-first responsive layout -->
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
    
    <!-- Header with role-based greeting -->
    <div class="mb-8">
      <h1 class="text-2xl font-bold text-gray-900 sm:text-3xl">
        Good <%= greeting_time() %>, <%= @current_user.first_name || "there" %>
      </h1>
      <p class="text-gray-600"><%= User.role_display_name(@user_role) %> Dashboard</p>
    </div>

    <!-- Quick Stats Cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      <!-- Work Orders Card -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <.icon name="hero-clipboard-document-list" class="h-8 w-8 text-blue-600" />
          </div>
          <div class="ml-4 flex-1">
            <p class="text-sm font-medium text-gray-600">Active Work Orders</p>
            <p class="text-2xl font-bold text-gray-900">
              <%= Map.get(@work_order_counts, "in_progress", 0) + Map.get(@work_order_counts, "assigned", 0) %>
            </p>
          </div>
        </div>
        <%= if user_can?(@socket, :view_work_orders) do %>
          <.link navigate={~p"/work-orders"} class="mt-4 text-sm text-blue-600 hover:text-blue-500">
            View all →
          </.link>
        <% end %>
      </div>

      <!-- Overdue PMs Card -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex items-center">
          <div class="flex-shrink-0">
            <.icon name="hero-exclamation-triangle" class="h-8 w-8 text-red-600" />
          </div>
          <div class="ml-4 flex-1">
            <p class="text-sm font-medium text-gray-600">Overdue PMs</p>
            <p class="text-2xl font-bold text-red-600"><%= @overdue_pms %></p>
          </div>
        </div>
        <%= if user_can?(@socket, :manage_pm_schedules) do %>
          <.link navigate={~p"/pm/calendar"} class="mt-4 text-sm text-red-600 hover:text-red-500">
            View calendar →
          </.link>
        <% end %>
      </div>

      <!-- Low Stock Alert (if inventory access) -->
      <%= if user_can?(@socket, :view_inventory) do %>
        <div class="bg-white rounded-lg shadow p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <.icon name="hero-archive-box-x-mark" class="h-8 w-8 text-yellow-600" />
            </div>
            <div class="ml-4 flex-1">
              <p class="text-sm font-medium text-gray-600">Low Stock Items</p>
              <p class="text-2xl font-bold text-yellow-600"><%= length(@low_stock_parts) %></p>
            </div>
          </div>
          <.link navigate={~p"/inventory"} class="mt-4 text-sm text-yellow-600 hover:text-yellow-500">
            Manage inventory →
          </.link>
        </div>
      <% end %>

      <!-- Quick Actions -->
      <div class="bg-white rounded-lg shadow p-6">
        <p class="text-sm font-medium text-gray-600 mb-4">Quick Actions</p>
        <div class="space-y-2">
          <%= if user_can?(@socket, :create_work_orders) do %>
            <.link navigate={~p"/work-orders/new"} 
                   class="block w-full text-center bg-blue-600 text-white px-3 py-2 rounded text-sm font-medium hover:bg-blue-700">
              New Work Order
            </.link>
          <% end %>
          <%= if @user_role == "operator" do %>
            <.link navigate={~p"/work-requests/new"} 
                   class="block w-full text-center bg-green-600 text-white px-3 py-2 rounded text-sm font-medium hover:bg-green-700">
              Report Issue
            </.link>
          <% end %>
          <.link navigate={~p"/meter-readings/quick"} 
                 class="block w-full text-center bg-gray-600 text-white px-3 py-2 rounded text-sm font-medium hover:bg-gray-700">
            Add Reading
          </.link>
        </div>
      </div>
    </div>

    <!-- Main Content Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      
      <!-- Recent Work Orders -->
      <div class="bg-white rounded-lg shadow">
        <div class="px-6 py-4 border-b border-gray-200">
          <h2 class="text-lg font-medium text-gray-900">Recent Work Orders</h2>
        </div>
        <div class="divide-y divide-gray-200">
          <%= for work_order <- @recent_work_orders do %>
            <div class="px-6 py-4 hover:bg-gray-50">
              <div class="flex items-center justify-between">
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-gray-900 truncate">
                    <%= work_order.number %> - <%= work_order.title %>
                  </p>
                  <p class="text-sm text-gray-500">
                    <%= work_order.asset && work_order.asset.name %>
                  </p>
                </div>
                <div class="flex-shrink-0 ml-4">
                  <.badge status={work_order.status} />
                </div>
              </div>
              <div class="mt-2 flex items-center text-sm text-gray-500">
                <.icon name="hero-calendar" class="h-4 w-4 mr-1" />
                <%= if work_order.due_date do %>
                  Due <%= Calendar.strftime(work_order.due_date, "%b %d") %>
                <% else %>
                  No due date
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
        <%= if user_can?(@socket, :view_work_orders) do %>
          <div class="px-6 py-3 bg-gray-50">
            <.link navigate={~p"/work-orders"} class="text-sm text-blue-600 hover:text-blue-500">
              View all work orders →
            </.link>
          </div>
        <% end %>
      </div>

      <!-- PM Calendar Preview -->
      <%= if user_can?(@socket, :view_pm_schedules) do %>
        <div class="bg-white rounded-lg shadow">
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-lg font-medium text-gray-900">Upcoming PMs</h2>
          </div>
          <div class="p-6">
            <.live_component 
              module={Shop1CmmsWeb.Components.PMCalendarPreview}
              id="pm-calendar-preview"
              tenant_id={@current_user.tenant_id}
              site_id={@current_user.site_id}
            />
          </div>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

## 2. PM Calendar LiveView

### PM Calendar (lib/shop1_cmms_web/live/pm_live/calendar.ex)

```elixir
defmodule Shop1CmmsWeb.PMLive.Calendar do
  use Shop1CmmsWeb, :live_view
  import Shop1CmmsWeb.LiveHelpers

  alias Shop1Cmms.Maintenance

  def mount(_params, _session, socket) do
    socket = require_permission(socket, :view_pm_schedules)
    
    today = Date.utc_today()
    current_month = %{year: today.year, month: today.month}
    
    socket =
      socket
      |> assign(:current_month, current_month)
      |> assign(:selected_date, today)
      |> assign(:view_mode, "month") # month, week, list
      |> load_pm_data()

    {:ok, socket}
  end

  def handle_event("change_month", %{"month" => month_str}, socket) do
    [year, month] = String.split(month_str, "-") |> Enum.map(&String.to_integer/1)
    current_month = %{year: year, month: month}
    
    socket =
      socket
      |> assign(:current_month, current_month)
      |> load_pm_data()
    
    {:noreply, socket}
  end

  def handle_event("complete_pm", %{"schedule_id" => schedule_id}, socket) do
    socket = require_permission(socket, :complete_pm_schedules)
    
    case Maintenance.complete_pm_schedule(schedule_id, %{completed_by: socket.assigns.current_user.id}) do
      {:ok, _schedule} ->
        socket =
          socket
          |> put_flash(:info, "PM marked as completed")
          |> load_pm_data()
        
        {:noreply, socket}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to complete PM")}
    end
  end

  def handle_event("generate_work_order", %{"schedule_id" => schedule_id}, socket) do
    socket = require_permission(socket, :create_work_orders)
    
    schedule = Maintenance.get_pm_schedule!(schedule_id, socket.assigns.current_user.tenant_id)
    
    case Maintenance.create_work_order_from_schedule(schedule) do
      {:ok, work_order} ->
        socket =
          socket
          |> put_flash(:info, "Work order #{work_order.number} created")
          |> load_pm_data()
        
        {:noreply, socket}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create work order")}
    end
  end

  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :view_mode, view)}
  end

  defp load_pm_data(socket) do
    user = socket.assigns.current_user
    current_month = socket.assigns.current_month
    
    # Get PM schedules for the current month
    start_date = Date.new!(current_month.year, current_month.month, 1)
    end_date = Date.end_of_month(start_date)
    
    pm_schedules = Maintenance.list_pm_schedules_for_period(
      user.tenant_id, 
      start_date, 
      end_date,
      site_id: user.site_id
    )
    
    # Group by date for calendar display
    pm_calendar = group_pms_by_date(pm_schedules, start_date, end_date)
    
    socket
    |> assign(:pm_schedules, pm_schedules)
    |> assign(:pm_calendar, pm_calendar)
    |> assign(:overdue_count, count_overdue_pms(pm_schedules))
  end

  defp group_pms_by_date(schedules, start_date, end_date) do
    # Create a map of dates to PM schedules
    date_range = Date.range(start_date, end_date)
    
    empty_calendar = 
      Enum.reduce(date_range, %{}, fn date, acc ->
        Map.put(acc, date, [])
      end)
    
    Enum.reduce(schedules, empty_calendar, fn schedule, acc ->
      due_date = schedule.next_due_date
      if due_date && due_date >= start_date && due_date <= end_date do
        Map.update(acc, due_date, [schedule], &[schedule | &1])
      else
        acc
      end
    end)
  end
end
```

## 3. Work Order Kanban LiveView

### Work Order Index (lib/shop1_cmms_web/live/work_order_live/index.ex)

```elixir
defmodule Shop1CmmsWeb.WorkOrderLive.Index do
  use Shop1CmmsWeb, :live_view
  import Shop1CmmsWeb.LiveHelpers

  alias Shop1Cmms.Work

  def mount(_params, _session, socket) do
    socket = require_permission(socket, :view_work_orders)
    
    if connected?(socket) do
      Work.subscribe_to_work_order_updates(socket.assigns.current_user.tenant_id)
    end
    
    socket =
      socket
      |> assign(:view_mode, "kanban") # kanban, list, calendar
      |> assign(:filters, %{status: nil, priority: nil, assigned_to: nil})
      |> load_work_orders()

    {:ok, socket}
  end

  def handle_info({:work_order_updated, work_order}, socket) do
    # Real-time work order updates
    {:noreply, update_work_order_in_lists(socket, work_order)}
  end

  def handle_event("filter", %{"filter" => filter_params}, socket) do
    filters = parse_filters(filter_params)
    
    socket =
      socket
      |> assign(:filters, filters)
      |> load_work_orders()
    
    {:noreply, socket}
  end

  def handle_event("change_status", %{"id" => id, "status" => new_status}, socket) do
    socket = require_permission(socket, :update_work_orders)
    
    work_order = Work.get_work_order!(id, socket.assigns.current_user.tenant_id)
    
    case Work.update_work_order_status(work_order, new_status, socket.assigns.current_user.id) do
      {:ok, updated_work_order} ->
        # Broadcast update to other connected users
        Work.broadcast_work_order_update(updated_work_order)
        
        {:noreply, put_flash(socket, :info, "Work order status updated")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update work order")}
    end
  end

  def handle_event("assign_to_me", %{"id" => id}, socket) do
    work_order = Work.get_work_order!(id, socket.assigns.current_user.tenant_id)
    
    case Work.assign_work_order(work_order, socket.assigns.current_user.id) do
      {:ok, _updated_work_order} ->
        {:noreply, put_flash(socket, :info, "Work order assigned to you")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to assign work order")}
    end
  end

  defp load_work_orders(socket) do
    user = socket.assigns.current_user
    filters = socket.assigns.filters
    
    work_orders = 
      Work.list_work_orders(user.tenant_id, filters)
      |> filter_by_user_access(user, :work_order)
    
    # Group by status for kanban view
    kanban_columns = group_work_orders_by_status(work_orders)
    
    socket
    |> assign(:work_orders, work_orders)
    |> assign(:kanban_columns, kanban_columns)
  end

  defp group_work_orders_by_status(work_orders) do
    statuses = ["new", "assigned", "in_progress", "waiting_parts", "review", "completed"]
    
    Enum.reduce(statuses, %{}, fn status, acc ->
      wos = Enum.filter(work_orders, &(&1.status == status))
      Map.put(acc, status, wos)
    end)
  end
end
```

## 4. Mobile-Responsive Components

### Mobile Navigation Component

```elixir
defmodule Shop1CmmsWeb.Components.MobileNav do
  use Shop1CmmsWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="lg:hidden">
      <!-- Mobile menu button -->
      <button 
        type="button" 
        class="p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100"
        phx-click="toggle_mobile_menu"
        phx-target={@myself}
      >
        <.icon name="hero-bars-3" class="h-6 w-6" />
      </button>

      <!-- Mobile menu overlay -->
      <%= if @show_mobile_menu do %>
        <div class="fixed inset-0 z-50 lg:hidden">
          <div class="fixed inset-0 bg-black bg-opacity-25" phx-click="close_mobile_menu" phx-target={@myself}></div>
          
          <div class="fixed top-0 right-0 w-full max-w-xs bg-white h-full shadow-xl">
            <div class="p-4">
              <!-- Close button -->
              <button 
                type="button"
                class="float-right p-2 text-gray-400 hover:text-gray-500"
                phx-click="close_mobile_menu"
                phx-target={@myself}
              >
                <.icon name="hero-x-mark" class="h-6 w-6" />
              </button>
              
              <!-- Navigation items -->
              <nav class="mt-8 space-y-4">
                <.mobile_nav_item 
                  icon="hero-home" 
                  text="Dashboard" 
                  path={~p"/dashboard"} 
                  current_path={@current_path}
                />
                
                <%= if user_can?(@current_user, :view_work_orders) do %>
                  <.mobile_nav_item 
                    icon="hero-clipboard-document-list" 
                    text="Work Orders" 
                    path={~p"/work-orders"} 
                    current_path={@current_path}
                  />
                <% end %>
                
                <%= if user_can?(@current_user, :view_pm_schedules) do %>
                  <.mobile_nav_item 
                    icon="hero-calendar-days" 
                    text="PM Calendar" 
                    path={~p"/pm/calendar"} 
                    current_path={@current_path}
                  />
                <% end %>
                
                <%= if user_can?(@current_user, :view_assets) do %>
                  <.mobile_nav_item 
                    icon="hero-cog-6-tooth" 
                    text="Assets" 
                    path={~p"/assets"} 
                    current_path={@current_path}
                  />
                <% end %>
                
                <%= if @current_user.role == "operator" do %>
                  <.mobile_nav_item 
                    icon="hero-plus-circle" 
                    text="Report Issue" 
                    path={~p"/work-requests/new"} 
                    current_path={@current_path}
                  />
                <% end %>
              </nav>
              
              <!-- Quick actions for technicians -->
              <%= if @current_user.role == "technician" do %>
                <div class="mt-8 pt-4 border-t border-gray-200">
                  <h3 class="text-sm font-medium text-gray-500 mb-4">Quick Actions</h3>
                  <div class="space-y-2">
                    <button class="w-full bg-blue-600 text-white px-4 py-2 rounded text-sm font-medium">
                      Clock In/Out
                    </button>
                    <.link 
                      navigate={~p"/meter-readings/quick"}
                      class="block w-full bg-gray-600 text-white px-4 py-2 rounded text-sm font-medium text-center"
                    >
                      Add Reading
                    </.link>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("toggle_mobile_menu", _, socket) do
    {:noreply, assign(socket, :show_mobile_menu, !socket.assigns.show_mobile_menu)}
  end

  def handle_event("close_mobile_menu", _, socket) do
    {:noreply, assign(socket, :show_mobile_menu, false)}
  end

  defp mobile_nav_item(assigns) do
    ~H"""
    <.link 
      navigate={@path}
      class={[
        "flex items-center px-4 py-2 text-sm font-medium rounded-md",
        if(@path == @current_path, do: "bg-blue-100 text-blue-700", else: "text-gray-600 hover:bg-gray-50")
      ]}
    >
      <.icon name={@icon} class="h-5 w-5 mr-3" />
      <%= @text %>
    </.link>
    """
  end
end
```

## Key Features of the LiveView Implementation

### Real-time Updates
- PubSub integration for live work order status changes
- Real-time PM overdue notifications
- Live inventory level updates

### Mobile-Responsive Design
- Tailwind CSS with mobile-first approach
- Collapsible navigation for mobile devices
- Touch-friendly interface elements
- Quick action buttons for technicians

### Role-Based Interface
- Dynamic content based on user permissions
- Filtered data based on site/tenant access
- Role-specific quick actions and workflows

### Performance Optimizations
- Efficient database queries with proper indexing
- Component-based architecture for reusability
- Optimistic UI updates where appropriate

This LiveView implementation provides a modern, responsive interface optimized for both desktop and mobile use, with real-time updates and proper security isolation.
