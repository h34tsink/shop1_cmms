defmodule Shop1CmmsWeb.PmSchedulesLive do
  use Shop1CmmsWeb, :live_view
  alias Shop1Cmms.Maintenance
  alias Shop1Cmms.Assets
  alias Shop1Cmms.Maintenance.PmSchedule

  @impl true
  def mount(_params, _session, socket) do
    tenant_id = socket.assigns.current_tenant_id
    
    {:ok,
     socket
     |> assign(:page_title, "PM Schedules")
     |> assign(:search_query, "")
     |> assign(:filter_frequency, "all")
     |> assign(:filter_status, "active")
     |> assign(:selected_schedule, nil)
     |> assign(:show_form, false)
     |> assign(:form, nil)
     |> assign(:work_instruction_lines, [])
     |> assign(:checklist_items, [])
     |> assign(:components, [])
     |> assign(:documents, [])
     |> assign(:asset_search, "")
     |> load_pm_schedules(tenant_id)
     |> load_assets(tenant_id)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "PM Schedules")
    |> assign(:show_form, false)
    |> assign(:selected_schedule, nil)
    |> assign(:form, nil)
  end

  defp apply_action(socket, :new, _params) do
    changeset = PmSchedule.changeset(%PmSchedule{tenant_id: socket.assigns.current_tenant_id}, %{})
    
    socket
    |> assign(:page_title, "New PM Schedule")
    |> assign(:show_form, true)
    |> assign(:selected_schedule, %PmSchedule{})
    |> assign(:form, to_form(changeset))
    |> assign(:work_instruction_lines, [])
    |> assign(:checklist_items, [])
    |> assign(:components, [])
    |> assign(:documents, [])
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    tenant_id = socket.assigns.current_tenant_id
    schedule = Maintenance.get_pm_schedule!(tenant_id, id)
    changeset = PmSchedule.changeset(schedule, %{})
    
    # Parse work instructions into lines
    work_instruction_lines = 
      if schedule.work_instructions do
        schedule.work_instructions
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.map(fn {line, idx} -> %{id: idx, text: line} end)
      else
        []
      end
    
    socket
    |> assign(:page_title, "Edit PM Schedule")
    |> assign(:show_form, true)
    |> assign(:selected_schedule, schedule)
    |> assign(:form, to_form(changeset))
    |> assign(:work_instruction_lines, work_instruction_lines)
    |> assign(:checklist_items, schedule.checklist_items || [])
    |> assign(:components, schedule.components || [])
    |> assign(:documents, schedule.documents || [])
  end

  @impl true
  def handle_event("search", %{"search" => query}, socket) do
    {:noreply, assign(socket, :search_query, query) |> filter_schedules()}
  end

  def handle_event("filter_frequency", %{"frequency" => frequency}, socket) do
    {:noreply, assign(socket, :filter_frequency, frequency) |> filter_schedules()}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply, assign(socket, :filter_status, status) |> filter_schedules()}
  end

  def handle_event("delete_schedule", %{"id" => id}, socket) do
    tenant_id = socket.assigns.current_tenant_id
    schedule = Maintenance.get_pm_schedule!(tenant_id, id)
    
    case Maintenance.delete_pm_schedule(schedule) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "PM Schedule deleted successfully")
         |> load_pm_schedules(tenant_id)}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete PM Schedule")}
    end
  end

  def handle_event("complete_schedule", %{"id" => id}, socket) do
    tenant_id = socket.assigns.current_tenant_id
    schedule = Maintenance.get_pm_schedule!(tenant_id, id)
    
    case Maintenance.complete_pm_schedule(schedule) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "PM Schedule marked as completed")
         |> load_pm_schedules(tenant_id)}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to complete PM Schedule")}
    end
  end

  def handle_event("validate", %{"pm_schedule" => pm_params}, socket) do
    changeset =
      socket.assigns.selected_schedule
      |> PmSchedule.changeset(pm_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"pm_schedule" => pm_params}, socket) do
    save_pm_schedule(socket, socket.assigns.live_action, pm_params)
  end

  def handle_event("close_form", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/pm-schedules")}
  end

  # Work Instruction Line Management
  def handle_event("add_instruction_line", _params, socket) do
    lines = socket.assigns.work_instruction_lines
    next_id = if Enum.empty?(lines), do: 1, else: Enum.max_by(lines, & &1.id).id + 1
    new_line = %{id: next_id, text: ""}
    {:noreply, assign(socket, :work_instruction_lines, lines ++ [new_line])}
  end

  def handle_event("update_instruction_line", %{"id" => id, "text" => text}, socket) do
    id = String.to_integer(id)
    lines = 
      Enum.map(socket.assigns.work_instruction_lines, fn line ->
        if line.id == id, do: %{line | text: text}, else: line
      end)
    {:noreply, assign(socket, :work_instruction_lines, lines)}
  end

  def handle_event("remove_instruction_line", %{"id" => id}, socket) do
    id = String.to_integer(id)
    lines = Enum.reject(socket.assigns.work_instruction_lines, &(&1.id == id))
    {:noreply, assign(socket, :work_instruction_lines, lines)}
  end

  def handle_event("move_instruction_up", %{"id" => id}, socket) do
    id = String.to_integer(id)
    lines = socket.assigns.work_instruction_lines
    idx = Enum.find_index(lines, &(&1.id == id))
    
    if idx && idx > 0 do
      lines = swap_elements(lines, idx, idx - 1)
      {:noreply, assign(socket, :work_instruction_lines, lines)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("move_instruction_down", %{"id" => id}, socket) do
    id = String.to_integer(id)
    lines = socket.assigns.work_instruction_lines
    idx = Enum.find_index(lines, &(&1.id == id))
    
    if idx && idx < length(lines) - 1 do
      lines = swap_elements(lines, idx, idx + 1)
      {:noreply, assign(socket, :work_instruction_lines, lines)}
    else
      {:noreply, socket}
    end
  end

  # Equipment Search
  def handle_event("search_assets", %{"search" => query}, socket) do
    {:noreply, assign(socket, :asset_search, query)}
  end

  defp swap_elements(list, idx1, idx2) do
    elem1 = Enum.at(list, idx1)
    elem2 = Enum.at(list, idx2)
    list
    |> List.replace_at(idx1, elem2)
    |> List.replace_at(idx2, elem1)
  end

  defp save_pm_schedule(socket, :new, pm_params) do
    tenant_id = socket.assigns.current_tenant_id
    
    # Combine work instruction lines into a single text field
    work_instructions = 
      socket.assigns.work_instruction_lines
      |> Enum.map(& &1.text)
      |> Enum.filter(&(String.trim(&1) != ""))
      |> Enum.join("\n")
    
    pm_params = 
      pm_params
      |> Map.put("tenant_id", tenant_id)
      |> Map.put("work_instructions", work_instructions)

    case Maintenance.create_pm_schedule(pm_params) do
      {:ok, _pm_schedule} ->
        {:noreply,
         socket
         |> put_flash(:info, "PM Schedule created successfully")
         |> push_patch(to: ~p"/pm-schedules")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_pm_schedule(socket, :edit, pm_params) do
    # Combine work instruction lines into a single text field
    work_instructions = 
      socket.assigns.work_instruction_lines
      |> Enum.map(& &1.text)
      |> Enum.filter(&(String.trim(&1) != ""))
      |> Enum.join("\n")
    
    pm_params = Map.put(pm_params, "work_instructions", work_instructions)

    case Maintenance.update_pm_schedule(socket.assigns.selected_schedule, pm_params) do
      {:ok, _pm_schedule} ->
        {:noreply,
         socket
         |> put_flash(:info, "PM Schedule updated successfully")
         |> push_patch(to: ~p"/pm-schedules")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp load_pm_schedules(socket, tenant_id) do
    schedules = Maintenance.list_pm_schedules(tenant_id)
    assign(socket, :schedules, schedules) |> filter_schedules()
  end

  defp load_assets(socket, tenant_id) do
    assets = Assets.list_assets(tenant_id)
    assign(socket, :assets, assets)
  end

  defp filter_schedules(socket) do
    schedules = socket.assigns.schedules
    search_query = socket.assigns.search_query |> String.downcase()
    frequency = socket.assigns.filter_frequency
    status = socket.assigns.filter_status
    
    filtered =
      schedules
      |> Enum.filter(fn schedule ->
        # Search filter
        search_match = search_query == "" or
          String.contains?(String.downcase(schedule.title || ""), search_query) or
          String.contains?(String.downcase(schedule.schedule_number || ""), search_query) or
          String.contains?(String.downcase(schedule.description || ""), search_query)
        
        # Frequency filter
        frequency_match = frequency == "all" or
          to_string(schedule.frequency) == frequency
        
        # Status filter
        status_match = case status do
          "active" -> schedule.is_active == true
          "inactive" -> schedule.is_active == false
          "overdue" -> schedule.is_active == true and 
                       schedule.next_due_date != nil and
                       DateTime.compare(schedule.next_due_date, DateTime.utc_now()) == :lt
          "due_soon" -> schedule.is_active == true and
                        schedule.next_due_date != nil and
                        DateTime.compare(schedule.next_due_date, DateTime.utc_now()) == :gt and
                        DateTime.diff(schedule.next_due_date, DateTime.utc_now(), :day) <= 30
          _ -> true
        end
        
        search_match and frequency_match and status_match
      end)
    
    assign(socket, :filtered_schedules, filtered)
  end

  defp filtered_assets(assigns) do
    search = String.downcase(assigns.asset_search)
    if search == "" do
      assigns.assets
    else
      Enum.filter(assigns.assets, fn asset ->
        String.contains?(String.downcase(asset.name || ""), search) or
        String.contains?(String.downcase(asset.asset_number || ""), search)
      end)
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen flex flex-col bg-gray-50">
      <!-- Header with Actions -->
      <div class="bg-white border-b border-gray-200 px-6 py-4">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900">PM Schedules</h1>
            <p class="mt-1 text-sm text-gray-500">
              Manage preventive maintenance schedules for your assets
            </p>
          </div>
          
          <div class="flex items-center gap-3">
            <.link
              patch={~p"/pm-schedules/new"}
              class="inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
              </svg>
              New PM Schedule
            </.link>
          </div>
        </div>
      </div>

      <!-- Filters and Search Bar -->
      <div class="bg-white border-b border-gray-200 px-6 py-4">
        <div class="flex items-center gap-4">
          <!-- Search -->
          <div class="flex-1">
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
              </div>
              <input
                type="text"
                phx-change="search"
                name="search"
                value={@search_query}
                placeholder="Search schedules..."
                class="block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>

          <!-- Frequency Filter -->
          <select
            phx-change="filter_frequency"
            name="frequency"
            class="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="all">All Frequencies</option>
            <%= for freq <- PmSchedule.frequency_values() do %>
              <option value={freq} selected={@filter_frequency == to_string(freq)}>
                <%= PmSchedule.frequency_label(freq) %>
              </option>
            <% end %>
          </select>

          <!-- Status Filter -->
          <select
            phx-change="filter_status"
            name="status"
            class="px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="active" selected={@filter_status == "active"}>Active</option>
            <option value="inactive" selected={@filter_status == "inactive"}>Inactive</option>
            <option value="overdue" selected={@filter_status == "overdue"}>Overdue</option>
            <option value="due_soon" selected={@filter_status == "due_soon"}>Due Soon</option>
            <option value="all" selected={@filter_status == "all"}>All Status</option>
          </select>
        </div>
      </div>

      <!-- Main Content Area -->
      <div class="flex-1 overflow-auto">
        <div class="px-6 py-6">
          <!-- Statistics Cards -->
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
            <div class="bg-white rounded-lg border border-gray-200 p-4">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600">Total Schedules</p>
                  <p class="text-2xl font-bold text-gray-900 mt-1">
                    <%= length(@schedules) %>
                  </p>
                </div>
                <div class="p-3 bg-blue-100 rounded-lg">
                  <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                  </svg>
                </div>
              </div>
            </div>

            <div class="bg-white rounded-lg border border-gray-200 p-4">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600">Active</p>
                  <p class="text-2xl font-bold text-green-600 mt-1">
                    <%= Enum.count(@schedules, & &1.is_active) %>
                  </p>
                </div>
                <div class="p-3 bg-green-100 rounded-lg">
                  <svg class="w-6 h-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                </div>
              </div>
            </div>

            <div class="bg-white rounded-lg border border-gray-200 p-4">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600">Overdue</p>
                  <p class="text-2xl font-bold text-red-600 mt-1">
                    <%= Enum.count(@schedules, fn s -> 
                      s.is_active and s.next_due_date != nil and 
                      DateTime.compare(s.next_due_date, DateTime.utc_now()) == :lt 
                    end) %>
                  </p>
                </div>
                <div class="p-3 bg-red-100 rounded-lg">
                  <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                </div>
              </div>
            </div>

            <div class="bg-white rounded-lg border border-gray-200 p-4">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600">Due Soon (30d)</p>
                  <p class="text-2xl font-bold text-yellow-600 mt-1">
                    <%= Enum.count(@schedules, fn s -> 
                      s.is_active and s.next_due_date != nil and 
                      DateTime.compare(s.next_due_date, DateTime.utc_now()) == :gt and
                      DateTime.diff(s.next_due_date, DateTime.utc_now(), :day) <= 30
                    end) %>
                  </p>
                </div>
                <div class="p-3 bg-yellow-100 rounded-lg">
                  <svg class="w-6 h-6 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                  </svg>
                </div>
              </div>
            </div>
          </div>

          <!-- PM Schedules Table -->
          <div class="bg-white rounded-lg border border-gray-200 overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Schedule #
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Title
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Asset
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Frequency
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Last Completed
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Next Due
                  </th>
                  <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                  <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= if Enum.empty?(@filtered_schedules) do %>
                  <tr>
                    <td colspan="8" class="px-6 py-12 text-center">
                      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                      </svg>
                      <p class="mt-2 text-sm text-gray-500">No PM schedules found</p>
                      <.link
                        patch={~p"/pm-schedules/new"}
                        class="mt-4 inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
                      >
                        Create your first PM schedule
                      </.link>
                    </td>
                  </tr>
                <% else %>
                  <%= for schedule <- @filtered_schedules do %>
                    <tr class="hover:bg-gray-50">
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="text-sm font-medium text-gray-900">
                          <%= schedule.schedule_number %>
                        </div>
                      </td>
                      <td class="px-6 py-4">
                        <div class="text-sm font-medium text-gray-900">
                          <%= schedule.title %>
                        </div>
                        <%= if schedule.description do %>
                          <div class="text-sm text-gray-500 truncate max-w-md">
                            <%= schedule.description %>
                          </div>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <%= if schedule.asset do %>
                          <div class="text-sm text-gray-900"><%= schedule.asset.name %></div>
                          <div class="text-sm text-gray-500"><%= schedule.asset.asset_number %></div>
                        <% else %>
                          <span class="text-sm text-gray-400">-</span>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span class="inline-flex px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800">
                          <%= PmSchedule.frequency_label(schedule.frequency) %>
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <%= if schedule.last_completed_date do %>
                          <%= Calendar.strftime(schedule.last_completed_date, "%b %d, %Y") %>
                        <% else %>
                          <span class="text-gray-400">Never</span>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <%= if schedule.next_due_date do %>
                          <div class="text-sm text-gray-900">
                            <%= Calendar.strftime(schedule.next_due_date, "%b %d, %Y") %>
                          </div>
                          <%= cond do %>
                            <% DateTime.compare(schedule.next_due_date, DateTime.utc_now()) == :lt -> %>
                              <span class="text-xs text-red-600 font-medium">Overdue</span>
                            <% DateTime.diff(schedule.next_due_date, DateTime.utc_now(), :day) <= 7 -> %>
                              <span class="text-xs text-orange-600 font-medium">Due Soon</span>
                            <% DateTime.diff(schedule.next_due_date, DateTime.utc_now(), :day) <= 30 -> %>
                              <span class="text-xs text-yellow-600 font-medium">Upcoming</span>
                            <% true -> %>
                              <span class="text-xs text-gray-500">On Track</span>
                          <% end %>
                        <% else %>
                          <span class="text-sm text-gray-400">Not scheduled</span>
                        <% end %>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <span class={"inline-flex px-2 py-1 text-xs font-medium rounded-full #{PmSchedule.status_color(schedule.is_active)}"}>
                          <%= if schedule.is_active, do: "Active", else: "Inactive" %>
                        </span>
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <div class="flex items-center justify-end gap-2">
                          <%= if schedule.is_active do %>
                            <button
                              phx-click="complete_schedule"
                              phx-value-id={schedule.id}
                              class="text-green-600 hover:text-green-900"
                              title="Mark as Completed"
                            >
                              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                              </svg>
                            </button>
                          <% end %>
                          
                          <.link
                            navigate={~p"/pm-schedules/#{schedule.id}"}
                            class="text-indigo-600 hover:text-indigo-900"
                            title="View Details"
                          >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                            </svg>
                          </.link>
                          
                          <.link
                            patch={~p"/pm-schedules/#{schedule.id}/edit"}
                            class="text-blue-600 hover:text-blue-900"
                            title="Edit"
                          >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                            </svg>
                          </.link>
                          
                          <button
                            phx-click="delete_schedule"
                            phx-value-id={schedule.id}
                            data-confirm="Are you sure you want to delete this PM schedule?"
                            class="text-red-600 hover:text-red-900"
                            title="Delete"
                          >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                            </svg>
                          </button>
                        </div>
                      </td>
                    </tr>
                  <% end %>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal Form -->
    <%= if @show_form do %>
      <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
        <div class="bg-white rounded-lg shadow-xl max-w-6xl w-full max-h-[92vh] overflow-hidden flex flex-col">
          <!-- Modal Header -->
          <div class="px-4 py-3 border-b border-gray-200 flex items-center justify-between bg-gray-50">
            <div>
              <h2 class="text-lg font-bold text-gray-900"><%= @page_title %></h2>
              <%= if @selected_schedule.id do %>
                <p class="text-xs text-gray-500 mt-0.5">Schedule #: <span class="font-mono font-medium text-blue-600"><%= @selected_schedule.schedule_number %></span></p>
              <% else %>
                <p class="text-xs text-green-600 mt-0.5">Schedule number will be auto-generated (PM-NNNNNNNN)</p>
              <% end %>
            </div>
            <button
              type="button"
              phx-click="close_form"
              class="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <!-- Modal Body -->
          <div class="flex-1 overflow-y-auto">
            <.form for={@form} phx-change="validate" phx-submit="save">
              <div class="grid grid-cols-2 gap-4 p-4">
                <!-- Left Column -->
                <div class="space-y-4">
                  <!-- Basic Information Card -->
                  <div class="bg-white border border-gray-200 rounded-lg p-4">
                    <h3 class="text-sm font-semibold text-gray-900 mb-3 flex items-center">
                      <svg class="w-4 h-4 mr-2 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                      </svg>
                      Basic Information
                    </h3>
                    
                    <div class="space-y-3">
                      <div>
                        <label class="block text-xs font-medium text-gray-700 mb-1">
                          Equipment <span class="text-red-500">*</span>
                        </label>
                        <div class="relative">
                          <input
                            type="text"
                            placeholder="Search equipment..."
                            phx-keyup="search_assets"
                            phx-debounce="300"
                            name="search"
                            value={@asset_search}
                            class="w-full px-3 py-1.5 text-sm border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-transparent mb-1"
                          />
                          <.input field={@form[:asset_id]} type="select" options={Enum.map(filtered_assets(assigns), &{"#{&1.name} (#{&1.asset_number})", &1.id})} prompt="Select equipment" required class="text-sm" />
                        </div>
                      </div>

                      <div>
                        <label class="block text-xs font-medium text-gray-700 mb-1">
                          Title <span class="text-red-500">*</span>
                        </label>
                        <.input field={@form[:title]} type="text" required class="text-sm" placeholder="e.g., Monthly CNC Maintenance" />
                      </div>

                      <div>
                        <label class="block text-xs font-medium text-gray-700 mb-1">
                          Description
                        </label>
                        <.input field={@form[:description]} type="textarea" rows="2" class="text-sm" placeholder="Brief description of this PM schedule" />
                      </div>
                    </div>
                  </div>

                  <!-- Scheduling Card -->
                  <div class="bg-white border border-gray-200 rounded-lg p-4">
                    <h3 class="text-sm font-semibold text-gray-900 mb-3 flex items-center">
                      <svg class="w-4 h-4 mr-2 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                      </svg>
                      Scheduling
                    </h3>
                    
                    <div class="space-y-3">
                      <div class="grid grid-cols-2 gap-3">
                        <div>
                          <label class="block text-xs font-medium text-gray-700 mb-1">
                            Frequency <span class="text-red-500">*</span>
                          </label>
                          <.input field={@form[:frequency]} type="select" options={Enum.map(PmSchedule.frequency_values(), &{PmSchedule.frequency_label(&1), &1})} prompt="Select" required class="text-sm" />
                        </div>

                        <div>
                          <label class="block text-xs font-medium text-gray-700 mb-1">
                            Interval
                          </label>
                          <.input field={@form[:frequency_interval]} type="number" min="1" class="text-sm" placeholder="1" />
                        </div>
                      </div>

                      <div class="grid grid-cols-2 gap-3">
                        <div>
                          <label class="block text-xs font-medium text-gray-700 mb-1">
                            Next Due Date
                          </label>
                          <.input field={@form[:next_due_date]} type="datetime-local" class="text-sm" />
                        </div>

                        <div>
                          <label class="block text-xs font-medium text-gray-700 mb-1">
                            Est. Duration (hrs)
                          </label>
                          <.input field={@form[:estimated_duration]} type="number" step="0.5" min="0" class="text-sm" placeholder="2.5" />
                        </div>
                      </div>

                      <div class="pt-2 border-t">
                        <label class="flex items-center">
                          <.input field={@form[:is_active]} type="checkbox" class="rounded" />
                          <span class="ml-2 text-xs font-medium text-gray-700">Active Schedule</span>
                        </label>
                      </div>
                    </div>
                  </div>

                  <!-- Safety Information Card -->
                  <div class="bg-white border border-gray-200 rounded-lg p-4">
                    <h3 class="text-sm font-semibold text-gray-900 mb-3 flex items-center">
                      <svg class="w-4 h-4 mr-2 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
                      </svg>
                      Safety Information
                    </h3>
                    
                    <div>
                      <label class="block text-xs font-medium text-gray-700 mb-1">
                        Safety Notes
                      </label>
                      <.input field={@form[:safety_notes]} type="textarea" rows="3" class="text-sm" placeholder="Important safety considerations and PPE requirements" />
                    </div>
                  </div>
                </div>

                <!-- Right Column -->
                <div class="space-y-4">
                  <!-- Work Instructions Card -->
                  <div class="bg-white border border-gray-200 rounded-lg p-4">
                    <div class="flex items-center justify-between mb-3">
                      <h3 class="text-sm font-semibold text-gray-900 flex items-center">
                        <svg class="w-4 h-4 mr-2 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"/>
                        </svg>
                        Work Instructions
                      </h3>
                      <button
                        type="button"
                        phx-click="add_instruction_line"
                        class="px-2 py-1 text-xs font-medium text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded transition-colors"
                      >
                        + Add Step
                      </button>
                    </div>
                    
                    <div class="space-y-2 max-h-64 overflow-y-auto">
                      <%= if Enum.empty?(@work_instruction_lines) do %>
                        <div class="text-center py-6 text-xs text-gray-400 bg-gray-50 rounded border border-dashed border-gray-300">
                          <svg class="w-8 h-8 mx-auto mb-2 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                          </svg>
                          <p>No work instructions yet</p>
                          <p class="text-gray-400">Click "+ Add Step" to create step-by-step instructions</p>
                        </div>
                      <% else %>
                        <%= for {line, index} <- Enum.with_index(@work_instruction_lines, 1) do %>
                          <div class="flex items-start gap-2 group">
                            <div class="flex flex-col gap-0.5 mt-1.5">
                              <%= if index > 1 do %>
                                <button
                                  type="button"
                                  phx-click="move_instruction_up"
                                  phx-value-id={line.id}
                                  class="text-gray-400 hover:text-blue-600 opacity-0 group-hover:opacity-100 transition-opacity"
                                  title="Move Up"
                                >
                                  <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"/>
                                  </svg>
                                </button>
                              <% end %>
                              <%= if index < length(@work_instruction_lines) do %>
                                <button
                                  type="button"
                                  phx-click="move_instruction_down"
                                  phx-value-id={line.id}
                                  class="text-gray-400 hover:text-blue-600 opacity-0 group-hover:opacity-100 transition-opacity"
                                  title="Move Down"
                                >
                                  <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/>
                                  </svg>
                                </button>
                              <% end %>
                            </div>
                            <span class="flex-shrink-0 w-6 h-6 flex items-center justify-center bg-blue-100 text-blue-700 rounded-full text-xs font-medium mt-1">
                              <%= index %>
                            </span>
                            <input
                              type="text"
                              value={line.text}
                              phx-blur="update_instruction_line"
                              phx-value-id={line.id}
                              phx-debounce="500"
                              name="text"
                              placeholder="Enter instruction step..."
                              class="flex-1 px-2 py-1 text-xs border border-gray-300 rounded focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                            />
                            <button
                              type="button"
                              phx-click="remove_instruction_line"
                              phx-value-id={line.id}
                              class="flex-shrink-0 text-gray-400 hover:text-red-600 opacity-0 group-hover:opacity-100 transition-opacity"
                              title="Remove"
                            >
                              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                              </svg>
                            </button>
                          </div>
                        <% end %>
                      <% end %>
                    </div>
                  </div>

                  <!-- Documents Card (Placeholder for future implementation) -->
                  <div class="bg-white border border-gray-200 rounded-lg p-4">
                    <div class="flex items-center justify-between mb-3">
                      <h3 class="text-sm font-semibold text-gray-900 flex items-center">
                        <svg class="w-4 h-4 mr-2 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
                        </svg>
                        Documents & Attachments
                      </h3>
                      <span class="px-2 py-0.5 text-xs font-medium text-gray-500 bg-gray-100 rounded">Coming Soon</span>
                    </div>
                    
                    <div class="text-center py-4 text-xs text-gray-400 bg-gray-50 rounded border border-dashed border-gray-300">
                      <svg class="w-8 h-8 mx-auto mb-2 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                      </svg>
                      <p>Document management coming soon</p>
                      <p class="text-gray-400 text-[10px] mt-1">Attach manuals, procedures, and certificates</p>
                    </div>
                  </div>

                  <!-- Quick Notes (using safety notes for now) -->
                  <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
                    <div class="flex items-start gap-2">
                      <svg class="w-4 h-4 text-yellow-600 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                      </svg>
                      <div class="flex-1">
                        <p class="text-xs font-medium text-yellow-900 mb-1">Tips for Creating PM Schedules</p>
                        <ul class="text-[10px] text-yellow-700 space-y-0.5 list-disc list-inside">
                          <li>Be specific with work instruction steps</li>
                          <li>Include all safety requirements upfront</li>
                          <li>Set realistic time estimates</li>
                          <li>Document all required tools and parts</li>
                        </ul>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Modal Footer -->
              <div class="flex items-center justify-between gap-3 px-4 py-3 border-t border-gray-200 bg-gray-50">
                <div class="text-xs text-gray-500">
                  <span class="font-medium"><span class="text-red-500">*</span></span> Required fields
                </div>
                <div class="flex items-center gap-2">
                  <button
                    type="button"
                    phx-click="close_form"
                    class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 transition-colors flex items-center gap-2"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                    </svg>
                    <%= if @selected_schedule.id, do: "Update Schedule", else: "Create Schedule" %>
                  </button>
                </div>
              </div>
            </.form>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
