defmodule Shop1CmmsWeb.Components.Assets do
  use Shop1CmmsWeb, :html

  @doc """
  Renders an asset card for grid/kanban views
  """
  attr :asset, :map, required: true
  attr :view_mode, :string, default: "grid"
  attr :class, :string, default: ""

  def asset_card(assigns) do
    ~H"""
    <div class={["bg-white rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow group", @class]}>
      <!-- Asset Header -->
      <.link navigate={~p"/assets/#{@asset.id}"} class="block">
        <div class="p-4 border-b border-gray-100">
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <h3 class="font-semibold text-gray-900 text-sm leading-tight group-hover:text-blue-600">
                <%= @asset.name %>
              </h3>
              <p class="text-xs text-gray-600 mt-1">
                <%= @asset.asset_number %>
              </p>
            </div>
            <div class="flex flex-col space-y-1 ml-2">
              <.status_badge status={@asset.status} />
              <.criticality_badge criticality={@asset.criticality} />
            </div>
          </div>
        </div>

        <!-- Asset Details -->
        <div class="p-4 space-y-3">
          <!-- Manufacturer & Model -->
          <div class="space-y-1">
            <p class="text-xs text-gray-500">Manufacturer</p>
            <p class="text-sm font-medium text-gray-900">
              <%= @asset.manufacturer || "-" %>
            </p>
          </div>

          <div class="space-y-1">
            <p class="text-xs text-gray-500">Model</p>
            <p class="text-sm text-gray-700">
              <%= @asset.model || "-" %>
            </p>
          </div>

          <!-- Purchase Info -->
          <%= if @asset.purchase_cost do %>
            <div class="space-y-1">
              <p class="text-xs text-gray-500">Purchase Cost</p>
              <p class="text-sm font-medium text-green-600">
                $<%= Decimal.to_string(@asset.purchase_cost, :normal) %>
              </p>
            </div>
          <% end %>

          <!-- Dates -->
          <%= if @asset.install_date do %>
            <div class="space-y-1">
              <p class="text-xs text-gray-500">Install Date</p>
              <p class="text-sm text-gray-700">
                <%= Calendar.strftime(@asset.install_date, "%B %d, %Y") %>
              </p>
            </div>
          <% end %>
        </div>
      </.link>

      <!-- Actions -->
      <div class="px-4 py-3 border-t border-gray-100 bg-gray-50 rounded-b-lg">
        <div class="flex justify-between items-center">
          <.link navigate={~p"/assets/#{@asset.id}"} class="text-sm text-blue-600 hover:text-blue-800 font-medium">
            View Details
          </.link>
          <div class="flex space-x-2">
            <.link
              navigate={~p"/assets/#{@asset.id}/edit"}
              class="inline-flex items-center p-2 text-gray-400 hover:text-blue-600 rounded-full hover:bg-blue-50"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path>
              </svg>
            </.link>
            <button
              phx-click="delete_asset"
              phx-value-id={@asset.id}
              data-confirm="Are you sure you want to delete this asset?"
              class="inline-flex items-center p-2 text-gray-400 hover:text-red-600 rounded-full hover:bg-red-50"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders an asset row for list view
  """
  attr :asset, :map, required: true

  def asset_row(assigns) do
    ~H"""
    <tr class="hover:bg-gray-50">
      <td class="px-6 py-4 whitespace-nowrap">
        <div class="flex items-center">
          <div class="flex-shrink-0 h-10 w-10">
            <div class="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
              <svg class="h-6 w-6 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"/>
              </svg>
            </div>
          </div>
          <div class="ml-4">
            <.link navigate={~p"/assets/#{@asset.id}"} class="text-sm font-medium text-blue-600 hover:text-blue-800">
              <%= @asset.name %>
            </.link>
            <div class="text-sm text-gray-500"><%= @asset.asset_number %></div>
          </div>
        </div>
      </td>
      <td class="px-6 py-4 whitespace-nowrap">
        <div class="text-sm text-gray-900"><%= @asset.manufacturer || "-" %></div>
        <div class="text-sm text-gray-500"><%= @asset.model || "-" %></div>
      </td>
      <td class="px-6 py-4 whitespace-nowrap">
        <.status_badge status={@asset.status} />
      </td>
      <td class="px-6 py-4 whitespace-nowrap">
        <.criticality_badge criticality={@asset.criticality} />
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
        <%= if @asset.purchase_cost do %>
          $<%= Decimal.to_string(@asset.purchase_cost, :normal) %>
        <% else %>
          -
        <% end %>
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
        <%= if @asset.install_date, do: Calendar.strftime(@asset.install_date, "%B %d, %Y"), else: "-" %>
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
        <div class="flex justify-end space-x-2">
          <.link navigate={~p"/assets/#{@asset.id}/edit"} class="text-blue-600 hover:text-blue-900">
            Edit
          </.link>
          <button
            phx-click="delete_asset"
            phx-value-id={@asset.id}
            data-confirm="Are you sure you want to delete this asset?"
            class="text-red-600 hover:text-red-900"
          >
            Delete
          </button>
        </div>
      </td>
    </tr>
    """
  end

  @doc """
  Renders a status badge
  """
  attr :status, :atom, required: true

  def status_badge(assigns) do
    ~H"""
    <span class={["px-2 py-1 text-xs font-medium rounded-full", status_color(@status)]}>
      <%= String.capitalize(to_string(@status)) %>
    </span>
    """
  end

  @doc """
  Renders a criticality badge
  """
  attr :criticality, :atom, required: true

  def criticality_badge(assigns) do
    ~H"""
    <span class={["px-2 py-1 text-xs font-medium rounded-full", criticality_color(@criticality)]}>
      <%= String.capitalize(to_string(@criticality)) %>
    </span>
    """
  end

  @doc """
  Renders an icon button
  """
  attr :icon, :string, required: true
  attr :color, :string, default: "gray"

  def icon_button(assigns) do
    ~H"""
    <button class={["p-2 rounded hover:text-#{@color}-600", "text-#{@color}-400"]}>
      <%= case @icon do %>
        <% "edit" -> %>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
          </svg>
        <% "delete" -> %>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
          </svg>
        <% _ -> %>
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"/>
          </svg>
      <% end %>
    </button>
    """
  end

  @doc """
  Renders view mode toggle buttons
  """
  attr :current_view, :string, required: true
  attr :target, :any, default: nil

  def view_toggle(assigns) do
    ~H"""
    <div class="flex items-center border border-gray-200 rounded-lg overflow-hidden">
      <button
        phx-click="change_view"
        phx-value-view="grid"
        phx-target={@target}
        class={[
          "px-3 py-2 text-sm font-medium transition-colors",
          if(@current_view == "grid", do: "bg-blue-100 text-blue-700", else: "text-gray-500 hover:text-gray-700")
        ]}
        title="Grid View"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/>
        </svg>
      </button>

      <button
        phx-click="change_view"
        phx-value-view="list"
        phx-target={@target}
        class={[
          "px-3 py-2 text-sm font-medium transition-colors border-l border-gray-200",
          if(@current_view == "list", do: "bg-blue-100 text-blue-700", else: "text-gray-500 hover:text-gray-700")
        ]}
        title="List View"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 10h16M4 14h16M4 18h16"/>
        </svg>
      </button>

      <button
        phx-click="change_view"
        phx-value-view="kanban"
        phx-target={@target}
        class={[
          "px-3 py-2 text-sm font-medium transition-colors border-l border-gray-200",
          if(@current_view == "kanban", do: "bg-blue-100 text-blue-700", else: "text-gray-500 hover:text-gray-700")
        ]}
        title="Kanban View"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"/>
        </svg>
      </button>
    </div>
    """
  end

  # Helper functions
  defp status_color(status) do
    case status do
      :operational -> "bg-green-100 text-green-800"
      :maintenance -> "bg-yellow-100 text-yellow-800"
      :repair -> "bg-red-100 text-red-800"
      :retired -> "bg-gray-100 text-gray-800"
      :pending -> "bg-blue-100 text-blue-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp criticality_color(criticality) do
    case criticality do
      :high -> "bg-red-100 text-red-800"
      :medium -> "bg-yellow-100 text-yellow-800"
      :low -> "bg-green-100 text-green-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end

  defp format_currency(nil), do: "-"
  defp format_currency(amount) do
    Number.Currency.number_to_currency(amount)
  rescue
    _ -> "$#{amount}"
  end
end
