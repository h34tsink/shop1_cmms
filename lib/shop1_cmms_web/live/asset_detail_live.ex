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

    socket = socket
    |> assign(:user, current_user)
    |> assign(:tenant_id, current_tenant_id)
    |> assign(:asset, asset)
    |> assign(:work_orders, work_orders)
    |> assign(:maintenance_history, maintenance_history)
    |> assign(:page_title, "Asset Details - #{asset.name}")
    |> assign(:active_tab, "overview")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, tab)}
  end

  def handle_event("delete_asset", %{"id" => id}, socket) do
    asset = Assets.get_asset!(id, socket.assigns.tenant_id)

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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Header -->
      <div class="mb-8">
        <nav class="flex mb-4" aria-label="Breadcrumb">
          <ol role="list" class="flex items-center space-x-4">
            <li>
              <.link navigate={~p"/assets"} class="text-gray-400 hover:text-gray-500">
                <svg class="w-5 h-5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clip-rule="evenodd"></path>
                </svg>
              </.link>
            </li>
            <li>
              <.link navigate={~p"/assets"} class="text-sm font-medium text-gray-500 hover:text-gray-700">
                Assets
              </.link>
            </li>
            <li>
              <div class="flex items-center">
                <svg class="w-5 h-5 flex-shrink-0 text-gray-300" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 111.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
                </svg>
                <span class="ml-4 text-sm font-medium text-gray-500"><%= @asset.name %></span>
              </div>
            </li>
          </ol>
        </nav>

        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <h1 class="text-3xl font-bold text-gray-900"><%= @asset.name %></h1>
            <AssetComponents.status_badge status={@asset.status} />
            <AssetComponents.criticality_badge criticality={@asset.criticality} />
          </div>

          <div class="flex items-center space-x-3">
            <.link
              navigate={~p"/assets/#{@asset.id}/edit"}
              class="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
              </svg>
              Edit
            </.link>

            <button
              phx-click="delete_asset"
              phx-value-id={@asset.id}
              data-confirm="Are you sure you want to delete this asset? This action cannot be undone."
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
            >
              <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
              </svg>
              Delete
            </button>
          </div>
        </div>
      </div>

      <!-- Tabs -->
      <div class="border-b border-gray-200 mb-6">
        <nav class="-mb-px flex space-x-8" aria-label="Tabs">
          <button
            phx-click="change_tab"
            phx-value-tab="overview"
            class={["py-2 px-1 border-b-2 font-medium text-sm",
                   if(@active_tab == "overview",
                      do: "border-blue-500 text-blue-600",
                      else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")]}
          >
            Overview
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="work_orders"
            class={["py-2 px-1 border-b-2 font-medium text-sm",
                   if(@active_tab == "work_orders",
                      do: "border-blue-500 text-blue-600",
                      else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")]}
          >
            Work Orders (<%= length(@work_orders) %>)
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="maintenance"
            class={["py-2 px-1 border-b-2 font-medium text-sm",
                   if(@active_tab == "maintenance",
                      do: "border-blue-500 text-blue-600",
                      else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")]}
          >
            Maintenance History
          </button>
          <button
            phx-click="change_tab"
            phx-value-tab="documents"
            class={["py-2 px-1 border-b-2 font-medium text-sm",
                   if(@active_tab == "documents",
                      do: "border-blue-500 text-blue-600",
                      else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300")]}
          >
            Documents
          </button>
        </nav>
      </div>

      <!-- Tab Content -->
      <div class="mt-6">
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
    """
  end

  defp render_overview_tab(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Asset Details -->
      <div class="lg:col-span-2">
        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900 mb-6">Asset Information</h2>

          <dl class="grid grid-cols-1 gap-x-4 gap-y-6 sm:grid-cols-2">
            <div>
              <dt class="text-sm font-medium text-gray-500">Asset Number</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @asset.asset_number %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Asset Type</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @asset.asset_type.name %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Manufacturer</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @asset.manufacturer || "N/A" %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Model</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @asset.model || "N/A" %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Serial Number</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @asset.serial_number || "N/A" %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Location</dt>
              <dd class="mt-1 text-sm text-gray-900"><%= @asset.location || "N/A" %></dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Purchase Date</dt>
              <dd class="mt-1 text-sm text-gray-900">
                <%= if @asset.purchase_date, do: Calendar.strftime(@asset.purchase_date, "%B %d, %Y"), else: "N/A" %>
              </dd>
            </div>
            <div>
              <dt class="text-sm font-medium text-gray-500">Install Date</dt>
              <dd class="mt-1 text-sm text-gray-900">
                <%= if @asset.install_date, do: Calendar.strftime(@asset.install_date, "%B %d, %Y"), else: "N/A" %>
              </dd>
            </div>
          </dl>

          <%= if @asset.description do %>
            <div class="mt-6 pt-6 border-t border-gray-200">
              <dt class="text-sm font-medium text-gray-500 mb-2">Description</dt>
              <dd class="text-sm text-gray-900"><%= @asset.description %></dd>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Quick Stats -->
      <div class="space-y-6">
        <!-- Status Card -->
        <div class="bg-white shadow rounded-lg p-6">
          <h3 class="text-lg font-medium text-gray-900 mb-4">Quick Stats</h3>
          <div class="space-y-4">
            <div class="flex justify-between">
              <span class="text-sm text-gray-500">Open Work Orders</span>
              <span class="text-sm font-medium text-gray-900">
                <%= Enum.count(@work_orders, &(&1.status in [:pending, :in_progress])) %>
              </span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm text-gray-500">Total Work Orders</span>
              <span class="text-sm font-medium text-gray-900"><%= length(@work_orders) %></span>
            </div>
            <div class="flex justify-between">
              <span class="text-sm text-gray-500">Maintenance Tasks</span>
              <span class="text-sm font-medium text-gray-900"><%= length(@maintenance_history) %></span>
            </div>
          </div>
        </div>

        <!-- Financial Info -->
        <%= if @asset.purchase_cost do %>
          <div class="bg-white shadow rounded-lg p-6">
            <h3 class="text-lg font-medium text-gray-900 mb-4">Financial</h3>
            <div class="space-y-4">
              <div class="flex justify-between">
                <span class="text-sm text-gray-500">Purchase Cost</span>
                <span class="text-sm font-medium text-gray-900">
                  $<%= Decimal.to_string(@asset.purchase_cost, :normal) %>
                </span>
              </div>
              <%= if @asset.warranty_expiry do %>
                <div class="flex justify-between">
                  <span class="text-sm text-gray-500">Warranty Expiry</span>
                  <span class="text-sm font-medium text-gray-900">
                    <%= Calendar.strftime(@asset.warranty_expiry, "%B %d, %Y") %>
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
end
