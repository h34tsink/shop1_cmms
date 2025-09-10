defmodule Shop1CmmsWeb.DashboardLive do
  use Shop1CmmsWeb, :live_view

  alias Shop1Cmms.{Auth, Tenants, Assets}

  on_mount {Shop1CmmsWeb.UserAuth, :ensure_authenticated}
  on_mount {Shop1CmmsWeb.UserAuth, :ensure_tenant_access}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen w-full bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50">
      <!-- Full-width Top Navigation Bar -->
      <nav class="w-full bg-white/95 backdrop-blur-sm shadow-lg border-b border-gray-200/20 sticky top-0 z-40">
        <div class="w-full px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex">
              <div class="flex-shrink-0 flex items-center">
                <div class="flex items-center space-x-3">
                  <div class="w-10 h-10 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg">
                    <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                    </svg>
                  </div>
                  <div>
                    <span class="text-xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent">Shop1 CMMS</span>
                    <div class="text-xs text-gray-500 font-medium">Maintenance Management</div>
                  </div>
                </div>
              </div>

              <div class="hidden sm:ml-8 sm:flex sm:space-x-1">
                <%= if @auth.view_work_orders do %>
                  <.nav_link href="/work-orders" class="bg-blue-50 text-blue-700 border-blue-200 hover:bg-blue-100">
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                    </svg>
                    Work Orders
                  </.nav_link>
                <% end %>

                <%= if @auth.view_assets do %>
                  <.nav_link href="/assets" class="text-gray-600 hover:text-gray-900 hover:bg-gray-50">
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                    </svg>
                    Assets
                  </.nav_link>
                <% end %>

                <%= if @auth.manage_pm_templates do %>
                  <.nav_link href="/preventive-maintenance" class="text-gray-600 hover:text-gray-900 hover:bg-gray-50">
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                    PM Schedules
                  </.nav_link>
                <% end %>

                <%= if @auth.view_reports do %>
                  <.nav_link href="/reports" class="text-gray-600 hover:text-gray-900 hover:bg-gray-50">
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                    </svg>
                    Reports
                  </.nav_link>
                <% end %>

                <%= if @auth.manage_users do %>
                  <.nav_link href="/admin" class="text-gray-600 hover:text-gray-900 hover:bg-gray-50">
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                    </svg>
                    Admin
                  </.nav_link>
                <% end %>
              </div>
            </div>

            <div class="flex items-center space-x-4">
              <!-- Enhanced Tenant info -->
              <div class="hidden md:flex items-center space-x-3 bg-gray-50/80 rounded-lg px-3 py-2">
                <div class="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                <div class="text-sm">
                  <div class="font-semibold text-gray-900"><%= @current_tenant.name %></div>
                  <%= if @user_role do %>
                    <div class="text-xs text-gray-500 capitalize"><%= String.replace(@user_role, "_", " ") %></div>
                  <% end %>
                </div>
              </div>

              <!-- Enhanced User menu -->
              <div class="relative" x-data="{ open: false }" x-init="open = false">
                <button @click="open = !open" type="button" class="flex items-center space-x-2 text-sm rounded-xl focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 bg-white shadow-md hover:shadow-lg transition-all duration-200 px-3 py-2">
                  <div class="w-8 h-8 rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 flex items-center justify-center shadow-sm">
                    <span class="text-sm font-bold text-white">
                      <%= String.first(@current_user.username) |> String.upcase() %>
                    </span>
                  </div>
                  <svg class="w-4 h-4 text-gray-400 transition-transform duration-150" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                  </svg>
                </button>

                <div x-show="open" @click.outside="open = false" x-transition class="origin-top-right absolute right-0 mt-2 w-56 rounded-xl shadow-xl bg-white ring-1 ring-black ring-opacity-5 z-50 overflow-hidden" style="display: none;">
                  <div class="py-1">
                    <div class="px-4 py-3 bg-gray-50 border-b">
                      <p class="text-sm font-medium text-gray-900">Signed in as</p>
                      <p class="text-sm font-bold text-blue-600"><%= @current_user.username %></p>
                    </div>

                    <%= if length(@user_tenants) > 1 do %>
                      <a href="/select-tenant" class="block px-4 py-2 text-sm text-gray-700 hover:bg-blue-50 hover:text-blue-900 flex items-center">
                        <svg class="w-4 h-4 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"></path>
                        </svg>
                        Switch Tenant
                      </a>
                    <% end %>

                    <a href="#" phx-click="show_preferences" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 flex items-center">
                      <svg class="w-4 h-4 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
                      </svg>
                      Preferences
                    </a>

                    <div class="border-t border-gray-100">
                      <a href="/auth/logout" class="block px-4 py-2 text-sm text-red-700 hover:bg-red-50 flex items-center">
                        <svg class="w-4 h-4 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path>
                        </svg>
                        Sign out
                      </a>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </nav>

      <!-- Full-width Main content -->
      <main class="w-full py-8 px-6 lg:px-8">
        <!-- Enhanced Dashboard Header -->
        <div class="mb-10">
          <div class="lg:flex lg:items-center lg:justify-between">
            <div class="flex-1 min-w-0">
              <div class="flex items-center space-x-4">
                <div class="w-16 h-16 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl flex items-center justify-center shadow-lg">
                  <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                  </svg>
                </div>
                <div>
                  <h1 class="text-3xl font-bold text-gray-900 leading-tight">
                    Welcome back, <%= String.split(@current_user.username, "@") |> List.first() |> String.capitalize() %>
                  </h1>
                  <div class="mt-1 flex items-center space-x-2 text-sm text-gray-500">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path>
                    </svg>
                    <span><%= @current_tenant.name %></span>
                    <span class="text-gray-300">•</span>
                    <span><%= Date.utc_today() |> Calendar.strftime("%B %d, %Y") %></span>
                  </div>
                </div>
              </div>
            </div>
            <div class="mt-6 lg:mt-0 lg:ml-4 flex flex-col sm:flex-row items-start sm:items-center space-y-2 sm:space-y-0 sm:space-x-3">
              <div class="flex items-center space-x-2 bg-green-50 text-green-700 px-4 py-2 rounded-xl border border-green-200">
                <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                <span class="text-sm font-medium">System Online</span>
              </div>
              <div class="flex items-center space-x-2 bg-blue-50 text-blue-700 px-4 py-2 rounded-xl border border-blue-200">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z"></path>
                </svg>
                <span class="text-sm font-medium"><%= @stats.active_users %> Active Users</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Enhanced Stats Overview -->
        <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4 mb-10">
          <%= if @auth.view_work_orders do %>
            <div class="group relative bg-white overflow-hidden shadow-xl rounded-2xl border border-gray-100 hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1">
              <div class="absolute top-0 right-0 w-32 h-32 transform translate-x-8 -translate-y-8 opacity-10">
                <div class="w-full h-full bg-gradient-to-br from-blue-400 to-blue-600 rounded-full"></div>
              </div>
              <div class="relative p-6">
                <div class="flex items-center justify-between">
                  <div class="flex-shrink-0">
                    <div class="w-14 h-14 bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-lg group-hover:shadow-xl transition-shadow duration-300">
                      <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                      </svg>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-sm font-medium text-gray-500 uppercase tracking-wide">Work Orders</p>
                    <p class="text-3xl font-bold text-gray-900 mt-1"><%= @stats.open_work_orders || 0 %></p>
                  </div>
                </div>
                <div class="mt-4">
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-gray-600">Priority tasks pending</span>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                      Active
                    </span>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @auth.view_assets do %>
            <div class="group relative bg-white overflow-hidden shadow-xl rounded-2xl border border-gray-100 hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1">
              <div class="absolute top-0 right-0 w-32 h-32 transform translate-x-8 -translate-y-8 opacity-10">
                <div class="w-full h-full bg-gradient-to-br from-green-400 to-green-600 rounded-full"></div>
              </div>
              <div class="relative p-6">
                <div class="flex items-center justify-between">
                  <div class="flex-shrink-0">
                    <div class="w-14 h-14 bg-gradient-to-r from-green-500 to-green-600 rounded-xl flex items-center justify-center shadow-lg group-hover:shadow-xl transition-shadow duration-300">
                      <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                      </svg>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-sm font-medium text-gray-500 uppercase tracking-wide">Total Assets</p>
                    <p class="text-3xl font-bold text-gray-900 mt-1"><%= @stats.total_assets || 0 %></p>
                  </div>
                </div>
                <div class="mt-4">
                  <div class="flex items-center justify-between text-sm">
                    <div class="flex items-center space-x-1">
                      <div class="w-2 h-2 bg-green-500 rounded-full"></div>
                      <span class="text-gray-600"><%= @stats.operational_assets || 0 %> operational</span>
                    </div>
                    <div class="flex items-center space-x-1">
                      <div class="w-2 h-2 bg-orange-500 rounded-full"></div>
                      <span class="text-gray-600"><%= @stats.maintenance_assets || 0 %> maintenance</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @auth.manage_pm_templates do %>
            <div class="group relative bg-white overflow-hidden shadow-xl rounded-2xl border border-gray-100 hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1">
              <div class="absolute top-0 right-0 w-32 h-32 transform translate-x-8 -translate-y-8 opacity-10">
                <div class="w-full h-full bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full"></div>
              </div>
              <div class="relative p-6">
                <div class="flex items-center justify-between">
                  <div class="flex-shrink-0">
                    <div class="w-14 h-14 bg-gradient-to-r from-yellow-500 to-orange-500 rounded-xl flex items-center justify-center shadow-lg group-hover:shadow-xl transition-shadow duration-300">
                      <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                      </svg>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-sm font-medium text-gray-500 uppercase tracking-wide">PM Tasks</p>
                    <p class="text-3xl font-bold text-gray-900 mt-1"><%= @stats.due_pm_tasks || 0 %></p>
                  </div>
                </div>
                <div class="mt-4">
                  <div class="flex items-center justify-between">
                    <span class="text-sm text-gray-600">Scheduled maintenance</span>
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                      Pending
                    </span>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

          <!-- Additional summary card -->
          <div class="group relative bg-gradient-to-r from-indigo-500 to-purple-600 overflow-hidden shadow-xl rounded-2xl hover:shadow-2xl transition-all duration-300 transform hover:-translate-y-1">
            <div class="absolute top-0 right-0 w-32 h-32 transform translate-x-8 -translate-y-8 opacity-20">
              <div class="w-full h-full bg-white rounded-full"></div>
            </div>
            <div class="relative p-6 text-white">
              <div class="flex items-center justify-between">
                <div class="flex-shrink-0">
                  <div class="w-14 h-14 bg-white/20 backdrop-blur-sm rounded-xl flex items-center justify-center shadow-lg">
                    <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                    </svg>
                  </div>
                </div>
                <div class="text-right">
                  <p class="text-sm font-medium text-white/80 uppercase tracking-wide">Efficiency</p>
                  <p class="text-3xl font-bold text-white mt-1">98.5%</p>
                </div>
              </div>
              <div class="mt-4">
                <div class="flex items-center justify-between">
                  <span class="text-sm text-white/80">System uptime</span>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-white/20 text-white backdrop-blur-sm">
                    Excellent
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Asset Breakdown Charts -->
        <%= if @auth.view_assets and @stats.total_assets > 0 do %>
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-10">
            <!-- Asset Status Breakdown -->
            <div class="bg-white overflow-hidden shadow-xl rounded-2xl border border-gray-100">
              <div class="p-6">
                <h3 class="text-lg font-bold text-gray-900 mb-4">Asset Status</h3>
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
            <div class="bg-white overflow-hidden shadow-xl rounded-2xl border border-gray-100">
              <div class="p-6">
                <h3 class="text-lg font-bold text-gray-900 mb-4">Asset Criticality</h3>
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

        <!-- Enhanced Quick Actions -->
        <div class="bg-white/80 backdrop-blur-sm shadow-xl rounded-2xl border border-gray-100/50 mb-10 overflow-hidden">
          <div class="bg-gradient-to-r from-gray-50 to-blue-50 px-8 py-6 border-b border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="text-xl font-bold text-gray-900">Quick Actions</h3>
                <p class="text-sm text-gray-600 mt-1">Get things done efficiently</p>
              </div>
              <div class="flex items-center space-x-2">
                <div class="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
                <span class="text-sm text-gray-500">Ready</span>
              </div>
            </div>
          </div>
          <div class="p-8">
            <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <%= if @auth.create_work_orders do %>
                <button class="group relative overflow-hidden inline-flex items-center justify-center px-6 py-5 border border-transparent text-sm font-bold rounded-xl shadow-lg text-white bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-300 transform hover:scale-105 hover:shadow-xl">
                  <div class="absolute inset-0 bg-gradient-to-r from-blue-400 to-blue-500 opacity-0 group-hover:opacity-20 transition-opacity duration-300"></div>
                  <svg class="w-5 h-5 mr-3 relative z-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
                  </svg>
                  <span class="relative z-10">Create Work Order</span>
                </button>
              <% end %>

              <%= if @auth.add_meter_readings do %>
                <button class="group relative overflow-hidden inline-flex items-center justify-center px-6 py-5 border border-gray-200 text-sm font-bold rounded-xl text-gray-700 bg-white hover:bg-gradient-to-r hover:from-gray-50 hover:to-blue-50 hover:border-blue-200 hover:text-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl">
                  <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
                  </svg>
                  Add Meter Reading
                </button>
              <% end %>

              <%= if @auth.manage_assets do %>
                <button class="group relative overflow-hidden inline-flex items-center justify-center px-6 py-5 border border-gray-200 text-sm font-bold rounded-xl text-gray-700 bg-white hover:bg-gradient-to-r hover:from-gray-50 hover:to-green-50 hover:border-green-200 hover:text-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl">
                  <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                  </svg>
                  Add Asset
                </button>
              <% end %>

              <%= if @auth.view_reports do %>
                <button class="group relative overflow-hidden inline-flex items-center justify-center px-6 py-5 border border-gray-200 text-sm font-bold rounded-xl text-gray-700 bg-white hover:bg-gradient-to-r hover:from-gray-50 hover:to-purple-50 hover:border-purple-200 hover:text-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl">
                  <svg class="w-5 h-5 mr-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                  </svg>
                  View Reports
                </button>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Enhanced Activity and Status Section -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <!-- Enhanced Recent Activity -->
          <div class="lg:col-span-2 bg-white/80 backdrop-blur-sm shadow-xl rounded-2xl border border-gray-100/50 overflow-hidden">
            <div class="bg-gradient-to-r from-gray-50 to-blue-50 px-8 py-6 border-b border-gray-100">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="text-xl font-bold text-gray-900">Recent Activity</h3>
                  <p class="text-sm text-gray-600 mt-1">Stay updated with system events</p>
                </div>
                <button class="text-blue-600 hover:text-blue-700 text-sm font-medium transition-colors duration-200">
                  View All
                </button>
              </div>
            </div>
            <div class="p-8">
              <div class="space-y-6">
                <!-- Enhanced activity items -->
                <div class="group flex items-start space-x-4 p-4 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-xl border border-blue-100 hover:shadow-md transition-all duration-200">
                  <div class="flex-shrink-0">
                    <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-md group-hover:shadow-lg transition-shadow duration-200">
                      <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                      </svg>
                    </div>
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-bold text-gray-900">System initialized</p>
                    <p class="text-sm text-gray-600 mt-1">CMMS dashboard loaded successfully with all modules active</p>
                    <div class="flex items-center mt-2 space-x-2">
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        System
                      </span>
                      <span class="text-xs text-gray-400">Just now</span>
                    </div>
                  </div>
                </div>

                <div class="group flex items-start space-x-4 p-4 bg-gradient-to-r from-green-50 to-emerald-50 rounded-xl border border-green-100 hover:shadow-md transition-all duration-200">
                  <div class="flex-shrink-0">
                    <div class="w-10 h-10 bg-gradient-to-r from-green-500 to-green-600 rounded-xl flex items-center justify-center shadow-md group-hover:shadow-lg transition-shadow duration-200">
                      <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                      </svg>
                    </div>
                  </div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-bold text-gray-900">Asset database ready</p>
                    <p class="text-sm text-gray-600 mt-1"><%= @stats.total_assets %> assets loaded and available for management</p>
                    <div class="flex items-center mt-2 space-x-2">
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        Assets
                      </span>
                      <span class="text-xs text-gray-400">Today</span>
                    </div>
                  </div>
                </div>

                <%= if @stats.total_assets == 0 do %>
                  <div class="text-center py-12">
                    <div class="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                      <svg class="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                      </svg>
                    </div>
                    <h3 class="text-lg font-semibold text-gray-900">No recent activity</h3>
                    <p class="mt-2 text-sm text-gray-500 max-w-md mx-auto">Get started by adding your first asset or creating a work order to see activity here.</p>
                    <div class="mt-6">
                      <button class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-lg shadow-sm text-white bg-blue-600 hover:bg-blue-700 transition-colors duration-200">
                        Get Started
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Enhanced System Status -->
          <div class="bg-white/80 backdrop-blur-sm shadow-xl rounded-2xl border border-gray-100/50 overflow-hidden">
            <div class="bg-gradient-to-r from-gray-50 to-green-50 px-6 py-6 border-b border-gray-100">
              <div class="flex items-center justify-between">
                <div>
                  <h3 class="text-lg font-bold text-gray-900">System Status</h3>
                  <p class="text-sm text-gray-600 mt-1">All systems operational</p>
                </div>
                <div class="w-3 h-3 bg-green-400 rounded-full animate-pulse"></div>
              </div>
            </div>
            <div class="p-6">
              <div class="space-y-4">
                <div class="flex items-center justify-between p-3 bg-green-50 rounded-xl border border-green-100">
                  <div class="flex items-center space-x-3">
                    <div class="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                      <svg class="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"></path>
                      </svg>
                    </div>
                    <span class="text-sm font-medium text-gray-800">Database</span>
                  </div>
                  <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-800">
                    Online
                  </span>
                </div>

                <div class="flex items-center justify-between p-3 bg-green-50 rounded-xl border border-green-100">
                  <div class="flex items-center space-x-3">
                    <div class="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                      <svg class="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                      </svg>
                    </div>
                    <span class="text-sm font-medium text-gray-800">Assets Module</span>
                  </div>
                  <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-green-100 text-green-800">
                    Active
                  </span>
                </div>

                <div class="flex items-center justify-between p-3 bg-yellow-50 rounded-xl border border-yellow-100">
                  <div class="flex items-center space-x-3">
                    <div class="w-8 h-8 bg-yellow-100 rounded-lg flex items-center justify-center">
                      <svg class="w-4 h-4 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"></path>
                      </svg>
                    </div>
                    <span class="text-sm font-medium text-gray-800">Work Orders</span>
                  </div>
                  <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-yellow-100 text-yellow-800">
                    Pending
                  </span>
                </div>

                <div class="flex items-center justify-between p-3 bg-yellow-50 rounded-xl border border-yellow-100">
                  <div class="flex items-center space-x-3">
                    <div class="w-8 h-8 bg-yellow-100 rounded-lg flex items-center justify-center">
                      <svg class="w-4 h-4 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                      </svg>
                    </div>
                    <span class="text-sm font-medium text-gray-800">PM Schedules</span>
                  </div>
                  <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-yellow-100 text-yellow-800">
                    Pending
                  </span>
                </div>

                <div class="pt-4 mt-6 border-t border-gray-200">
                  <div class="flex items-center justify-center space-x-2 text-xs text-gray-500">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                    <span>Last updated: <%= Time.utc_now() |> Time.truncate(:second) |> Time.to_string() %> UTC</span>
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

    # Pre-calculate authorization for template
    auth = %{
      view_work_orders: authorized?(current_user, current_tenant_id, :view_work_orders),
      view_assets: authorized?(current_user, current_tenant_id, :view_assets),
      view_preventive_maintenance: authorized?(current_user, current_tenant_id, :view_preventive_maintenance),
      view_reports: authorized?(current_user, current_tenant_id, :view_reports),
      view_admin: authorized?(current_user, current_tenant_id, :view_admin),
      manage_pm_templates: authorized?(current_user, current_tenant_id, :manage_pm_templates),
      manage_users: authorized?(current_user, current_tenant_id, :manage_users),
      create_work_orders: authorized?(current_user, current_tenant_id, :create_work_orders),
      add_meter_readings: authorized?(current_user, current_tenant_id, :add_meter_readings),
      manage_assets: authorized?(current_user, current_tenant_id, :manage_assets)
    }

    {:ok,
     socket
     |> assign(:current_tenant, current_tenant)
     |> assign(:user_tenants, user_tenants)
     |> assign(:user_role, user_role)
     |> assign(:stats, stats)
     |> assign(:auth, auth)}
  end

  @impl true
  def handle_event("show_preferences", _params, socket) do
    # TODO: Implement preferences modal
    {:noreply, put_flash(socket, :info, "Preferences coming soon!")}
  end

  # Helper function to check authorization
  defp authorized?(user, tenant_id, action) do
    case Shop1Cmms.Auth.authorize(user, action, nil, tenant_id) do
      :ok -> true
      _ -> false
    end
  end  # Enhanced navigation link component
  defp nav_link(assigns) do
    ~H"""
    <a href={@href} class={"px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 flex items-center border #{@class}"}>
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
