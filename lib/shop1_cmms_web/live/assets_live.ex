defmodule Shop1CmmsWeb.AssetsLive do
  use Shop1CmmsWeb, :live_view
  alias Shop1Cmms.Assets
  import Shop1CmmsWeb.Components.Assets

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @live_action in [:new, :edit] && @show_modal do %>
      <.modal id="asset-modal" show on_cancel={JS.patch(~p"/assets")}>
        <:title><%= @page_title %></:title>
        <.live_component
          module={Shop1CmmsWeb.AssetFormLive}
          id={@asset.id || :new}
          title={@page_title}
          action={@live_action}
          asset={@asset}
          asset_types={@asset_types}
          asset_locations={@asset_locations}
          tenant_id={@tenant_id}
          user={@user}
          patch={~p"/assets"}
        />
      </.modal>
    <% end %>
    
    <!-- Desktop-Style Assets Page with Dense Table -->
    <div class="h-full flex flex-col overflow-hidden">
      <!-- Toolbar -->
      <div class="flex-shrink-0 h-11 bg-gray-100 border-b border-gray-300 flex items-center justify-between px-3">
        <!-- Breadcrumb -->
        <nav class="flex items-center text-xs space-x-1">
          <.link href="/" class="text-gray-600 hover:text-gray-900">Home</.link>
          <span class="text-gray-400">/</span>
          <span class="text-gray-900 font-medium">Equipment</span>
        </nav>
        
        <!-- Quick Actions -->
        <div class="flex items-center gap-2">
          <.link 
            navigate={~p"/assets/new"}
            class="btn-toolbar-primary"
          >
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"></path>
            </svg>
            <span>New Equipment</span>
          </.link>
          <button phx-click="import" class="btn-toolbar" title="Import equipment data">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"></path>
            </svg>
            <span>Import</span>
          </button>
          <div x-data="{ open: false }" class="relative inline-block">
            <button @click="open = !open" class="btn-toolbar" title="Export equipment data">
              <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM6.293 6.707a1 1 0 010-1.414l3-3a1 1 0 011.414 0l3 3a1 1 0 01-1.414 1.414L11 5.414V13a1 1 0 11-2 0V5.414L7.707 6.707a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
              </svg>
              <span>Export</span>
              <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/>
              </svg>
            </button>
            <div x-show="open" @click.away="open = false" x-cloak class="absolute right-0 mt-1 w-48 bg-white border border-gray-300 rounded shadow-lg z-50">
              <button phx-click="export" phx-value-format="csv" @click="open = false" class="block w-full text-left px-4 py-2 text-xs hover:bg-gray-100 transition-colors">
                <span class="font-medium">Export as CSV</span>
              </button>
              <button phx-click="export" phx-value-format="xlsx" @click="open = false" class="block w-full text-left px-4 py-2 text-xs hover:bg-gray-100 transition-colors">
                <span class="font-medium">Export as Excel</span>
              </button>
              <button phx-click="export" phx-value-format="pdf" @click="open = false" class="block w-full text-left px-4 py-2 text-xs hover:bg-gray-100 transition-colors">
                <span class="font-medium">Export as PDF</span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Filters Bar -->
      <div class="flex-shrink-0 bg-white border-b border-gray-200 p-2">
        <div class="flex items-center space-x-2">
          <!-- Search -->
          <div class="flex-1 max-w-md">
            <form phx-change="search" phx-submit="search">
              <div class="relative">
                <input 
                  type="text" 
                  name="search[term]" 
                  value={@search_term}
                  placeholder="Search equipment..." 
                  class="block w-full pl-7 pr-2 py-1 text-xs border-gray-300 rounded focus:ring-blue-500 focus:border-blue-500"
                />
                <svg class="absolute left-2 top-1.5 w-3.5 h-3.5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                </svg>
              </div>
            </form>
          </div>

          <!-- Quick Filters -->
          <select phx-change="filter_status" name="status" class="text-xs py-1 px-2 border-gray-300 rounded">
            <option value="all">All Status</option>
            <option value="operational" selected={@selected_status == "operational"}>Operational</option>
            <option value="maintenance" selected={@selected_status == "maintenance"}>Maintenance</option>
            <option value="repair" selected={@selected_status == "repair"}>Repair</option>
            <option value="retired" selected={@selected_status == "retired"}>Retired</option>
            <option value="disposed" selected={@selected_status == "disposed"}>Disposed</option>
          </select>

          <select phx-change="filter_type" name="type" class="text-xs py-1 px-2 border-gray-300 rounded">
            <option value="all">All Types</option>
            <%= for asset_type <- @asset_types do %>
              <option value={asset_type.id} selected={@selected_type == to_string(asset_type.id)}>
                <%= asset_type.name %>
              </option>
            <% end %>
          </select>

          <select phx-change="filter_criticality" name="criticality" class="text-xs py-1 px-2 border-gray-300 rounded">
            <option value="all">All Criticality</option>
            <option value="critical" selected={@selected_criticality == "critical"}>Critical</option>
            <option value="high" selected={@selected_criticality == "high"}>High</option>
            <option value="medium" selected={@selected_criticality == "medium"}>Medium</option>
            <option value="low" selected={@selected_criticality == "low"}>Low</option>
          </select>

          <!-- Results Count -->
          <div class="text-xs text-gray-600 ml-auto">
            <%= length(@filtered_assets) %> of <%= length(@assets) %> equipment
          </div>
        </div>
      </div>

      <!-- Dense Table -->
      <div class="flex-1 overflow-auto">
        <%= if length(@filtered_assets) > 0 do %>
          <table class="table-dense">
            <thead>
              <tr>
                <th class="w-8">
                  <input type="checkbox" class="rounded border-gray-300" />
                </th>
                <th phx-click="sort" phx-value-field="asset_number" class="cursor-pointer hover:bg-gray-100">
                  <div class="flex items-center gap-1">
                    Equipment #
                    <%= if @sort_field == "asset_number" do %>
                      <%= if @sort_direction == :asc do %>
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/></svg>
                      <% else %>
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd"/></svg>
                      <% end %>
                    <% end %>
                  </div>
                </th>
                <th phx-click="sort" phx-value-field="name" class="cursor-pointer hover:bg-gray-100">
                  <div class="flex items-center gap-1">
                    Name
                    <%= if @sort_field == "name" do %>
                      <%= if @sort_direction == :asc do %>
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/></svg>
                      <% else %>
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd"/></svg>
                      <% end %>
                    <% end %>
                  </div>
                </th>
                <th>Type</th>
                <th>Location</th>
                <th>Manufacturer</th>
                <th>Model</th>
                <th phx-click="sort" phx-value-field="status" class="cursor-pointer hover:bg-gray-100">
                  <div class="flex items-center gap-1">
                    Status
                    <%= if @sort_field == "status" do %>
                      <%= if @sort_direction == :asc do %>
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/></svg>
                      <% else %>
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd"/></svg>
                      <% end %>
                    <% end %>
                  </div>
                </th>
                <th phx-click="sort" phx-value-field="criticality" class="cursor-pointer hover:bg-gray-100">
                  <div class="flex items-center gap-1">
                    Criticality
                    <%= if @sort_field == "criticality" do %>
                      <%= if @sort_direction == :asc do %>
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/></svg>
                      <% else %>
                        <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clip-rule="evenodd"/></svg>
                      <% end %>
                    <% end %>
                  </div>
                </th>
                <th class="w-24">Actions</th>
              </tr>
            </thead>
            <tbody>
              <%= for asset <- @filtered_assets do %>
                <tr 
                  phx-click="select_asset" 
                  phx-value-id={asset.id}
                  data-context-menu="asset"
                  data-context-id={asset.id}
                >
                  <td>
                    <input type="checkbox" class="rounded border-gray-300" onclick="event.stopPropagation()" />
                  </td>
                  <td class="font-mono text-gray-600"><%= asset.asset_number %></td>
                  <td class="font-medium text-gray-900"><%= asset.name %></td>
                  <td><%= asset.asset_type.name %></td>
                  <td class="text-gray-600"><%= asset.location.name %></td>
                  <td class="text-gray-600"><%= asset.manufacturer || "-" %></td>
                  <td class="text-gray-600"><%= asset.model || "-" %></td>
                  <td>
                    <span class={[
                      "inline-block px-2 py-0.5 text-xs font-medium rounded",
                      status_badge_class(asset.status)
                    ]}>
                      <%= format_status(asset.status) %>
                    </span>
                  </td>
                  <td>
                    <div class="flex items-center">
                      <%= for _ <- 1..criticality_to_number(asset.criticality) do %>
                        <svg class="w-3 h-3 text-orange-500" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path>
                        </svg>
                      <% end %>
                    </div>
                  </td>
                  <td>
                    <div class="flex items-center space-x-1">
                      <.link href={"/assets/#{asset.id}"} class="p-1 hover:bg-gray-200 rounded" title="View">
                        <svg class="w-3.5 h-3.5 text-gray-600" fill="currentColor" viewBox="0 0 20 20">
                          <path d="M10 12a2 2 0 100-4 2 2 0 000 4z"></path>
                          <path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"></path>
                        </svg>
                      </.link>
                      <.link navigate={"/assets/#{asset.id}/edit"} class="p-1 hover:bg-gray-200 rounded" title="Edit">
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
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                </svg>
              </div>
              <h3 class="text-lg font-semibold text-gray-900">No equipment found</h3>
              <p class="mt-2 text-sm text-gray-500 max-w-md mx-auto">
                <%= if @search_term != "" or @selected_status != "all" or @selected_type != "all" do %>
                  No equipment matches your current filters. Try adjusting your search criteria.
                <% else %>
                  Get started by adding your first equipment to the system.
                <% end %>
              </p>
              <div class="mt-6">
                <%= if @search_term != "" or @selected_status != "all" or @selected_type != "all" do %>
                  <button phx-click="clear_filters" class="btn-toolbar">
                    Clear Filters
                  </button>
                <% else %>
                  <.link navigate={~p"/assets/new"} class="btn-toolbar-primary">
                    <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                      <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"></path>
                    </svg>
                    <span>Add First Equipment</span>
                  </.link>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <!-- Table Footer -->
      <%= if length(@filtered_assets) > 0 do %>
        <div class="flex-shrink-0 h-8 bg-gray-50 border-t border-gray-300 flex items-center justify-between px-3 text-xs">
          <div class="text-gray-600">
            Showing <%= length(@filtered_assets) %> equipment
          </div>
          <div class="flex items-center space-x-2">
            <span class="text-gray-500">Page 1 of 1</span>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper functions for template
  defp status_badge_class(:operational), do: "bg-green-100 text-green-800"
  defp status_badge_class(:maintenance), do: "bg-yellow-100 text-yellow-800"
  defp status_badge_class(:repair), do: "bg-orange-100 text-orange-800"
  defp status_badge_class(:retired), do: "bg-gray-100 text-gray-800"
  defp status_badge_class(:disposed), do: "bg-red-100 text-red-800"
  defp status_badge_class(_), do: "bg-gray-100 text-gray-600"

  defp format_status(:operational), do: "Operational"
  defp format_status(:maintenance), do: "Maintenance"
  defp format_status(:repair), do: "Repair"
  defp format_status(:retired), do: "Retired"
  defp format_status(:disposed), do: "Disposed"
  defp format_status(status), do: to_string(status) |> String.capitalize()

  defp criticality_to_number(:critical), do: 4
  defp criticality_to_number(:high), do: 3
  defp criticality_to_number(:medium), do: 2
  defp criticality_to_number(:low), do: 1
  defp criticality_to_number(_), do: 0

  @impl true
  def mount(%{"id" => id}, _session, socket) when socket.assigns.live_action == :edit do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    asset = Assets.get_asset!(current_tenant_id, id)
    assets = Assets.list_assets_with_details(current_tenant_id)
    asset_types = Assets.list_asset_types(current_tenant_id)
    asset_locations = Assets.list_asset_locations(current_tenant_id)

    socket = socket
    |> assign(:user, current_user)
    |> assign(:tenant_id, current_tenant_id)
    |> assign(:assets, assets)
    |> assign(:asset, asset)
    |> assign(:asset_types, asset_types)
    |> assign(:asset_locations, asset_locations)
    |> assign(:unique_manufacturers, get_unique_manufacturers(assets))
    |> assign(:selected_status, "all")
    |> assign(:selected_type, "all")
    |> assign(:selected_criticality, "all")
    |> assign(:selected_manufacturer, "all")
    |> assign(:search_term, "")
    |> assign(:date_from, "")
    |> assign(:date_to, "")
    |> assign(:show_advanced_filters, false)
    |> assign(:filtered_assets, assets)
    |> assign(:page_title, "Edit Asset - #{asset.name}")
    |> assign(:view_mode, "grid")
    |> assign(:live_action, :edit)
    |> assign(:show_modal, true)
    |> assign(:sort_field, "name")
    |> assign(:sort_direction, :asc)

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) when socket.assigns.live_action == :new do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    # Load assets and asset types
    assets = Assets.list_assets_with_details(current_tenant_id)
    asset_types = Assets.list_asset_types(current_tenant_id)
    asset_locations = Assets.list_asset_locations(current_tenant_id)

    socket = socket
    |> assign(:user, current_user)
    |> assign(:tenant_id, current_tenant_id)
    |> assign(:assets, assets)
    |> assign(:asset_types, asset_types)
    |> assign(:asset_locations, asset_locations)
    |> assign(:asset, %Assets.Asset{})
    |> assign(:unique_manufacturers, get_unique_manufacturers(assets))
    |> assign(:selected_status, "all")
    |> assign(:selected_type, "all")
    |> assign(:selected_criticality, "all")
    |> assign(:selected_manufacturer, "all")
    |> assign(:search_term, "")
    |> assign(:date_from, "")
    |> assign(:date_to, "")
    |> assign(:show_advanced_filters, false)
    |> assign(:filtered_assets, assets)
    |> assign(:page_title, "Add New Asset")
    |> assign(:view_mode, "grid")
    |> assign(:live_action, :new)
    |> assign(:show_modal, true)
    |> assign(:sort_field, "name")
    |> assign(:sort_direction, :asc)

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    # Load assets and asset types
    assets = Assets.list_assets_with_details(current_tenant_id)
    asset_types = Assets.list_asset_types(current_tenant_id)
    asset_locations = Assets.list_asset_locations(current_tenant_id)

    socket = socket
    |> assign(:user, current_user)
    |> assign(:tenant_id, current_tenant_id)
    |> assign(:assets, assets)
    |> assign(:asset_types, asset_types)
    |> assign(:asset_locations, asset_locations)
    |> assign(:unique_manufacturers, get_unique_manufacturers(assets))
    |> assign(:selected_status, "all")
    |> assign(:selected_type, "all")
    |> assign(:selected_criticality, "all")
    |> assign(:selected_manufacturer, "all")
    |> assign(:search_term, "")
    |> assign(:date_from, "")
    |> assign(:date_to, "")
    |> assign(:show_advanced_filters, false)
    |> assign(:filtered_assets, assets)
    |> assign(:page_title, "Assets Management")
    |> assign(:view_mode, "grid")  # grid, list, kanban
    |> assign(:live_action, :index)
    |> assign(:show_modal, false)
    |> assign(:sort_field, "name")
    |> assign(:sort_direction, :asc)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add New Asset")
    |> assign(:asset, %Assets.Asset{})
    |> assign(:show_modal, true)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    asset = Assets.get_asset!(socket.assigns.tenant_id, id)
    socket
    |> assign(:page_title, "Edit Asset - #{asset.name}")
    |> assign(:asset, asset)
    |> assign(:show_modal, true)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Assets Management")
    |> assign(:show_modal, false)
  end

  @impl true
  def handle_event("search", %{"search" => %{"term" => term}}, socket) do
    socket = socket
    |> assign(:search_term, term)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("change_view", %{"view" => view}, socket) do
    {:noreply, assign(socket, :view_mode, view)}
  end

  def handle_event("toggle_advanced_filters", _params, socket) do
    {:noreply, assign(socket, :show_advanced_filters, !socket.assigns.show_advanced_filters)}
  end

  def handle_event("clear_filters", _params, socket) do
    socket = socket
    |> assign(:search_term, "")
    |> assign(:selected_status, "all")
    |> assign(:selected_type, "all")
    |> assign(:selected_criticality, "all")
    |> assign(:selected_manufacturer, "all")
    |> apply_filters()
    
    {:noreply, socket}
  end

  def handle_event("select_asset", %{"id" => id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/assets/#{id}")}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    socket = socket
    |> assign(:selected_status, status)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    socket = socket
    |> assign(:selected_type, type)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("filter_criticality", %{"criticality" => criticality}, socket) do
    socket = socket
    |> assign(:selected_criticality, criticality)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("filter_manufacturer", %{"manufacturer" => manufacturer}, socket) do
    socket = socket
    |> assign(:selected_manufacturer, manufacturer)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("filter_date_range", %{"date_from" => date_from, "date_to" => date_to}, socket) do
    socket = socket
    |> assign(:date_from, date_from)
    |> assign(:date_to, date_to)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("sort", %{"field" => field}, socket) do
    field_atom = String.to_existing_atom(field)
    
    sort_direction = 
      if socket.assigns.sort_field == field_atom do
        if socket.assigns.sort_direction == :asc, do: :desc, else: :asc
      else
        :asc
      end
    
    socket = socket
    |> assign(:sort_field, field_atom)
    |> assign(:sort_direction, sort_direction)
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("export", %{"format" => format}, socket) do
    # TODO: Implement actual export functionality
    # For now, just show a flash message
    {:noreply, put_flash(socket, :info, "Export to #{String.upcase(format)} coming soon")}
  end

  def handle_event("import", _params, socket) do
    # TODO: Implement import functionality
    {:noreply, put_flash(socket, :info, "Import functionality coming soon")}
  end

  def handle_event("clear_filters", _params, socket) do
    socket = socket
    |> assign(:selected_status, "all")
    |> assign(:selected_type, "all")
    |> assign(:selected_criticality, "all")
    |> assign(:selected_manufacturer, "all")
    |> assign(:search_term, "")
    |> assign(:date_from, "")
    |> assign(:date_to, "")
    |> apply_filters()

    {:noreply, socket}
  end

  def handle_event("delete_asset", %{"id" => id}, socket) do
    asset = Assets.get_asset!(socket.assigns.tenant_id, id)

    case Assets.delete_asset(asset) do
      {:ok, _asset} ->
        assets = Assets.list_assets_with_details(socket.assigns.tenant_id)
        socket = socket
        |> assign(:assets, assets)
        |> apply_filters()
        |> put_flash(:info, "Asset deleted successfully")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Unable to delete asset. It may have associated work orders.")}
    end
  end

  @impl true
  def handle_info({:close_modal}, socket) do
    {:noreply, push_patch(socket, to: ~p"/assets")}
  end

  def handle_info({:asset_saved, _asset, message}, socket) do
    assets = Assets.list_assets_with_details(socket.assigns.tenant_id)

    socket = socket
    |> assign(:assets, assets)
    |> assign(:unique_manufacturers, get_unique_manufacturers(assets))
    |> apply_filters()
    |> put_flash(:info, message)
    |> push_patch(to: ~p"/assets")

    {:noreply, socket}
  end

  defp apply_filters(socket) do
    filtered_assets = socket.assigns.assets
    |> filter_by_status(socket.assigns.selected_status)
    |> filter_by_type(socket.assigns.selected_type)
    |> filter_by_criticality(socket.assigns.selected_criticality)
    |> filter_by_manufacturer(socket.assigns.selected_manufacturer)
    |> filter_by_search(socket.assigns.search_term)
    |> filter_by_date_range(socket.assigns.date_from, socket.assigns.date_to)
    |> sort_assets(socket.assigns.sort_field, socket.assigns.sort_direction)

    assign(socket, :filtered_assets, filtered_assets)
  end

  defp sort_assets(assets, :name, :asc), do: Enum.sort_by(assets, & &1.name)
  defp sort_assets(assets, :name, :desc), do: Enum.sort_by(assets, & &1.name, :desc)
  defp sort_assets(assets, :asset_number, :asc), do: Enum.sort_by(assets, & &1.asset_number)
  defp sort_assets(assets, :asset_number, :desc), do: Enum.sort_by(assets, & &1.asset_number, :desc)
  defp sort_assets(assets, :status, :asc), do: Enum.sort_by(assets, & &1.status)
  defp sort_assets(assets, :status, :desc), do: Enum.sort_by(assets, & &1.status, :desc)
  defp sort_assets(assets, :criticality, :asc), do: Enum.sort_by(assets, &criticality_to_number(&1.criticality))
  defp sort_assets(assets, :criticality, :desc), do: Enum.sort_by(assets, &criticality_to_number(&1.criticality), :desc)
  defp sort_assets(assets, _, _), do: assets

  defp filter_by_status(assets, "all"), do: assets
  defp filter_by_status(assets, status) do
    Enum.filter(assets, &(&1.status == String.to_atom(status)))
  end

  defp filter_by_type(assets, "all"), do: assets
  defp filter_by_type(assets, type_id) when is_binary(type_id) do
    {type_id_int, _} = Integer.parse(type_id)
    Enum.filter(assets, &(&1.asset_type_id == type_id_int))
  end
  defp filter_by_type(assets, type_id) do
    Enum.filter(assets, &(&1.asset_type_id == type_id))
  end

  defp filter_by_criticality(assets, "all"), do: assets
  defp filter_by_criticality(assets, criticality) do
    Enum.filter(assets, &(&1.criticality == String.to_atom(criticality)))
  end

  defp filter_by_manufacturer(assets, "all"), do: assets
  defp filter_by_manufacturer(assets, ""), do: assets
  defp filter_by_manufacturer(assets, manufacturer) do
    Enum.filter(assets, fn asset ->
      asset.manufacturer && String.downcase(asset.manufacturer) == String.downcase(manufacturer)
    end)
  end

  defp filter_by_search(assets, ""), do: assets
  defp filter_by_search(assets, term) do
    term = String.downcase(term)
    Enum.filter(assets, fn asset ->
      String.contains?(String.downcase(asset.name || ""), term) ||
      String.contains?(String.downcase(asset.asset_number || ""), term) ||
      String.contains?(String.downcase(asset.manufacturer || ""), term) ||
      String.contains?(String.downcase(asset.model || ""), term) ||
      (asset.location && String.contains?(String.downcase(asset.location.name || ""), term))
    end)
  end

  defp filter_by_date_range(assets, "", ""), do: assets
  defp filter_by_date_range(assets, date_from, date_to) do
    {from_date, to_date} = parse_date_range(date_from, date_to)

    Enum.filter(assets, fn asset ->
      case asset.install_date do
        nil -> false
        date ->
          (from_date == nil || Date.compare(date, from_date) != :lt) &&
          (to_date == nil || Date.compare(date, to_date) != :gt)
      end
    end)
  end

  defp parse_date_range(date_from, date_to) do
    from_date = if date_from != "", do: Date.from_iso8601!(date_from), else: nil
    to_date = if date_to != "", do: Date.from_iso8601!(date_to), else: nil
    {from_date, to_date}
  end

  defp get_unique_manufacturers(assets) do
    assets
    |> Enum.map(& &1.manufacturer)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.sort()
  end


end
