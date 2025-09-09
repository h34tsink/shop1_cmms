# Shop1 CMMS (Computerized Maintenance Management System)

A modern, multi-tenant CMMS built with ## 📞 Support

- **Repository**: [Shop1 CMMS on GitHub](https://github.com/h34tsink/shop1_cmms)
- **Issues**: Use GitHub Issues for bug reports
- **Documentation**: See linked documentation files aboveix LiveView that integrates seamlessly with the existing Shop1FinishLine ERP system.

## 🏭 Overview

Shop1 CMMS provides comprehensive maintenance management capabilities for manufacturing facilities, with a focus on preventive maintenance scheduling, asset management, and work order tracking.

## ✨ Current Status

**Phase 1 Complete** ✅ - Foundation and Authentication
- Multi-tenant architecture with row-level security
- Integration with existing Shop1FinishLine users
- Role-based access control (5 user roles)
- Responsive dashboard with Phoenix LiveView
- Secure authentication and session management

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[ROADMAP.md](ROADMAP.md)** | Development phases and feature timeline |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | Technical architecture and design decisions |
| **[DEVELOPMENT.md](DEVELOPMENT.md)** | Setup guide and development workflow |
| **[MIGRATION.md](MIGRATION.md)** | Database migration details and verification |

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

See **[DEVELOPMENT.md](DEVELOPMENT.md)** for:
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
- Asset hierarchy and categorization
- Equipment specifications
- Meter readings and monitoring
- QR code generation
- Asset search and filtering

## � Support

- **Repository**: https://github.com/h34tsink/shop1_cmms
- **Issues**: Use GitHub Issues for bug reports
- **Documentation**: See linked documentation files above

---

**Built for International Hardcoat LLC manufacturing operations**  
*Last Updated: September 9, 2025*
