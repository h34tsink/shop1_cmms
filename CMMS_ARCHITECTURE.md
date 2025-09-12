# CMMS Centralized Architecture - Memory Note

## Implemented ✅
- **Navigation System**: Centralized top navigation component visible on all authenticated pages
- **Assets Management**: Multi-view system (Grid, List, Kanban) with centralized asset components
- **Component Architecture**: Reusable components in `lib/shop1_cmms_web/components/`

## Core CMMS Functions Architecture Plan

### 1. Work Orders System 🔧
**Priority: HIGH**
- **Module**: `Shop1Cmms.WorkOrders`
- **LiveView**: `Shop1CmmsWeb.WorkOrdersLive`
- **Components**: `Shop1CmmsWeb.Components.WorkOrders`
- **Features**:
  - Create, assign, track work orders
  - Multi-view (List, Kanban by status, Calendar)
  - Asset linking, parts requests, time tracking
  - Status workflow (Open → In Progress → Completed)
  - Priority levels, due dates, attachments

### 2. Preventive Maintenance (PM) 📅
**Priority: HIGH**
- **Module**: `Shop1Cmms.PreventiveMaintenance`
- **LiveView**: `Shop1CmmsWeb.PMScheduleLive`
- **Components**: `Shop1CmmsWeb.Components.PM`
- **Features**:
  - PM schedule templates, frequency-based scheduling
  - Auto-generation of work orders from PM schedules
  - Calendar view, overdue tracking
  - Asset-specific maintenance procedures
  - Compliance and regulatory tracking

### 3. Inventory & Parts Management 📦
**Priority: MEDIUM**
- **Module**: `Shop1Cmms.Inventory`
- **LiveView**: `Shop1CmmsWeb.InventoryLive`
- **Components**: `Shop1CmmsWeb.Components.Inventory`
- **Features**:
  - Parts catalog, stock levels, reorder points
  - Parts usage tracking, cost analysis
  - Vendor management, purchase orders
  - Barcode/QR code integration
  - Multi-location inventory

### 4. Reporting & Analytics 📊
**Priority: MEDIUM**
- **Module**: `Shop1Cmms.Reports`
- **LiveView**: `Shop1CmmsWeb.ReportsLive`
- **Components**: `Shop1CmmsWeb.Components.Reports`
- **Features**:
  - Asset performance metrics (MTTR, MTBF)
  - Maintenance cost analysis
  - Compliance reports, work order analytics
  - Dashboard widgets, custom reports
  - Export capabilities (PDF, Excel)

### 5. Scheduling & Calendar 🗓️
**Priority: MEDIUM-LOW**
- **Module**: `Shop1Cmms.Scheduling`
- **LiveView**: `Shop1CmmsWeb.ScheduleLive`
- **Components**: `Shop1CmmsWeb.Components.Calendar`
- **Features**:
  - Technician scheduling, resource allocation
  - Drag-and-drop calendar interface
  - Availability tracking, shift management
  - Integration with work orders and PM

### 6. Mobile/PWA Interface 📱
**Priority: LOW**
- **Module**: `Shop1CmmsWeb.Mobile`
- **LiveView**: Mobile-optimized versions
- **Features**:
  - Offline work order completion
  - Barcode scanning, photo attachments
  - Simplified technician interface
  - Push notifications

## Centralization Principles 🏗️

### 1. Shared Components Pattern
- All modules use centralized UI components
- Consistent view modes (Grid, List, Kanban, Calendar)
- Reusable form components, modals, filters
- Standardized status badges, action buttons

### 2. Common Data Patterns
- Standardized status enums across modules
- Common audit trail (created_at, updated_at, created_by)
- Tenant isolation at database level
- UUID primary keys for all entities

### 3. Shared Services
- **Notification Service**: Centralized alerts/notifications
- **Audit Service**: Activity logging across modules
- **File Service**: Document/photo attachment handling
- **Search Service**: Global search across entities
- **Export Service**: Standardized report generation

### 4. Authentication & Authorization
- Role-based permissions per tenant
- Granular permissions (read, write, admin) per module
- Centralized authorization helpers
- Consistent user context across all modules

## Implementation Order 📝

1. **Work Orders System** (Next Priority)
   - Core CMMS functionality
   - Foundation for other modules
   - High business value

2. **Preventive Maintenance**
   - Builds on work orders
   - Critical for maintenance planning
   - Auto-generation reduces manual work

3. **Inventory Management**
   - Links to work orders for parts
   - Cost tracking capabilities
   - Vendor relationships

4. **Reporting & Analytics**
   - Uses data from all previous modules
   - Business intelligence layer
   - ROI tracking

5. **Advanced Scheduling**
   - Resource optimization
   - Integration with existing modules
   - Complex calendar features

## Database Design Patterns 🗃️

### Common Table Structure
```sql
-- All tables follow this pattern
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
tenant_id UUID NOT NULL REFERENCES tenants(id)
created_at TIMESTAMP DEFAULT NOW()
updated_at TIMESTAMP DEFAULT NOW()
created_by UUID REFERENCES users(id)
updated_by UUID REFERENCES users(id)
```

### Status Management
- Consistent enum patterns across modules
- Status history tracking in separate tables
- Workflow validation at database level

### Multi-tenancy
- All queries filtered by tenant_id
- Row-level security policies
- Shared schema, isolated data

## Technology Stack Decisions 📚

- **Phoenix LiveView**: Real-time updates, rich interactions
- **Tailwind CSS**: Consistent styling, responsive design
- **Alpine.js**: Client-side interactivity where needed
- **PostgreSQL**: ACID compliance, JSON support, full-text search
- **Oban**: Background job processing (notifications, reports)

## File Organization 📁
```
lib/shop1_cmms/
├── work_orders/          # Work orders domain
├── preventive_maintenance/   # PM domain  
├── inventory/            # Inventory domain
├── reports/              # Reporting domain
├── shared/              # Common services
└── accounts/            # Users & auth (existing)

lib/shop1_cmms_web/
├── live/
│   ├── work_orders_live.ex
│   ├── pm_schedule_live.ex
│   └── inventory_live.ex
├── components/
│   ├── work_orders.ex
│   ├── pm.ex
│   ├── inventory.ex
│   ├── shared.ex       # Common components
│   ├── assets.ex       # (existing)
│   └── navigation.ex   # (existing)
```

This architecture ensures:
- **Consistency**: Shared patterns across all modules
- **Maintainability**: Centralized common functionality
- **Scalability**: Modular design for future growth
- **User Experience**: Consistent interface and workflows
