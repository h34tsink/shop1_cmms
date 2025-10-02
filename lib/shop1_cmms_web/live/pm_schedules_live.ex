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
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    tenant_id = socket.assigns.current_tenant_id
    schedule = Maintenance.get_pm_schedule!(tenant_id, id)
    changeset = PmSchedule.changeset(schedule, %{})
    
    socket
    |> assign(:page_title, "Edit PM Schedule")
    |> assign(:show_form, true)
    |> assign(:selected_schedule, schedule)
    |> assign(:form, to_form(changeset))
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

  defp save_pm_schedule(socket, :new, pm_params) do
    tenant_id = socket.assigns.current_tenant_id
    pm_params = Map.put(pm_params, "tenant_id", tenant_id)

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
    tenant_id = socket.assigns.current_tenant_id

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
        <div class="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col">
          <!-- Modal Header -->
          <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h2 class="text-xl font-bold text-gray-900"><%= @page_title %></h2>
            <button
              type="button"
              phx-click="close_form"
              class="text-gray-400 hover:text-gray-500"
            >
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <!-- Modal Body -->
          <div class="flex-1 overflow-y-auto px-6 py-6">
            <.form for={@form} phx-change="validate" phx-submit="save">
              <div class="space-y-6">
                <!-- Basic Information -->
                <%= if @selected_schedule.id do %>
                  <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
                    <div class="flex items-center gap-2">
                      <svg class="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                      </svg>
                      <div>
                        <p class="text-sm font-medium text-blue-900">Schedule Number</p>
                        <p class="text-lg font-bold text-blue-700"><%= @selected_schedule.schedule_number %></p>
                      </div>
                    </div>
                  </div>
                <% else %>
                  <div class="bg-green-50 border border-green-200 rounded-lg p-4 mb-4">
                    <div class="flex items-center gap-2">
                      <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                      </svg>
                      <p class="text-sm text-green-700">
                        <span class="font-medium">Schedule Number will be auto-generated</span> in format: PM-00000001
                      </p>
                    </div>
                  </div>
                <% end %>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Equipment <span class="text-red-500">*</span>
                  </label>
                  <.input field={@form[:asset_id]} type="select" options={Enum.map(@assets, &{&1.name, &1.id})} prompt="Select equipment" required />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Title <span class="text-red-500">*</span>
                  </label>
                  <.input field={@form[:title]} type="text" required />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Description
                  </label>
                  <.input field={@form[:description]} type="textarea" rows="3" />
                </div>

                <!-- Scheduling -->
                <div class="border-t pt-4">
                  <h3 class="text-lg font-medium text-gray-900 mb-4">Scheduling</h3>
                  
                  <div class="grid grid-cols-2 gap-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Frequency <span class="text-red-500">*</span>
                      </label>
                      <.input field={@form[:frequency]} type="select" options={Enum.map(PmSchedule.frequency_values(), &{PmSchedule.frequency_label(&1), &1})} prompt="Select frequency" required />
                    </div>

                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Frequency Interval
                      </label>
                      <.input field={@form[:frequency_interval]} type="number" min="1" />
                    </div>
                  </div>

                  <div class="grid grid-cols-2 gap-4 mt-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Next Due Date
                      </label>
                      <.input field={@form[:next_due_date]} type="datetime-local" />
                    </div>

                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Estimated Duration (hours)
                      </label>
                      <.input field={@form[:estimated_duration]} type="number" step="0.5" min="0" />
                    </div>
                  </div>
                </div>

                <!-- Work Instructions -->
                <div class="border-t pt-4">
                  <h3 class="text-lg font-medium text-gray-900 mb-4">Work Instructions</h3>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      Work Instructions
                    </label>
                    <.input field={@form[:work_instructions]} type="textarea" rows="6" />
                  </div>
                </div>

                <!-- Safety -->
                <div class="border-t pt-4">
                  <h3 class="text-lg font-medium text-gray-900 mb-4">Safety Information</h3>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">
                      Safety Notes
                    </label>
                    <.input field={@form[:safety_notes]} type="textarea" rows="3" />
                  </div>
                </div>

                <!-- Status -->
                <div class="border-t pt-4">
                  <label class="flex items-center">
                    <.input field={@form[:is_active]} type="checkbox" />
                    <span class="ml-2 text-sm font-medium text-gray-700">Active Schedule</span>
                  </label>
                </div>
              </div>

              <!-- Modal Footer -->
              <div class="flex items-center justify-end gap-3 mt-6 pt-6 border-t">
                <button
                  type="button"
                  phx-click="close_form"
                  class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700"
                >
                  <%= if @selected_schedule.id, do: "Update", else: "Create" %> PM Schedule
                </button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
