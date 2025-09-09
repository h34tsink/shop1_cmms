defmodule Shop1CmmsWeb.DashboardLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.{Auth, Tenants}

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
          <h1 class="text-2xl font-bold text-gray-900 mb-6">
            Dashboard
          </h1>

          <!-- Stats overview -->
          <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4 mb-8">
            <%= if authorized?(@socket, :view_work_orders) do %>
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="w-8 h-8 bg-blue-500 rounded-md flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                        </svg>
                      </div>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-medium text-gray-500 truncate">Open Work Orders</dt>
                        <dd class="text-lg font-medium text-gray-900"><%= @stats.open_work_orders || 0 %></dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

            <%= if authorized?(@socket, :view_assets) do %>
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="w-8 h-8 bg-green-500 rounded-md flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                        </svg>
                      </div>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-medium text-gray-500 truncate">Total Assets</dt>
                        <dd class="text-lg font-medium text-gray-900"><%= @stats.total_assets || 0 %></dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

            <%= if authorized?(@socket, :manage_pm_templates) do %>
              <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                  <div class="flex items-center">
                    <div class="flex-shrink-0">
                      <div class="w-8 h-8 bg-yellow-500 rounded-md flex items-center justify-center">
                        <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                      </div>
                    </div>
                    <div class="ml-5 w-0 flex-1">
                      <dl>
                        <dt class="text-sm font-medium text-gray-500 truncate">Due PM Tasks</dt>
                        <dd class="text-lg font-medium text-gray-900"><%= @stats.due_pm_tasks || 0 %></dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>

            <div class="bg-white overflow-hidden shadow rounded-lg">
              <div class="p-5">
                <div class="flex items-center">
                  <div class="flex-shrink-0">
                    <div class="w-8 h-8 bg-purple-500 rounded-md flex items-center justify-center">
                      <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                      </svg>
                    </div>
                  </div>
                  <div class="ml-5 w-0 flex-1">
                    <dl>
                      <dt class="text-sm font-medium text-gray-500 truncate">Active Users</dt>
                      <dd class="text-lg font-medium text-gray-900"><%= @stats.active_users || 0 %></dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Quick actions -->
          <div class="bg-white shadow rounded-lg mb-8">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Quick Actions</h3>
              <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <%= if authorized?(@socket, :create_work_orders) do %>
                  <button class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                    Create Work Order
                  </button>
                <% end %>

                <%= if authorized?(@socket, :add_meter_readings) do %>
                  <button class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                    Add Meter Reading
                  </button>
                <% end %>

                <%= if authorized?(@socket, :manage_assets) do %>
                  <button class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                    Add Asset
                  </button>
                <% end %>

                <%= if authorized?(@socket, :view_reports) do %>
                  <button class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500">
                    View Reports
                  </button>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Recent activity -->
          <div class="bg-white shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h3 class="text-lg leading-6 font-medium text-gray-900 mb-4">Recent Activity</h3>
              <div class="text-sm text-gray-500">
                No recent activity to display.
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

    # Placeholder stats - these would come from actual queries
    stats = %{
      open_work_orders: 0,
      total_assets: 0,
      due_pm_tasks: 0,
      active_users: Tenants.get_tenant_user_count(current_tenant_id)
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
end
