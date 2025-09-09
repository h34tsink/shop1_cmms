# Development Setup Guide

## 🚀 Quick Start

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
   cd assets
   npm install
   cd ..
   ```

4. **Configure database connection**
   ```bash
   cp config/dev.exs.example config/dev.exs
   # Edit config/dev.exs with your database credentials
   ```

5. **Verify database connection**
   ```bash
   mix ecto.setup
   ```

6. **Start the development server**
   ```bash
   mix phx.server
   ```

7. **Access the application**
   Open http://localhost:4000

## ⚙️ Configuration

### Database Configuration

Edit `config/dev.exs`:

```elixir
config :shop1_cmms, Shop1Cmms.Repo,
  username: "your_username",
  password: "your_password", 
  hostname: "localhost",
  port: 5433,
  database: "Shop1",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### Environment Variables

Create a `.env` file in the project root:

```bash
# Database
DATABASE_URL=ecto://user:pass@localhost:5433/Shop1

# Security
SECRET_KEY_BASE=your_secret_key_base_here
GUARDIAN_SECRET_KEY=your_guardian_secret_here

# CMMS Configuration
CMMS_DEFAULT_TENANT=1
CMMS_SESSION_TIMEOUT=28800
CMMS_MAX_UPLOAD_SIZE=10485760

# Development
PHX_HOST=localhost
PHX_PORT=4000
```

### Initial Data Setup

Run the setup script to create test data:

```bash
mix run priv/repo/seeds.exs
```

## 🧪 Testing

### Running Tests

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/shop1_cmms/accounts_test.exs

# Run tests in watch mode
mix test.watch
```

### Test Database Setup

```bash
# Create test database
MIX_ENV=test mix ecto.create

# Run test migrations
MIX_ENV=test mix ecto.migrate
```

## 🔧 Development Tools

### Code Quality

```bash
# Format code
mix format

# Check code quality
mix credo

# Type checking (if dialyzer is set up)
mix dialyzer

# Security analysis
mix sobelow
```

### Database Tools

```bash
# Generate migration
mix ecto.gen.migration add_new_feature

# Run migrations
mix ecto.migrate

# Rollback migrations
mix ecto.rollback

# Reset database
mix ecto.reset

# Database console
mix ecto.shell
```

### Phoenix Console

```bash
# Start IEx console
iex -S mix

# Start with Phoenix server
iex -S mix phx.server

# Useful console commands
iex> alias Shop1Cmms.{Accounts, Auth, Tenants}
iex> user = Accounts.get_user_by_username("admin")
iex> Auth.get_user_tenant_options(user)
```

## 🐛 Debugging

### LiveView Debugging

```elixir
# In your LiveView module
require Logger

def handle_event("debug", params, socket) do
  Logger.info("Debug params: #{inspect(params)}")
  Logger.info("Socket assigns: #{inspect(socket.assigns)}")
  {:noreply, socket}
end
```

### Database Query Debugging

```elixir
# In config/dev.exs
config :shop1_cmms, Shop1Cmms.Repo,
  log: :debug

# Or in IEx
import Ecto.Query
Ecto.Adapters.SQL.to_sql(:all, Shop1Cmms.Repo, query)
```

### Common Issues

1. **Database Connection Errors**
   - Check PostgreSQL is running on port 5433
   - Verify credentials in config/dev.exs
   - Test connection: `mix ecto.setup`

2. **Asset Compilation Issues**
   - Run `npm install` in assets directory
   - Check Node.js version (18+ required)
   - Clear compiled assets: `rm -rf _build/`

3. **LiveView Not Updating**
   - Check browser console for WebSocket errors
   - Verify CSRF token configuration
   - Restart server: `mix phx.server`

## 📁 Project Structure

```
shop1_cmms/
├── 📁 assets/                 # Frontend assets (CSS, JS)
├── 📁 config/                 # Configuration files
├── 📁 lib/
│   ├── 📁 shop1_cmms/         # Core business logic
│   └── 📁 shop1_cmms_web/     # Web interface
├── 📁 priv/
│   ├── 📁 repo/               # Database migrations
│   └── 📁 static/             # Static assets
├── 📁 test/                   # Test files
├── 📄 mix.exs                 # Project configuration
├── 📄 README.md               # Project overview
├── 📄 ROADMAP.md              # Development roadmap
└── 📄 ARCHITECTURE.md         # Technical architecture
```

## 🌐 Development Workflow

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/asset-management

# Make changes, commit regularly
git add .
git commit -m "feat: add asset hierarchy support"

# Push to remote
git push origin feature/asset-management

# Create pull request on GitHub
# After review and approval, merge to main
```

### Code Review Checklist

- [ ] Code follows Elixir conventions
- [ ] Tests added for new functionality
- [ ] Documentation updated
- [ ] Database migrations included
- [ ] Security considerations addressed
- [ ] Performance impact evaluated

### Release Process

```bash
# Create release branch
git checkout -b release/v1.1.0

# Update version numbers
# Update CHANGELOG.md
# Run full test suite

# Tag release
git tag v1.1.0
git push origin v1.1.0
```

## 🐳 Docker Development

### Using Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f web

# Run commands in container
docker-compose exec web mix test

# Stop services
docker-compose down
```

### Docker Configuration

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "4000:4000"
    environment:
      - DATABASE_URL=ecto://postgres:postgres@db:5432/shop1_cmms_dev
    depends_on:
      - db
    volumes:
      - .:/app

  db:
    image: postgres:14
    environment:
      - POSTGRES_DB=shop1_cmms_dev
      - POSTGRES_PASSWORD=postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## 🚀 Deployment

### Production Checklist

- [ ] Environment variables configured
- [ ] Database migrations run
- [ ] Assets compiled and optimized
- [ ] SSL certificates installed
- [ ] Monitoring configured
- [ ] Backup procedures tested

### Environment Configuration

```bash
# Production environment variables
export SECRET_KEY_BASE=$(mix phx.gen.secret)
export DATABASE_URL=ecto://user:pass@localhost/shop1_cmms_prod
export PHX_HOST=your-domain.com
export PORT=4000
```

### Health Checks

```bash
# Application health check
curl http://localhost:4000/health

# Database connection check
mix ecto.migrate --check

# Performance monitoring
mix telemetry.stats
```

---

*Development guide maintained by the CMMS Development Team*  
*Last Updated: September 9, 2025*
