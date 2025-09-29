# Metadata Management System Architecture

## Overview

The metadata management system provides a centralized interface for managing all dropdown data and configuration used throughout the CMMS application. This includes asset types, manufacturers, locations, departments, suppliers, priority codes, maintenance categories, and custom fields.

## Core Requirements

### 1. Metadata Categories
- **Asset Types**: CNC, Furnace, Press, Vehicle, Hand Tool
- **Manufacturers**: OEM/vendor information with optional contact fields
- **Locations**: Buildings, Rooms, Lines, Departments with hierarchy support
- **Departments/Cost Centers**: For assignment & reporting
- **Suppliers/Vendors**: For parts, services, etc.
- **Priority Codes**: For ranking importance (Critical, High, Medium, Low)
- **Maintenance Categories**: Preventive, Predictive, Corrective, Calibration
- **Custom Fields/Tags**: Extensible metadata system

### 2. Key Features
- **Multi-tenant isolation**: All metadata scoped by tenant_id
- **Hierarchical support**: Locations can have parent-child relationships
- **Audit trail**: Track who created/modified entries with timestamps
- **Soft deletes**: Deactivation instead of deletion to preserve references
- **Searchable interface**: Type-ahead search and filtering
- **Role-based permissions**: Admin/supervisor controls
- **Import/Export**: CSV bulk operations
- **Inline creation**: Add new entries from form dropdowns

### 3. Technical Architecture

#### Database Design
All metadata tables follow consistent patterns:
```sql
CREATE TABLE metadata_table_name (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL REFERENCES tenants(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  code VARCHAR(50), -- Optional short code
  is_active BOOLEAN DEFAULT TRUE,
  parent_id UUID REFERENCES metadata_table_name(id), -- For hierarchical data
  metadata JSONB DEFAULT '{}', -- Flexible additional data
  created_by INTEGER REFERENCES users(id),
  updated_by INTEGER REFERENCES users(id),
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, name),
  UNIQUE(tenant_id, code) WHERE code IS NOT NULL
);
```

#### Context Structure
```
lib/shop1_cmms/
├── metadata/
│   ├── asset_type.ex
│   ├── manufacturer.ex
│   ├── location.ex
│   ├── department.ex
│   ├── supplier.ex
│   ├── priority_code.ex
│   ├── maintenance_category.ex
│   └── custom_field.ex
└── metadata.ex  -- Main context
```

#### LiveView Structure
```
lib/shop1_cmms_web/
├── live/
│   └── metadata_live.ex  -- Main metadata management interface
├── components/
│   ├── metadata_table.ex  -- Reusable table component
│   ├── metadata_form.ex   -- Form component
│   └── searchable_select.ex -- Dropdown component
```

## UI/UX Design

### Layout
- **Left Sidebar**: Collapsible navigation for metadata categories
- **Main Panel**: Searchable table with inline editing capabilities
- **Modal Forms**: For add/edit operations
- **Breadcrumb Navigation**: Current category context

### Features
- **Live Search**: Real-time filtering as user types
- **Inline Editing**: Click-to-edit table cells for quick updates
- **Bulk Operations**: Multi-select with bulk activate/deactivate
- **Responsive Design**: Mobile-friendly with collapsible sidebar
- **Keyboard Navigation**: Tab/enter support for efficiency

### Permissions
- **View**: All authenticated users can view active metadata
- **Create/Edit**: Admin and Manager roles only
- **Delete/Deactivate**: Admin role only
- **Import/Export**: Admin role only

## Integration Points

### Form Dropdowns
All forms throughout the application use standardized searchable dropdowns:
```elixir
<.searchable_select
  field={@form[:asset_type_id]}
  options={@asset_types}
  label="Asset Type"
  prompt="Select Asset Type..."
  allow_create={@can_manage_metadata}
  create_event="create_asset_type"
/>
```

### API Functions
Context functions provide consistent interfaces:
```elixir
# Standard CRUD operations
Metadata.list_asset_types(tenant_id, opts \\ [])
Metadata.get_asset_type!(tenant_id, id)
Metadata.create_asset_type(attrs)
Metadata.update_asset_type(asset_type, attrs)
Metadata.deactivate_asset_type(asset_type)

# Search and filtering
Metadata.search_asset_types(tenant_id, term, opts \\ [])
Metadata.list_active_asset_types(tenant_id)
```

## Performance Considerations

### Caching Strategy
- **ETS Cache**: Frequently accessed metadata cached in memory
- **Cache Invalidation**: PubSub notifications on updates
- **Preloading**: Eager load related data in list operations

### Database Optimizations
- **Indexes**: Composite indexes on (tenant_id, name), (tenant_id, code)
- **Partial Indexes**: On is_active for faster active-only queries
- **Full-text Search**: PostgreSQL tsvector for advanced search

### Frontend Optimizations
- **Debounced Search**: 300ms delay on search input
- **Pagination**: Large datasets paginated with LiveView streams
- **Lazy Loading**: Hierarchical data loaded on demand

## Security Considerations

### Data Isolation
- **Row Level Security**: PostgreSQL RLS policies by tenant
- **Context Validation**: All operations validate tenant access
- **Input Sanitization**: XSS protection on all user inputs

### Audit Requirements
- **Change Log**: All modifications logged with user/timestamp
- **Data Retention**: Soft deletes maintain referential integrity
- **Compliance Ready**: Audit trail supports ISO/ITAR requirements

## Future Enhancements

### Phase 2 Features
- **Workflow Automation**: Approval workflows for metadata changes
- **Data Validation Rules**: Custom validation for specific metadata types
- **API Integration**: REST API for external system integration
- **Advanced Search**: Full-text search with filters and sorting
- **Bulk Import Validation**: Preview and error handling for CSV imports
- **Metadata Relationships**: Define relationships between metadata types

### Scalability Considerations
- **Microservices**: Potential extraction to separate service
- **Event Sourcing**: Full audit trail with event streams
- **Multi-region**: Distributed caching for global deployments

## Implementation Phases

### Phase 1: Core Foundation (Week 1-2)
1. Database schema and migrations
2. Basic Ecto schemas with validations
3. Context functions for CRUD operations
4. Simple LiveView interface for one metadata type

### Phase 2: Full Interface (Week 3-4)
1. Complete LiveView with all metadata types
2. Searchable dropdown components
3. Role-based permissions
4. Basic import/export functionality

### Phase 3: Advanced Features (Week 5-6)
1. Audit trail implementation
2. Hierarchical data support
3. Advanced search and filtering
4. Performance optimizations

### Phase 4: Polish & Integration (Week 7-8)
1. Integration with existing forms
2. Comprehensive testing
3. Documentation and training materials
4. Production deployment and monitoring

This architecture provides a solid foundation for a scalable, maintainable metadata management system that integrates seamlessly with the existing CMMS application while following Phoenix LiveView best practices.