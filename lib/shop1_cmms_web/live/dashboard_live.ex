defmodule Shop1CmmsWeb.DashboardLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.{Auth, Tenants, Assets}

  on_mount {Shop1CmmsWeb.UserAuth, :ensure_authenticated}
  on_mount {Shop1CmmsWeb.UserAuth, :ensure_tenant_access}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50">
      <!-- Navigation -->
      <nav class="bg-white shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex">
              <div class="flex-shrink-0 flex items-center">
                <img class="h-8 w-auto" src="/images/logo.svg" alt="Shop1 CMMS" />
                <span class="ml-2 text-xl font-semibold text-gray-900">CMMS</span>
              </div>
              
              <div class="hidden sm:ml-6 sm:flex sm:space-x-8">
                <%= if authorized?(@socket, :view_work_orders) do %>
                  <.nav_link href="/work-orders" class="text-gray-900 hover:text-gray-700">
                    Work Orders
                  </.nav_link>
                <% end %>
                
                <%= if authorized?(@socket, :view_assets) do %>
                  <.nav_link href="/assets" class="text-gray-500 hover:text-gray-700">
                    Assets
                  </.nav_link>
                <% end %>
                
                <%= if authorized?(@socket, :manage_pm_templates) do %>
                  <.nav_link href="/preventive-maintenance" class="text-gray-500 hover:text-gray-700">
                    PM Schedules
                  </.nav_link>
                <% end %>
                
                <%= if authorized?(@socket, :view_reports) do %>
                  <.nav_link href="/reports" class="text-gray-500 hover:text-gray-700">
                    Reports
                  </.nav_link>
                <% end %>
                
                <%= if authorized?(@socket, :manage_users) do %>
                  <.nav_link href="/admin" class="text-gray-500 hover:text-gray-700">
                    Admin
                  </.nav_link>
                <% end %>
              </div>
            </div>

            <div class="flex items-center space-x-4">
              <!-- Tenant info -->
              <div class="text-sm text-gray-600">
                <span class="font-medium"><%= @current_tenant.name %></span>
                <%= if @user_role do %>
                  <span class="text-gray-400">·</span>
                  <span class="capitalize"><%= String.replace(@user_role, "_", " ") %></span>
                <% end %>
              </div>

              <!-- User menu -->
              <div class="relative" x-data="{ open: false }">
                <button @click="open = !open" class="flex items-center text-sm rounded-full focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                  <span class="sr-only">Open user menu</span>
                  <div class="h-8 w-8 rounded-full bg-blue-600 flex items-center justify-center">
                    <span class="text-sm font-medium text-white">
                      <%= String.first(@current_user.username) |> String.upcase() %>
                    </span>
                  </div>
                </button>

                <div x-show="open" @click.away="open = false" 
                     class="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-50">
                  <div class="py-1">
                    <div class="px-4 py-2 text-sm text-gray-700 border-b">
                      Signed in as <strong><%= @current_user.username %></strong>
                    </div>
                    
                    <%= if length(@user_tenants) > 1 do %>
                      <a href="/select-tenant" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                        Switch Tenant
                      </a>
                    <% end %>
                    
                    <a href="#" phx-click="show_preferences" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                      Preferences
                    </a>
                    
                    <a href="/auth/logout" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
                      Sign out
                    </a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </nav>

      <!-- Main content -->
      <main class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="px-4 py-6 sm:px-0">
          <!-- Dashboard Header -->
          <div class="mb-8">
            <div class="md:flex md:items-center md:justify-between">
              <div class="flex-1 min-w-0">
                <h1 class="text-3xl font-bold text-gray-900">
                  Welcome back, <%= String.split(@current_user.username, "@") |> List.first() |> String.capitalize() %>
                </h1>
                <p class="mt-1 text-sm text-gray-500">
                  <%= @current_tenant.name %> • <%= Date.utc_today() |> Calendar.strftime("%B %d, %Y") %>
                </p>
              </div>
              <div class="mt-4 md:mt-0 md:ml-4">
                <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                  <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 8 8">
                    <circle cx="4" cy="4" r="3"/>
                  </svg>
                  System Online
                </span>
              </div>
            </div>
          </div>

          <!-- Enhanced Stats overview -->
          <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4 mb-8">
            <%= if authorized?(@socket, :view_work_orders) do %>
              <div class="bg-white overflow-hidden shadow-lg rounded-xl border border-gray-100">
                <div class="p-6">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="w-12 h-12 bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-lg">
                        <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                        </svg>
                      </div>
                    </div>
                    <div class="ml-6 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-semibold text-gray-500 truncate">Open Work Orders</dt>
                        <dd class="flex items-baseline">
                          <div class="text-2xl font-bold text-gray-900"><%= @stats.open_work_orders || 0 %></div>
                          <div class="ml-2 text-sm text-gray-500">pending</div>
                        </dd>
                      </dl>
                    </div>
                  </div>
                  <div class="mt-4">
                    <div class="flex items-center text-sm">
                      <span class="text-gray-500">Priority tasks in queue</span>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

            <%= if authorized?(@socket, :view_assets) do %>
              <div class="bg-white overflow-hidden shadow-lg rounded-xl border border-gray-100">
                <div class="p-6">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="w-12 h-12 bg-gradient-to-r from-green-500 to-green-600 rounded-xl flex items-center justify-center shadow-lg">
                        <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                        </svg>
                      </div>
                    </div>
                    <div class="ml-6 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-semibold text-gray-500 truncate">Total Assets</dt>
                        <dd class="flex items-baseline">
                          <div class="text-2xl font-bold text-gray-900"><%= @stats.total_assets || 0 %></div>
                          <div class="ml-2 text-sm text-gray-500">managed</div>
                        </dd>
                      </dl>
                    </div>
                  </div>
                  <div class="mt-4">
                    <div class="flex items-center justify-between text-sm">
                      <span class="text-green-600 font-medium"><%= @stats.operational_assets || 0 %> operational</span>
                      <span class="text-orange-600 font-medium"><%= @stats.maintenance_assets || 0 %> need maintenance</span>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

            <%= if authorized?(@socket, :manage_pm_templates) do %>
              <div class="bg-white overflow-hidden shadow-lg rounded-xl border border-gray-100">
                <div class="p-6">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="w-12 h-12 bg-gradient-to-r from-yellow-500 to-orange-500 rounded-xl flex items-center justify-center shadow-lg">
                        <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                      </div>
                    </div>
                    <div class="ml-6 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-semibold text-gray-500 truncate">Due PM Tasks</dt>
                        <dd class="flex items-baseline">
                          <div class="text-2xl font-bold text-gray-900"><%= @stats.due_pm_tasks || 0 %></div>
                          <div class="ml-2 text-sm text-gray-500">overdue</div>
                        </dd>
                      </dl>
                    </div>
                  </div>
                  <div class="mt-4">
                    <div class="flex items-center text-sm">
                      <span class="text-gray-500">Preventive maintenance schedule</span>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

            <div class="bg-white overflow-hidden shadow-lg rounded-xl border border-gray-100">
              <div class="p-6">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <div class="w-12 h-12 bg-gradient-to-r from-purple-500 to-indigo-500 rounded-xl flex items-center justify-center shadow-lg">
                      <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                      </svg>
                    </div>
                  </div>
                  <div class="ml-6 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-semibold text-gray-500 truncate">Active Users</dt>
                      <dd class="flex items-baseline">
                        <div class="text-2xl font-bold text-gray-900"><%= @stats.active_users || 0 %></div>
                        <div class="ml-2 text-sm text-gray-500">team members</div>
                      </dd>
                    </dl>
                  </div>
                </div>
                <div class="mt-4">
                  <div class="flex items-center text-sm">
                    <span class="text-gray-500">Tenant access enabled</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Asset Breakdown Charts -->
          <%= if authorized?(@socket, :view_assets) and @stats.total_assets > 0 do %>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
              <!-- Asset Status Breakdown -->
              <div class="bg-white overflow-hidden shadow-lg rounded-xl border border-gray-100">
                <div class="p-6">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Asset Status</h3>
                  <div class="space-y-4">
                    <%= for {status, count} <- @stats.by_status do %>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center">
                          <div class={"w-3 h-3 rounded-full mr-3 #{status_color(status)}"}>
                          </div>
                          <span class="text-sm font-medium text-gray-700 capitalize">
                            <%= String.replace(to_string(status), "_", " ") %>
                          </span>
                        </div>
                        <div class="flex items-center">
                          <span class="text-sm font-bold text-gray-900 mr-2"><%= count %></span>
                          <span class="text-xs text-gray-500">
                            (<%= Float.round(count / @stats.total_assets * 100, 1) %>%)
                          </span>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>

              <!-- Asset Criticality Breakdown -->
              <div class="bg-white overflow-hidden shadow-lg rounded-xl border border-gray-100">
                <div class="p-6">
                  <h3 class="text-lg font-semibold text-gray-900 mb-4">Asset Criticality</h3>
                  <div class="space-y-4">
                    <%= for {criticality, count} <- @stats.by_criticality do %>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center">
                          <div class={"w-3 h-3 rounded-full mr-3 #{criticality_color(criticality)}"}>
                          </div>
                          <span class="text-sm font-medium text-gray-700 capitalize">
                            <%= String.replace(to_string(criticality), "_", " ") %>
                          </span>
                        </div>
                        <div class="flex items-center">
                          <span class="text-sm font-bold text-gray-900 mr-2"><%= count %></span>
                          <span class="text-xs text-gray-500">
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

          <!-- Enhanced Quick actions -->
          <div class="bg-white shadow-lg rounded-xl border border-gray-100 mb-8">
            <div class="px-6 py-6 sm:p-8">
              <div class="flex items-center justify-between mb-6">
                <h3 class="text-xl font-semibold text-gray-900">Quick Actions</h3>
                <span class="text-sm text-gray-500">Get things done quickly</span>
              </div>
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <%= if authorized?(@socket, :create_work_orders) do %>
                  <button class="group relative inline-flex items-center justify-center px-6 py-4 border border-transparent text-sm font-semibold rounded-lg shadow-lg text-white bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 transform hover:scale-105">
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                    </svg>
                    Create Work Order
                  </button>
                <% end %>

                <%= if authorized?(@socket, :add_meter_readings) do %>
                  <button class="group relative inline-flex items-center justify-center px-6 py-4 border border-gray-200 text-sm font-semibold rounded-lg text-gray-700 bg-white hover:bg-gray-50 hover:border-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 transform hover:scale-105 shadow-md">
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                    </svg>
                    Add Meter Reading
                  </button>
                <% end %>

                <%= if authorized?(@socket, :manage_assets) do %>
                  <button class="group relative inline-flex items-center justify-center px-6 py-4 border border-gray-200 text-sm font-semibold rounded-lg text-gray-700 bg-white hover:bg-gray-50 hover:border-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 transform hover:scale-105 shadow-md">
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                    </svg>
                    Add Asset
                  </button>
                <% end %>

                <%= if authorized?(@socket, :view_reports) do %>
                  <button class="group relative inline-flex items-center justify-center px-6 py-4 border border-gray-200 text-sm font-semibold rounded-lg text-gray-700 bg-white hover:bg-gray-50 hover:border-gray-300 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 transform hover:scale-105 shadow-md">
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                    </svg>
                    View Reports
                  </button>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Enhanced Recent activity and system status -->
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Recent Activity -->
            <div class="lg:col-span-2 bg-white shadow-lg rounded-xl border border-gray-100">
              <div class="px-6 py-6 sm:p-8">
                <h3 class="text-xl font-semibold text-gray-900 mb-6">Recent Activity</h3>
                <div class="space-y-4">
                  <!-- Placeholder activity items -->
                  <div class="flex items-start space-x-4 p-4 bg-gray-50 rounded-lg">
                    <div class="flex-shrink-0">
                      <div class="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                        <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
                        </svg>
                      </div>
                    </div>
                    <div class="flex-1">
                      <p class="text-sm font-medium text-gray-900">System initialized</p>
                      <p class="text-sm text-gray-500">CMMS dashboard loaded successfully</p>
                      <p class="text-xs text-gray-400 mt-1">Just now</p>
                    </div>
                  </div>

                  <div class="flex items-start space-x-4 p-4 bg-green-50 rounded-lg">
                    <div class="flex-shrink-0">
                      <div class="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                        <svg class="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                      </div>
                    </div>
                    <div class="flex-1">
                      <p class="text-sm font-medium text-gray-900">Asset database ready</p>
                      <p class="text-sm text-gray-500"><%= @stats.total_assets %> assets loaded and available</p>
                      <p class="text-xs text-gray-400 mt-1">Today</p>
                    </div>
                  </div>

                  <%= if @stats.total_assets == 0 do %>
                    <div class="text-center py-8">
                      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                      </svg>
                      <h3 class="mt-2 text-sm font-medium text-gray-900">No recent activity</h3>
                      <p class="mt-1 text-sm text-gray-500">Get started by adding your first asset or creating a work order.</p>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>

            <!-- System Status -->
            <div class="bg-white shadow-lg rounded-xl border border-gray-100">
              <div class="px-6 py-6 sm:p-8">
                <h3 class="text-xl font-semibold text-gray-900 mb-6">System Status</h3>
                <div class="space-y-4">
                  <div class="flex items-center justify-between">
                    <span class="text-sm font-medium text-gray-700">Database</span>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Online
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm font-medium text-gray-700">Assets Module</span>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Active
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm font-medium text-gray-700">Work Orders</span>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                      Pending
                    </span>
                  </div>
                  <div class="flex items-center justify-between">
                    <span class="text-sm font-medium text-gray-700">PM Schedules</span>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                      Pending
                    </span>
                  </div>
                  
                  <div class="pt-4 mt-6 border-t border-gray-200">
                    <p class="text-xs text-gray-500 text-center">
                      Last updated: <%= Time.utc_now() |> Time.truncate(:second) |> Time.to_string() %> UTC
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    current_tenant_id = socket.assigns.current_tenant_id

    # Get tenant information
    current_tenant = Tenants.get_tenant!(current_tenant_id)
    user_tenants = Auth.get_user_tenant_options(current_user)
    user_role = Auth.get_user_role(current_user, current_tenant_id)

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

    {:ok,
     socket
     |> assign(:current_tenant, current_tenant)
     |> assign(:user_tenants, user_tenants)
     |> assign(:user_role, user_role)
     |> assign(:stats, stats)}
  end

  @impl true
  def handle_event("show_preferences", _params, socket) do
    # TODO: Implement preferences modal
    {:noreply, put_flash(socket, :info, "Preferences coming soon!")}
  end

  # Helper function to check authorization
  defp authorized?(socket, action) do
    Shop1CmmsWeb.UserAuth.authorized?(socket, action)
  end

  # Navigation link component
  defp nav_link(assigns) do
    ~H"""
    <a href={@href} class={@class}>
      <%= render_slot(@inner_block) %>
    </a>
    """
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
