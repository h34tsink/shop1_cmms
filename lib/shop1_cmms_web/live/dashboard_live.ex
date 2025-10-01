defmodule Shop1CmmsWeb.DashboardLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.{Assets, Tenants}

  @impl true
  def render(assigns) do
    ~H"""
    <!-- Desktop Dashboard Layout -->
    <div class="h-full flex flex-col p-3 gap-2 overflow-hidden">
      <!-- Top Row: KPI Panels (Compact) -->
      <div class="flex gap-2 flex-shrink-0" style="min-height: 110px;">
        <%= if @auth.view_work_orders do %>
          <div class="panel flex-1 min-w-0">
            <div class="panel-header">Work Orders</div>
            <div class="panel-body flex items-center justify-between p-3">
              <div class="min-w-0">
                <div class="text-2xl font-bold text-gray-900"><%= @stats.open_work_orders %></div>
                <div class="text-xs text-gray-500 mt-0.5 whitespace-nowrap">Open</div>
              </div>
              <div class="text-right min-w-0 ml-2">
                <div class="text-xs text-red-600 font-medium whitespace-nowrap">0 Overdue</div>
                <div class="text-xxs text-gray-500 mt-0.5 whitespace-nowrap">0 Due Today</div>
              </div>
            </div>
          </div>
        <% end %>
        
        <%= if @auth.view_assets do %>
          <.link href="/assets" class="panel flex-1 min-w-0 hover:shadow-lg transition-shadow cursor-pointer">
            <div class="panel-header">Assets</div>
            <div class="panel-body flex items-center justify-between p-3">
              <div class="min-w-0">
                <div class="text-2xl font-bold text-gray-900"><%= @stats.total_assets %></div>
                <div class="text-xs text-gray-500 mt-0.5 whitespace-nowrap">Total</div>
              </div>
              <div class="text-right min-w-0 ml-2 flex-shrink-0">
                <div class="text-xs text-green-600 font-medium whitespace-nowrap"><%= @stats.operational_assets %> Op.</div>
                <div class="text-xxs text-orange-600 mt-0.5 whitespace-nowrap"><%= @stats.maintenance_assets %> Maint.</div>
              </div>
            </div>
          </.link>
        <% end %>
        
        <%= if @auth.manage_pm_templates do %>
          <div class="panel flex-1 min-w-0">
            <div class="panel-header">PM Compliance</div>
            <div class="panel-body flex items-center justify-between p-3">
              <div class="min-w-0">
                <div class="text-2xl font-bold text-gray-900">--</div>
                <div class="text-xs text-gray-500 mt-0.5 whitespace-nowrap">This Month</div>
              </div>
              <div class="flex items-center min-w-0">
                <div class="text-xs text-gray-500 whitespace-nowrap">Coming Soon</div>
              </div>
            </div>
          </div>
        <% end %>
        
        <div class="panel flex-1 min-w-0 bg-gradient-to-br from-blue-500 to-blue-600 text-white border-blue-600">
          <div class="panel-header bg-blue-600/50 border-blue-700 text-white">System Status</div>
          <div class="panel-body flex items-center justify-between p-3">
            <div class="min-w-0">
              <div class="text-2xl font-bold">100%</div>
              <div class="text-xs opacity-90 mt-0.5 whitespace-nowrap">Uptime</div>
            </div>
            <div class="text-right min-w-0 ml-2 flex-shrink-0">
              <div class="flex items-center justify-end whitespace-nowrap">
                <div class="w-2 h-2 bg-green-400 rounded-full animate-pulse mr-1 flex-shrink-0"></div>
                <span class="text-xs font-medium">Online</span>
              </div>
              <div class="text-xxs opacity-90 mt-0.5 whitespace-nowrap"><%= @stats.active_users %> Users</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Middle Row: Split View (Flexible height) -->
      <div class="flex-1 flex gap-2 min-h-0 overflow-hidden">
        <!-- Left Panel: Asset Status Breakdown (40%) -->
        <%= if @auth.view_assets and @stats.total_assets > 0 do %>
          <div class="panel flex flex-col min-w-0" style="width: 40%;">
            <div class="panel-header flex items-center justify-between flex-shrink-0">
              <span>Asset Overview</span>
              <.link href="/assets" class="text-blue-600 hover:text-blue-700 text-xs font-medium whitespace-nowrap">View All →</.link>
            </div>
            <div class="flex-1 overflow-auto p-3">
              <!-- Status Breakdown -->
              <div class="mb-4">
                <h4 class="text-xs font-semibold text-gray-700 uppercase mb-2">By Status</h4>
                <div class="space-y-2">
                  <%= for {status, count} <- @stats.by_status do %>
                    <div class="flex items-center justify-between p-2 bg-gray-50 rounded hover:bg-gray-100 transition-colors">
                      <div class="flex items-center min-w-0 flex-1">
                        <div class={"w-2 h-2 rounded-full mr-2 flex-shrink-0 #{status_color(status)}"}>
                        </div>
                        <span class="text-xs font-medium text-gray-700 capitalize truncate">
                          <%= String.replace(to_string(status), "_", " ") %>
                        </span>
                      </div>
                      <div class="flex items-center flex-shrink-0 ml-2">
                        <span class="text-sm font-bold text-gray-900 mr-2"><%= count %></span>
                        <span class="text-xs text-gray-500 whitespace-nowrap">
                          (<%= Float.round(count / @stats.total_assets * 100, 1) %>%)
                        </span>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
              
              <!-- Criticality Breakdown -->
              <div>
                <h4 class="text-xs font-semibold text-gray-700 uppercase mb-2">By Criticality</h4>
                <div class="space-y-2">
                  <%= for {criticality, count} <- @stats.by_criticality do %>
                    <div class="flex items-center justify-between p-2 bg-gray-50 rounded hover:bg-gray-100 transition-colors">
                      <div class="flex items-center min-w-0 flex-1">
                        <div class={"w-2 h-2 rounded-full mr-2 flex-shrink-0 #{criticality_color(criticality)}"}>
                        </div>
                        <span class="text-xs font-medium text-gray-700 capitalize truncate">
                          <%= String.replace(to_string(criticality), "_", " ") %>
                        </span>
                      </div>
                      <div class="flex items-center flex-shrink-0 ml-2">
                        <span class="text-sm font-bold text-gray-900 mr-2"><%= count %></span>
                        <span class="text-xs text-gray-500 whitespace-nowrap">
                          (<%= Float.round(count / @stats.total_assets * 100, 1) %>%)
                        </span>
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <!-- Right Panel: Recent Activity (60%) -->
        <div class="panel flex-1 flex flex-col min-w-0">
          <div class="panel-header flex items-center justify-between flex-shrink-0">
            <span>Recent Activity</span>
            <span class="text-xs text-gray-500">Last 24 hours</span>
          </div>
          <div class="flex-1 overflow-auto">
            <div class="p-3 space-y-3">
              <!-- Activity Item -->
              <div class="flex items-start space-x-3 p-3 bg-blue-50 rounded border border-blue-100">
                <div class="flex-shrink-0">
                  <div class="w-8 h-8 bg-blue-500 rounded flex items-center justify-center">
                    <svg class="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z"></path>
                    </svg>
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium text-gray-900">Dashboard loaded successfully</p>
                  <p class="text-xs text-gray-600 mt-0.5">System initialized with <%= @stats.total_assets %> assets</p>
                  <div class="flex items-center mt-1 space-x-2">
                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                      System
                    </span>
                    <span class="text-xs text-gray-400">Just now</span>
                  </div>
                </div>
              </div>

              <%= if @stats.total_assets > 0 do %>
                <div class="flex items-start space-x-3 p-3 bg-green-50 rounded border border-green-100">
                  <div class="flex-shrink-0">
                    <div class="w-8 h-8 bg-green-500 rounded flex items-center justify-center">
                      <svg class="w-4 h-4 text-white" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
                      </svg>
                    </div>
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900">Asset database ready</p>
                    <p class="text-xs text-gray-600 mt-0.5"><%= @stats.operational_assets %> assets operational, <%= @stats.maintenance_assets %> need attention</p>
                    <div class="flex items-center mt-1 space-x-2">
                      <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                        Assets
                      </span>
                      <span class="text-xs text-gray-400">Today</span>
                    </div>
                  </div>
                </div>
              <% else %>
                <!-- Empty State -->
                <div class="text-center py-12">
                  <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-3">
                    <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                  </div>
                  <h3 class="text-sm font-semibold text-gray-900">No recent activity</h3>
                  <p class="mt-1 text-xs text-gray-500 max-w-md mx-auto">
                    Get started by adding your first asset to see activity here.
                  </p>
                  <div class="mt-4">
                    <.link href="/assets/new" class="btn-toolbar-primary">
                      <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                        <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"></path>
                      </svg>
                      <span>Add First Asset</span>
                    </.link>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- Bottom Row: Quick Actions -->
      <div class="panel flex-shrink-0" style="min-height: 70px;">
        <div class="panel-header">Quick Actions</div>
        <div class="panel-body p-2">
          <div class="flex items-center space-x-2">
            <%= if @auth.create_work_orders do %>
              <button class="btn-toolbar-primary flex-1 whitespace-nowrap overflow-hidden">
                <svg class="w-3 h-3 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"></path>
                  <path fill-rule="evenodd" d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3z" clip-rule="evenodd"></path>
                </svg>
                <span class="truncate">Create WO</span>
              </button>
            <% end %>
            
            <%= if @auth.manage_assets do %>
              <.link href="/assets/new" class="btn-toolbar flex-1 whitespace-nowrap overflow-hidden">
                <svg class="w-3 h-3 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"></path>
                </svg>
                <span class="truncate">Add Asset</span>
              </.link>
            <% end %>
            
            <%= if @auth.view_assets do %>
              <.link href="/assets" class="btn-toolbar flex-1 whitespace-nowrap overflow-hidden">
                <svg class="w-3 h-3 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clip-rule="evenodd"></path>
                </svg>
                <span class="truncate">View All</span>
              </.link>
            <% end %>
            
            <%= if @auth.view_reports do %>
              <button class="btn-toolbar flex-1 whitespace-nowrap overflow-hidden">
                <svg class="w-3 h-3 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z"></path>
                </svg>
                <span class="truncate">Reports</span>
              </button>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_tenant_id = socket.assigns.current_tenant_id

    # Get real asset statistics
    asset_stats = Assets.get_asset_stats(current_tenant_id)

    # Comprehensive stats for dashboard
    stats = %{
      open_work_orders: 0, # TODO: Implement work orders module
      total_assets: asset_stats.total_assets,
      operational_assets: asset_stats.operational,
      maintenance_assets: asset_stats.needs_maintenance,
      due_pm_tasks: 0, # TODO: Implement PM module
      active_users: Tenants.get_tenant_user_count(current_tenant_id),
      by_criticality: asset_stats.by_criticality,
      by_status: asset_stats.by_status
    }

    {:ok, assign(socket, :stats, stats)}
  end

  @impl true
  def handle_event("show_preferences", _params, socket) do
    # TODO: Implement preferences modal
    {:noreply, put_flash(socket, :info, "Preferences coming soon!")}
  end

  # Helper functions for asset status colors
  defp status_color(:operational), do: "bg-green-500"
  defp status_color(:needs_maintenance), do: "bg-orange-500"
  defp status_color(:out_of_service), do: "bg-red-500"
  defp status_color(:retired), do: "bg-gray-500"
  defp status_color(_), do: "bg-gray-400"

  # Helper functions for asset criticality colors
  defp criticality_color(:critical), do: "bg-red-500"
  defp criticality_color(:high), do: "bg-orange-500"
  defp criticality_color(:medium), do: "bg-yellow-500"
  defp criticality_color(:low), do: "bg-green-500"
  defp criticality_color(_), do: "bg-gray-400"
end