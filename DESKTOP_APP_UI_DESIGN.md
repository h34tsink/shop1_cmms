# Desktop-Style Business Professional UI Design Guide

**Design Philosophy:** Transform Shop1 CMMS into a dense, professional, desktop-application-style interface that maximizes screen space utilization while maintaining clarity and usability.

---

## 🎯 Core Design Principles

### 1. **Maximum Screen Utilization**
- Use full viewport width and height
- Eliminate excessive padding and margins
- Tight, dense layouts like Microsoft Office or SAP
- No wasted whitespace

### 2. **Business Professional Aesthetic**
- Clean, corporate color scheme (grays, blues, subtle accents)
- Consistent spacing (8px grid system)
- Sharp corners or minimal rounding (2-4px max)
- Professional typography (smaller, tighter)
- Dense information display

### 3. **Desktop Application Feel**
- Fixed header/navigation (like Windows app title bar)
- Sidebar navigation (collapsible, always visible)
- Multi-panel layouts with splitters
- Context menus on right-click
- Dense tables with alternating row colors
- Toolbar ribbons for actions

---

## 🖥️ Layout Transformation

### Current Layout Issues:
- ❌ Too much padding and margin
- ❌ Centered content with unused side space
- ❌ Large, card-based layouts
- ❌ Mobile-first approach (too much whitespace on desktop)

### New Desktop Layout:
- ✅ Fixed sidebar navigation (200-250px)
- ✅ Full-width content area
- ✅ Dense header (40-50px height)
- ✅ Compact padding (8-12px instead of 16-24px)
- ✅ Multi-column layouts where appropriate
- ✅ Resizable panels

---

## 📐 Layout Architecture

### Master Layout Structure

```heex
<!-- lib/shop1_cmms_web/components/layouts/app.html.heex -->
<div class="h-screen flex flex-col overflow-hidden bg-gray-50">
  <!-- Fixed Top Bar (Windows-style title bar) -->
  <header class="h-12 bg-gradient-to-r from-gray-800 to-gray-900 text-white flex items-center px-3 shadow-lg flex-shrink-0">
    <div class="flex items-center space-x-3">
      <!-- App Logo/Icon -->
      <div class="w-6 h-6 bg-blue-500 rounded flex items-center justify-center">
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6z"></path>
        </svg>
      </div>
      <span class="text-sm font-semibold">Shop1 CMMS</span>
    </div>
    
    <!-- Global Actions (right side) -->
    <div class="ml-auto flex items-center space-x-2">
      <!-- Global Search -->
      <input 
        type="search" 
        placeholder="Search... (Ctrl+K)"
        class="w-64 h-7 px-3 text-xs bg-gray-700 text-white border border-gray-600 rounded focus:outline-none focus:bg-gray-600 focus:border-blue-500"
      />
      
      <!-- Notifications -->
      <button class="p-1.5 hover:bg-gray-700 rounded relative">
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6z"></path>
        </svg>
        <span class="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
      </button>
      
      <!-- User Menu -->
      <div class="flex items-center space-x-2 pl-2 border-l border-gray-600">
        <span class="text-xs"><%= @current_user.username %></span>
        <button class="p-1 hover:bg-gray-700 rounded">
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"></path>
          </svg>
        </button>
      </div>
    </div>
  </header>

  <!-- Main Content Area with Sidebar -->
  <div class="flex-1 flex overflow-hidden">
    <!-- Collapsible Sidebar Navigation -->
    <aside class="w-52 bg-gray-800 text-gray-300 flex-shrink-0 overflow-y-auto border-r border-gray-700">
      <nav class="py-2">
        <!-- Navigation Tree -->
        <div class="px-2 space-y-0.5">
          <.nav_item icon="dashboard" label="Dashboard" href="/" active={@current_page == "dashboard"} />
          
          <.nav_group label="Maintenance" expanded={true}>
            <.nav_item icon="clipboard" label="Work Orders" href="/work_orders" indent={true} />
            <.nav_item icon="calendar" label="PM Schedules" href="/preventive-maintenance" indent={true} />
          </.nav_group>
          
          <.nav_group label="Assets" expanded={true}>
            <.nav_item icon="box" label="All Assets" href="/assets" indent={true} />
            <.nav_item icon="database" label="Metadata" href="/metadata/manufacturers" indent={true} />
          </.nav_group>
          
          <.nav_item icon="chart" label="Reports" href="/reports" />
          <.nav_item icon="settings" label="Admin" href="/admin/users" />
        </div>
      </nav>
    </aside>

    <!-- Main Content Panel -->
    <main class="flex-1 flex flex-col overflow-hidden bg-white">
      <!-- Breadcrumb + Toolbar -->
      <div class="h-10 bg-gray-100 border-b border-gray-300 flex items-center justify-between px-3 flex-shrink-0">
        <!-- Breadcrumb -->
        <nav class="flex items-center text-xs space-x-1">
          <a href="/" class="text-gray-600 hover:text-gray-900">Home</a>
          <span class="text-gray-400">/</span>
          <span class="text-gray-900 font-medium">Assets</span>
        </nav>
        
        <!-- Quick Actions Toolbar -->
        <div class="flex items-center space-x-1">
          <button class="px-3 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 flex items-center space-x-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"></path>
            </svg>
            <span>New Asset</span>
          </button>
          <button class="px-3 py-1 text-xs border border-gray-300 rounded hover:bg-gray-50 flex items-center space-x-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z"></path>
            </svg>
            <span>Import</span>
          </button>
          <button class="px-3 py-1 text-xs border border-gray-300 rounded hover:bg-gray-50 flex items-center space-x-1">
            <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM6.293 6.707a1 1 0 010-1.414l3-3a1 1 0 011.414 0l3 3a1 1 0 01-1.414 1.414L11 5.414V13a1 1 0 11-2 0V5.414L7.707 6.707a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
            </svg>
            <span>Export</span>
          </button>
        </div>
      </div>

      <!-- Scrollable Content Area -->
      <div class="flex-1 overflow-auto">
        <.flash_group flash={@flash} />
        <%= @inner_content %>
      </div>

      <!-- Status Bar (Windows-style) -->
      <div class="h-6 bg-blue-600 text-white border-t border-blue-700 flex items-center justify-between px-3 text-xs flex-shrink-0">
        <div class="flex items-center space-x-4">
          <span>Ready</span>
          <span class="opacity-75">|</span>
          <span>Tenant: <%= @current_tenant.name %></span>
        </div>
        <div class="flex items-center space-x-4">
          <span><%= @stats.total_assets %> Assets</span>
          <span class="opacity-75">|</span>
          <span><%= @stats.open_work_orders %> Open WOs</span>
          <span class="opacity-75">|</span>
          <span class="flex items-center space-x-1">
            <div class="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
            <span>Connected</span>
          </span>
        </div>
      </div>
    </main>
  </div>
</div>
```

---

## 🎨 Professional Color Scheme

### Updated Tailwind Config

```javascript
// assets/tailwind.config.js
module.exports = {
  content: [
    './js/**/*.js',
    '../lib/shop1_cmms_web.ex',
    '../lib/shop1_cmms_web/**/*.*ex'
  ],
  theme: {
    extend: {
      colors: {
        // Professional Business Palette
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',  // Main blue
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
        sidebar: {
          DEFAULT: '#1f2937',  // Dark gray
          hover: '#374151',
          active: '#4b5563',
        },
        toolbar: {
          DEFAULT: '#f9fafb',
          border: '#e5e7eb',
        }
      },
      spacing: {
        // Tight spacing for desktop apps
        '0.5': '2px',
        '1.5': '6px',
        '2.5': '10px',
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms')
  ]
}
```

### CSS Overrides for Desktop Style

```css
/* assets/css/app.css */

/* Desktop Application Base Styles */
body {
  @apply text-sm;  /* Smaller default text */
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

/* Tighter spacing globally */
.desktop-tight {
  @apply p-0 m-0;
}

/* Dense Tables */
.table-dense {
  @apply w-full text-xs;
}

.table-dense thead {
  @apply bg-gray-100 border-b-2 border-gray-300;
}

.table-dense th {
  @apply px-3 py-1.5 text-left font-semibold text-gray-700 uppercase tracking-wider;
}

.table-dense tbody tr {
  @apply border-b border-gray-200;
}

.table-dense tbody tr:nth-child(even) {
  @apply bg-gray-50;
}

.table-dense tbody tr:hover {
  @apply bg-blue-50;
}

.table-dense td {
  @apply px-3 py-1.5 text-gray-900;
}

/* Compact Forms */
.form-compact label {
  @apply block text-xs font-medium text-gray-700 mb-1;
}

.form-compact input,
.form-compact select,
.form-compact textarea {
  @apply block w-full px-2 py-1 text-sm border-gray-300 rounded focus:ring-1 focus:ring-blue-500 focus:border-blue-500;
}

/* Toolbar Buttons */
.btn-toolbar {
  @apply px-2 py-1 text-xs font-medium border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-1 focus:ring-blue-500 inline-flex items-center space-x-1;
}

.btn-toolbar-primary {
  @apply btn-toolbar bg-blue-600 text-white border-blue-600 hover:bg-blue-700;
}

/* Panel Styling */
.panel {
  @apply bg-white border border-gray-300 rounded;
}

.panel-header {
  @apply bg-gray-50 border-b border-gray-300 px-3 py-2 font-semibold text-sm text-gray-900;
}

.panel-body {
  @apply p-3;
}

/* Splitter/Resizer */
.resizer {
  @apply bg-gray-300 hover:bg-blue-500 cursor-col-resize;
  width: 3px;
  position: relative;
}

.resizer:hover::after {
  content: '';
  @apply absolute inset-y-0 -left-1 -right-1;
}

/* Status Bar */
.status-bar {
  @apply h-6 bg-blue-600 text-white text-xs flex items-center justify-between px-3 border-t border-blue-700;
}

/* Context Menu (right-click menu) */
.context-menu {
  @apply fixed bg-white border border-gray-300 rounded shadow-lg py-1 z-50 min-w-[160px];
}

.context-menu-item {
  @apply px-3 py-1.5 text-xs hover:bg-blue-500 hover:text-white cursor-pointer flex items-center space-x-2;
}

/* Scrollbar Styling (Windows-like) */
::-webkit-scrollbar {
  width: 16px;
  height: 16px;
}

::-webkit-scrollbar-track {
  @apply bg-gray-100;
}

::-webkit-scrollbar-thumb {
  @apply bg-gray-400 border-2 border-gray-100;
}

::-webkit-scrollbar-thumb:hover {
  @apply bg-gray-500;
}

::-webkit-scrollbar-button {
  @apply bg-gray-200 border border-gray-300;
  height: 16px;
  width: 16px;
}

/* Remove excessive border radius */
.rounded, .rounded-md {
  border-radius: 2px !important;
}

.rounded-lg {
  border-radius: 4px !important;
}

/* Tight cards */
.card-tight {
  @apply bg-white border border-gray-300 rounded p-3;
}

/* Dense Grid */
.grid-dense {
  @apply grid gap-2;
}

/* No wasted space */
.container-full {
  @apply w-full max-w-full px-0;
}
```

---

## 📊 Dense Table Layout

```heex
<!-- Dense, professional table for asset list -->
<div class="flex-1 overflow-auto bg-white">
  <table class="table-dense">
    <thead>
      <tr>
        <th class="w-8">
          <input type="checkbox" class="rounded border-gray-300" />
        </th>
        <th>Asset ID</th>
        <th>Name</th>
        <th>Type</th>
        <th>Location</th>
        <th>Status</th>
        <th>Last Maintenance</th>
        <th>Criticality</th>
        <th class="w-20">Actions</th>
      </tr>
    </thead>
    <tbody>
      <%= for asset <- @assets do %>
        <tr class="cursor-pointer" phx-click="select_asset" phx-value-id={asset.id}>
          <td>
            <input type="checkbox" class="rounded border-gray-300" />
          </td>
          <td class="font-mono text-gray-600"><%= asset.asset_code %></td>
          <td class="font-medium text-gray-900"><%= asset.name %></td>
          <td><%= asset.asset_type.name %></td>
          <td class="text-gray-600"><%= asset.location.name %></td>
          <td>
            <span class={[
              "inline-block px-2 py-0.5 text-xs font-medium rounded",
              status_color_class(asset.status)
            ]}>
              <%= format_status(asset.status) %>
            </span>
          </td>
          <td class="text-gray-600"><%= format_date(asset.last_maintenance_date) %></td>
          <td>
            <div class="flex items-center">
              <%= for _ <- 1..asset.criticality do %>
                <svg class="w-3 h-3 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"></path>
                </svg>
              <% end %>
            </div>
          </td>
          <td>
            <div class="flex items-center space-x-1">
              <button class="p-1 hover:bg-gray-200 rounded" title="Edit">
                <svg class="w-3.5 h-3.5 text-gray-600" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"></path>
                </svg>
              </button>
              <button class="p-1 hover:bg-gray-200 rounded" title="View">
                <svg class="w-3.5 h-3.5 text-gray-600" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M10 12a2 2 0 100-4 2 2 0 000 4z"></path>
                  <path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"></path>
                </svg>
              </button>
            </div>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>

<!-- Table Footer with pagination and info -->
<div class="h-8 bg-gray-50 border-t border-gray-300 flex items-center justify-between px-3 text-xs">
  <div class="text-gray-600">
    Showing <%= @page_start %>-<%= @page_end %> of <%= @total %> assets
  </div>
  <div class="flex items-center space-x-1">
    <button class="px-2 py-0.5 border border-gray-300 rounded hover:bg-gray-100 disabled:opacity-50" disabled={@page == 1}>
      ‹
    </button>
    <span class="px-2"><%= @page %> / <%= @total_pages %></span>
    <button class="px-2 py-0.5 border border-gray-300 rounded hover:bg-gray-100 disabled:opacity-50" disabled={@page == @total_pages}>
      ›
    </button>
  </div>
</div>
```

---

## 🎛️ Multi-Panel Dashboard

```heex
<!-- Desktop-style dashboard with panels -->
<div class="h-full flex flex-col p-2 gap-2">
  <!-- Top Row: KPI Panels -->
  <div class="flex gap-2 h-24">
    <div class="panel flex-1">
      <div class="panel-header">Work Orders</div>
      <div class="panel-body flex items-center justify-between">
        <div>
          <div class="text-2xl font-bold text-gray-900"><%= @stats.open_work_orders %></div>
          <div class="text-xs text-gray-500">Open</div>
        </div>
        <div class="text-right">
          <div class="text-sm text-red-600 font-medium"><%= @stats.overdue_work_orders %> Overdue</div>
          <div class="text-xs text-gray-500"><%= @stats.due_today %> Due Today</div>
        </div>
      </div>
    </div>
    
    <div class="panel flex-1">
      <div class="panel-header">Assets</div>
      <div class="panel-body flex items-center justify-between">
        <div>
          <div class="text-2xl font-bold text-gray-900"><%= @stats.total_assets %></div>
          <div class="text-xs text-gray-500">Total</div>
        </div>
        <div class="text-right">
          <div class="text-sm text-green-600 font-medium"><%= @stats.operational %> Operational</div>
          <div class="text-xs text-orange-600"><%= @stats.maintenance %> In Maintenance</div>
        </div>
      </div>
    </div>
    
    <div class="panel flex-1">
      <div class="panel-header">PM Compliance</div>
      <div class="panel-body flex items-center justify-between">
        <div>
          <div class="text-2xl font-bold text-gray-900"><%= @stats.pm_compliance %>%</div>
          <div class="text-xs text-gray-500">This Month</div>
        </div>
        <div class="w-12 h-12">
          <!-- Mini chart or gauge -->
          <svg class="w-full h-full" viewBox="0 0 36 36">
            <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" 
                  fill="none" stroke="#e5e7eb" stroke-width="3"/>
            <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831" 
                  fill="none" stroke="#10b981" stroke-width="3" 
                  stroke-dasharray="<%= @stats.pm_compliance %>, 100"/>
          </svg>
        </div>
      </div>
    </div>
  </div>

  <!-- Middle Row: Split View -->
  <div class="flex-1 flex gap-2 min-h-0">
    <!-- Left Panel: Recent Activity -->
    <div class="panel w-1/2 flex flex-col">
      <div class="panel-header flex items-center justify-between">
        <span>Recent Activity</span>
        <button class="text-blue-600 hover:text-blue-700 text-xs">View All</button>
      </div>
      <div class="flex-1 overflow-auto p-0">
        <table class="table-dense">
          <tbody>
            <%= for activity <- @recent_activities do %>
              <tr>
                <td class="w-8">
                  <div class={[
                    "w-6 h-6 rounded flex items-center justify-center",
                    activity_icon_bg(activity.type)
                  ]}>
                    <%= activity_icon(activity.type) %>
                  </div>
                </td>
                <td>
                  <div class="font-medium"><%= activity.description %></div>
                  <div class="text-xs text-gray-500"><%= activity.user %> • <%= relative_time(activity.timestamp) %></div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Right Panel: Overdue Items -->
    <div class="panel w-1/2 flex flex-col">
      <div class="panel-header flex items-center justify-between">
        <span>Overdue Work Orders</span>
        <span class="text-xs text-red-600 font-medium"><%= length(@overdue_work_orders) %> Items</span>
      </div>
      <div class="flex-1 overflow-auto p-0">
        <table class="table-dense">
          <thead>
            <tr>
              <th>WO #</th>
              <th>Asset</th>
              <th>Priority</th>
              <th>Days Overdue</th>
            </tr>
          </thead>
          <tbody>
            <%= for wo <- @overdue_work_orders do %>
              <tr>
                <td class="font-mono"><%= wo.wo_number %></td>
                <td><%= wo.asset_name %></td>
                <td>
                  <span class={priority_badge(wo.priority)}>
                    <%= wo.priority %>
                  </span>
                </td>
                <td class="text-red-600 font-medium"><%= wo.days_overdue %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Bottom Row: Charts -->
  <div class="h-48 flex gap-2">
    <div class="panel flex-1">
      <div class="panel-header">Work Order Trend (30 Days)</div>
      <div class="panel-body p-2">
        <!-- Chart goes here -->
        <div class="h-32 bg-gray-50 flex items-center justify-center text-xs text-gray-500">
          Chart placeholder
        </div>
      </div>
    </div>
    
    <div class="panel flex-1">
      <div class="panel-header">Asset Status Distribution</div>
      <div class="panel-body p-2">
        <!-- Chart goes here -->
        <div class="h-32 bg-gray-50 flex items-center justify-center text-xs text-gray-500">
          Chart placeholder
        </div>
      </div>
    </div>
  </div>
</div>
```

---

## 🎨 Navigation Component (Sidebar)

```heex
<!-- lib/shop1_cmms_web/components/navigation.ex -->
defmodule Shop1CmmsWeb.Components.Navigation do
  use Phoenix.Component
  
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :href, :string, default: nil
  attr :active, :boolean, default: false
  attr :indent, :boolean, default: false
  attr :badge, :string, default: nil
  
  def nav_item(assigns) do
    ~H"""
    <.link 
      href={@href}
      class={[
        "flex items-center px-2 py-1.5 text-xs rounded transition-colors",
        @indent && "pl-6",
        @active && "bg-gray-700 text-white font-medium",
        !@active && "text-gray-300 hover:bg-gray-700 hover:text-white"
      ]}
    >
      <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
        <%= render_icon(@icon) %>
      </svg>
      <span class="flex-1"><%= @label %></span>
      <%= if @badge do %>
        <span class="px-1.5 py-0.5 text-xs bg-red-500 text-white rounded font-medium">
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
          class="w-3 h-3 mr-2 transition-transform" 
          :class="{ 'rotate-90': expanded }"
          fill="currentColor" 
          viewBox="0 0 20 20"
        >
          <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"></path>
        </svg>
        <span class="uppercase tracking-wider font-semibold"><%= @label %></span>
      </button>
      <div x-show="expanded" x-collapse>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
  
  defp render_icon("dashboard") do
    ~H"""
    <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"></path>
    """
  end
  
  # Add more icons as needed...
end
```

---

## 🔧 Compact Form Layout

```heex
<!-- Tight, professional form design -->
<form phx-submit="save" class="space-y-3 p-4">
  <!-- Two-column layout for forms -->
  <div class="grid grid-cols-2 gap-x-4 gap-y-3">
    <!-- Asset Code -->
    <div class="form-compact">
      <label for="asset_code">Asset Code <span class="text-red-500">*</span></label>
      <input 
        type="text" 
        id="asset_code" 
        name="asset[asset_code]"
        required
        placeholder="A-001"
      />
    </div>
    
    <!-- Asset Name -->
    <div class="form-compact">
      <label for="asset_name">Asset Name <span class="text-red-500">*</span></label>
      <input 
        type="text" 
        id="asset_name" 
        name="asset[name]"
        required
        placeholder="Conveyor Belt"
      />
    </div>
    
    <!-- Asset Type -->
    <div class="form-compact">
      <label for="asset_type">Type</label>
      <select id="asset_type" name="asset[asset_type_id]">
        <option value="">Select type...</option>
        <%= for type <- @asset_types do %>
          <option value={type.id}><%= type.name %></option>
        <% end %>
      </select>
    </div>
    
    <!-- Location -->
    <div class="form-compact">
      <label for="location">Location</label>
      <select id="location" name="asset[location_id]">
        <option value="">Select location...</option>
        <%= for location <- @locations do %>
          <option value={location.id}><%= location.name %></option>
        <% end %>
      </select>
    </div>
    
    <!-- Status -->
    <div class="form-compact">
      <label for="status">Status</label>
      <select id="status" name="asset[status]">
        <option value="operational">Operational</option>
        <option value="needs_maintenance">Needs Maintenance</option>
        <option value="out_of_service">Out of Service</option>
      </select>
    </div>
    
    <!-- Criticality -->
    <div class="form-compact">
      <label for="criticality">Criticality</label>
      <select id="criticality" name="asset[criticality]">
        <option value="1">Low</option>
        <option value="2">Medium</option>
        <option value="3">High</option>
        <option value="4">Critical</option>
      </select>
    </div>
  </div>
  
  <!-- Full-width fields -->
  <div class="form-compact">
    <label for="description">Description</label>
    <textarea 
      id="description" 
      name="asset[description]"
      rows="3"
      placeholder="Enter asset description..."
    ></textarea>
  </div>
  
  <!-- Form Actions (tight, inline) -->
  <div class="flex items-center justify-end space-x-2 pt-2 border-t border-gray-200">
    <button type="button" class="btn-toolbar" phx-click="cancel">
      Cancel
    </button>
    <button type="submit" class="btn-toolbar-primary">
      <svg class="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path>
      </svg>
      <span>Save Asset</span>
    </button>
  </div>
</form>
```

---

## 📋 Context Menu (Right-Click)

```javascript
// assets/js/app.js - Add context menu support

// Context menu handler
document.addEventListener('contextmenu', (e) => {
  // Check if target has data-context-menu attribute
  const contextElement = e.target.closest('[data-context-menu]');
  if (!contextElement) return;
  
  e.preventDefault();
  
  const menuType = contextElement.dataset.contextMenu;
  const menuId = contextElement.dataset.contextId;
  
  // Remove existing menus
  document.querySelectorAll('.context-menu').forEach(m => m.remove());
  
  // Create context menu
  const menu = document.createElement('div');
  menu.className = 'context-menu';
  menu.style.left = e.pageX + 'px';
  menu.style.top = e.pageY + 'px';
  
  // Build menu items based on type
  const items = getContextMenuItems(menuType, menuId);
  menu.innerHTML = items.map(item => `
    <div class="context-menu-item" data-action="${item.action}" data-id="${menuId}">
      ${item.icon}
      <span>${item.label}</span>
    </div>
  `).join('');
  
  document.body.appendChild(menu);
  
  // Close on click outside
  setTimeout(() => {
    document.addEventListener('click', () => menu.remove(), { once: true });
  }, 0);
  
  // Handle menu item clicks
  menu.querySelectorAll('.context-menu-item').forEach(item => {
    item.addEventListener('click', (e) => {
      const action = e.currentTarget.dataset.action;
      const id = e.currentTarget.dataset.id;
      
      // Push event to LiveView
      window.liveSocket.execJS(
        document.body,
        `[[&quot;push&quot;,{&quot;event&quot;:&quot;${action}&quot;,&quot;value&quot;:{&quot;id&quot;:${id}}}]]`
      );
      
      menu.remove();
    });
  });
});

function getContextMenuItems(type, id) {
  const icons = {
    edit: '<svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"></path></svg>',
    view: '<svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path d="M10 12a2 2 0 100-4 2 2 0 000 4z"></path><path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"></path></svg>',
    delete: '<svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>',
  };
  
  if (type === 'asset') {
    return [
      { action: 'view_asset', label: 'View Details', icon: icons.view },
      { action: 'edit_asset', label: 'Edit', icon: icons.edit },
      { action: 'create_wo', label: 'Create Work Order', icon: icons.edit },
      { action: 'view_history', label: 'View History', icon: icons.view },
      { action: 'delete_asset', label: 'Delete', icon: icons.delete },
    ];
  }
  
  return [];
}
```

```heex
<!-- Add to table rows for context menu -->
<tr data-context-menu="asset" data-context-id={asset.id}>
  <!-- table cells -->
</tr>
```

---

## 🎯 Key Changes Summary

### Layout Changes:
1. **Remove all max-width containers** - Use full viewport width
2. **Fixed sidebar** (200-250px) always visible on desktop
3. **Compact header** (40-50px instead of 64px+)
4. **Remove excessive padding** - 8-12px instead of 16-24px
5. **Status bar at bottom** like Windows apps
6. **Toolbar ribbons** for quick actions

### Visual Changes:
1. **Smaller text** - 12-14px default instead of 16px
2. **Minimal border radius** - 2-4px instead of 8-16px
3. **Dense tables** with alternating row colors
4. **Compact forms** with two-column layouts
5. **Professional color scheme** - grays and blues
6. **Windows-style scrollbars**

### Functional Changes:
1. **Context menus** (right-click)
2. **Resizable panels**
3. **Keyboard shortcuts**
4. **Multi-panel layouts**
5. **Fixed navigation structure**
6. **Dense information display**

---

## 🚀 Implementation Priority

### Phase 1: Core Layout (Week 1)
1. ✅ Implement fixed sidebar navigation
2. ✅ Create compact header/toolbar
3. ✅ Add status bar
4. ✅ Update spacing throughout (remove excessive padding)
5. ✅ Implement new layout structure

### Phase 2: Components (Week 2)
1. ✅ Convert tables to dense layout
2. ✅ Update form layouts (compact, two-column)
3. ✅ Create toolbar button components
4. ✅ Implement panel components
5. ✅ Update navigation styling

### Phase 3: Interactions (Week 3)
1. ✅ Add context menu system
2. ✅ Implement keyboard shortcuts
3. ✅ Add resizable panels
4. ✅ Create multi-panel dashboard
5. ✅ Add Windows-style scrollbars

---

## ✅ Checklist

- [ ] Update `app.html.heex` with new layout structure
- [ ] Create sidebar navigation component
- [ ] Update `app.css` with desktop styles
- [ ] Update `tailwind.config.js` with business colors
- [ ] Convert dashboard to multi-panel layout
- [ ] Convert asset list to dense table
- [ ] Update all forms to compact two-column layout
- [ ] Add context menu JavaScript
- [ ] Implement keyboard shortcuts
- [ ] Add status bar to all pages
- [ ] Remove all max-width containers
- [ ] Reduce all border-radius values
- [ ] Update all font sizes to be smaller
- [ ] Test on large monitors (1920px+)

---

This design will make Shop1 CMMS look and feel like a professional desktop business application (similar to SAP, Microsoft Dynamics, or Oracle ERP) while maintaining the benefits of a web-based system!
