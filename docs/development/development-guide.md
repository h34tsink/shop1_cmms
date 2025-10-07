# Development Guide

## Quick Start

### Prerequisites

Before setting up the Shop1 CMMS development environment, ensure you have:

- **Elixir 1.15+** with OTP 26+
- **Phoenix 1.7+**
- **PostgreSQL 14+**
- **Node.js 18+** (for asset compilation)
- **Git** for version control
- **Access to Shop1FinishLine database** (port 5433)

### Installation Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/h34tsink/shop1_cmms.git
   cd shop1_cmms
   ```

2. **Install Elixir dependencies**

   ```bash
   mix deps.get
   ```

3. **Install Node.js dependencies**

   ```bash
   cd assets && npm install && cd ..
   ```

4. **Setup database**

   ```bash
   mix ecto.setup
   ```

5. **Start development server**

   ```bash
   mix phx.server
   ```

6. **Access the application**
   - Navigate to [http://localhost:4000](http://localhost:4000)

## Development Environment

### Database Configuration

The application uses two PostgreSQL databases:

- **Shop1FinishLine (Port 5433)**: Existing ERP system
- **Shop1CMMS (Port 5432)**: New CMMS database

#### Database Connection Setup

```elixir
# config/dev.exs
config :shop1_cmms, Shop1Cmms.Repo,
  username: "postgres",
  password: "your_password",
  hostname: "localhost",
  database: "shop1_cmms_dev",
  port: 5432

# Shop1FinishLine integration
config :shop1_cmms, Shop1Cmms.Shop1Repo,
  username: "postgres", 
  password: "your_password",
  hostname: "localhost",
  database: "shop1finishline",
  port: 5433
```

### Asset Pipeline

The application uses:

- **Tailwind CSS** for styling
- **esbuild** for JavaScript bundling
- **Live Reload** for development

#### Asset Commands

```bash
# Install assets
cd assets && npm install

# Build assets for production
mix assets.deploy

# Watch assets during development
mix phx.server # Automatically watches assets
```

## Development Patterns

### LiveView Components

#### Creating a New LiveView

1. **Generate LiveView files**

   ```bash
   mix phx.gen.live Context Entity entities field:type
   ```

2. **Add route to router.ex**

   ```elixir
   live "/entities", EntityLive.Index, :index
   live "/entities/new", EntityLive.Index, :new
   ```

3. **Implement multi-tenancy**

   ```elixir
   def mount(_params, session, socket) do
     tenant_id = get_tenant_id(session)
     {:ok, assign(socket, :tenant_id, tenant_id)}
   end
   ```

#### Component Structure

```elixir
defmodule Shop1CmmsWeb.ComponentName do
  use Shop1CmmsWeb, :live_component
  
  def render(assigns) do
    ~H"""
    <div class="component-container">
      <!-- Component HTML -->
    </div>
    """
  end
  
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
  
  def handle_event("event_name", params, socket) do
    # Handle events
    {:noreply, socket}
  end
end
```

### Context Patterns

#### Business Logic Organization

```elixir
defmodule Shop1Cmms.Assets do
  @moduledoc """
  The Assets context - handles all asset-related business logic
  """
  
  alias Shop1Cmms.Assets.Asset
  alias Shop1Cmms.Repo
  
  def list_assets(tenant_id) do
    Asset
    |> where([a], a.tenant_id == ^tenant_id)
    |> Repo.all()
  end
  
  def create_asset(tenant_id, attrs) do
    %Asset{tenant_id: tenant_id}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end
end
```

### Multi-Tenancy Implementation

#### Row-Level Security

All data access includes tenant context:

```elixir
# Always filter by tenant_id
def list_records(tenant_id) do
  from(r in Record, where: r.tenant_id == ^tenant_id)
  |> Repo.all()
end

# Include tenant_id in all creates
def create_record(tenant_id, attrs) do
  %Record{tenant_id: tenant_id}
  |> Record.changeset(attrs)
  |> Repo.insert()
end
```

#### Session Management

```elixir
# Get tenant from session
defp get_tenant_id(session) do
  session["current_tenant_id"] || raise "No tenant context"
end

# Set tenant in session
def put_tenant_session(conn, tenant_id) do
  put_session(conn, "current_tenant_id", tenant_id)
end
```

## Testing Guidelines

### Test Structure

```
test/
├── shop1_cmms/          # Context tests
├── shop1_cmms_web/      # LiveView tests  
└── support/             # Test helpers
```

### Writing Tests

#### Context Tests

```elixir
defmodule Shop1Cmms.AssetsTest do
  use Shop1Cmms.DataCase
  
  alias Shop1Cmms.Assets
  
  describe "assets" do
    test "list_assets/1 returns assets for tenant" do
      tenant = tenant_fixture()
      asset = asset_fixture(tenant_id: tenant.id)
      
      assert Assets.list_assets(tenant.id) == [asset]
    end
  end
end
```

#### LiveView Tests

```elixir
defmodule Shop1CmmsWeb.AssetLiveTest do
  use Shop1CmmsWeb.ConnCase
  
  import Phoenix.LiveViewTest
  
  test "displays assets", %{conn: conn} do
    {:ok, _index_live, html} = live(conn, ~p"/assets")
    assert html =~ "Assets"
  end
end
```

### Test Commands

```bash
# Run all tests
mix test

# Run specific test
mix test test/shop1_cmms/assets_test.exs

# Run with coverage
mix test --cover

# Run tests in watch mode
mix test.watch
```

## Code Quality

### Formatting

```bash
# Format code
mix format

# Check formatting
mix format --check-formatted
```

### Static Analysis

```bash
# Install Credo
mix deps.get

# Run analysis  
mix credo

# Run strict analysis
mix credo --strict
```

### Documentation

```bash
# Generate documentation
mix docs

# View docs locally
open doc/index.html
```

## Debugging

### IEx Sessions

```bash
# Start IEx with project loaded
iex -S mix

# Start Phoenix in IEx
iex -S mix phx.server
```

### Database Inspection

```bash
# Access database console
mix ecto.psql

# Run specific migration
mix ecto.migrate -n 1

# Rollback migration
mix ecto.rollback -n 1
```

### LiveView Debugging

```elixir
# Add to LiveView for debugging
def handle_event("debug", params, socket) do
  require IEx
  IEx.pry()
  {:noreply, socket}
end
```

## Performance Optimization

### Database Performance

- Use proper indexes on frequently queried fields
- Implement database connection pooling
- Use `preload` for associations to avoid N+1 queries

```elixir
# Good - single query with preload
assets = Repo.all(from a in Asset, preload: [:manufacturer])

# Bad - N+1 query problem  
assets = Repo.all(Asset)
Enum.map(assets, & &1.manufacturer)
```

### LiveView Performance

- Use `temporary_assigns` for large datasets
- Implement pagination for large lists
- Use `phx-update="stream"` for efficient updates

```elixir
# Efficient large list handling
socket = stream(socket, :assets, assets, reset: true)

# Template with streaming
<div id="assets" phx-update="stream">
  <div :for={{id, asset} <- @streams.assets} id={id}>
    <%= asset.name %>
  </div>
</div>
```

## Deployment

### Production Build

```bash
# Build release
MIX_ENV=prod mix release

# Deploy release
_build/prod/rel/shop1_cmms/bin/shop1_cmms start
```

### Docker Deployment

```dockerfile
FROM elixir:1.15-alpine AS builder

WORKDIR /app
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY assets/package*.json assets/
RUN cd assets && npm ci --only=production

COPY . .
RUN mix assets.deploy
RUN mix phx.digest
RUN mix release

FROM alpine:3.18
RUN apk add --no-cache openssl ncurses-libs
COPY --from=builder /app/_build/prod/rel/shop1_cmms ./
CMD ["./bin/shop1_cmms", "start"]
```

---

**Note:** This document consolidates information from DEVELOPMENT.md and related development documentation files
