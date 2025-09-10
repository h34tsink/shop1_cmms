# Shop1 CMMS - Development Notes & Requirements

## Project Overview
- **Framework**: Elixir/Phoenix 1.7.21 with LiveView
- **Database**: PostgreSQL with Row-Level Security (RLS)
- **Frontend**: Alpine.js 3.x + Tailwind CSS 3.3.0
- **Architecture**: Multi-tenant CMMS (Computerized Maintenance Management System)

## Database Schema Patterns

### Table Structure Conventions
- All tables use `bigserial` primary keys
- Timestamps use `timestamp` (not `timestamptz`) with columns named `inserted_at`, `updated_at`
- Multi-tenant isolation via `tenant_id` foreign keys
- Soft deletes using `is_active` boolean fields

### Key Schema Files
- **Sites**: `lib/shop1_cmms/tenants/site.ex`
- **Assets**: `lib/shop1_cmms/assets/asset.ex`
- **Asset Types**: `lib/shop1_cmms/assets/asset_type.ex`

### Site Schema Requirements
```elixir
schema "sites" do
  field :name, :string
  field :code, :string
  field :description, :string
  field :address, :string
  field :contact_email, :string
  field :contact_phone, :string
  field :timezone, :string
  field :settings, :map, default: %{}
  field :is_active, :boolean, default: true
  field :inserted_at, :naive_datetime
  field :updated_at, :naive_datetime
  
  belongs_to :tenant, Shop1Cmms.Tenants.Tenant
end
```

### Asset Schema Requirements
```elixir
# Required fields for Asset creation:
- asset_number (string, required)
- asset_type_id (bigint, required, references asset_types.id)
- name (string, required)
- tenant_id (bigint, required)

# Optional but commonly used:
- description, manufacturer, model, serial_number
- status (enum), criticality (enum)
- purchase_cost (decimal), current_value (decimal)
- purchase_date, commission_date, warranty_expiry (dates)
- location, site_id
```

### Asset Type Schema Requirements
```elixir
# Required fields:
- name (string, required)
- category (string, required, must be from allowed list)
- tenant_id (bigint, required)

# Allowed categories (from validation):
["equipment", "machinery", "tools", "infrastructure", "vehicles", "it_equipment", "other"]
```

## Phoenix LiveView Patterns

### Authentication & Authorization
- Session-based authentication with tenant access control
- User context set via PostgreSQL session variables (`app.current_user_id`, `app.current_tenant_id`)
- Multi-tenant access validation in pipelines

### LiveView Structure
```elixir
defmodule Shop1CmmsWeb.DashboardLive do
  use Shop1CmmsWeb, :live_view
  
  def mount(_params, session, socket) do
    # Always validate tenant access first
    # Set user context
    # Load dashboard data
  end
  
  def handle_event("event_name", params, socket) do
    # Handle user interactions
  end
end
```

## Frontend Integration

### Alpine.js Setup
- Install via npm: `cd assets && npm install alpinejs`
- Import in `assets/js/app.js`:
```javascript
import Alpine from "alpinejs"
window.Alpine = Alpine
Alpine.start()
```

### Alpine.js + LiveView Integration
```javascript
// Handle LiveView DOM updates
let liveSocket = new LiveSocket("/live", Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to)
      }
    }
  },
  params: {_csrf_token: csrfToken}
})
```

### Dropdown Component Pattern
```elixir
<div x-data="{ open: false }" @click.away="open = false" class="relative">
  <button @click="open = !open" class="flex items-center space-x-2">
    <!-- Button content -->
  </button>
  
  <div x-show="open" 
       x-transition:enter="transition ease-out duration-100"
       x-transition:enter-start="transform opacity-0 scale-95"
       x-transition:enter-end="transform opacity-100 scale-100"
       class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg">
    <!-- Dropdown content -->
  </div>
</div>
```

## Data Seeding Patterns

### Safe Seeding Script Structure
```elixir
alias Shop1Cmms.Repo
alias Shop1Cmms.Tenants.Site
alias Shop1Cmms.Assets.{Asset, AssetType}

# Always check for existing data first
existing_count = Repo.aggregate(AssetType, :count, :id)
if existing_count == 0 do
  # Create data
end

# Use changesets for validation
%AssetType{}
|> AssetType.changeset(attrs)
|> Repo.insert!()
```

### Required Asset Type Creation
```elixir
asset_types_data = [
  %{name: "CNC Machines", category: "machinery", tenant_id: 1},
  %{name: "Air Compressors", category: "equipment", tenant_id: 1},
  %{name: "Material Handling", category: "equipment", tenant_id: 1},
  %{name: "HVAC Systems", category: "infrastructure", tenant_id: 1},
  %{name: "Quality Control", category: "equipment", tenant_id: 1},
  %{name: "Power Generation", category: "infrastructure", tenant_id: 1}
]
```

## Common Issues & Solutions

### Database Schema Mismatches
- **Problem**: Schema expects `timestamps()` but DB has different column names
- **Solution**: Explicitly define timestamp fields in schema
```elixir
field :inserted_at, :naive_datetime
field :updated_at, :naive_datetime
# Instead of: timestamps(type: :utc_datetime)
```

### Asset Creation Validation Errors
- **Problem**: Missing required fields `asset_number`, `asset_type_id`
- **Solution**: Always create asset types first, then reference them in assets

### Alpine.js Integration Issues
- **Problem**: Components not working after LiveView updates
- **Solution**: Proper Alpine.js integration with DOM update handling

## Development Workflow

### Running the Application
```bash
# Start Phoenix server
mix phx.server

# Run migrations
mix ecto.migrate

# Run seeds
mix run priv/repo/seeds.exs
```

### Asset Pipeline
```bash
# Install frontend dependencies
cd assets && npm install

# For Alpine.js specifically
cd assets && npm install alpinejs
```

### Testing Database Queries
```elixir
# In seeds or console
alias Shop1Cmms.Repo
alias Shop1Cmms.Assets.AssetType

# Check existing data
AssetType |> Repo.all() |> length()

# Query with conditions
AssetType |> where([at], at.tenant_id == 1) |> Repo.all()
```

## File Structure Conventions

### LiveView Files
- `lib/shop1_cmms_web/live/` - LiveView modules
- `lib/shop1_cmms_web/live/dashboard_live.ex` - Main dashboard

### Schema Files
- `lib/shop1_cmms/assets/` - Asset-related schemas
- `lib/shop1_cmms/tenants/` - Tenant/site schemas
- `lib/shop1_cmms/accounts/` - User management schemas

### Migration Files
- `priv/repo/migrations/` - Database migrations
- Use descriptive names with timestamps

### Seed Files
- `priv/repo/seeds.exs` - Main seeds file
- `priv/repo/seeds_*.exs` - Specific seed files

## Next Steps for Page Development

### Assets Management Page
1. Create `AssetsLive` module
2. Implement asset listing with search/filter
3. Add asset creation/editing forms
4. Include asset status management

### Maintenance Module
1. Work order creation/management
2. Maintenance scheduling
3. PM (Preventive Maintenance) tracking

### Inventory Management
1. Parts tracking
2. Stock management
3. Purchase order integration

Remember: Always validate tenant access, use proper changesets, and maintain consistent UI patterns with Alpine.js + Tailwind CSS.
