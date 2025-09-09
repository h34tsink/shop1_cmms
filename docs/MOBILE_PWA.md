# Mobile-Responsive Design & PWA Foundation

## Overview

This document outlines the mobile-responsive design optimizations and Progressive Web App (PWA) foundation for technician use, preparing for future mobile app development.

## Mobile-First Design Principles

### 1. Touch-Friendly Interface
- Minimum 44px touch targets
- Adequate spacing between interactive elements  
- Gesture-based navigation patterns
- Large, easy-to-read text (minimum 16px)

### 2. Optimized Layouts
- Single-column layouts on mobile
- Collapsible sections and accordions
- Bottom navigation for primary actions
- Simplified forms with fewer fields per screen

### 3. Performance Considerations
- Optimized images and assets
- Efficient LiveView updates
- Offline capability preparation
- Fast loading times (<3 seconds)

## CSS Framework Extensions

### Custom Tailwind Components (assets/css/app.css)

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom components for CMMS mobile interface */
@layer components {
  /* Touch-friendly buttons */
  .btn-touch {
    @apply min-h-[44px] px-6 py-3 text-base font-medium rounded-lg;
  }

  .btn-primary-touch {
    @apply btn-touch bg-blue-600 text-white hover:bg-blue-700 active:bg-blue-800;
  }

  .btn-secondary-touch {
    @apply btn-touch bg-gray-200 text-gray-800 hover:bg-gray-300 active:bg-gray-400;
  }

  /* Mobile cards */
  .card-mobile {
    @apply bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-3;
  }

  /* Status badges optimized for mobile */
  .status-badge {
    @apply inline-flex items-center px-3 py-1 rounded-full text-sm font-medium;
  }

  .status-new { @apply status-badge bg-gray-100 text-gray-800; }
  .status-assigned { @apply status-badge bg-blue-100 text-blue-800; }
  .status-in-progress { @apply status-badge bg-yellow-100 text-yellow-800; }
  .status-completed { @apply status-badge bg-green-100 text-green-800; }
  .status-overdue { @apply status-badge bg-red-100 text-red-800; }

  /* Mobile-optimized form inputs */
  .input-mobile {
    @apply block w-full min-h-[44px] px-4 py-3 text-base border border-gray-300 rounded-lg;
    @apply focus:ring-2 focus:ring-blue-500 focus:border-blue-500;
  }

  /* Quick action floating button */
  .fab {
    @apply fixed bottom-6 right-6 z-50 w-14 h-14 bg-blue-600 text-white rounded-full shadow-lg;
    @apply flex items-center justify-center hover:bg-blue-700 active:bg-blue-800;
  }

  /* Mobile navigation */
  .mobile-nav-item {
    @apply flex items-center w-full px-4 py-3 text-left text-base font-medium;
    @apply text-gray-700 hover:bg-gray-100 active:bg-gray-200 rounded-lg;
  }

  .mobile-nav-item.active {
    @apply bg-blue-50 text-blue-700;
  }

  /* Swipe actions container */
  .swipe-container {
    @apply relative overflow-hidden bg-white;
  }

  .swipe-actions {
    @apply absolute top-0 right-0 h-full flex items-center space-x-2 px-4;
    @apply bg-red-500 text-white;
    transform: translateX(100%);
    transition: transform 0.3s ease;
  }

  .swipe-container.swiped .swipe-actions {
    transform: translateX(0);
  }

  /* Loading states */
  .skeleton {
    @apply bg-gray-200 animate-pulse rounded;
  }

  .skeleton-text {
    @apply skeleton h-4 mb-2;
  }

  .skeleton-title {
    @apply skeleton h-6 mb-3;
  }
}

/* Responsive utilities */
@layer utilities {
  .safe-area-inset {
    padding-top: env(safe-area-inset-top);
    padding-bottom: env(safe-area-inset-bottom);
    padding-left: env(safe-area-inset-left);
    padding-right: env(safe-area-inset-right);
  }

  .touch-manipulation {
    touch-action: manipulation;
  }

  .no-tap-highlight {
    -webkit-tap-highlight-color: transparent;
  }
}

/* Mobile-specific media queries */
@media (max-width: 640px) {
  /* Increase font sizes on mobile */
  .text-xs { font-size: 0.875rem; }
  .text-sm { font-size: 1rem; }
  .text-base { font-size: 1.125rem; }
  
  /* Adjust spacing */
  .space-y-1 > * + * { margin-top: 0.375rem; }
  .space-y-2 > * + * { margin-top: 0.5rem; }
  
  /* Full-width buttons on mobile */
  .btn-mobile-full {
    width: 100%;
    justify-content: center;
  }
}

/* PWA specific styles */
@media (display-mode: standalone) {
  /* Hide the browser chrome when running as PWA */
  .pwa-hidden {
    display: none;
  }
  
  /* Adjust layout for standalone mode */
  .app-container {
    height: 100vh;
    overflow: hidden;
  }
}
```

## Mobile-Optimized Components

### 1. Mobile Work Order Card

```elixir
defmodule Shop1CmmsWeb.Components.WorkOrderCard do
  use Shop1CmmsWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="card-mobile swipe-container" data-work-order-id={@work_order.id}>
      <!-- Main card content -->
      <div class="swipe-content">
        <div class="flex items-start justify-between mb-3">
          <div class="flex-1 min-w-0">
            <h3 class="text-lg font-semibold text-gray-900 truncate">
              <%= @work_order.number %>
            </h3>
            <p class="text-gray-600 text-sm truncate">
              <%= @work_order.title %>
            </p>
          </div>
          <div class="ml-3 flex-shrink-0">
            <div class={"status-#{String.replace(@work_order.status, "_", "-")}"}>
              <%= String.replace(@work_order.status, "_", " ") |> String.capitalize() %>
            </div>
          </div>
        </div>

        <!-- Asset and priority info -->
        <div class="flex items-center justify-between text-sm text-gray-500 mb-3">
          <div class="flex items-center">
            <.icon name="hero-cog-6-tooth" class="h-4 w-4 mr-1" />
            <%= @work_order.asset && @work_order.asset.name || "No asset" %>
          </div>
          <div class="flex items-center">
            <.priority_icon priority={@work_order.priority} />
            <span class="ml-1">Priority <%= @work_order.priority %></span>
          </div>
        </div>

        <!-- Due date and assignment -->
        <div class="flex items-center justify-between text-sm">
          <%= if @work_order.due_date do %>
            <div class={[
              "flex items-center",
              if(Date.compare(@work_order.due_date, Date.utc_today()) == :lt, do: "text-red-600", else: "text-gray-500")
            ]}>
              <.icon name="hero-calendar" class="h-4 w-4 mr-1" />
              Due <%= Calendar.strftime(@work_order.due_date, "%b %d") %>
            </div>
          <% else %>
            <div class="text-gray-400">No due date</div>
          <% end %>

          <%= if @work_order.assigned_to do %>
            <div class="flex items-center text-gray-500">
              <.icon name="hero-user" class="h-4 w-4 mr-1" />
              <%= @work_order.assigned_to.first_name || "Assigned" %>
            </div>
          <% else %>
            <div class="text-gray-400">Unassigned</div>
          <% end %>
        </div>

        <!-- Quick actions for mobile -->
        <div class="mt-4 flex space-x-2">
          <%= if can_update_work_order?(@current_user, @work_order) do %>
            <button 
              phx-click="start_work_order"
              phx-value-id={@work_order.id}
              class="btn-primary-touch flex-1 text-sm"
            >
              <.icon name="hero-play" class="h-4 w-4 mr-1" />
              Start
            </button>
          <% end %>

          <%= if @current_user.id != @work_order.assigned_to do %>
            <button 
              phx-click="assign_to_me"
              phx-value-id={@work_order.id}
              class="btn-secondary-touch flex-1 text-sm"
            >
              <.icon name="hero-user-plus" class="h-4 w-4 mr-1" />
              Assign to Me
            </button>
          <% end %>

          <.link 
            navigate={~p"/work-orders/#{@work_order.id}"}
            class="btn-secondary-touch px-3"
          >
            <.icon name="hero-eye" class="h-4 w-4" />
          </.link>
        </div>
      </div>

      <!-- Swipe actions (hidden by default) -->
      <div class="swipe-actions">
        <button class="p-2 bg-green-500 rounded">
          <.icon name="hero-check" class="h-5 w-5" />
        </button>
        <button class="p-2 bg-red-500 rounded">
          <.icon name="hero-x-mark" class="h-5 w-5" />
        </button>
      </div>
    </div>
    """
  end

  defp priority_icon(assigns) do
    icon_class = case assigns.priority do
      1 -> "text-red-500"
      2 -> "text-orange-500"
      3 -> "text-yellow-500"
      4 -> "text-blue-500"
      5 -> "text-gray-500"
      _ -> "text-gray-500"
    end

    assigns = assign(assigns, :icon_class, icon_class)

    ~H"""
    <.icon name="hero-exclamation-triangle" class={"h-4 w-4 #{@icon_class}"} />
    """
  end
end
```

### 2. Mobile Quick Actions Menu

```elixir
defmodule Shop1CmmsWeb.Components.MobileQuickActions do
  use Shop1CmmsWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="lg:hidden">
      <!-- Floating Action Button -->
      <button 
        phx-click="toggle_quick_menu"
        phx-target={@myself}
        class="fab no-tap-highlight touch-manipulation"
      >
        <.icon name={if @show_menu, do: "hero-x-mark", else: "hero-plus"} class="h-6 w-6" />
      </button>

      <!-- Quick actions menu -->
      <%= if @show_menu do %>
        <div class="fixed inset-0 z-40 pointer-events-none">
          <!-- Backdrop -->
          <div 
            class="absolute inset-0 bg-black bg-opacity-25 pointer-events-auto"
            phx-click="close_quick_menu"
            phx-target={@myself}
          ></div>

          <!-- Menu items -->
          <div class="absolute bottom-20 right-6 space-y-3 pointer-events-auto">
            <%= for action <- quick_actions_for_user(@current_user) do %>
              <div class="flex items-center">
                <span class="bg-gray-800 text-white px-3 py-1 rounded-lg text-sm mr-3 opacity-75">
                  <%= action.label %>
                </span>
                <.link 
                  navigate={action.path}
                  class="w-12 h-12 bg-white rounded-full shadow-lg flex items-center justify-center"
                  phx-click="close_quick_menu"
                  phx-target={@myself}
                >
                  <.icon name={action.icon} class="h-6 w-6 text-gray-700" />
                </.link>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("toggle_quick_menu", _, socket) do
    {:noreply, assign(socket, :show_menu, !socket.assigns.show_menu)}
  end

  def handle_event("close_quick_menu", _, socket) do
    {:noreply, assign(socket, :show_menu, false)}
  end

  defp quick_actions_for_user(user) do
    base_actions = [
      %{
        label: "Add Reading",
        icon: "hero-plus-circle",
        path: ~p"/meter-readings/quick"
      }
    ]

    role_actions = case user.role do
      "technician" ->
        [
          %{
            label: "My Work Orders",
            icon: "hero-clipboard-document-list",
            path: ~p"/work-orders?filter[assigned_to]=me"
          },
          %{
            label: "Start Timer",
            icon: "hero-clock",
            path: ~p"/time-tracking/start"
          }
        ]
      
      "operator" ->
        [
          %{
            label: "Report Issue",
            icon: "hero-exclamation-triangle",
            path: ~p"/work-requests/new"
          }
        ]
      
      _ ->
        [
          %{
            label: "New Work Order",
            icon: "hero-document-plus",
            path: ~p"/work-orders/new"
          }
        ]
    end

    base_actions ++ role_actions
  end
end
```

## Progressive Web App Setup

### 1. PWA Manifest (priv/static/manifest.json)

```json
{
  "name": "Shop1 CMMS",
  "short_name": "CMMS",
  "description": "Computerized Maintenance Management System",
  "start_url": "/dashboard",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#2563eb",
  "orientation": "portrait-primary",
  "categories": ["productivity", "business"],
  "icons": [
    {
      "src": "/images/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-96x96.png",
      "sizes": "96x96",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-128x128.png",
      "sizes": "128x128",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-144x144.png",
      "sizes": "144x144",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-152x152.png",
      "sizes": "152x152",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-384x384.png",
      "sizes": "384x384",
      "type": "image/png",
      "purpose": "maskable any"
    },
    {
      "src": "/images/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable any"
    }
  ],
  "screenshots": [
    {
      "src": "/images/screenshots/dashboard-mobile.png",
      "sizes": "390x844",
      "type": "image/png",
      "form_factor": "narrow"
    },
    {
      "src": "/images/screenshots/dashboard-desktop.png",
      "sizes": "1920x1080",
      "type": "image/png",
      "form_factor": "wide"
    }
  ]
}
```

### 2. Service Worker (priv/static/sw.js)

```javascript
const CACHE_NAME = 'shop1-cmms-v1.0.0';
const STATIC_CACHE_URLS = [
  '/',
  '/dashboard',
  '/css/app.css',
  '/js/app.js',
  '/images/icons/icon-192x192.png',
  '/manifest.json'
];

// Install event - cache static assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => {
        console.log('Caching static assets');
        return cache.addAll(STATIC_CACHE_URLS);
      })
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(cacheNames => {
      return Promise.all(
        cacheNames.map(cacheName => {
          if (cacheName !== CACHE_NAME) {
            console.log('Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - serve from cache when offline
self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);

  // Handle API requests with network-first strategy
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(
      fetch(request)
        .then(response => {
          // Clone and cache successful responses
          if (response.status === 200) {
            const responseClone = response.clone();
            caches.open(CACHE_NAME).then(cache => {
              cache.put(request, responseClone);
            });
          }
          return response;
        })
        .catch(() => {
          // Fallback to cache when network fails
          return caches.match(request);
        })
    );
    return;
  }

  // Handle LiveView socket requests
  if (url.pathname.includes('/live/websocket')) {
    // Don't cache WebSocket connections
    event.respondWith(fetch(request));
    return;
  }

  // Handle static assets and pages with cache-first strategy
  event.respondWith(
    caches.match(request)
      .then(response => {
        if (response) {
          return response;
        }
        
        return fetch(request).then(response => {
          // Don't cache non-successful responses
          if (!response || response.status !== 200 || response.type !== 'basic') {
            return response;
          }

          const responseToCache = response.clone();
          caches.open(CACHE_NAME).then(cache => {
            cache.put(request, responseToCache);
          });

          return response;
        });
      })
      .catch(() => {
        // Fallback for offline scenarios
        if (request.destination === 'document') {
          return caches.match('/dashboard');
        }
      })
  );
});

// Background sync for work order updates when back online
self.addEventListener('sync', event => {
  if (event.tag === 'work-order-sync') {
    event.waitUntil(syncWorkOrders());
  }
});

async function syncWorkOrders() {
  // Get pending work order updates from IndexedDB
  const pendingUpdates = await getPendingWorkOrderUpdates();
  
  for (const update of pendingUpdates) {
    try {
      await fetch('/api/work-orders/' + update.id, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(update.data)
      });
      
      // Remove from pending updates after successful sync
      await removePendingUpdate(update.id);
    } catch (error) {
      console.error('Failed to sync work order update:', error);
    }
  }
}

// Push notifications for urgent work orders
self.addEventListener('push', event => {
  if (event.data) {
    const data = event.data.json();
    
    const options = {
      body: data.body,
      icon: '/images/icons/icon-192x192.png',
      badge: '/images/icons/icon-72x72.png',
      tag: data.tag || 'cmms-notification',
      requireInteraction: data.urgent || false,
      actions: data.actions || [],
      data: data.url || '/dashboard'
    };

    event.waitUntil(
      self.registration.showNotification(data.title, options)
    );
  }
});

// Handle notification clicks
self.addEventListener('notificationclick', event => {
  event.notification.close();

  const url = event.notification.data || '/dashboard';
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then(clients => {
        // Check if app is already open
        for (const client of clients) {
          if (client.url.includes(url) && 'focus' in client) {
            return client.focus();
          }
        }
        
        // Open new window if app not already open
        if (clients.openWindow) {
          return clients.openWindow(url);
        }
      })
  );
});
```

### 3. PWA Registration Script (assets/js/pwa.js)

```javascript
// PWA registration and mobile optimizations
class PWAManager {
  constructor() {
    this.isStandalone = window.matchMedia('(display-mode: standalone)').matches;
    this.init();
  }

  init() {
    this.registerServiceWorker();
    this.setupBeforeInstallPrompt();
    this.setupMobileOptimizations();
    this.setupOfflineDetection();
  }

  async registerServiceWorker() {
    if ('serviceWorker' in navigator) {
      try {
        const registration = await navigator.serviceWorker.register('/sw.js');
        console.log('Service Worker registered:', registration);
        
        // Handle service worker updates
        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing;
          newWorker.addEventListener('statechange', () => {
            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
              this.showUpdateAvailableNotification();
            }
          });
        });
      } catch (error) {
        console.error('Service Worker registration failed:', error);
      }
    }
  }

  setupBeforeInstallPrompt() {
    let deferredPrompt;

    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      deferredPrompt = e;
      this.showInstallButton(deferredPrompt);
    });

    window.addEventListener('appinstalled', () => {
      console.log('PWA was installed');
      this.hideInstallButton();
    });
  }

  showInstallButton(deferredPrompt) {
    const installButton = document.getElementById('pwa-install-button');
    if (installButton) {
      installButton.style.display = 'block';
      installButton.addEventListener('click', async () => {
        deferredPrompt.prompt();
        const { outcome } = await deferredPrompt.userChoice;
        console.log(`User response to install prompt: ${outcome}`);
        deferredPrompt = null;
        this.hideInstallButton();
      });
    }
  }

  hideInstallButton() {
    const installButton = document.getElementById('pwa-install-button');
    if (installButton) {
      installButton.style.display = 'none';
    }
  }

  setupMobileOptimizations() {
    // Prevent zoom on input focus
    if (/iPhone|iPad|iPod|Android/i.test(navigator.userAgent)) {
      document.addEventListener('focusin', (e) => {
        if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
          this.preventZoom();
        }
      });

      document.addEventListener('focusout', () => {
        this.restoreZoom();
      });
    }

    // Setup swipe gestures for work order cards
    this.setupSwipeGestures();

    // Setup pull-to-refresh
    this.setupPullToRefresh();
  }

  preventZoom() {
    const viewport = document.querySelector('meta[name=viewport]');
    if (viewport) {
      viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
    }
  }

  restoreZoom() {
    const viewport = document.querySelector('meta[name=viewport]');
    if (viewport) {
      viewport.content = 'width=device-width, initial-scale=1.0';
    }
  }

  setupSwipeGestures() {
    let startX, startY, currentX, currentY;

    document.addEventListener('touchstart', (e) => {
      const card = e.target.closest('.swipe-container');
      if (!card) return;

      startX = e.touches[0].clientX;
      startY = e.touches[0].clientY;
    });

    document.addEventListener('touchmove', (e) => {
      const card = e.target.closest('.swipe-container');
      if (!card || !startX) return;

      currentX = e.touches[0].clientX;
      currentY = e.touches[0].clientY;

      const diffX = startX - currentX;
      const diffY = startY - currentY;

      // Only handle horizontal swipes
      if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 10) {
        e.preventDefault();
        
        if (diffX > 50) {
          // Swipe left - show actions
          card.classList.add('swiped');
        } else {
          // Swipe right - hide actions
          card.classList.remove('swiped');
        }
      }
    });

    document.addEventListener('touchend', () => {
      startX = null;
      startY = null;
    });
  }

  setupPullToRefresh() {
    let startY, currentY, pullThreshold = 100;

    document.addEventListener('touchstart', (e) => {
      if (window.scrollY === 0) {
        startY = e.touches[0].clientY;
      }
    });

    document.addEventListener('touchmove', (e) => {
      if (!startY) return;

      currentY = e.touches[0].clientY;
      const pullDistance = currentY - startY;

      if (pullDistance > 0 && window.scrollY === 0) {
        e.preventDefault();
        
        if (pullDistance > pullThreshold) {
          this.showPullToRefreshIndicator();
        }
      }
    });

    document.addEventListener('touchend', () => {
      if (startY && currentY) {
        const pullDistance = currentY - startY;
        
        if (pullDistance > pullThreshold) {
          this.triggerRefresh();
        }
      }
      
      this.hidePullToRefreshIndicator();
      startY = null;
      currentY = null;
    });
  }

  showPullToRefreshIndicator() {
    // Show loading indicator
    console.log('Show refresh indicator');
  }

  hidePullToRefreshIndicator() {
    // Hide loading indicator
    console.log('Hide refresh indicator');
  }

  triggerRefresh() {
    // Trigger page refresh or data reload
    window.location.reload();
  }

  setupOfflineDetection() {
    window.addEventListener('online', () => {
      this.showConnectionStatus('online');
      this.syncOfflineData();
    });

    window.addEventListener('offline', () => {
      this.showConnectionStatus('offline');
    });
  }

  showConnectionStatus(status) {
    const statusBar = document.getElementById('connection-status');
    if (statusBar) {
      statusBar.textContent = status === 'online' ? 'Back online' : 'You are offline';
      statusBar.className = status === 'online' ? 'alert-success' : 'alert-warning';
      statusBar.style.display = 'block';
      
      if (status === 'online') {
        setTimeout(() => {
          statusBar.style.display = 'none';
        }, 3000);
      }
    }
  }

  async syncOfflineData() {
    // Trigger background sync for any pending data
    if ('serviceWorker' in navigator && 'sync' in window.ServiceWorkerRegistration.prototype) {
      const registration = await navigator.serviceWorker.ready;
      await registration.sync.register('work-order-sync');
    }
  }

  showUpdateAvailableNotification() {
    const notification = document.createElement('div');
    notification.innerHTML = `
      <div class="fixed top-4 left-4 right-4 bg-blue-600 text-white p-4 rounded-lg shadow-lg z-50">
        <p>A new version is available!</p>
        <button onclick="window.location.reload()" class="mt-2 bg-white text-blue-600 px-4 py-2 rounded">
          Update Now
        </button>
      </div>
    `;
    document.body.appendChild(notification);
  }
}

// Initialize PWA manager when DOM is loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => new PWAManager());
} else {
  new PWAManager();
}
```

### 4. Layout Updates for PWA (lib/shop1_cmms_web/components/layouts/app.html.heex)

```heex
<!DOCTYPE html>
<html lang="en" class="[scrollbar-gutter:stable]">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="csrf-token" content={get_csrf_token()} />
    
    <!-- PWA Meta Tags -->
    <meta name="application-name" content="Shop1 CMMS" />
    <meta name="apple-mobile-web-app-capable" content="yes" />
    <meta name="apple-mobile-web-app-status-bar-style" content="default" />
    <meta name="apple-mobile-web-app-title" content="CMMS" />
    <meta name="mobile-web-app-capable" content="yes" />
    <meta name="theme-color" content="#2563eb" />
    
    <!-- Apple Touch Icons -->
    <link rel="apple-touch-icon" sizes="152x152" href={~p"/images/icons/icon-152x152.png"} />
    <link rel="apple-touch-icon" sizes="144x144" href={~p"/images/icons/icon-144x144.png"} />
    
    <!-- PWA Manifest -->
    <link rel="manifest" href={~p"/manifest.json"} />
    
    <.live_title suffix=" · Shop1 CMMS">
      <%= assigns[:page_title] || "Dashboard" %>
    </.live_title>
    
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
    <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
    <script defer phx-track-static type="text/javascript" src={~p"/assets/pwa.js"}></script>
  </head>
  
  <body class="bg-gray-50 antialiased safe-area-inset">
    <!-- Connection Status Bar -->
    <div id="connection-status" class="hidden fixed top-0 left-0 right-0 z-50 p-2 text-center text-sm font-medium"></div>
    
    <!-- PWA Install Button -->
    <button 
      id="pwa-install-button" 
      class="hidden fixed top-4 right-4 z-50 bg-blue-600 text-white px-4 py-2 rounded-lg shadow-lg text-sm"
    >
      Install App
    </button>
    
    <!-- Main App Container -->
    <div class="app-container">
      <%= @inner_content %>
    </div>
    
    <!-- Mobile Quick Actions -->
    <.live_component 
      module={Shop1CmmsWeb.Components.MobileQuickActions}
      id="mobile-quick-actions"
      current_user={assigns[:current_user]}
    />
  </body>
</html>
```

This mobile-responsive design and PWA foundation provides:

**Mobile Optimizations:**
- Touch-friendly interface with 44px minimum touch targets
- Swipe gestures for quick actions
- Pull-to-refresh functionality
- Responsive layouts optimized for mobile screens
- Floating action buttons for quick access

**PWA Features:**
- Service worker for offline functionality
- App manifest for installation
- Background sync for data when back online
- Push notifications for urgent work orders
- Standalone app experience

**Technician-Focused Features:**
- Quick access to assigned work orders
- One-tap actions for common tasks
- Offline capability for field work
- Fast loading and smooth interactions

This foundation prepares the system for future native mobile app development while providing an excellent mobile web experience immediately.
