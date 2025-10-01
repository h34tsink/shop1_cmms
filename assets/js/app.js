// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
// Import Alpine.js for interactive components
import Alpine from "alpinejs"
import collapse from '@alpinejs/collapse'

// Add Alpine collapse plugin
Alpine.plugin(collapse)

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken}
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#2563eb"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// Initialize Alpine.js after LiveView is ready
window.Alpine = Alpine

// Make sure Alpine.js reinitializes when LiveView patches DOM
window.addEventListener("phx:update", () => {
  Alpine.initTree(document.body)
})

// Start Alpine.js
Alpine.start()

// ============================================
// DESKTOP UI ENHANCEMENTS
// ============================================

// Global keyboard shortcuts
document.addEventListener('keydown', (e) => {
  // Ctrl+K or / for global search
  if ((e.ctrlKey && e.key === 'k') || (e.key === '/' && !isInputFocused())) {
    e.preventDefault()
    const searchInput = document.querySelector('#global-search')
    if (searchInput) {
      searchInput.focus()
      searchInput.select()
    }
  }
  
  // Escape to close modals and dropdowns
  if (e.key === 'Escape') {
    // Close any open dropdowns
    const dropdowns = document.querySelectorAll('[x-data]')
    dropdowns.forEach(el => {
      if (el.__x) {
        Object.keys(el.__x.$data).forEach(key => {
          if (key.includes('open') || key.includes('Open')) {
            el.__x.$data[key] = false
          }
        })
      }
    })
    
    // Close modals
    const closeButtons = document.querySelectorAll('[data-modal-close]')
    closeButtons.forEach(btn => btn.click())
  }
})

// Helper to check if an input is focused
function isInputFocused() {
  const activeElement = document.activeElement
  return activeElement && (
    activeElement.tagName === 'INPUT' ||
    activeElement.tagName === 'TEXTAREA' ||
    activeElement.tagName === 'SELECT' ||
    activeElement.isContentEditable
  )
}

// Auto-dismiss flash messages after 5 seconds
window.addEventListener('phx:page-loading-stop', () => {
  const alerts = document.querySelectorAll('[role="alert"]:not(.persist)')
  alerts.forEach(alert => {
    setTimeout(() => {
      alert.style.opacity = '0'
      alert.style.transition = 'opacity 0.3s'
      setTimeout(() => alert.remove(), 300)
    }, 5000)
  })
})

// Add loading class to forms on submit
document.addEventListener('submit', (e) => {
  const form = e.target
  const submitBtn = form.querySelector('[type="submit"]')
  if (submitBtn && !submitBtn.disabled) {
    submitBtn.disabled = true
    submitBtn.classList.add('opacity-50', 'cursor-not-allowed')
    
    // Re-enable after 3 seconds as fallback
    setTimeout(() => {
      submitBtn.disabled = false
      submitBtn.classList.remove('opacity-50', 'cursor-not-allowed')
    }, 3000)
  }
})

// Context menu support (right-click)
document.addEventListener('contextmenu', (e) => {
  const contextElement = e.target.closest('[data-context-menu]')
  if (!contextElement) return
  
  e.preventDefault()
  
  const menuType = contextElement.dataset.contextMenu
  const menuId = contextElement.dataset.contextId
  
  // Remove existing menus
  document.querySelectorAll('.context-menu').forEach(m => m.remove())
  
  // Create context menu
  const menu = document.createElement('div')
  menu.className = 'context-menu'
  menu.style.left = e.pageX + 'px'
  menu.style.top = e.pageY + 'px'
  
  // Build menu items based on type
  const items = getContextMenuItems(menuType, menuId)
  menu.innerHTML = items.map(item => `
    <div class="context-menu-item" data-action="${item.action}" data-id="${menuId}">
      ${item.icon}
      <span>${item.label}</span>
    </div>
  `).join('')
  
  document.body.appendChild(menu)
  
  // Close on click outside
  setTimeout(() => {
    document.addEventListener('click', () => menu.remove(), { once: true })
  }, 0)
  
  // Handle menu item clicks
  menu.querySelectorAll('.context-menu-item').forEach(item => {
    item.addEventListener('click', (e) => {
      const action = e.currentTarget.dataset.action
      const id = e.currentTarget.dataset.id
      
      // Trigger LiveView event
      const event = new CustomEvent('phx:context-menu-action', {
        detail: { action, id }
      })
      document.dispatchEvent(event)
      
      menu.remove()
    })
  })
})

function getContextMenuItems(type, id) {
  const icons = {
    edit: '<svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"></path></svg>',
    view: '<svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path d="M10 12a2 2 0 100-4 2 2 0 000 4z"></path><path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"></path></svg>',
    delete: '<svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd"></path></svg>',
    work: '<svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z"></path><path fill-rule="evenodd" d="M4 5a2 2 0 012-2 3 3 0 003 3h2a3 3 0 003-3 2 2 0 012 2v11a2 2 0 01-2 2H6a2 2 0 01-2-2V5zm3 4a1 1 0 000 2h.01a1 1 0 100-2H7zm3 0a1 1 0 000 2h3a1 1 0 100-2h-3z" clip-rule="evenodd"></path></svg>',
    history: '<svg class="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"></path></svg>',
  }
  
  if (type === 'asset') {
    return [
      { action: 'view_asset', label: 'View Details', icon: icons.view },
      { action: 'edit_asset', label: 'Edit Asset', icon: icons.edit },
      { action: 'create_wo', label: 'Create Work Order', icon: icons.work },
      { action: 'view_history', label: 'View History', icon: icons.history },
      { action: 'delete_asset', label: 'Delete', icon: icons.delete },
    ]
  }
  
  if (type === 'work_order') {
    return [
      { action: 'view_wo', label: 'View Details', icon: icons.view },
      { action: 'edit_wo', label: 'Edit', icon: icons.edit },
      { action: 'complete_wo', label: 'Mark Complete', icon: icons.work },
      { action: 'delete_wo', label: 'Delete', icon: icons.delete },
    ]
  }
  
  return []
}

// Smooth scroll for anchor links
document.addEventListener('click', (e) => {
  const link = e.target.closest('a[href^="#"]')
  if (!link) return
  
  const target = document.querySelector(link.getAttribute('href'))
  if (target) {
    e.preventDefault()
    target.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }
})
