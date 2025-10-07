# Shop1 CMMS Architecture Documentation

## 🏗️ System Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Frontend Layer                       │
├─────────────────────────────────────────────────────────────┤
│  Phoenix LiveView  │  Tailwind CSS  │  Alpine.js (Future)   │
├─────────────────────────────────────────────────────────────┤
│                     Application Layer                       │
├─────────────────────────────────────────────────────────────┤
│    Contexts    │   LiveViews   │  Controllers  │   Auth     │
├─────────────────────────────────────────────────────────────┤
│                      Database Layer                         │
├─────────────────────────────────────────────────────────────┤
│  PostgreSQL 14+  │  Row-Level Security  │  Shop1 Integration│
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Design Principles

### 1. Multi-Tenant Architecture
- **Data Isolation**: Row-Level Security (RLS) at database level
- **Tenant Context**: Session-based tenant switching
- **Scalability**: Horizontal scaling support

### 2. Integration-First Design
- **Shop1FinishLine Integration**: Extends existing user system
- **Non-Disruptive**: No changes to existing ERP workflows
- **Data Consistency**: Shared user authentication

### 3. Role-Based Security
- **Granular Permissions**: Five distinct user roles
- **Context-Aware**: Permissions vary by tenant/site
- **Audit Trail**: All changes tracked and logged

## 📊 Database Design

### Core Tables Structure

```sql
-- Multi-tenant structure
tenants (id, name, tenant_code, settings)
sites (id, tenant_id, name, site_code, location)

-- User management (extends Shop1FinishLine)
users (existing table + cmms_enabled, last_cmms_login, cmms_preferences)
user_tenant_assignments (user_id, tenant_id, default_site_id, is_primary)
cmms_user_roles (user_id, tenant_id, role, granted_by, is_active)

-- Future: Asset management
assets (id, tenant_id, site_id, asset_code, name, category_id)
asset_categories (id, tenant_id, name, parent_id)
asset_specifications (asset_id, spec_name, spec_value)

-- Future: Maintenance management
pm_templates (id, tenant_id, name, frequency_type, frequency_value)
work_orders (id, tenant_id, site_id, asset_id, priority, status)
```

### Row-Level Security Implementation

```sql
-- Example RLS policy
CREATE POLICY tenant_isolation ON assets
    FOR ALL TO cmms_user
    USING (tenant_id = current_setting('app.current_tenant_id')::bigint);

-- Session variables set per request
SET app.current_user_id = 123;
SET app.current_tenant_id = 1;
SET app.current_site_id = 5;
```

## 🔧 Application Structure

### Phoenix Context Organization

```
lib/shop1_cmms/
├── accounts/           # User management
│   ├── user.ex
│   ├── user_details.ex
│   ├── cmms_user_role.ex
│   └── user_tenant_assignment.ex
├── tenants/           # Multi-tenant management
│   ├── tenant.ex
│   └── site.ex
├── assets/            # Asset management (future)
├── maintenance/       # PM and work orders (future)
├── inventory/         # Parts management (future)
├── accounts.ex        # User context
├── tenants.ex         # Tenant context
├── auth.ex            # Authentication helpers
└── repo.ex            # Database connection
```

### LiveView Structure

```
lib/shop1_cmms_web/
├── live/
│   ├── dashboard_live.ex       # Main dashboard
│   ├── login_live.ex           # Authentication
│   ├── tenant_select_live.ex   # Tenant switching
│   ├── assets/                 # Asset management (future)
│   ├── maintenance/            # PM and WO management (future)
│   └── admin/                  # Administration (future)
├── components/
│   ├── core_components.ex      # Reusable UI components
│   └── layouts.ex              # Page layouts
├── controllers/
│   └── auth_controller.ex      # Authentication flow
└── user_auth.ex               # Authentication plugs
```

## 🔐 Security Architecture

### Authentication Flow

```
1. User enters Shop1FinishLine credentials
2. System validates against existing users table
3. Check cmms_enabled flag
4. Retrieve available tenants for user
5. Set session context with tenant selection
6. Establish RLS session variables
7. Grant access based on role permissions
```

### Authorization Levels

```
Tenant Admin    ──→ Full system access within tenant
     │
Maintenance Manager ──→ Asset and PM management
     │
Supervisor      ──→ Work order assignment and approval
     │
Technician      ──→ Work order execution and updates
     │
Operator        ──→ Basic asset interaction and requests
```

### Session Management

```elixir
# Session establishment
Auth.establish_session_context(user_id, tenant_id)
Tenants.set_tenant_context(tenant_id)

# Permission checking
Auth.authorize(user, :manage_assets, asset, tenant_id)
UserAuth.authorized?(socket, :create_work_orders)
```

## 🚀 Performance Considerations

### Database Performance
- **Connection Pooling**: Configured for high concurrency
- **Indexing Strategy**: Optimized for multi-tenant queries
- **Query Optimization**: Ecto query optimization
- **RLS Overhead**: Minimal impact with proper indexing

### Frontend Performance
- **LiveView Efficiency**: Minimal DOM updates
- **Asset Pipeline**: Optimized CSS/JS delivery
- **Responsive Design**: Mobile-first approach
- **Caching Strategy**: Static asset caching

### Scalability Patterns
- **Horizontal Scaling**: Multi-node Phoenix deployment
- **Database Scaling**: Read replicas for reporting
- **Background Jobs**: Oban for async processing
- **CDN Integration**: Static asset delivery

## 🔄 Integration Patterns

### Shop1FinishLine Integration

```elixir
# User lookup with existing system
def get_user_by_username_and_password(username, password) do
  user = get_cmms_user_by_username(username)
  if User.valid_password?(user, password), do: user
end

# Extending existing user data
def enable_cmms_for_user(user_id, tenant_id, enabling_user_id) do
  # Add CMMS access without disrupting existing system
end
```

### Data Flow Architecture

```
Shop1FinishLine ERP ←→ Shared Database ←→ CMMS Application
                              │
                        Row-Level Security
                              │
                    Multi-tenant Data Isolation
```

## 🧪 Testing Strategy

### Test Pyramid

```
                    🔺
                   /   \
                  / E2E \
                 /       \
                /_________\
               /           \
              /  Integration \
             /               \
            /_________________\
           /                   \
          /    Unit Tests       \
         /                       \
        /_______________________\
```

### Test Categories
- **Unit Tests**: Schema validations, business logic
- **Integration Tests**: Context functions, database queries
- **Controller Tests**: HTTP endpoints, authentication
- **LiveView Tests**: User interactions, real-time updates
- **E2E Tests**: Complete user workflows

## 📈 Monitoring & Observability

### Application Metrics
- **Response Times**: Phoenix endpoint metrics
- **Database Performance**: Query timing and frequency
- **User Sessions**: Authentication and tenant switching
- **Error Rates**: Application and database errors

### Business Metrics
- **User Adoption**: Active users per tenant
- **Feature Usage**: Most used CMMS functions
- **Performance KPIs**: Maintenance efficiency metrics
- **System Health**: Uptime and availability

## 🔮 Future Architecture Considerations

### Microservices Evolution
- **Asset Service**: Dedicated asset management
- **Workflow Engine**: Advanced automation
- **Analytics Service**: Separate reporting engine
- **Integration Hub**: API gateway for third-party systems

### Technology Roadmap
- **GraphQL API**: For mobile and third-party integration
- **Event Sourcing**: For audit trails and analytics
- **Message Queues**: For system integration
- **Machine Learning**: Predictive maintenance algorithms

---

*Architecture documentation maintained by the CMMS Development Team*  
*Last Updated: September 9, 2025*
