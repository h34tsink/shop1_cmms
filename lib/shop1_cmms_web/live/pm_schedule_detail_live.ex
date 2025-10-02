defmodule Shop1CmmsWeb.PmScheduleDetailLive do
  use Shop1CmmsWeb, :live_view
  alias Shop1Cmms.Maintenance
  alias Shop1Cmms.Maintenance.{PmSchedule, PmScheduleComponent, PmChecklistItem, AssetDocument}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    tenant_id = socket.assigns.current_tenant_id
    schedule = Maintenance.get_pm_schedule!(tenant_id, id)

    {:ok,
     socket
     |> assign(:page_title, "PM Schedule Details")
     |> assign(:schedule, schedule)
     |> assign(:active_tab, "overview")
     |> assign(:show_component_form, false)
     |> assign(:show_checklist_form, false)
     |> assign(:show_document_form, false)
     |> assign(:selected_component, nil)
     |> assign(:selected_checklist_item, nil)
     |> assign(:selected_document, nil)
     |> assign(:component_form, nil)
     |> assign(:checklist_form, nil)
     |> assign(:document_form, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  # Component Events
  def handle_event("new_component", _params, socket) do
    changeset = PmScheduleComponent.changeset(%PmScheduleComponent{
      pm_schedule_id: socket.assigns.schedule.id,
      tenant_id: socket.assigns.current_tenant_id
    }, %{})
    
    {:noreply,
     socket
     |> assign(:show_component_form, true)
     |> assign(:selected_component, %PmScheduleComponent{})
     |> assign(:component_form, to_form(changeset))}
  end

  def handle_event("edit_component", %{"id" => id}, socket) do
    component = Enum.find(socket.assigns.schedule.components, &(&1.id == id))
    changeset = PmScheduleComponent.changeset(component, %{})
    
    {:noreply,
     socket
     |> assign(:show_component_form, true)
     |> assign(:selected_component, component)
     |> assign(:component_form, to_form(changeset))}
  end

  def handle_event("delete_component", %{"id" => id}, socket) do
    component = Enum.find(socket.assigns.schedule.components, &(&1.id == id))
    
    case Maintenance.delete_pm_schedule_component(component) do
      {:ok, _} ->
        tenant_id = socket.assigns.current_tenant_id
        schedule = Maintenance.get_pm_schedule!(tenant_id, socket.assigns.schedule.id)
        
        {:noreply,
         socket
         |> put_flash(:info, "Component deleted successfully")
         |> assign(:schedule, schedule)}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete component")}
    end
  end

  def handle_event("validate_component", %{"pm_schedule_component" => component_params}, socket) do
    changeset =
      socket.assigns.selected_component
      |> PmScheduleComponent.changeset(component_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :component_form, to_form(changeset))}
  end

  def handle_event("save_component", %{"pm_schedule_component" => component_params}, socket) do
    component_params = Map.merge(component_params, %{
      "pm_schedule_id" => socket.assigns.schedule.id,
      "tenant_id" => socket.assigns.current_tenant_id
    })

    result = if socket.assigns.selected_component.id do
      Maintenance.update_pm_schedule_component(socket.assigns.selected_component, component_params)
    else
      Maintenance.create_pm_schedule_component(component_params)
    end

    case result do
      {:ok, _component} ->
        tenant_id = socket.assigns.current_tenant_id
        schedule = Maintenance.get_pm_schedule!(tenant_id, socket.assigns.schedule.id)
        
        {:noreply,
         socket
         |> put_flash(:info, "Component saved successfully")
         |> assign(:schedule, schedule)
         |> assign(:show_component_form, false)
         |> assign(:selected_component, nil)
         |> assign(:component_form, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :component_form, to_form(changeset))}
    end
  end

  def handle_event("close_component_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_component_form, false)
     |> assign(:selected_component, nil)
     |> assign(:component_form, nil)}
  end

  # Checklist Item Events
  def handle_event("new_checklist_item", _params, socket) do
    max_sequence = Enum.map(socket.assigns.schedule.checklist_items, & &1.sequence) |> Enum.max(fn -> 0 end)
    
    changeset = PmChecklistItem.changeset(%PmChecklistItem{
      pm_schedule_id: socket.assigns.schedule.id,
      tenant_id: socket.assigns.current_tenant_id,
      sequence: max_sequence + 1
    }, %{})
    
    {:noreply,
     socket
     |> assign(:show_checklist_form, true)
     |> assign(:selected_checklist_item, %PmChecklistItem{})
     |> assign(:checklist_form, to_form(changeset))}
  end

  def handle_event("edit_checklist_item", %{"id" => id}, socket) do
    item = Enum.find(socket.assigns.schedule.checklist_items, &(&1.id == id))
    changeset = PmChecklistItem.changeset(item, %{})
    
    {:noreply,
     socket
     |> assign(:show_checklist_form, true)
     |> assign(:selected_checklist_item, item)
     |> assign(:checklist_form, to_form(changeset))}
  end

  def handle_event("delete_checklist_item", %{"id" => id}, socket) do
    item = Enum.find(socket.assigns.schedule.checklist_items, &(&1.id == id))
    
    case Maintenance.delete_pm_checklist_item(item) do
      {:ok, _} ->
        tenant_id = socket.assigns.current_tenant_id
        schedule = Maintenance.get_pm_schedule!(tenant_id, socket.assigns.schedule.id)
        
        {:noreply,
         socket
         |> put_flash(:info, "Checklist item deleted successfully")
         |> assign(:schedule, schedule)}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete checklist item")}
    end
  end

  def handle_event("validate_checklist", %{"pm_checklist_item" => item_params}, socket) do
    changeset =
      socket.assigns.selected_checklist_item
      |> PmChecklistItem.changeset(item_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :checklist_form, to_form(changeset))}
  end

  def handle_event("save_checklist", %{"pm_checklist_item" => item_params}, socket) do
    item_params = Map.merge(item_params, %{
      "pm_schedule_id" => socket.assigns.schedule.id,
      "tenant_id" => socket.assigns.current_tenant_id
    })

    result = if socket.assigns.selected_checklist_item.id do
      Maintenance.update_pm_checklist_item(socket.assigns.selected_checklist_item, item_params)
    else
      Maintenance.create_pm_checklist_item(item_params)
    end

    case result do
      {:ok, _item} ->
        tenant_id = socket.assigns.current_tenant_id
        schedule = Maintenance.get_pm_schedule!(tenant_id, socket.assigns.schedule.id)
        
        {:noreply,
         socket
         |> put_flash(:info, "Checklist item saved successfully")
         |> assign(:schedule, schedule)
         |> assign(:show_checklist_form, false)
         |> assign(:selected_checklist_item, nil)
         |> assign(:checklist_form, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :checklist_form, to_form(changeset))}
    end
  end

  def handle_event("close_checklist_form", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_checklist_form, false)
     |> assign(:selected_checklist_item, nil)
     |> assign(:checklist_form, nil)}
  end

  def handle_event("complete_pm", _params, socket) do
    case Maintenance.complete_pm_schedule(socket.assigns.schedule) do
      {:ok, _schedule} ->
        tenant_id = socket.assigns.current_tenant_id
        schedule = Maintenance.get_pm_schedule!(tenant_id, socket.assigns.schedule.id)
        
        {:noreply,
         socket
         |> put_flash(:info, "PM marked as completed and next due date updated")
         |> assign(:schedule, schedule)}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to complete PM")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen flex flex-col bg-gray-50">
      <!-- Header -->
      <div class="bg-white border-b border-gray-200 px-6 py-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-4">
            <.link navigate={~p"/pm-schedules"} class="text-gray-400 hover:text-gray-600">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
              </svg>
            </.link>
            <div>
              <h1 class="text-2xl font-bold text-gray-900"><%= @schedule.title %></h1>
              <p class="mt-1 text-sm text-gray-500">
                <%= @schedule.schedule_number %> • <%= PmSchedule.frequency_label(@schedule.frequency) %>
              </p>
            </div>
          </div>
          
          <div class="flex items-center gap-3">
            <button
              phx-click="complete_pm"
              class="inline-flex items-center px-4 py-2 bg-green-600 hover:bg-green-700 text-white font-medium rounded-lg transition-colors"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
              </svg>
              Complete PM
            </button>
            <.link
              patch={~p"/pm-schedules/#{@schedule.id}/edit"}
              class="inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
              </svg>
              Edit
            </.link>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="bg-white border-b border-gray-200 px-6">
        <nav class="flex gap-8" aria-label="Tabs">
          <button
            phx-click="switch_tab"
            phx-value-tab="overview"
            class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "overview", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
          >
            Overview
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="instructions"
            class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "instructions", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
          >
            Work Instructions
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="checklist"
            class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "checklist", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
          >
            Checklist
            <span class="ml-2 bg-gray-200 text-gray-700 py-0.5 px-2 rounded-full text-xs">
              <%= length(@schedule.checklist_items) %>
            </span>
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="components"
            class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "components", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
          >
            Components
            <span class="ml-2 bg-gray-200 text-gray-700 py-0.5 px-2 rounded-full text-xs">
              <%= length(@schedule.components) %>
            </span>
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="documents"
            class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "documents", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
          >
            Documents
            <span class="ml-2 bg-gray-200 text-gray-700 py-0.5 px-2 rounded-full text-xs">
              <%= length(@schedule.documents) %>
            </span>
          </button>
          <button
            phx-click="switch_tab"
            phx-value-tab="history"
            class={"py-4 px-1 border-b-2 font-medium text-sm #{if @active_tab == "history", do: "border-blue-500 text-blue-600", else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"}"}
          >
            Execution History
          </button>
        </nav>
      </div>

      <!-- Main Content -->
      <div class="flex-1 overflow-auto">
        <div class="px-6 py-6">
          <%= case @active_tab do %>
            <% "overview" -> %>
              <.render_overview schedule={@schedule} />
            <% "instructions" -> %>
              <.render_instructions schedule={@schedule} />
            <% "checklist" -> %>
              <.render_checklist schedule={@schedule} />
            <% "components" -> %>
              <.render_components schedule={@schedule} />
            <% "documents" -> %>
              <.render_documents schedule={@schedule} />
            <% "history" -> %>
              <.live_component
                module={Shop1CmmsWeb.PmSchedulesLive.HistoryComponent}
                id="pm-execution-history"
                pm_schedule={@schedule}
                tenant_id={@current_tenant_id}
              />
          <% end %>
        </div>
      </div>
    </div>

    <%!-- Component Form Modal --%>
    <%= if @show_component_form do %>
      <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
        <div class="bg-white rounded-lg shadow-xl max-w-2xl w-full">
          <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h2 class="text-xl font-bold text-gray-900">
              <%= if @selected_component.id, do: "Edit", else: "Add" %> Component
            </h2>
            <button type="button" phx-click="close_component_form" class="text-gray-400 hover:text-gray-500">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <.form for={@component_form} phx-change="validate_component" phx-submit="save_component">
            <div class="px-6 py-4 space-y-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Component Name <span class="text-red-500">*</span>
                </label>
                <.input field={@component_form[:component_name]} type="text" required />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Location
                </label>
                <.input field={@component_form[:component_location]} type="text" />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Description
                </label>
                <.input field={@component_form[:component_description]} type="textarea" rows="3" />
              </div>
            </div>

            <div class="flex items-center justify-end gap-3 px-6 py-4 border-t">
              <button
                type="button"
                phx-click="close_component_form"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700"
              >
                Save Component
              </button>
            </div>
          </.form>
        </div>
      </div>
    <% end %>

    <%!-- Checklist Item Form Modal --%>
    <%= if @show_checklist_form do %>
      <div class="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center p-4 z-50">
        <div class="bg-white rounded-lg shadow-xl max-w-3xl w-full">
          <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
            <h2 class="text-xl font-bold text-gray-900">
              <%= if @selected_checklist_item.id, do: "Edit", else: "Add" %> Checklist Item
            </h2>
            <button type="button" phx-click="close_checklist_form" class="text-gray-400 hover:text-gray-500">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <.form for={@checklist_form} phx-change="validate_checklist" phx-submit="save_checklist">
            <div class="px-6 py-4 space-y-4">
              <div class="grid grid-cols-4 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Sequence <span class="text-red-500">*</span>
                  </label>
                  <.input field={@checklist_form[:sequence]} type="number" min="1" required />
                </div>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Task Description <span class="text-red-500">*</span>
                </label>
                <.input field={@checklist_form[:item_description]} type="textarea" rows="2" required />
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                  Expected Result
                </label>
                <.input field={@checklist_form[:expected_result]} type="textarea" rows="2" />
              </div>

              <div class="border-t pt-4">
                <label class="flex items-center">
                  <.input field={@checklist_form[:requires_measurement]} type="checkbox" />
                  <span class="ml-2 text-sm font-medium text-gray-700">Requires Measurement</span>
                </label>
              </div>

              <div class="grid grid-cols-3 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Measurement Unit
                  </label>
                  <.input field={@checklist_form[:measurement_unit]} type="text" placeholder="e.g., PSI, °C, mm" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Min Value
                  </label>
                  <.input field={@checklist_form[:min_value]} type="number" step="0.0001" />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 mb-1">
                    Max Value
                  </label>
                  <.input field={@checklist_form[:max_value]} type="number" step="0.0001" />
                </div>
              </div>
            </div>

            <div class="flex items-center justify-end gap-3 px-6 py-4 border-t">
              <button
                type="button"
                phx-click="close_checklist_form"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700"
              >
                Save Checklist Item
              </button>
            </div>
          </.form>
        </div>
      </div>
    <% end %>
    """
  end

  # Tab Render Components

  defp render_overview(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Main Info -->
      <div class="lg:col-span-2 space-y-6">
        <!-- Details Card -->
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Details</h3>
          <dl class="grid grid-cols-2 gap-4">
            <div>
              <dt class="text-sm font-medium text-gray-500">Equipment</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @schedule.asset.name %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Equipment Number</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @schedule.asset.asset_number %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Frequency</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= PmSchedule.frequency_label(@schedule.frequency) %></dd>
            </div>
            <%= if @schedule.estimated_duration do %>
              <div>
                <dt class="text-sm font-medium text-gray-500">Estimated Duration</dt>
                <dd class="mt-1 text-sm text-gray-900"><%= @schedule.estimated_duration %> hours</dd>
              </div>
            <% end %>
            <div>
              <dt class="text-sm font-medium text-gray-500">Last Completed</dt>
              <dd class="mt-1 text-sm text-gray-900">
                <%= if @schedule.last_completed_date do %>
                  <%= Calendar.strftime(@schedule.last_completed_date, "%b %d, %Y at %I:%M %p") %>
                <% else %>
                  <span class="text-gray-400">Never</span>
                <% end %>
              </dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Next Due</dt>
              <dd class="mt-1 text-sm text-gray-900">
                <%= if @schedule.next_due_date do %>
                  <%= Calendar.strftime(@schedule.next_due_date, "%b %d, %Y at %I:%M %p") %>
                <% else %>
                  <span class="text-gray-400">Not scheduled</span>
                <% end %>
              </dd>
            </div>
          </dl>

          <%= if @schedule.description do %>
            <div class="mt-6 pt-6 border-t">
              <dt class="text-sm font-medium text-gray-500 mb-2">Description</dt>
              <dd class="text-sm text-gray-900"><%= @schedule.description %></dd>
            </div>
          <% end %>
        </div>

        <!-- Safety Notes -->
        <%= if @schedule.safety_notes do %>
          <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
            <div class="flex items-start">
              <svg class="w-6 h-6 text-yellow-600 mr-3 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
              </svg>
              <div class="flex-1">
                <h3 class="text-sm font-semibold text-yellow-900 mb-2">Safety Notes</h3>
                <p class="text-sm text-yellow-800"><%= @schedule.safety_notes %></p>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Sidebar -->
      <div class="space-y-6">
        <!-- Status Card -->
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Status</h3>
          <div class="space-y-4">
            <div>
              <span class={"inline-flex px-3 py-1 text-sm font-medium rounded-full #{PmSchedule.status_color(@schedule.is_active)}"}>
                <%= if @schedule.is_active, do: "Active", else: "Inactive" %>
              </span>
            </div>

            <%= if @schedule.next_due_date do %>
              <div>
                <%= cond do %>
                  <% DateTime.compare(@schedule.next_due_date, DateTime.utc_now()) == :lt -> %>
                    <span class="inline-flex items-center px-3 py-1 text-sm font-medium rounded-full bg-red-100 text-red-800">
                      <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                      </svg>
                      Overdue
                    </span>
                  <% DateTime.diff(@schedule.next_due_date, DateTime.utc_now(), :day) <= 7 -> %>
                    <span class="inline-flex items-center px-3 py-1 text-sm font-medium rounded-full bg-orange-100 text-orange-800">
                      <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
                      </svg>
                      Due Soon
                    </span>
                  <% true -> %>
                    <span class="inline-flex items-center px-3 py-1 text-sm font-medium rounded-full bg-green-100 text-green-800">
                      <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                      </svg>
                      On Track
                    </span>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Quick Stats -->
        <div class="bg-white rounded-lg border border-gray-200 p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Quick Stats</h3>
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-600">Checklist Items</span>
              <span class="text-sm font-semibold text-gray-900"><%= length(@schedule.checklist_items) %></span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-600">Components</span>
              <span class="text-sm font-semibold text-gray-900"><%= length(@schedule.components) %></span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-600">Documents</span>
              <span class="text-sm font-semibold text-gray-900"><%= length(@schedule.documents) %></span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp render_instructions(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-gray-200 p-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-4">Work Instructions</h3>
      
      <%= if @schedule.work_instructions do %>
        <div class="prose max-w-none">
          <div class="whitespace-pre-wrap text-sm text-gray-700"><%= @schedule.work_instructions %></div>
        </div>
      <% else %>
        <div class="text-center py-12">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
          </svg>
          <p class="mt-2 text-sm text-gray-500">No work instructions available</p>
          <.link
            patch={~p"/pm-schedules/#{@schedule.id}/edit"}
            class="mt-4 inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
          >
            Add Instructions
          </.link>
        </div>
      <% end %>

      <%= if @schedule.required_tools && length(@schedule.required_tools) > 0 do %>
        <div class="mt-6 pt-6 border-t">
          <h4 class="text-sm font-semibold text-gray-900 mb-3">Required Tools</h4>
          <ul class="list-disc list-inside text-sm text-gray-700 space-y-1">
            <%= for tool <- @schedule.required_tools do %>
              <li><%= tool %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <%= if @schedule.required_skills && length(@schedule.required_skills) > 0 do %>
        <div class="mt-6 pt-6 border-t">
          <h4 class="text-sm font-semibold text-gray-900 mb-3">Required Skills</h4>
          <div class="flex flex-wrap gap-2">
            <%= for skill <- @schedule.required_skills do %>
              <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
                <%= skill %>
              </span>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_checklist(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-gray-200">
      <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-900">Checklist Items</h3>
        <button
          phx-click="new_checklist_item"
          class="inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
        >
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          Add Item
        </button>
      </div>

      <div class="divide-y divide-gray-200">
        <%= if Enum.empty?(@schedule.checklist_items) do %>
          <div class="px-6 py-12 text-center">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"/>
            </svg>
            <p class="mt-2 text-sm text-gray-500">No checklist items yet</p>
            <button
              phx-click="new_checklist_item"
              class="mt-4 inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
            >
              Create First Item
            </button>
          </div>
        <% else %>
          <%= for item <- Enum.sort_by(@schedule.checklist_items, & &1.sequence) do %>
            <div class="px-6 py-4 hover:bg-gray-50">
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <div class="flex items-center gap-3">
                    <span class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-gray-100 text-gray-700 text-sm font-medium">
                      <%= item.sequence %>
                    </span>
                    <div class="flex-1">
                      <p class="text-sm font-medium text-gray-900"><%= item.item_description %></p>
                      <%= if item.expected_result do %>
                        <p class="mt-1 text-sm text-gray-500">Expected: <%= item.expected_result %></p>
                      <% end %>
                      <%= if item.requires_measurement do %>
                        <div class="mt-2 flex items-center gap-4 text-xs text-gray-500">
                          <%= if item.measurement_unit do %>
                            <span class="inline-flex items-center px-2 py-1 rounded bg-blue-50 text-blue-700">
                              Unit: <%= item.measurement_unit %>
                            </span>
                          <% end %>
                          <%= if item.min_value do %>
                            <span>Min: <%= item.min_value %></span>
                          <% end %>
                          <%= if item.max_value do %>
                            <span>Max: <%= item.max_value %></span>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
                <div class="flex items-center gap-2 ml-4">
                  <button
                    phx-click="edit_checklist_item"
                    phx-value-id={item.id}
                    class="text-blue-600 hover:text-blue-900"
                    title="Edit"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                    </svg>
                  </button>
                  <button
                    phx-click="delete_checklist_item"
                    phx-value-id={item.id}
                    data-confirm="Are you sure?"
                    class="text-red-600 hover:text-red-900"
                    title="Delete"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_components(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-gray-200">
      <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-900">PM Components</h3>
        <button
          phx-click="new_component"
          class="inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
        >
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          Add Component
        </button>
      </div>

      <div class="divide-y divide-gray-200">
        <%= if Enum.empty?(@schedule.components) do %>
          <div class="px-6 py-12 text-center">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/>
            </svg>
            <p class="mt-2 text-sm text-gray-500">No components defined yet</p>
            <button
              phx-click="new_component"
              class="mt-4 inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
            >
              Add First Component
            </button>
          </div>
        <% else %>
          <%= for component <- @schedule.components do %>
            <div class="px-6 py-4 hover:bg-gray-50">
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <h4 class="text-sm font-semibold text-gray-900"><%= component.component_name %></h4>
                  <%= if component.component_location do %>
                    <p class="mt-1 text-sm text-gray-500">
                      <svg class="inline w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
                      </svg>
                      <%= component.component_location %>
                    </p>
                  <% end %>
                  <%= if component.component_description do %>
                    <p class="mt-2 text-sm text-gray-600"><%= component.component_description %></p>
                  <% end %>
                </div>
                <div class="flex items-center gap-2 ml-4">
                  <button
                    phx-click="edit_component"
                    phx-value-id={component.id}
                    class="text-blue-600 hover:text-blue-900"
                    title="Edit"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                    </svg>
                  </button>
                  <button
                    phx-click="delete_component"
                    phx-value-id={component.id}
                    data-confirm="Are you sure?"
                    class="text-red-600 hover:text-red-900"
                    title="Delete"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_documents(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-gray-200">
      <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-900">Documents</h3>
        <button
          class="inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors"
        >
          <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
          </svg>
          Upload Document
        </button>
      </div>

      <div class="divide-y divide-gray-200">
        <%= if Enum.empty?(@schedule.documents) do %>
          <div class="px-6 py-12 text-center">
            <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>
            </svg>
            <p class="mt-2 text-sm text-gray-500">No documents uploaded yet</p>
            <button class="mt-4 inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors">
              Upload First Document
            </button>
          </div>
        <% else %>
          <%= for document <- @schedule.documents do %>
            <div class="px-6 py-4 hover:bg-gray-50">
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="flex-shrink-0">
                    <svg class="w-10 h-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"/>
                    </svg>
                  </div>
                  <div>
                    <h4 class="text-sm font-medium text-gray-900"><%= document.name || document.file_name %></h4>
                    <%= if document.description do %>
                      <p class="mt-1 text-sm text-gray-500"><%= document.description %></p>
                    <% end %>
                    <div class="mt-1 flex items-center gap-3 text-xs text-gray-500">
                      <%= if document.document_type do %>
                        <span class={"inline-flex items-center px-2 py-0.5 rounded #{AssetDocument.document_type_color(document.document_type)}"}>
                          <%= AssetDocument.document_type_label(document.document_type) %>
                        </span>
                      <% end %>
                      <%= if document.version do %>
                        <span>v<%= document.version %></span>
                      <% end %>
                    </div>
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <a
                    href={document.file_url || "#"}
                    target="_blank"
                    class="text-blue-600 hover:text-blue-900"
                    title="View"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                    </svg>
                  </a>
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
