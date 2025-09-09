# Shop1FinishLine CMMS Integration Migration

## Overview

This migration integrates the CMMS system with your existing Shop1FinishLine database structure, reusing the users, user_details, and roles tables while adding CMMS-specific functionality.

## Current Schema Analysis

### Existing Tables (Shop1FinishLine)
```sql
-- users table
users (
    id integer,
    username USER-DEFINED,
    password_hash text,
    role_id integer REFERENCES roles(id),
    last_login timestamp with time zone,
    failed_logins integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    is_active boolean
);

-- user_details (view or table with rich profile data)
user_details (
    id integer,
    username USER-DEFINED,
    role_id integer,
    user_is_active boolean,
    last_login timestamp with time zone,
    user_created_at timestamp with time zone,
    role_name text,
    role_description text,
    profile_id integer,
    first_name character varying,
    last_name character varying,
    display_name character varying,
    full_name character varying,
    email character varying,
    phone character varying,
    mobile character varying,
    department character varying,
    job_title character varying,
    avatar_url text,
    bio text,
    location character varying
);

-- roles table
roles (
    id integer,
    name text,
    description text,
    permissions ARRAY,
    code text,
    is_system boolean,
    is_active boolean,
    priority integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);
```

## Migration Plan

### Phase 1: Add CMMS Extensions to Existing Tables

```sql
-- Add CMMS-specific columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS cmms_enabled BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_cmms_login TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS cmms_preferences JSONB DEFAULT '{}';

-- Create indexes for CMMS queries
CREATE INDEX IF NOT EXISTS idx_users_cmms_enabled ON users(cmms_enabled) WHERE cmms_enabled = true;
CREATE INDEX IF NOT EXISTS idx_users_last_cmms_login ON users(last_cmms_login);
```

### Phase 2: Create CMMS-Specific Tables

```sql
-- Create tenants table for multi-tenant isolation
CREATE TABLE IF NOT EXISTS tenants (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    address TEXT,
    timezone VARCHAR(50) DEFAULT 'UTC',
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create sites table for location management
CREATE TABLE IF NOT EXISTS sites (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL REFERENCES tenants(id),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL,
    description TEXT,
    address TEXT,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    timezone VARCHAR(50),
    settings JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, code)
);

-- Create CMMS user roles table (separate from CRM roles)
CREATE TABLE IF NOT EXISTS cmms_user_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    tenant_id INTEGER NOT NULL REFERENCES tenants(id),
    site_id INTEGER REFERENCES sites(id), -- NULL = access all sites in tenant
    role VARCHAR(50) NOT NULL CHECK (role IN ('tenant_admin', 'maintenance_manager', 'supervisor', 'technician', 'operator')),
    granted_by INTEGER REFERENCES users(id),
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create user tenant assignments table
CREATE TABLE IF NOT EXISTS user_tenant_assignments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    tenant_id INTEGER NOT NULL REFERENCES tenants(id),
    default_site_id INTEGER REFERENCES sites(id),
    is_primary BOOLEAN DEFAULT false,
    assigned_by INTEGER REFERENCES users(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, tenant_id)
);
```

### Phase 3: Create Indexes and Constraints

```sql
-- Indexes for CMMS user roles
CREATE INDEX idx_cmms_user_roles_user_tenant ON cmms_user_roles(user_id, tenant_id) WHERE is_active = true;
CREATE INDEX idx_cmms_user_roles_tenant ON cmms_user_roles(tenant_id) WHERE is_active = true;
CREATE INDEX idx_cmms_user_roles_site ON cmms_user_roles(site_id) WHERE is_active = true;

-- Indexes for user tenant assignments
CREATE INDEX idx_user_tenant_assignments_user ON user_tenant_assignments(user_id) WHERE is_active = true;
CREATE INDEX idx_user_tenant_assignments_tenant ON user_tenant_assignments(tenant_id) WHERE is_active = true;
CREATE INDEX idx_user_tenant_assignments_primary ON user_tenant_assignments(user_id, is_primary) WHERE is_primary = true;

-- Indexes for sites
CREATE INDEX idx_sites_tenant ON sites(tenant_id) WHERE is_active = true;
CREATE INDEX idx_sites_code ON sites(tenant_id, code);

-- Indexes for tenants
CREATE INDEX idx_tenants_code ON tenants(code) WHERE is_active = true;
CREATE INDEX idx_tenants_active ON tenants(is_active);
```

### Phase 4: Row Level Security (RLS)

```sql
-- Enable RLS on CMMS tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE cmms_user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tenant_assignments ENABLE ROW LEVEL SECURITY;

-- RLS policies for tenant isolation
CREATE POLICY tenant_isolation ON tenants
    FOR ALL USING (
        id = COALESCE(current_setting('app.current_tenant_id', true)::integer, id)
    );

CREATE POLICY site_tenant_isolation ON sites
    FOR ALL USING (
        tenant_id = COALESCE(current_setting('app.current_tenant_id', true)::integer, tenant_id)
    );

CREATE POLICY cmms_user_roles_tenant_isolation ON cmms_user_roles
    FOR ALL USING (
        tenant_id = COALESCE(current_setting('app.current_tenant_id', true)::integer, tenant_id)
    );

CREATE POLICY user_tenant_assignments_isolation ON user_tenant_assignments
    FOR ALL USING (
        tenant_id = COALESCE(current_setting('app.current_tenant_id', true)::integer, tenant_id)
        OR user_id = COALESCE(current_setting('app.current_user_id', true)::integer, user_id)
    );
```

### Phase 5: Helper Functions

```sql
-- Function to get user's CMMS tenants
CREATE OR REPLACE FUNCTION get_user_cmms_tenants(p_user_id INTEGER)
RETURNS TABLE(tenant_id INTEGER, tenant_name TEXT, tenant_code TEXT, role TEXT, default_site_id INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id as tenant_id,
        t.name as tenant_name,
        t.code as tenant_code,
        cur.role,
        uta.default_site_id
    FROM tenants t
    JOIN user_tenant_assignments uta ON uta.tenant_id = t.id
    LEFT JOIN cmms_user_roles cur ON cur.tenant_id = t.id AND cur.user_id = p_user_id AND cur.is_active = true
    WHERE uta.user_id = p_user_id 
      AND uta.is_active = true 
      AND t.is_active = true
    ORDER BY uta.is_primary DESC, t.name;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has CMMS access to tenant
CREATE OR REPLACE FUNCTION user_has_cmms_access(p_user_id INTEGER, p_tenant_id INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM users u
        JOIN user_tenant_assignments uta ON uta.user_id = u.id
        WHERE u.id = p_user_id 
          AND u.cmms_enabled = true 
          AND u.is_active = true
          AND uta.tenant_id = p_tenant_id 
          AND uta.is_active = true
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get user's highest CMMS role in tenant
CREATE OR REPLACE FUNCTION get_user_highest_cmms_role(p_user_id INTEGER, p_tenant_id INTEGER)
RETURNS TEXT AS $$
DECLARE
    user_role TEXT;
    role_hierarchy JSONB := '{"tenant_admin": 5, "maintenance_manager": 4, "supervisor": 3, "technician": 2, "operator": 1}';
    highest_priority INTEGER := 0;
    current_priority INTEGER;
BEGIN
    FOR user_role IN 
        SELECT cur.role 
        FROM cmms_user_roles cur 
        WHERE cur.user_id = p_user_id 
          AND cur.tenant_id = p_tenant_id 
          AND cur.is_active = true
          AND (cur.expires_at IS NULL OR cur.expires_at > CURRENT_TIMESTAMP)
    LOOP
        current_priority := (role_hierarchy ->> user_role)::INTEGER;
        IF current_priority > highest_priority THEN
            highest_priority := current_priority;
        END IF;
    END LOOP;
    
    -- Return the role name for the highest priority
    SELECT key INTO user_role 
    FROM jsonb_each_text(role_hierarchy) 
    WHERE value::INTEGER = highest_priority;
    
    RETURN COALESCE(user_role, 'operator');
END;
$$ LANGUAGE plpgsql;
```

### Phase 6: Create Enhanced User View for CMMS

```sql
-- Create a comprehensive user view that combines CRM and CMMS data
CREATE OR REPLACE VIEW cmms_user_details AS
SELECT 
    u.id,
    u.username,
    u.is_active,
    u.last_login as crm_last_login,
    u.cmms_enabled,
    u.last_cmms_login,
    u.cmms_preferences,
    ud.first_name,
    ud.last_name,
    ud.display_name,
    ud.full_name,
    ud.email,
    ud.phone,
    ud.mobile,
    ud.department,
    ud.job_title,
    ud.avatar_url,
    ud.bio,
    ud.location,
    r.name as crm_role_name,
    r.code as crm_role_code,
    r.description as crm_role_description,
    u.created_at,
    u.updated_at
FROM users u
LEFT JOIN user_details ud ON ud.id = u.id
LEFT JOIN roles r ON r.id = u.role_id
WHERE u.is_active = true;
```

## Data Seeding

### Initial Tenant Setup

```sql
-- Create a default tenant for your organization
INSERT INTO tenants (name, code, description, contact_email, timezone, is_active)
VALUES 
('Shop1 Organization', 'SHOP1', 'Main organization tenant for CMMS', 'admin@shop1finishline.com', 'America/New_York', true)
ON CONFLICT (code) DO NOTHING;

-- Create default sites
INSERT INTO sites (tenant_id, name, code, description, timezone, is_active)
SELECT 
    t.id,
    'Main Facility',
    'MAIN',
    'Primary maintenance facility',
    'America/New_York',
    true
FROM tenants t 
WHERE t.code = 'SHOP1'
ON CONFLICT (tenant_id, code) DO NOTHING;
```

### Enable CMMS for Existing Admin Users

```sql
-- Enable CMMS for users with admin roles (adjust role names as needed)
UPDATE users 
SET cmms_enabled = true 
WHERE id IN (
    SELECT u.id 
    FROM users u 
    JOIN roles r ON r.id = u.role_id 
    WHERE r.code IN ('admin', 'super_admin', 'system_admin') -- Adjust role codes
      AND u.is_active = true
);

-- Assign tenant admin roles to these users
INSERT INTO user_tenant_assignments (user_id, tenant_id, is_primary, assigned_at)
SELECT 
    u.id,
    t.id,
    true,
    CURRENT_TIMESTAMP
FROM users u
JOIN roles r ON r.id = u.role_id
CROSS JOIN tenants t
WHERE r.code IN ('admin', 'super_admin', 'system_admin') -- Adjust role codes
  AND u.is_active = true
  AND u.cmms_enabled = true
  AND t.code = 'SHOP1'
ON CONFLICT (user_id, tenant_id) DO NOTHING;

-- Grant tenant admin CMMS roles
INSERT INTO cmms_user_roles (user_id, tenant_id, role, granted_at)
SELECT 
    uta.user_id,
    uta.tenant_id,
    'tenant_admin',
    CURRENT_TIMESTAMP
FROM user_tenant_assignments uta
JOIN users u ON u.id = uta.user_id
JOIN roles r ON r.id = u.role_id
WHERE r.code IN ('admin', 'super_admin', 'system_admin') -- Adjust role codes
  AND uta.is_active = true
ON CONFLICT DO NOTHING;
```

## Integration Testing

```sql
-- Test user CMMS access
SELECT 
    u.id,
    u.username,
    ud.full_name,
    ud.email,
    u.cmms_enabled,
    get_user_cmms_tenants(u.id) as cmms_tenants,
    user_has_cmms_access(u.id, 1) as has_access,
    get_user_highest_cmms_role(u.id, 1) as highest_role
FROM users u
LEFT JOIN user_details ud ON ud.id = u.id
WHERE u.cmms_enabled = true
ORDER BY u.id;

-- Test tenant isolation
SET app.current_tenant_id = '1';
SET app.current_user_id = '1';

SELECT * FROM tenants; -- Should only show accessible tenants
SELECT * FROM sites;   -- Should only show sites for current tenant
```

## Phoenix Integration Notes

1. **User Schema Updates**: The existing user schema needs to be mapped to include CMMS fields
2. **Authentication**: Existing authentication can be extended to check `cmms_enabled`
3. **Role System**: CMMS roles are separate from CRM roles for proper separation of concerns
4. **Multi-tenant Context**: Use PostgreSQL session variables for RLS enforcement

## Rollback Plan

```sql
-- If needed, rollback CMMS extensions
ALTER TABLE users DROP COLUMN IF EXISTS cmms_enabled;
ALTER TABLE users DROP COLUMN IF EXISTS last_cmms_login;
ALTER TABLE users DROP COLUMN IF EXISTS cmms_preferences;

DROP TABLE IF EXISTS cmms_user_roles CASCADE;
DROP TABLE IF EXISTS user_tenant_assignments CASCADE;
DROP TABLE IF EXISTS sites CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;

DROP FUNCTION IF EXISTS get_user_cmms_tenants(INTEGER);
DROP FUNCTION IF EXISTS user_has_cmms_access(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_user_highest_cmms_role(INTEGER, INTEGER);

DROP VIEW IF EXISTS cmms_user_details;
```
