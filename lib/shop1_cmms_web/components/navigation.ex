defmodule Shop1CmmsWeb.Components.Navigation do
  use Phoenix.Component
  import Shop1CmmsWeb.CoreComponents

  attr :current_user, :map, required: true
  attr :current_tenant, :map, required: true
  attr :user_role, :string, default: nil
  attr :auth, :map, required: true
  attr :current_path, :string, default: "/"

  def sidebar_nav(assigns) do
    ~H"""
    <!-- Collapsible Sidebar Navigation -->
    <aside class="w-52 bg-sidebar text-sidebar-text flex-shrink-0 overflow-y-auto border-r border-gray-700">
      <nav class="py-2">
        <div class="px-2 space-y-0.5">
          <!-- Dashboard -->
          <.nav_item 
            href="/" 
            label="Dashboard" 
            icon="dashboard"
            active={@current_path == "/" || @current_path == "/dashboard"}
          />
          
          <!-- Maintenance Section -->
          <.nav_group label="Maintenance" expanded={true}>
            <%= if @auth.view_work_orders do %>
              <.nav_item 
                href="/work_orders" 
                label="Work Orders" 
                icon="clipboard"
                indent={true}
                active={String.starts_with?(@current_path, "/work_orders") || String.starts_with?(@current_path, "/work-orders")}
              />
            <% end %>
            <%= if @auth.manage_pm_templates do %>
              <.nav_item 
                href="/preventive-maintenance" 
                label="PM Schedules" 
                icon="calendar"
                indent={true}
                active={String.starts_with?(@current_path, "/preventive-maintenance")}
              />
            <% end %>
          </.nav_group>
          
          <!-- Assets Section -->
          <%= if @auth.view_assets do %>
            <.nav_group label="Assets" expanded={true}>
              <.nav_item 
                href="/assets" 
                label="All Assets" 
                icon="box"
                indent={true}
                active={String.starts_with?(@current_path, "/assets")}
              />
              <.nav_item 
                href="/metadata/manufacturers" 
                label="Metadata" 
                icon="database"
                indent={true}
                active={String.starts_with?(@current_path, "/metadata")}
              />
            </.nav_group>
          <% end %>
          
          <!-- Reports -->
          <%= if @auth.view_reports do %>
            <.nav_item 
              href="/reports" 
              label="Reports" 
              icon="chart"
              active={String.starts_with?(@current_path, "/reports")}
            />
          <% end %>
          
          <!-- Admin -->
          <%= if @auth.manage_users do %>
            <.nav_item 
              href="/admin/users" 
              label="Administration" 
              icon="settings"
              active={String.starts_with?(@current_path, "/admin")}
            />
          <% end %>
        </div>
      </nav>
    </aside>
    """
  end

  attr :href, :string, default: nil
  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :active, :boolean, default: false
  attr :indent, :boolean, default: false
  attr :badge, :string, default: nil
  
  def nav_item(assigns) do
    ~H"""
    <.link 
      href={@href}
      class={[
        "flex items-center px-2 py-1.5 text-xs rounded transition-colors group",
        @indent && "pl-6",
        @active && "bg-sidebar-active text-white font-medium",
        !@active && "text-sidebar-text hover:bg-sidebar-hover hover:text-white"
      ]}
    >
      <svg class="w-4 h-4 mr-2 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
        <%= render_icon(@icon) %>
      </svg>
      <span class="flex-1 truncate"><%= @label %></span>
      <%= if @badge do %>
        <span class="px-1.5 py-0.5 text-xxs bg-red-500 text-white rounded font-medium">
          <%= @badge %>
        </span>
      <% end %>
    </.link>
    """
  end
  
  attr :label, :string, required: true
  attr :expanded, :boolean, default: false
  slot :inner_block, required: true
  
  def nav_group(assigns) do
    ~H"""
    <div x-data={"{ expanded: #{@expanded} }"} class="space-y-0.5">
      <button 
        @click="expanded = !expanded"
        class="w-full flex items-center px-2 py-1.5 text-xs text-gray-400 hover:text-gray-200 transition-colors"
      >
        <svg 
          class="w-3 h-3 mr-2 transition-transform flex-shrink-0" 
          :class="{ 'rotate-90': expanded }"
          fill="currentColor" 
          viewBox="0 0 20 20"
        >
          <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
        </svg>
        <span class="uppercase tracking-wider font-semibold text-xxs"><%= @label %></span>
      </button>
      <div x-show="expanded" x-collapse>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  # Icon definitions
  defp render_icon("dashboard") do
    ~H"""
    <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"></path>
    """
  end
  
  defp render_icon("clipboard") do
    ~H"""
    <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"></path>
    <path fill-rule="evenodd" d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3zm-3 4a1 1 0 100 2h.01a1 1 0 100-2H7zm3 0a1 1 0 100 2h3a1 1 0 100-2h-3z" clip-rule="evenodd"></path>
    """
  end
  
  defp render_icon("calendar") do
    ~H"""
    <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"></path>
    """
  end
  
  defp render_icon("box") do
    ~H"""
    <path fill-rule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clip-rule="evenodd"></path>
    """
  end
  
  defp render_icon("database") do
    ~H"""
    <path d="M3 12v3c0 1.657 3.134 3 7 3s7-1.343 7-3v-3c0 1.657-3.134 3-7 3s-7-1.343-7-3z"></path>
    <path d="M3 7v3c0 1.657 3.134 3 7 3s7-1.343 7-3V7c0 1.657-3.134 3-7 3S3 8.657 3 7z"></path>
    <path d="M17 5c0 1.657-3.134 3-7 3S3 6.657 3 5s3.134-3 7-3 7 1.343 7 3z"></path>
    """
  end
  
  defp render_icon("chart") do
    ~H"""
    <path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z"></path>
    """
  end
  
  defp render_icon("settings") do
    ~H"""
    <path fill-rule="evenodd" d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z" clip-rule="evenodd"></path>
    """
  end
  
  defp render_icon(_), do: ~H""

  # Keep old top_nav for backward compatibility (can be removed later)
  attr :current_user, :map, required: true
  attr :current_tenant, :map, required: true
  attr :user_role, :string, default: nil
  attr :user_tenants, :list, default: []
  attr :auth, :map, required: true

  def top_nav(assigns) do
    ~H"""
    <!-- Full-width Top Navigation Bar -->
    <nav class="w-full bg-white/95 backdrop-blur-sm shadow-lg border-b border-gray-200/20 sticky top-0 z-40">
      <div class="w-full px-6 lg:px-8">
        <div class="flex justify-between h-16">
          <div class="flex">
            <div class="flex-shrink-0 flex items-center">
              <.link href="/" class="flex items-center space-x-3 hover:opacity-90 transition-opacity">
                <div class="w-10 h-10 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl flex items-center justify-center shadow-lg">
                  <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"></path>
                  </svg>
                </div>
                <div>
                  <span class="text-xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent">Shop1 CMMS</span>
                  <div class="text-xs text-gray-500 font-medium">Maintenance Management</div>
                </div>
              </.link>
            </div>

            <div class="hidden sm:ml-8 sm:flex sm:space-x-1">
              <.nav_link href="/" class="text-gray-600 hover:text-gray-900 hover:bg-gray-50">
                <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"></path>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5v4"></path>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 5v4"></path>
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 5v4"></path>
                </svg>
                Dashboard
              </.nav_link>

              <%= if @auth.view_work_orders do %>
                <.nav_link href="/work-orders" class="text-gray-600 hover:text-gray-900 hover:bg-gray-50">
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

              <%= if @auth.view_assets do %>
                <.nav_link href="/metadata/manufacturers" class="text-gray-600 hover:text-gray-900 hover:bg-gray-50">
                  <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4"></path>
                  </svg>
                  Metadata
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
                <.nav_link href="/admin/users" class="text-gray-600 hover:text-gray-900 hover:bg-gray-50">
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
                <span class="hidden md:block font-medium text-gray-700">
                  <%= String.split(@current_user.username, "@") |> List.first() |> String.capitalize() %>
                </span>
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
    """
  end

  defp nav_link(assigns) do
    ~H"""
    <.link href={@href} class={["inline-flex items-center px-3 py-2 rounded-lg text-sm font-medium transition-colors duration-200", @class]}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
