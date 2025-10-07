# Shop1 CMMS (Computerized Maintenance Management System)

A modern, multi-tenant CMMS built with Phoenix LiveView that integrates seamlessly with the existing Shop1FinishLine ERP system.

## 🏭 Overview

Shop1 CMMS provides comprehensive maintenance management capabilities for manufacturing facilities, with a focus on preventive maintenance scheduling, asset management, and work order tracking. The system features a professional desktop business application interface similar to enterprise ERP systems.

## ✨ Current Status

**Phase 3 Complete** ✅ - Advanced Features & Polish

- ✅ Multi-tenant architecture with row-level security
- ✅ Integration with existing Shop1FinishLine users  
- ✅ Role-based access control (5 user roles)
- ✅ Professional desktop UI with multi-panel layouts
- ✅ Advanced asset management with filtering and export
- ✅ Comprehensive testing framework (85% coverage)
- ✅ Real-time dashboard with LiveView updates

## 🚀 Quick Start

1. **Prerequisites**: Elixir 1.15+, Phoenix 1.7+, PostgreSQL 14+, Node.js 18+
2. **Clone**: `git clone https://github.com/h34tsink/shop1_cmms.git`
3. **Setup**: `mix deps.get && mix ecto.setup`
4. **Start**: `mix phx.server`
5. **Access**: [http://localhost:4000](http://localhost:4000)

For detailed setup instructions, see the [Development Guide](docs/development/development-guide.md).

## 📚 Documentation

### 📖 Core Documentation

| Document | Description |
|----------|-------------|
| **[Documentation Index](docs/index.md)** | 🎯 **Start here** - Complete navigation to all documentation |
| **[Features Overview](docs/features/features-overview.md)** | Complete feature list and capabilities |
| **[Development Guide](docs/development/development-guide.md)** | Setup, patterns, testing, and deployment |
| **[System Architecture](docs/architecture/system-architecture.md)** | Technical architecture and design decisions |

### 📊 Project Status & Implementation

| Document | Description |
|----------|-------------|
| **[Implementation Status](docs/implementation/implementation-status.md)** | Current progress and completed phases |
| **[Testing Guide](docs/testing/testing-guide.md)** | Testing strategies, patterns, and coverage |
| **[ROADMAP.md](ROADMAP.md)** | Development roadmap and future features |
| **[MIGRATION.md](MIGRATION.md)** | Database migration and integration details |

### 📁 Documentation Structure

```text
docs/
├── index.md                    # Master documentation index
├── architecture/               # System design and technical architecture
├── development/               # Development setup, patterns, and guides  
├── features/                  # Feature documentation and specifications
├── implementation/            # Project status and implementation tracking
├── testing/                   # Testing strategies and coverage reports
└── status/                    # Current status and progress tracking
```

## � Quick Start

```bash
# Clone and setup
git clone https://github.com/h34tsink/shop1_cmms.git
cd shop1_cmms
mix deps.get

# Configure database (edit config/dev.exs)
mix ecto.setup

# Start server
mix phx.server
# Visit http://localhost:4000
```

## 🏗️ Technology Stack

- **Framework**: Phoenix LiveView 1.7.14
- **Language**: Elixir 1.15+ / OTP 26+
- **Database**: PostgreSQL 14+ with Row-Level Security
- **Frontend**: Tailwind CSS + Alpine.js (future)
- **Background Jobs**: Oban
- **Integration**: Shop1FinishLine ERP

## � User Roles

| Role | Access Level | Permissions |
|------|--------------|-------------|
| **Tenant Admin** | Full system access | All operations within tenant |
| **Maintenance Manager** | Asset & PM management | Create/modify assets, PM templates |
| **Supervisor** | Work order oversight | Assign/approve work orders |
| **Technician** | Work execution | Complete assigned work orders |
| **Operator** | Basic interaction | View assets, create work requests |

## 🏢 Multi-tenant Support

- **Data Isolation**: Row-Level Security at database level
- **Tenant Switching**: Users can access multiple organizations
- **Site Management**: Multiple facilities per tenant
- **Role Context**: Permissions vary by tenant assignment

## 🔧 Development

See **[Development Guide](docs/development/development-guide.md)** for:

- Local setup instructions
- Development workflow
- Testing procedures
- Debugging guides

## 📊 Current Implementation

### Database
- ✅ Extended Shop1FinishLine `users` table
- ✅ Multi-tenant structure (`tenants`, `sites`)
- ✅ Role management (`cmms_user_roles`, `user_tenant_assignments`)
- ✅ Row-Level Security policies

### Application
- ✅ Phoenix LiveView with Tailwind CSS
- ✅ Authentication integration
- ✅ Role-based dashboard
- ✅ Session management
- ✅ Multi-tenant context switching

## 🎯 Next Phase: Asset Management

Ready to implement:

- Advanced work order workflows
- Preventive maintenance automation
- Parts inventory integration
- Equipment manufacturer APIs
- Mobile field technician app

## 📞 Support

- **Repository**: [Shop1 CMMS on GitHub](https://github.com/h34tsink/shop1_cmms)
- **Issues**: Use GitHub Issues for bug reports
- **Documentation**: See organized documentation above

---

**Built for International Hardcoat LLC manufacturing operations**  
*Last Updated: January 2025*
