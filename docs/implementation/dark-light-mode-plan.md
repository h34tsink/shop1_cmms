# Dark/Light Mode Implementation Plan

## Overview

This document outlines the comprehensive plan for implementing a theme switching system in Shop1 CMMS, allowing users to toggle between light and dark modes with proper contrast and accessibility.

## Phase 1: Improved Light Mode Contrast ✅ IN PROGRESS

### Objectives
- Reduce eye strain from pure white backgrounds
- Increase border and text contrast
- Make UI elements more distinguishable

### Changes Implemented
1. **Table Headers**: Changed from `#f3f4f6` to `#e5e7eb` (darker)
2. **Table Borders**: Changed from `#d1d5db` to `#9ca3af` (stronger)
3. **Table Text**: Changed from `#374151` to `#1f2937` (darker)
4. **Even Row Backgrounds**: Changed from `#f9fafb` to `#f3f4f6` (more distinct)
5. **Form Inputs**: Added `#f9fafb` background, stronger `#9ca3af` borders
6. **Buttons**: Changed from white to `#f3f4f6` background
7. **Panels**: Changed from white to `#f9fafb` background
8. **Context Menus**: Updated backgrounds and borders

### Color Scheme Changes
```css
/* Before (Too Light) */
background: white (#ffffff)
borders: #d1d5db, #e5e7eb
text: #374151

/* After (Better Contrast) */
background: #f9fafb, #f3f4f6
borders: #9ca3af, #6b7280
text: #1f2937, #111827
```

## Phase 2: Design Color System for Themes

### Semantic Color Variables

Create a comprehensive color system using CSS custom properties that work for both themes:

```css
:root {
  /* Light Mode (Default) */
  --color-background: #f3f4f6;
  --color-surface: #f9fafb;
  --color-surface-elevated: #ffffff;
  
  --color-border: #9ca3af;
  --color-border-light: #d1d5db;
  --color-border-strong: #6b7280;
  
  --color-text-primary: #111827;
  --color-text-secondary: #1f2937;
  --color-text-tertiary: #4b5563;
  --color-text-muted: #6b7280;
  
  --color-primary: #2563eb;
  --color-primary-hover: #1d4ed8;
  --color-primary-light: #dbeafe;
  
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #3b82f6;
  
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.1);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1);
}

[data-theme="dark"] {
  /* Dark Mode */
  --color-background: #111827;
  --color-surface: #1f2937;
  --color-surface-elevated: #374151;
  
  --color-border: #4b5563;
  --color-border-light: #374151;
  --color-border-strong: #6b7280;
  
  --color-text-primary: #f9fafb;
  --color-text-secondary: #e5e7eb;
  --color-text-tertiary: #d1d5db;
  --color-text-muted: #9ca3af;
  
  --color-primary: #3b82f6;
  --color-primary-hover: #60a5fa;
  --color-primary-light: #1e3a8a;
  
  --color-success: #34d399;
  --color-warning: #fbbf24;
  --color-error: #f87171;
  --color-info: #60a5fa;
  
  --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.3);
  --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.5);
  --shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.7);
}
```

### Tailwind Configuration Extension

```javascript
// tailwind.config.js
module.exports = {
  darkMode: 'class', // Use class-based dark mode
  theme: {
    extend: {
      colors: {
        // Theme-aware colors
        background: 'var(--color-background)',
        surface: 'var(--color-surface)',
        'surface-elevated': 'var(--color-surface-elevated)',
        
        border: {
          DEFAULT: 'var(--color-border)',
          light: 'var(--color-border-light)',
          strong: 'var(--color-border-strong)',
        },
        
        text: {
          primary: 'var(--color-text-primary)',
          secondary: 'var(--color-text-secondary)',
          tertiary: 'var(--color-text-tertiary)',
          muted: 'var(--color-text-muted)',
        },
      },
    },
  },
}
```

## Phase 3: Implement Theme Toggle Mechanism

### Backend: User Preference Storage

#### 1. Database Schema Update

```sql
-- Add theme preference to users table
ALTER TABLE users ADD COLUMN theme_preference VARCHAR(10) DEFAULT 'light';
-- Values: 'light', 'dark', 'auto' (follows system)

-- Create index for better query performance
CREATE INDEX idx_users_theme_preference ON users(theme_preference);
```

#### 2. Context Function

```elixir
# lib/shop1_cmms/accounts.ex
def update_user_theme(user, theme) when theme in ["light", "dark", "auto"] do
  user
  |> User.changeset(%{theme_preference: theme})
  |> Repo.update()
end

def get_user_theme(user) do
  user.theme_preference || "light"
end
```

### Frontend: Theme Toggle Component

#### 1. Create Theme Toggle LiveComponent

```elixir
# lib/shop1_cmms_web/components/theme_toggle.ex
defmodule Shop1CmmsWeb.Components.ThemeToggle do
  use Shop1CmmsWeb, :live_component
  
  def render(assigns) do
    ~H"""
    <button
      phx-click="toggle_theme"
      phx-target={@myself}
      class="btn-toolbar flex items-center gap-2"
      title="Toggle theme"
    >
      <%= if @current_theme == "dark" do %>
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
            d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
        <span class="text-xs">Light</span>
      <% else %>
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
            d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
        </svg>
        <span class="text-xs">Dark</span>
      <% end %>
    </button>
    """
  end
  
  def handle_event("toggle_theme", _params, socket) do
    current_theme = socket.assigns.current_theme
    new_theme = if current_theme == "dark", do: "light", else: "dark"
    
    # Update user preference in database
    Shop1Cmms.Accounts.update_user_theme(socket.assigns.current_user, new_theme)
    
    # Update session
    send(self(), {:update_theme, new_theme})
    
    {:noreply, assign(socket, :current_theme, new_theme)}
  end
end
```

#### 2. Add to Root Layout

```heex
<!-- lib/shop1_cmms_web/components/layouts/app.html.heex -->
<div class="toolbar-actions">
  <.live_component 
    module={Shop1CmmsWeb.Components.ThemeToggle}
    id="theme-toggle"
    current_theme={@current_theme}
    current_user={@current_user}
  />
</div>
```

#### 3. JavaScript for Theme Application

```javascript
// assets/js/app.js

// Theme management
const ThemeManager = {
  getStoredTheme() {
    return localStorage.getItem('theme') || 'light';
  },
  
  setStoredTheme(theme) {
    localStorage.setItem('theme', theme);
  },
  
  applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    document.documentElement.classList.toggle('dark', theme === 'dark');
  },
  
  init() {
    // Apply theme on page load
    const theme = this.getStoredTheme();
    this.applyTheme(theme);
    
    // Listen for theme updates from LiveView
    window.addEventListener('phx:update_theme', (e) => {
      const newTheme = e.detail.theme;
      this.setStoredTheme(newTheme);
      this.applyTheme(newTheme);
    });
  }
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
  ThemeManager.init();
});
```

## Phase 4: Update CSS for Theme Support

### Convert Existing Styles to Use CSS Variables

```css
/* app.css - Example conversions */

/* Before */
.table-dense thead {
  background-color: #e5e7eb;
  border-bottom: 2px solid #9ca3af;
}

/* After */
.table-dense thead {
  background-color: var(--color-surface);
  border-bottom: 2px solid var(--color-border-strong);
}

/* Before */
.table-dense td {
  color: #111827;
}

/* After */
.table-dense td {
  color: var(--color-text-primary);
}
```

### Update All Component Styles

1. **Tables**: Use theme variables for all colors
2. **Forms**: Apply surface and border colors
3. **Buttons**: Use theme-aware states
4. **Panels**: Background and text colors
5. **Modals**: Overlays and backgrounds
6. **Sidebar**: Dark mode optimized
7. **Tooltips**: Proper contrast in both modes

## Phase 5: Apply Theme to All LiveView Pages

### Page-by-Page Updates

#### Dashboard
- Update KPI panels with theme variables
- Chart colors that work in both modes
- Status indicators with proper contrast

#### Assets Page
- Table styling with theme support
- Filter dropdowns with theme colors
- Action buttons with theme states

#### Work Orders Page
- Status badges with theme-aware colors
- Priority indicators with proper contrast
- Form fields with theme support

#### Asset Detail Page
- Tab navigation with theme colors
- Content panels with proper backgrounds
- Edit mode with theme-aware inputs

### Component Updates

```elixir
# Example: Status badge with theme support
def status_badge(assigns) do
  ~H"""
  <span class={[
    "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium",
    status_color_classes(@status)
  ]}>
    <%= @status %>
  </span>
  """
end

defp status_color_classes("Active") do
  "bg-success/10 text-success dark:bg-success/20"
end

defp status_color_classes("Inactive") do
  "bg-text-muted/10 text-text-muted dark:bg-text-muted/20"
end
```

## Phase 6: Testing and Refinement

### Accessibility Testing

#### WCAG Compliance
- **AA Standard Minimum**: 4.5:1 contrast ratio for normal text
- **AAA Standard Goal**: 7:1 contrast ratio for normal text
- **Large Text**: 3:1 minimum contrast ratio

#### Testing Tools
- Chrome DevTools Accessibility Panel
- WAVE Browser Extension
- axe DevTools
- Contrast Checker (WebAIM)

### Test Checklist

#### Visual Testing
- [ ] All pages render correctly in light mode
- [ ] All pages render correctly in dark mode
- [ ] Theme toggle works on all pages
- [ ] No color inconsistencies
- [ ] Smooth transitions between themes
- [ ] Icons visible in both modes
- [ ] Images have proper backgrounds

#### Functional Testing
- [ ] Theme preference persists after logout
- [ ] Theme syncs across browser tabs
- [ ] Theme preference saved to database
- [ ] LiveView updates apply theme correctly
- [ ] No JavaScript errors during theme switch
- [ ] Performance: <100ms theme switch time

#### Accessibility Testing
- [ ] All text meets WCAG AA contrast requirements
- [ ] Focus indicators visible in both modes
- [ ] Keyboard navigation works in both modes
- [ ] Screen reader announces theme changes
- [ ] Color is not the only indicator of state

#### Cross-Browser Testing
- [ ] Chrome/Edge (Chromium)
- [ ] Firefox
- [ ] Safari
- [ ] Mobile browsers (iOS Safari, Chrome Mobile)

### Performance Optimization

```css
/* Add smooth transitions */
* {
  transition: background-color 0.2s ease, 
              color 0.2s ease, 
              border-color 0.2s ease;
}

/* Reduce motion for users who prefer it */
@media (prefers-reduced-motion: reduce) {
  * {
    transition: none !important;
  }
}
```

## Implementation Timeline

### Week 1: Phase 1-2 ✅
- [x] Improve current light mode contrast
- [ ] Design complete color system
- [ ] Update Tailwind configuration

### Week 2: Phase 3
- [ ] Implement database schema changes
- [ ] Create theme toggle component
- [ ] Add JavaScript theme manager

### Week 3: Phase 4-5
- [ ] Convert all CSS to use variables
- [ ] Update all LiveView pages
- [ ] Update all components

### Week 4: Phase 6
- [ ] Comprehensive testing
- [ ] Fix accessibility issues
- [ ] Performance optimization
- [ ] Documentation and training

## Best Practices

### 1. Always Use Semantic Variables
```css
/* Good */
color: var(--color-text-primary);

/* Bad */
color: #111827;
```

### 2. Test Both Themes During Development
- Keep theme toggle easily accessible
- Test each feature in both modes
- Use browser DevTools to simulate

### 3. Consider Color-Blind Users
- Don't rely solely on color for information
- Use icons, labels, and patterns
- Test with color-blind simulators

### 4. Respect User Preferences
```javascript
// Auto-detect system preference
const systemPreference = window.matchMedia('(prefers-color-scheme: dark)').matches 
  ? 'dark' 
  : 'light';
```

### 5. Smooth Transitions
- Keep transitions subtle (200ms)
- Apply to all color properties
- Respect `prefers-reduced-motion`

## Future Enhancements

### Auto Theme Scheduling
- Automatic theme switching based on time of day
- Sunrise/sunset detection
- Custom schedule per user

### Theme Customization
- Allow users to customize accent colors
- High contrast mode option
- Font size adjustment

### Additional Themes
- "Midnight Blue" dark theme variant
- "Sepia" reduced blue light theme
- "High Contrast" accessibility theme

---

**Status**: Phase 1 In Progress  
**Last Updated**: January 2025  
**Next Review**: After Phase 1 completion