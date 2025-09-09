# Shop1 CMMS Migration Guide

## 📋 Database Migration Overview

This document outlines the database changes made to integrate Shop1 CMMS with the existing Shop1FinishLine system.

## 🗄️ Migration Summary

### Modified Tables

#### `users` table (Extended)
- **Added:** `cmms_enabled` BOOLEAN DEFAULT FALSE
- **Added:** `last_cmms_login` TIMESTAMP
- **Added:** `cmms_preferences` JSONB
- **Purpose:** Enable CMMS access control without disrupting existing authentication

### New Tables Created

#### `tenants`
Multi-tenant organization management
```sql
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    tenant_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    settings JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### `sites`
Physical locations within tenants
```sql
CREATE TABLE sites (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT REFERENCES tenants(id),
    name VARCHAR(255) NOT NULL,
    site_code VARCHAR(50) NOT NULL,
    description TEXT,
    location_data JSONB,
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, site_code)
);
```

#### `cmms_user_roles`
Role assignments for CMMS users
```sql
CREATE TABLE cmms_user_roles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    tenant_id BIGINT REFERENCES tenants(id),
    role VARCHAR(50) NOT NULL,
    granted_by BIGINT REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### `user_tenant_assignments`
User access to specific tenants
```sql
CREATE TABLE user_tenant_assignments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    tenant_id BIGINT REFERENCES tenants(id),
    assigned_by BIGINT REFERENCES users(id),
    default_site_id BIGINT REFERENCES sites(id),
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, tenant_id)
);
```

## 🔐 Row-Level Security (RLS)

### RLS Policies Created

```sql
-- Enable RLS on all CMMS tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE cmms_user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tenant_assignments ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policy
CREATE POLICY tenant_isolation_policy ON sites
    FOR ALL TO cmms_user
    USING (tenant_id = current_setting('app.current_tenant_id')::bigint);

-- User access policy
CREATE POLICY user_access_policy ON cmms_user_roles
    FOR ALL TO cmms_user
    USING (
        user_id = current_setting('app.current_user_id')::bigint OR
        EXISTS (
            SELECT 1 FROM user_tenant_assignments uta
            WHERE uta.user_id = current_setting('app.current_user_id')::bigint
            AND uta.tenant_id = tenant_id
            AND uta.is_active = true
        )
    );
```

### Session Variables

The following session variables are set for each CMMS request:
- `app.current_user_id` - Current user ID
- `app.current_tenant_id` - Current tenant context
- `app.current_site_id` - Current site context (optional)

## 📊 Initial Data Setup

### Test Tenant Created
```sql
INSERT INTO tenants (name, tenant_code, description) VALUES 
('International Hardcoat LLC', 'IHC', 'Main manufacturing tenant');
```

### Test Sites Created
```sql
INSERT INTO sites (tenant_id, name, site_code, description, is_primary) VALUES 
(1, 'Burt', 'BURT', 'Burt manufacturing facility', true),
(1, 'Glendale', 'GLEN', 'Glendale manufacturing facility', false);
```

### Admin Users Enabled
The following users were enabled for CMMS access:
- `admin` - Tenant admin role
- `h34tsink` - Tenant admin role  
- `sysop` - Tenant admin role

## 🔄 Migration Script

### Complete Migration SQL
```sql
-- File: priv/repo/migrations/001_initial_cmms_setup.sql

BEGIN;

-- Add CMMS columns to existing users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS cmms_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS last_cmms_login TIMESTAMP,
ADD COLUMN IF NOT EXISTS cmms_preferences JSONB;

-- Create tenants table
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    tenant_code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    settings JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create sites table
CREATE TABLE sites (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT REFERENCES tenants(id),
    name VARCHAR(255) NOT NULL,
    site_code VARCHAR(50) NOT NULL,
    description TEXT,
    location_data JSONB,
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tenant_id, site_code)
);

-- Create user roles table
CREATE TABLE cmms_user_roles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    tenant_id BIGINT REFERENCES tenants(id),
    role VARCHAR(50) NOT NULL CHECK (role IN ('tenant_admin', 'maintenance_manager', 'supervisor', 'technician', 'operator')),
    granted_by BIGINT REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create user tenant assignments table
CREATE TABLE user_tenant_assignments (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    tenant_id BIGINT REFERENCES tenants(id),
    assigned_by BIGINT REFERENCES users(id),
    default_site_id BIGINT REFERENCES sites(id),
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, tenant_id)
);

-- Create indexes for performance
CREATE INDEX idx_users_cmms_enabled ON users(cmms_enabled) WHERE cmms_enabled = true;
CREATE INDEX idx_sites_tenant_id ON sites(tenant_id);
CREATE INDEX idx_cmms_user_roles_user_tenant ON cmms_user_roles(user_id, tenant_id);
CREATE INDEX idx_user_tenant_assignments_user ON user_tenant_assignments(user_id);
CREATE INDEX idx_user_tenant_assignments_tenant ON user_tenant_assignments(tenant_id);

-- Enable Row Level Security
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE cmms_user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tenant_assignments ENABLE ROW LEVEL SECURITY;

-- Create CMMS user role
CREATE ROLE cmms_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO cmms_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO cmms_user;

-- Create RLS policies
CREATE POLICY tenant_isolation_policy ON sites
    FOR ALL TO cmms_user
    USING (tenant_id = current_setting('app.current_tenant_id')::bigint);

CREATE POLICY tenant_roles_policy ON cmms_user_roles
    FOR ALL TO cmms_user
    USING (tenant_id = current_setting('app.current_tenant_id')::bigint);

CREATE POLICY tenant_assignments_policy ON user_tenant_assignments
    FOR ALL TO cmms_user
    USING (tenant_id = current_setting('app.current_tenant_id')::bigint);

-- Insert initial data
INSERT INTO tenants (name, tenant_code, description) VALUES 
('International Hardcoat LLC', 'IHC', 'Main manufacturing tenant');

INSERT INTO sites (tenant_id, name, site_code, description, is_primary) VALUES 
(1, 'Burt', 'BURT', 'Burt manufacturing facility', true),
(1, 'Glendale', 'GLEN', 'Glendale manufacturing facility', false);

-- Enable CMMS for admin users
UPDATE users SET cmms_enabled = true 
WHERE username IN ('admin', 'h34tsink', 'sysop');

-- Assign admin users to tenant
INSERT INTO user_tenant_assignments (user_id, tenant_id, assigned_by, default_site_id, is_primary)
SELECT id, 1, id, 1, true 
FROM users 
WHERE username IN ('admin', 'h34tsink', 'sysop');

-- Grant tenant admin roles
INSERT INTO cmms_user_roles (user_id, tenant_id, role, granted_by)
SELECT id, 1, 'tenant_admin', id 
FROM users 
WHERE username IN ('admin', 'h34tsink', 'sysop');

COMMIT;
```

## ✅ Migration Verification

### Verification Queries

```sql
-- Check CMMS-enabled users
SELECT username, cmms_enabled, last_cmms_login 
FROM users 
WHERE cmms_enabled = true;

-- Check tenant assignments
SELECT u.username, t.name as tenant_name, s.name as default_site
FROM users u
JOIN user_tenant_assignments uta ON u.id = uta.user_id
JOIN tenants t ON uta.tenant_id = t.id
LEFT JOIN sites s ON uta.default_site_id = s.id
WHERE u.cmms_enabled = true;

-- Check user roles
SELECT u.username, t.name as tenant_name, cur.role
FROM users u
JOIN cmms_user_roles cur ON u.id = cur.user_id
JOIN tenants t ON cur.tenant_id = t.id
WHERE cur.is_active = true;

-- Verify RLS policies
SELECT schemaname, tablename, policyname, roles, cmd, qual
FROM pg_policies 
WHERE tablename IN ('tenants', 'sites', 'cmms_user_roles', 'user_tenant_assignments');
```

## 🔄 Rollback Plan

### Rollback Script
```sql
-- Emergency rollback (removes all CMMS data)
BEGIN;

-- Drop CMMS tables (in reverse dependency order)
DROP TABLE IF EXISTS user_tenant_assignments CASCADE;
DROP TABLE IF EXISTS cmms_user_roles CASCADE;
DROP TABLE IF EXISTS sites CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;

-- Remove CMMS columns from users table
ALTER TABLE users 
DROP COLUMN IF EXISTS cmms_enabled,
DROP COLUMN IF EXISTS last_cmms_login,
DROP COLUMN IF EXISTS cmms_preferences;

-- Drop CMMS user role
DROP ROLE IF EXISTS cmms_user;

COMMIT;
```

## 📈 Performance Impact

### Migration Performance
- **Duration:** ~2-3 seconds on test database
- **Impact:** Minimal during migration (quick schema changes)
- **Downtime:** None required (additive changes only)

### Ongoing Performance
- **RLS Overhead:** ~5-10% query overhead (acceptable)
- **Index Usage:** Optimized for tenant-based queries
- **Connection Pooling:** No impact on existing connections

## 🔍 Monitoring

### Key Metrics to Monitor
- CMMS user login frequency
- Tenant context switching performance
- RLS policy effectiveness
- Database connection usage

### Alerts to Configure
- Failed CMMS logins
- RLS policy violations
- Tenant isolation breaches
- Performance degradation

---

*Migration documentation maintained by Database Team*  
*Migration completed: September 8, 2025*  
*Last updated: September 9, 2025*
