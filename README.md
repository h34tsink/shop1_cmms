# Shop1 CMMS (Computerized Maintenance Management System)

A modern, multi-tenant CMMS built with Phoenix LiveView that integrates seamlessly with the existing Shop1FinishLine ERP system.

## 🏭 Overview

Shop1 CMMS provides comprehensive maintenance management capabilities for manufacturing facilities, with a focus on preventive maintenance scheduling, asset management, and work order tracking.

## ✨ Features

### Completed
- ✅ **Multi-tenant Architecture** - Support for multiple facilities/sites
- ✅ **User Integration** - Seamless integration with existing Shop1FinishLine users
- ✅ **Role-based Access Control** - Five user roles with granular permissions
- ✅ **Authentication System** - Secure login with existing credentials
- ✅ **Responsive Dashboard** - Modern UI with role-based navigation
- ✅ **Database Integration** - PostgreSQL with Row-Level Security

### Planned
- 🔄 **Asset Management** - Equipment tracking and hierarchies
- 🔄 **Preventive Maintenance** - PM templates and scheduling
- 🔄 **Work Order Management** - Creation, assignment, and tracking
- 🔄 **Inventory Management** - Parts and supplies tracking
- 🔄 **Reporting & Analytics** - Maintenance metrics and KPIs
- 🔄 **Mobile PWA** - Mobile-optimized interface

## 🏗️ Architecture

### Technology Stack
- **Backend**: Elixir/Phoenix LiveView
- **Database**: PostgreSQL 14+ with Row-Level Security
- **Frontend**: Phoenix LiveView + Tailwind CSS
- **Background Jobs**: Oban
- **Integration**: Shop1FinishLine ERP

### Multi-tenant Structure
```
International Hardcoat LLC (Tenant)
├── Burt Site
├── Glendale Site
└── [Additional Sites...]
```

### User Roles
- **Tenant Admin** - Full system access
- **Maintenance Manager** - Asset and PM management
- **Supervisor** - Work order assignment and approval
- **Technician** - Work order execution
- **Operator** - Basic asset interaction and work requests

## 🚀 Getting Started

### Prerequisites
- Elixir 1.15+
- Phoenix 1.7+
- PostgreSQL 14+
- Access to Shop1FinishLine database

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd shop1_cmms
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Configure database connection**
   Edit `config/dev.exs` and `config/prod.exs` with your Shop1 database credentials:
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

4. **Run database migrations** (if not already applied)
   ```bash
   mix ecto.migrate
   ```

5. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```

6. **Access the application**
   Navigate to `http://localhost:4000`

### Docker Setup (Optional)
```bash
docker-compose up -d
```

## 🔐 Authentication

The system integrates with existing Shop1FinishLine user accounts:

1. Users log in with their existing credentials
2. CMMS access must be enabled by an administrator
3. Users are assigned to tenants with specific roles
4. Session context is established for multi-tenant data isolation

### Enabling CMMS Access
```elixir
# In IEx console
alias Shop1Cmms.Auth
Auth.initialize_cmms_access("username", tenant_id, admin_user_id)
```

## 🏢 Multi-tenant Setup

### Adding a New Tenant
1. Access admin interface
2. Create new tenant with company information
3. Set up sites/facilities under the tenant
4. Assign users with appropriate roles

### Database Security
- Row-Level Security (RLS) ensures data isolation
- Session variables control data access
- Audit trails track all changes

## 📊 Database Schema

### Core Tables
- `users` - Extended Shop1FinishLine users table
- `tenants` - Company/organization entities
- `sites` - Physical locations within tenants
- `cmms_user_roles` - User role assignments
- `user_tenant_assignments` - User-tenant relationships

### Integration Tables
- Extends existing `users` table with CMMS-specific fields
- Maintains compatibility with Shop1FinishLine
- Uses foreign keys to existing structure

## 🔧 Development

### Running Tests
```bash
mix test
```

### Code Quality
```bash
mix format
mix credo
mix dialyzer
```

### Database Console
```bash
mix ecto.gen.migration migration_name
mix ecto.migrate
```

### Phoenix Console
```bash
iex -S mix phx.server
```

## 📝 Configuration

### Environment Variables
```bash
# Database
DATABASE_URL=ecto://user:pass@localhost:5433/Shop1

# Security
SECRET_KEY_BASE=your_secret_key_base
GUARDIAN_SECRET_KEY=your_guardian_secret

# CMMS Specific
CMMS_DEFAULT_TENANT=1
CMMS_SESSION_TIMEOUT=28800
```

### Application Configuration
Key configuration files:
- `config/config.exs` - Base configuration
- `config/dev.exs` - Development settings
- `config/prod.exs` - Production settings
- `config/runtime.exs` - Runtime configuration

## 🚦 Deployment

### Production Checklist
- [ ] Set up SSL certificates
- [ ] Configure database connection pooling
- [ ] Set environment variables
- [ ] Run database migrations
- [ ] Set up monitoring
- [ ] Configure backups

### Scaling Considerations
- Database connection pooling
- Background job processing with Oban
- Static asset serving
- Session storage for multi-node deployments

## 📈 Monitoring

### Health Checks
- Database connectivity
- Background job processing
- User session management
- Multi-tenant data isolation

### Metrics
- User login frequency
- Work order completion rates
- Asset maintenance schedules
- System performance

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

Copyright © 2025 International Hardcoat LLC. All rights reserved.

## 🆘 Support

For technical support or questions:
- Internal documentation: [Link to internal docs]
- Issue tracking: [Link to issue tracker]
- Contact: CMMS Development Team

---

**Built with ❤️ for International Hardcoat LLC manufacturing operations**
