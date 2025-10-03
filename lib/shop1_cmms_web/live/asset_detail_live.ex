defmodule Shop1CmmsWeb.AssetDetailLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.Assets
  alias Shop1Cmms.WorkOrders
  alias Shop1CmmsWeb.Components.Assets, as: AssetComponents

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    asset = Assets.get_asset_with_details!(id, current_tenant_id)
    work_orders = WorkOrders.list_work_orders_for_asset(id, current_tenant_id)
    maintenance_history = WorkOrders.get_maintenance_history(id, current_tenant_id)
    manufacturers = Shop1Cmms.Metadata.list_manufacturers(current_tenant_id, active_only: true)

    # Check if user can edit assets
    can_edit = Shop1Cmms.Accounts.can?(current_user, :manage_assets, asset, current_tenant_id)

    # Create empty manufacturer changeset for modal form
    manufacturer_changeset = Shop1Cmms.Metadata.change_manufacturer(%Shop1Cmms.Metadata.Manufacturer{})

    socket = socket
    |> assign(:user, current_user)
    |> assign(:tenant_id, current_tenant_id)
    |> assign(:asset, asset)
    |> assign(:work_orders, work_orders)
    |> assign(:maintenance_history, maintenance_history)
    |> assign(:manufacturers, manufacturers)
    |> assign(:manufacturer_form, to_form(manufacturer_changeset))
    |> assign(:show_manufacturer_modal, false)
    |> assign(:page_title, "Asset Details - #{asset.name}")
    |> assign(:active_tab, "overview")
    |> assign(:edit_mode, false)
    |> assign(:can_edit, can_edit)
    |> assign(:form, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("toggle_edit", _params, socket) do
    if socket.assigns.can_edit do
      if socket.assigns.edit_mode do
        # Exiting edit mode - clear form
        socket = socket
        |> assign(:edit_mode, false)
        |> assign(:form, nil)

        {:noreply, socket}
      else
        # Entering edit mode - create form
        changeset = Assets.change_asset(socket.assigns.asset)

        socket = socket
        |> assign(:edit_mode, true)
        |> assign(:form, to_form(changeset))

        {:noreply, socket}
      end
    else
      {:noreply, put_flash(socket, :error, "You don't have permission to edit assets")}
    end
  end

  def handle_event("validate", %{"asset" => asset_params}, socket) do
    changeset =
      socket.assigns.asset
      |> Assets.change_asset(asset_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"asset" => asset_params}, socket) do
    require Logger
    Logger.info("Save asset called with params: #{inspect(asset_params)}")

    case Assets.update_asset(socket.assigns.asset, asset_params) do
      {:ok, updated_asset} ->
        # Reload asset with details to get fresh data
        asset = Assets.get_asset_with_details!(updated_asset.id, socket.assigns.tenant_id)

        socket = socket
        |> assign(:asset, asset)
        |> assign(:edit_mode, false)
        |> assign(:form, nil)
        |> put_flash(:info, "Asset updated successfully")

        {:noreply, socket}

      {:error, changeset} ->
        Logger.error("Asset update failed: #{inspect(changeset.errors)}")
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete_asset", %{"id" => id}, socket) do
    asset = Assets.get_asset!(socket.assigns.tenant_id, id)

    case Assets.delete_asset(asset) do
      {:ok, _asset} ->
        socket = socket
        |> put_flash(:info, "Asset deleted successfully")
        |> push_navigate(to: ~p"/assets")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to delete asset. It may have associated work orders.")}
    end
  end

  def handle_event("show_manufacturer_modal", _params, socket) do
    # Reset manufacturer form with empty changeset
    manufacturer_changeset = Shop1Cmms.Metadata.change_manufacturer(%Shop1Cmms.Metadata.Manufacturer{})

    {:noreply,
     socket
     |> assign(show_manufacturer_modal: true)
     |> assign(manufacturer_form: to_form(manufacturer_changeset))
     |> put_flash(:info, "Opening manufacturer modal...")}
  end

  def handle_event("hide_manufacturer_modal", _params, socket) do
    {:noreply, assign(socket, show_manufacturer_modal: false)}
  end

  def handle_event("validate_manufacturer", %{"manufacturer" => manufacturer_params}, socket) do
    changeset = Shop1Cmms.Metadata.change_manufacturer(%Shop1Cmms.Metadata.Manufacturer{}, manufacturer_params)
    {:noreply, assign(socket, manufacturer_form: to_form(changeset, action: :validate))}
  end

  def handle_event("create_manufacturer", %{"manufacturer" => manufacturer_params}, socket) do
    tenant_id = socket.assigns.tenant_id

    manufacturer_params = Map.put(manufacturer_params, "tenant_id", tenant_id)

    case Shop1Cmms.Metadata.create_manufacturer(manufacturer_params) do
      {:ok, manufacturer} ->
        manufacturers = Shop1Cmms.Metadata.list_manufacturers(tenant_id, active_only: true)

        # Update the asset form with the new manufacturer
        changeset = Assets.change_asset(socket.assigns.asset, %{"manufacturer" => manufacturer.name})
        form = to_form(changeset)

        {:noreply,
         socket
         |> assign(manufacturers: manufacturers, show_manufacturer_modal: false, form: form)
         |> put_flash(:info, "Manufacturer '#{manufacturer.name}' created successfully")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create manufacturer")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Desktop Asset Detail Page -->
    <div class="h-full flex flex-col overflow-hidden">
      <!-- Toolbar -->
      <div class="flex-shrink-0 h-10 bg-gray-100 border-b border-gray-300 flex items-center justify-between px-3">
        <!-- Breadcrumb -->
        <nav class="flex items-center text-xs space-x-1">
          <.link href="/" class="text-gray-600 hover:text-gray-900">Home</.link>
          <span class="text-gray-400">/</span>
          <.link href="/assets" class="text-gray-600 hover:text-gray-900">Assets</.link>
          <span class="text-gray-400">/</span>
          <span class="text-gray-900 font-medium truncate max-w-xs"><%= @asset.name %></span>
        </nav>
        
        <!-- Actions -->
        <div class="flex items-center space-x-1">
          <%= if @can_edit do %>
            <button
              phx-click="toggle_edit"
              class={if @edit_mode, do: "btn-toolbar", else: "btn-toolbar-primary"}
              title={if @edit_mode, do: "Cancel Edit", else: "Edit Asset"}
            >
              <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                <%= if @edit_mode do %>
                  <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"></path>
                <% else %>
                  <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"></path>
                <% end %>
              </svg>
              <span><%= if @edit_mode, do: "Cancel", else: "Edit" %></span>
            </button>
          <% end %>
          
          <button class="btn-toolbar">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"></path>
              <path fill-rule="evenodd" d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3z" clip-rule="evenodd"></path>
            </svg>
            <span>Create WO</span>
          </button>
          
          <button class="btn-toolbar">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"></path>
            </svg>
            <span>Schedule PM</span>
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

      <!-- Header Bar with Asset Info -->
      <div class="flex-shrink-0 bg-white border-b border-gray-200 px-3 py-2">
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3 min-w-0 flex-1">
            <h1 class="text-lg font-bold text-gray-900 truncate"><%= @asset.name %></h1>
            <span class="text-xs font-mono text-gray-600 flex-shrink-0"><%= @asset.asset_number %></span>
            <AssetComponents.status_badge status={@asset.status} />
            <AssetComponents.criticality_badge criticality={@asset.criticality} />
          </div>
          
          <div class="flex items-center space-x-2 flex-shrink-0 text-xs text-gray-600">
            <span><%= @asset.asset_type.name %></span>
            <span class="text-gray-300">|</span>
            <span><%= @asset.location.name %></span>
          </div>
        </div>
      </div>

      <!-- Compact Tabs -->
      <div class="flex-shrink-0 bg-gray-50 border-b border-gray-200">
        <nav class="flex space-x-1 px-3" aria-label="Tabs">
          <button
            phx-click="change_tab"
            phx-value-tab="overview"
            class={[
              "px-3 py-1.5 text-xs font-medium border-b-2 transition-colors",
              if(@active_tab == "overview",
                do: "border-blue-500 text-blue-600 bg-white",
                else: "border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300")
            ]}
          >
            Overview
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="work_orders"
            class={[
              "px-3 py-1.5 text-xs font-medium border-b-2 transition-colors",
              if(@active_tab == "work_orders",
                do: "border-blue-500 text-blue-600 bg-white",
                else: "border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300")
            ]}
          >
            Work Orders (<%= length(@work_orders) %>)
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="maintenance"
            class={[
              "px-3 py-1.5 text-xs font-medium border-b-2 transition-colors",
              if(@active_tab == "maintenance",
                do: "border-blue-500 text-blue-600 bg-white",
                else: "border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300")
            ]}
          >
            Maintenance History
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="documents"
            class={[
              "px-3 py-1.5 text-xs font-medium border-b-2 transition-colors",
              if(@active_tab == "documents",
                do: "border-blue-500 text-blue-600 bg-white",
                else: "border-transparent text-gray-600 hover:text-gray-900 hover:border-gray-300")
            ]}
          >
            Documents
          </button>
        </nav>
      </div>

      <!-- Tab Content -->
      <div class="flex-1 overflow-auto p-3 bg-gray-50">
        <%= case @active_tab do %>
          <% "overview" -> %>
            <%= render_overview_tab(assigns) %>
          <% "work_orders" -> %>
            <%= render_work_orders_tab(assigns) %>
          <% "maintenance" -> %>
            <%= render_maintenance_tab(assigns) %>
          <% "documents" -> %>
            <%= render_documents_tab(assigns) %>
        <% end %>
      </div>
    </div>

    <!-- Manufacturer Creation Modal -->
    <%= if @show_manufacturer_modal do %>
      <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50" phx-click="hide_manufacturer_modal">
        <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white" phx-click-away="hide_manufacturer_modal">
          <div class="mt-3">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium text-gray-900">Create New Manufacturer</h3>
              <button phx-click="hide_manufacturer_modal" class="text-gray-400 hover:text-gray-600">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>

            <.simple_form for={@manufacturer_form} phx-submit="create_manufacturer" phx-change="validate_manufacturer" class="space-y-4">
              <.input field={@manufacturer_form[:name]} label="Name" type="text" required />
              <.input field={@manufacturer_form[:description]} label="Description" type="textarea" rows="3" />
              <.input field={@manufacturer_form[:contact_email]} label="Contact Email" type="email" />
              <.input field={@manufacturer_form[:contact_phone]} label="Contact Phone" type="text" />
              <.input field={@manufacturer_form[:website]} label="Website" type="url" />
              <.input field={@manufacturer_form[:address]} label="Address" type="textarea" rows="2" />

              <div class="flex justify-end space-x-3 pt-4">
                <.button type="button" phx-click="hide_manufacturer_modal" class="bg-gray-300 hover:bg-gray-400 text-gray-800">
                  Cancel
                </.button>
                <.button type="submit" class="bg-blue-600 hover:bg-blue-700 text-white">
                  Create Manufacturer
                </.button>
              </div>
            </.simple_form>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
  defp render_overview_tab(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <!-- Asset Details -->
      <div class="lg:col-span-2">
        <div class="bg-white shadow rounded-lg p-4">
          <h2 class="text-base font-semibold text-gray-900 mb-4">Asset Information</h2>

          <%= if @edit_mode and not is_nil(@form) and not is_nil(@manufacturers) and not is_nil(@asset) do %>
            <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-4">
              <!-- Hidden fields for required values -->
              <.input field={@form[:tenant_id]} type="hidden" />
              <.input field={@form[:asset_type_id]} type="hidden" />

              <!-- Compact 3-column grid with borders -->
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                <!-- Basic Information -->
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:name]} label="Asset Name" type="text" required class="text-sm" />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:asset_number]} label="Asset Number" type="text" required class="text-sm" />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:serial_number]} label="Serial Number" type="text" class="text-sm" />
                </div>
                
                <!-- Manufacturer with inline button -->
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <label class="block text-xs font-medium text-gray-700 mb-1">Manufacturer</label>
                  <div class="flex gap-1">
                    <.input
                      field={@form[:manufacturer]}
                      type="select"
                      options={manufacturer_options(@manufacturers, @asset.manufacturer || "")}
                      prompt="Select..."
                      class="text-sm flex-1"
                    />
                    <button
                      type="button"
                      phx-click="show_manufacturer_modal"
                      class="px-2 py-1 bg-green-600 hover:bg-green-700 text-white text-xs rounded"
                      title="Add New Manufacturer"
                    >
                      +
                    </button>
                  </div>
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:model]} label="Model" type="text" class="text-sm" />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:barcode]} label="Barcode" type="text" class="text-sm" />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:qr_code]} label="QR Code" type="text" class="text-sm" />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input
                    field={@form[:status]}
                    label="Status"
                    type="select"
                    options={status_options()}
                    required
                    class="text-sm"
                  />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input
                    field={@form[:criticality]}
                    label="Criticality"
                    type="select"
                    options={criticality_options()}
                    required
                    class="text-sm"
                  />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:purchase_date]} label="Purchase Date" type="date" class="text-sm" />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:install_date]} label="Install Date" type="date" class="text-sm" />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:commission_date]} label="Commission Date" type="date" class="text-sm" />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:warranty_expiry]} label="Warranty Expiry" type="date" class="text-sm" />
                </div>
                
                <div class="border border-gray-300 rounded p-2 bg-gray-50">
                  <.input field={@form[:purchase_cost]} label="Purchase Cost ($)" type="number" step="0.01" min="0" class="text-sm" />
                </div>
              </div>

              <!-- Full-width text fields -->
              <div class="border border-gray-300 rounded p-2 bg-gray-50">
                <.input field={@form[:description]} label="Description" type="textarea" rows="2" class="text-sm" />
              </div>
              
              <div class="border border-gray-300 rounded p-2 bg-gray-50">
                <.input field={@form[:notes]} label="Notes" type="textarea" rows="2" class="text-sm" />
              </div>

              <!-- Action buttons -->
              <div class="flex justify-end space-x-2 pt-3 border-t">
                <button
                  type="button"
                  phx-click="toggle_edit"
                  class="px-3 py-1.5 text-sm bg-gray-300 hover:bg-gray-400 text-gray-800 rounded"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="px-3 py-1.5 text-sm bg-blue-600 hover:bg-blue-700 text-white rounded"
                >
                  Save Changes
                </button>
              </div>
            </.form>
          <% else %>
            <!-- Read-only View - Compact -->
            <div class="space-y-4">
              <!-- Basic Information Section -->
              <div class="border border-gray-200 rounded-lg p-3 bg-gray-50">
                <h3 class="text-xs font-semibold text-gray-700 uppercase mb-2">Basic Information</h3>
                <dl class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                  <div>
                    <dt class="text-xs text-gray-500">Asset Number</dt>
                    <dd class="text-sm font-medium text-gray-900 font-mono"><%= @asset.asset_number %></dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Asset Type</dt>
                    <dd class="text-sm text-gray-900"><%= @asset.asset_type.name %></dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Asset Name</dt>
                    <dd class="text-sm text-gray-900"><%= @asset.name %></dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Location</dt>
                    <dd class="text-sm text-gray-900"><%= if @asset.location, do: @asset.location.name, else: "N/A" %></dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Status</dt>
                    <dd class="text-sm"><AssetComponents.status_badge status={@asset.status} /></dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Criticality</dt>
                    <dd class="text-sm"><AssetComponents.criticality_badge criticality={@asset.criticality} /></dd>
                  </div>
                </dl>
              </div>

              <!-- Identification Section -->
              <div class="border border-gray-200 rounded-lg p-3 bg-gray-50">
                <h3 class="text-xs font-semibold text-gray-700 uppercase mb-2">Identification</h3>
                <dl class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                  <div>
                    <dt class="text-xs text-gray-500">Serial Number</dt>
                    <dd class="text-sm text-gray-900"><%= @asset.serial_number || "N/A" %></dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Barcode</dt>
                    <dd class="text-sm text-gray-900 font-mono"><%= @asset.barcode || "N/A" %></dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">QR Code</dt>
                    <dd class="text-sm text-gray-900 font-mono"><%= @asset.qr_code || "N/A" %></dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Manufacturer</dt>
                    <dd class="text-sm text-gray-900"><%= @asset.manufacturer || "N/A" %></dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Model</dt>
                    <dd class="text-sm text-gray-900"><%= @asset.model || "N/A" %></dd>
                  </div>
                </dl>
              </div>

              <!-- Dates Section -->
              <div class="border border-gray-200 rounded-lg p-3 bg-gray-50">
                <h3 class="text-xs font-semibold text-gray-700 uppercase mb-2">Important Dates</h3>
                <dl class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                  <div>
                    <dt class="text-xs text-gray-500">Purchase Date</dt>
                    <dd class="text-sm text-gray-900">
                      <%= if @asset.purchase_date, do: Calendar.strftime(@asset.purchase_date, "%m/%d/%Y"), else: "N/A" %>
                    </dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Install Date</dt>
                    <dd class="text-sm text-gray-900">
                      <%= if @asset.install_date, do: Calendar.strftime(@asset.install_date, "%m/%d/%Y"), else: "N/A" %>
                    </dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Commission Date</dt>
                    <dd class="text-sm text-gray-900">
                      <%= if @asset.commission_date, do: Calendar.strftime(@asset.commission_date, "%m/%d/%Y"), else: "N/A" %>
                    </dd>
                  </div>
                  <div>
                    <dt class="text-xs text-gray-500">Warranty Expiry</dt>
                    <dd class="text-sm text-gray-900">
                      <%= if @asset.warranty_expiry, do: Calendar.strftime(@asset.warranty_expiry, "%m/%d/%Y"), else: "N/A" %>
                    </dd>
                  </div>
                </dl>
              </div>

              <!-- Description & Notes -->
              <%= if @asset.description || @asset.notes do %>
                <div class="border border-gray-200 rounded-lg p-3 bg-gray-50 space-y-2">
                  <%= if @asset.description do %>
                    <div>
                      <dt class="text-xs font-semibold text-gray-700 uppercase mb-1">Description</dt>
                      <dd class="text-sm text-gray-900 whitespace-pre-wrap"><%= @asset.description %></dd>
                    </div>
                  <% end %>
                  <%= if @asset.notes do %>
                    <div class={if @asset.description, do: "pt-2 border-t border-gray-300", else: ""}>
                      <dt class="text-xs font-semibold text-gray-700 uppercase mb-1">Notes</dt>
                      <dd class="text-sm text-gray-900 whitespace-pre-wrap"><%= @asset.notes %></dd>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Quick Stats Sidebar -->
      <div class="space-y-4">
        <!-- Status Card -->
        <div class="bg-white shadow rounded-lg p-4">
          <h3 class="text-sm font-semibold text-gray-900 mb-3">Quick Stats</h3>
          <div class="space-y-2">
            <div class="flex justify-between items-center">
              <span class="text-xs text-gray-500">Open Work Orders</span>
              <span class="text-sm font-bold text-blue-600">
                <%= Enum.count(@work_orders, &(&1.status in [:pending, :in_progress])) %>
              </span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-xs text-gray-500">Total Work Orders</span>
              <span class="text-sm font-semibold text-gray-900"><%= length(@work_orders) %></span>
            </div>
            <div class="flex justify-between items-center">
              <span class="text-xs text-gray-500">Maintenance Tasks</span>
              <span class="text-sm font-semibold text-gray-900"><%= length(@maintenance_history) %></span>
            </div>
          </div>
        </div>

        <!-- Financial Info -->
        <%= if @asset.purchase_cost do %>
          <div class="bg-white shadow rounded-lg p-4">
            <h3 class="text-sm font-semibold text-gray-900 mb-3">Financial</h3>
            <div class="space-y-2">
              <div class="flex justify-between items-center">
                <span class="text-xs text-gray-500">Purchase Cost</span>
                <span class="text-sm font-bold text-green-600">
                  $<%= Decimal.to_string(@asset.purchase_cost, :normal) %>
                </span>
              </div>
              <%= if @asset.warranty_expiry do %>
                <div class="flex justify-between items-center">
                  <span class="text-xs text-gray-500">Warranty Expiry</span>
                  <span class="text-sm text-gray-900">
                    <%= Calendar.strftime(@asset.warranty_expiry, "%m/%d/%Y") %>
                  </span>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp render_work_orders_tab(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg">
      <div class="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
        <h2 class="text-lg font-medium text-gray-900">Work Orders</h2>
        <.link
          navigate={~p"/work_orders/new?asset_id=#{@asset.id}"}
          class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
        >
          New Work Order
        </.link>
      </div>

      <%= if Enum.empty?(@work_orders) do %>
        <div class="p-6 text-center">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No work orders</h3>
          <p class="mt-1 text-sm text-gray-500">Get started by creating a new work order for this asset.</p>
        </div>
      <% else %>
        <div class="divide-y divide-gray-200">
          <%= for work_order <- @work_orders do %>
            <div class="p-6 hover:bg-gray-50">
              <div class="flex items-center justify-between">
                <div class="flex-1">
                  <div class="flex items-center space-x-3">
                    <.link
                      navigate={~p"/work_orders/#{work_order.id}"}
                      class="text-sm font-medium text-blue-600 hover:text-blue-800"
                    >
                      <%= work_order.title %>
                    </.link>
                    <span class={["inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
                                status_color_class(work_order.status)]}>
                      <%= work_order.status |> to_string() |> String.replace("_", " ") |> String.capitalize() %>
                    </span>
                  </div>
                  <p class="mt-1 text-sm text-gray-500"><%= work_order.description %></p>
                  <div class="mt-2 flex items-center text-sm text-gray-500 space-x-4">
                    <span>Priority: <%= work_order.priority |> to_string() |> String.capitalize() %></span>
                    <span>Created: <%= Calendar.strftime(work_order.inserted_at, "%B %d, %Y") %></span>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_maintenance_tab(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg">
      <div class="px-6 py-4 border-b border-gray-200">
        <h2 class="text-lg font-medium text-gray-900">Maintenance History</h2>
      </div>

      <%= if Enum.empty?(@maintenance_history) do %>
        <div class="p-6 text-center">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No maintenance history</h3>
          <p class="mt-1 text-sm text-gray-500">Maintenance activities will appear here once work orders are completed.</p>
        </div>
      <% else %>
        <div class="flow-root">
          <ul role="list" class="-mb-8">
            <%= for {record, index} <- Enum.with_index(@maintenance_history) do %>
              <li>
                <div class="relative pb-8">
                  <%= if index < length(@maintenance_history) - 1 do %>
                    <span class="absolute top-5 left-5 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
                  <% end %>
                  <div class="relative flex items-start space-x-3">
                    <div>
                      <div class="relative px-1">
                        <div class="h-8 w-8 bg-blue-500 rounded-full ring-8 ring-white flex items-center justify-center">
                          <svg class="h-4 w-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                          </svg>
                        </div>
                      </div>
                    </div>
                    <div class="min-w-0 flex-1 py-1.5">
                      <div class="text-sm text-gray-500">
                        <span class="font-medium text-gray-900"><%= record.title %></span>
                        completed maintenance
                        <span class="whitespace-nowrap">
                          <%= Calendar.strftime(record.completed_at, "%B %d, %Y at %I:%M %p") %>
                        </span>
                      </div>
                      <%= if record.description do %>
                        <div class="mt-2 text-sm text-gray-700">
                          <p><%= record.description %></p>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      <% end %>
    </div>
    """
  end

  defp render_documents_tab(assigns) do
    ~H"""
    <div class="bg-white shadow rounded-lg">
      <div class="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
        <h2 class="text-lg font-medium text-gray-900">Documents</h2>
        <button class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700">
          Upload Document
        </button>
      </div>

      <div class="p-6 text-center">
        <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
        </svg>
        <h3 class="mt-2 text-sm font-medium text-gray-900">No documents</h3>
        <p class="mt-1 text-sm text-gray-500">Upload manuals, warranties, and other documents for this asset.</p>
      </div>
    </div>
    """
  end

  defp status_color_class(:pending), do: "bg-yellow-100 text-yellow-800"
  defp status_color_class(:in_progress), do: "bg-blue-100 text-blue-800"
  defp status_color_class(:completed), do: "bg-green-100 text-green-800"
  defp status_color_class(:cancelled), do: "bg-red-100 text-red-800"
  defp status_color_class(_), do: "bg-gray-100 text-gray-800"

  defp manufacturer_options(manufacturers, current_manufacturer) do
    options = Enum.map(manufacturers, &{&1.name, &1.name})

    # Include current manufacturer if it's not in the list
    if current_manufacturer && current_manufacturer not in Enum.map(options, &elem(&1, 1)) do
      [{current_manufacturer, current_manufacturer} | options]
    else
      options
    end
  end

  defp status_options do
    [
      {"Operational", "operational"},
      {"Maintenance", "maintenance"},
      {"Repair", "repair"},
      {"Retired", "retired"},
      {"Disposed", "disposed"}
    ]
  end

  defp criticality_options do
    [
      {"Low", "low"},
      {"Medium", "medium"},
      {"High", "high"},
      {"Critical", "critical"}
    ]
  end
end
