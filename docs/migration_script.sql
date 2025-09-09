-- Shop1FinishLine CMMS Integration Migration
-- Run this script on your existing Shop1FinishLine database to add CMMS functionality

-- =============================================================================
-- PHASE 1: Add CMMS Extensions to Existing Users Table
-- =============================================================================

-- Add CMMS-specific columns to existing users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS cmms_enabled BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_cmms_login TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS cmms_preferences JSONB DEFAULT '{}';

-- Create indexes for CMMS queries
CREATE INDEX IF NOT EXISTS idx_users_cmms_enabled ON users(cmms_enabled) WHERE cmms_enabled = true;
CREATE INDEX IF NOT EXISTS idx_users_last_cmms_login ON users(last_cmms_login);

-- =============================================================================
-- PHASE 2: Create CMMS-Specific Tables
-- =============================================================================

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

-- =============================================================================
-- PHASE 3: Create Indexes and Constraints
-- =============================================================================

-- Indexes for CMMS user roles
CREATE INDEX IF NOT EXISTS idx_cmms_user_roles_user_tenant ON cmms_user_roles(user_id, tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_cmms_user_roles_tenant ON cmms_user_roles(tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_cmms_user_roles_site ON cmms_user_roles(site_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_cmms_user_roles_role ON cmms_user_roles(role) WHERE is_active = true;

-- Indexes for user tenant assignments
CREATE INDEX IF NOT EXISTS idx_user_tenant_assignments_user ON user_tenant_assignments(user_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_tenant_assignments_tenant ON user_tenant_assignments(tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_user_tenant_assignments_primary ON user_tenant_assignments(user_id, is_primary) WHERE is_primary = true;

-- Indexes for sites
CREATE INDEX IF NOT EXISTS idx_sites_tenant ON sites(tenant_id) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_sites_code ON sites(tenant_id, code);

-- Indexes for tenants
CREATE INDEX IF NOT EXISTS idx_tenants_code ON tenants(code) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_tenants_active ON tenants(is_active);

-- =============================================================================
-- PHASE 4: Row Level Security (RLS)
-- =============================================================================

-- Enable RLS on CMMS tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE cmms_user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tenant_assignments ENABLE ROW LEVEL SECURITY;

-- RLS policies for tenant isolation
DROP POLICY IF EXISTS tenant_isolation ON tenants;
CREATE POLICY tenant_isolation ON tenants
    FOR ALL USING (
        id = COALESCE(current_setting('app.current_tenant_id', true)::integer, id)
    );

DROP POLICY IF EXISTS site_tenant_isolation ON sites;
CREATE POLICY site_tenant_isolation ON sites
    FOR ALL USING (
        tenant_id = COALESCE(current_setting('app.current_tenant_id', true)::integer, tenant_id)
    );

DROP POLICY IF EXISTS cmms_user_roles_tenant_isolation ON cmms_user_roles;
CREATE POLICY cmms_user_roles_tenant_isolation ON cmms_user_roles
    FOR ALL USING (
        tenant_id = COALESCE(current_setting('app.current_tenant_id', true)::integer, tenant_id)
    );

DROP POLICY IF EXISTS user_tenant_assignments_isolation ON user_tenant_assignments;
CREATE POLICY user_tenant_assignments_isolation ON user_tenant_assignments
    FOR ALL USING (
        tenant_id = COALESCE(current_setting('app.current_tenant_id', true)::integer, tenant_id)
        OR user_id = COALESCE(current_setting('app.current_user_id', true)::integer, user_id)
    );

-- =============================================================================
-- PHASE 5: Helper Functions
-- =============================================================================

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

-- =============================================================================
-- PHASE 6: Create Enhanced User View for CMMS
-- =============================================================================

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

-- =============================================================================
-- PHASE 7: Data Seeding
-- =============================================================================

-- Create a default tenant for your organization
INSERT INTO tenants (name, code, description, contact_email, timezone, is_active)
VALUES 
('International Hardcoat LLC.', 'IHC', 'Main organization tenant for CMMS', 'streppa@ihccorp.com', 'America/Detroit', true)
ON CONFLICT (code) DO NOTHING;

-- Create default sites
INSERT INTO sites (tenant_id, name, code, description, timezone, is_active)
SELECT 
    t.id,
    'Burt Facility',
    'BURT',
    'Primary maintenance facility',
    'America/Detroit',
    true
FROM tenants t 
WHERE t.code = 'IHC'
ON CONFLICT (tenant_id, code) DO NOTHING;

-- Add more sites as needed
INSERT INTO sites (tenant_id, name, code, description, timezone, is_active)
SELECT 
    t.id,
    'Glendale Facility',
    'GLENDALE',
    'Secondary facility',
    'America/Detroit',
    true
FROM tenants t 
WHERE t.code = 'IHC'
ON CONFLICT (tenant_id, code) DO NOTHING;

-- =============================================================================
-- PHASE 8: Enable CMMS for Admin Users
-- =============================================================================

-- Enable CMMS for users with admin roles (adjust role codes as needed for your system)
-- First, let's see what admin roles exist in your system:
-- SELECT code, name FROM roles WHERE code ILIKE '%admin%' OR name ILIKE '%admin%';

-- Example - adjust these role codes based on your actual admin roles:
UPDATE users 
SET cmms_enabled = true 
WHERE id IN (
    SELECT u.id 
    FROM users u 
    JOIN roles r ON r.id = u.role_id 
    WHERE r.code IN ('admin', 'super_admin', 'system_admin', 'administrator') -- Adjust these codes
      AND u.is_active = true
);

-- Assign tenant assignments to admin users
INSERT INTO user_tenant_assignments (user_id, tenant_id, is_primary, assigned_at)
SELECT 
    u.id,
    t.id,
    true,
    CURRENT_TIMESTAMP
FROM users u
JOIN roles r ON r.id = u.role_id
CROSS JOIN tenants t
WHERE r.code IN ('admin', 'super_admin', 'system_admin', 'administrator') -- Adjust these codes
  AND u.is_active = true
  AND u.cmms_enabled = true
  AND t.code = 'IHC'
ON CONFLICT (user_id, tenant_id) DO NOTHING;

-- Grant tenant admin CMMS roles to admin users
INSERT INTO cmms_user_roles (user_id, tenant_id, role, granted_at)
SELECT 
    uta.user_id,
    uta.tenant_id,
    'tenant_admin',
    CURRENT_TIMESTAMP
FROM user_tenant_assignments uta
JOIN users u ON u.id = uta.user_id
JOIN roles r ON r.id = u.role_id
WHERE r.code IN ('admin', 'super_admin', 'system_admin', 'administrator') -- Adjust these codes
  AND uta.is_active = true
ON CONFLICT DO NOTHING;

-- =============================================================================
-- PHASE 8a: Additional Data Seeding
-- =============================================================================

-- Add some sample CMMS roles for common job functions
-- Enable CMMS for maintenance-related users based on job titles or departments
UPDATE users 
SET cmms_enabled = true 
WHERE id IN (
    SELECT u.id 
    FROM users u 
    LEFT JOIN user_details ud ON ud.id = u.id
    WHERE (
        ud.department ILIKE '%maintenance%' OR 
        ud.department ILIKE '%facility%' OR
        ud.job_title ILIKE '%maintenance%' OR
        ud.job_title ILIKE '%technician%' OR
        ud.job_title ILIKE '%engineer%'
    )
    AND u.is_active = true
);

-- Assign maintenance staff to tenant
INSERT INTO user_tenant_assignments (user_id, tenant_id, is_primary, assigned_at)
SELECT 
    u.id,
    t.id,
    false, -- Not primary for non-admin users
    CURRENT_TIMESTAMP
FROM users u
LEFT JOIN user_details ud ON ud.id = u.id
CROSS JOIN tenants t
WHERE u.cmms_enabled = true
  AND u.is_active = true
  AND t.code = 'IHC'
  AND u.id NOT IN (
    -- Exclude users who already have tenant assignments
    SELECT uta.user_id FROM user_tenant_assignments uta WHERE uta.tenant_id = t.id
  );

-- Grant appropriate CMMS roles based on job titles
-- Maintenance Managers
INSERT INTO cmms_user_roles (user_id, tenant_id, role, granted_at)
SELECT 
    u.id,
    t.id,
    'maintenance_manager',
    CURRENT_TIMESTAMP
FROM users u
LEFT JOIN user_details ud ON ud.id = u.id
CROSS JOIN tenants t
WHERE (
    ud.job_title ILIKE '%manager%' OR
    ud.job_title ILIKE '%supervisor%' OR
    ud.job_title ILIKE '%lead%'
  )
  AND u.cmms_enabled = true
  AND u.is_active = true
  AND t.code = 'IHC'
ON CONFLICT DO NOTHING;

-- Technicians
INSERT INTO cmms_user_roles (user_id, tenant_id, role, granted_at)
SELECT 
    u.id,
    t.id,
    'technician',
    CURRENT_TIMESTAMP
FROM users u
LEFT JOIN user_details ud ON ud.id = u.id
CROSS JOIN tenants t
WHERE (
    ud.job_title ILIKE '%technician%' OR
    ud.job_title ILIKE '%mechanic%' OR
    ud.department ILIKE '%maintenance%'
  )
  AND u.cmms_enabled = true
  AND u.is_active = true
  AND t.code = 'IHC'
  AND u.id NOT IN (
    -- Don't override manager roles
    SELECT cur.user_id FROM cmms_user_roles cur 
    WHERE cur.role IN ('tenant_admin', 'maintenance_manager') 
    AND cur.tenant_id = t.id
  )
ON CONFLICT DO NOTHING;

-- Default role for any CMMS-enabled user without a specific role
INSERT INTO cmms_user_roles (user_id, tenant_id, role, granted_at)
SELECT 
    u.id,
    t.id,
    'operator',
    CURRENT_TIMESTAMP
FROM users u
CROSS JOIN tenants t
WHERE u.cmms_enabled = true
  AND u.is_active = true
  AND t.code = 'IHC'
  AND u.id NOT IN (
    -- Only add if user doesn't already have a CMMS role
    SELECT cur.user_id FROM cmms_user_roles cur 
    WHERE cur.tenant_id = t.id AND cur.is_active = true
  )
ON CONFLICT DO NOTHING;

-- =============================================================================
-- PHASE 8b: Manual User Setup Examples
-- =============================================================================

-- Example: Enable CMMS for specific users by username
-- Uncomment and modify as needed for your specific users
/*
UPDATE users 
SET cmms_enabled = true 
WHERE username IN ('streppa', 'admin', 'maintenance_lead') -- Add your specific usernames
  AND is_active = true;

-- Assign specific users to IHC tenant with admin privileges  
INSERT INTO user_tenant_assignments (user_id, tenant_id, is_primary, assigned_at)
SELECT 
    u.id,
    t.id,
    true,
    CURRENT_TIMESTAMP
FROM users u
CROSS JOIN tenants t
WHERE u.username = 'streppa' -- Replace with your username
  AND t.code = 'IHC'
  AND u.is_active = true
ON CONFLICT (user_id, tenant_id) DO UPDATE SET is_primary = true;

-- Grant tenant admin role to specific user
INSERT INTO cmms_user_roles (user_id, tenant_id, role, granted_at)
SELECT 
    u.id,
    t.id,
    'tenant_admin',
    CURRENT_TIMESTAMP
FROM users u
CROSS JOIN tenants t  
WHERE u.username = 'streppa' -- Replace with your username
  AND t.code = 'IHC'
  AND u.is_active = true
ON CONFLICT DO NOTHING;
*/

-- =============================================================================
-- PHASE 9: Create Triggers for Updated_At Fields
-- =============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at fields
DROP TRIGGER IF EXISTS update_tenants_updated_at ON tenants;
CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_sites_updated_at ON sites;
CREATE TRIGGER update_sites_updated_at BEFORE UPDATE ON sites FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_cmms_user_roles_updated_at ON cmms_user_roles;
CREATE TRIGGER update_cmms_user_roles_updated_at BEFORE UPDATE ON cmms_user_roles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_tenant_assignments_updated_at ON user_tenant_assignments;
CREATE TRIGGER update_user_tenant_assignments_updated_at BEFORE UPDATE ON user_tenant_assignments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Verify the migration worked
SELECT 'Users with CMMS enabled:' as check_type, count(*) as count FROM users WHERE cmms_enabled = true
UNION ALL
SELECT 'Tenants created:', count(*) FROM tenants
UNION ALL  
SELECT 'Sites created:', count(*) FROM sites
UNION ALL
SELECT 'CMMS user roles:', count(*) FROM cmms_user_roles WHERE is_active = true
UNION ALL
SELECT 'User tenant assignments:', count(*) FROM user_tenant_assignments WHERE is_active = true;

-- Detailed user setup verification
SELECT 
    'User Details' as section,
    u.id,
    u.username,
    ud.full_name,
    ud.email,
    ud.department,
    ud.job_title,
    u.cmms_enabled,
    user_has_cmms_access(u.id, (SELECT id FROM tenants WHERE code = 'IHC' LIMIT 1)) as has_access,
    get_user_highest_cmms_role(u.id, (SELECT id FROM tenants WHERE code = 'IHC' LIMIT 1)) as highest_role
FROM users u
LEFT JOIN user_details ud ON ud.id = u.id
WHERE u.cmms_enabled = true
ORDER BY u.id;

-- Show user's tenant assignments with roles
SELECT 
    'Tenant Assignments' as section,
    u.username,
    ud.full_name,
    ud.department,
    t.name as tenant_name,
    t.code as tenant_code,
    s.name as default_site,
    uta.is_primary,
    cur.role as cmms_role,
    cur.granted_at
FROM users u
LEFT JOIN user_details ud ON ud.id = u.id
JOIN user_tenant_assignments uta ON uta.user_id = u.id AND uta.is_active = true
JOIN tenants t ON t.id = uta.tenant_id
LEFT JOIN sites s ON s.id = uta.default_site_id
LEFT JOIN cmms_user_roles cur ON cur.user_id = u.id AND cur.tenant_id = t.id AND cur.is_active = true
WHERE u.cmms_enabled = true
ORDER BY u.username, uta.is_primary DESC, cur.role;

-- Show role distribution
SELECT 
    'Role Distribution' as section,
    cur.role,
    count(*) as user_count,
    string_agg(u.username, ', ' ORDER BY u.username) as users
FROM cmms_user_roles cur
JOIN users u ON u.id = cur.user_id
WHERE cur.is_active = true
GROUP BY cur.role
ORDER BY count(*) DESC;

-- Show site assignments
SELECT 
    'Site Assignments' as section,
    s.name as site_name,
    s.code as site_code,
    count(uta.user_id) as assigned_users,
    string_agg(u.username, ', ' ORDER BY u.username) as users
FROM sites s
LEFT JOIN user_tenant_assignments uta ON uta.default_site_id = s.id AND uta.is_active = true
LEFT JOIN users u ON u.id = uta.user_id
WHERE s.is_active = true
GROUP BY s.id, s.name, s.code
ORDER BY s.name;

-- =============================================================================
-- UTILITY QUERIES FOR ONGOING MANAGEMENT
-- =============================================================================

-- Query to find users who might need CMMS access (uncomment to use)
/*
SELECT 
    'Potential CMMS Users' as section,
    u.username,
    ud.full_name,
    ud.department,
    ud.job_title,
    u.cmms_enabled,
    CASE 
        WHEN ud.department ILIKE '%maintenance%' THEN 'Maintenance Dept'
        WHEN ud.department ILIKE '%facility%' THEN 'Facilities Dept'
        WHEN ud.job_title ILIKE '%maintenance%' THEN 'Maintenance Role'
        WHEN ud.job_title ILIKE '%technician%' THEN 'Technical Role'
        WHEN ud.job_title ILIKE '%engineer%' THEN 'Engineering Role'
        WHEN ud.job_title ILIKE '%manager%' THEN 'Management Role'
        ELSE 'Other'
    END as suggested_reason
FROM users u
LEFT JOIN user_details ud ON ud.id = u.id
WHERE u.is_active = true
  AND u.cmms_enabled = false
  AND (
    ud.department ILIKE '%maintenance%' OR 
    ud.department ILIKE '%facility%' OR
    ud.job_title ILIKE '%maintenance%' OR
    ud.job_title ILIKE '%technician%' OR
    ud.job_title ILIKE '%engineer%' OR
    ud.job_title ILIKE '%manager%'
  )
ORDER BY ud.department, ud.job_title, u.username;
*/

-- =============================================================================
-- QUICK SETUP COMMANDS FOR ADDITIONAL USERS
-- =============================================================================

-- Template for enabling CMMS for a specific user:
/*
-- Replace 'USERNAME_HERE' with actual username and 'ROLE_HERE' with desired role
UPDATE users SET cmms_enabled = true WHERE username = 'USERNAME_HERE' AND is_active = true;

INSERT INTO user_tenant_assignments (user_id, tenant_id, is_primary, assigned_at)
SELECT u.id, t.id, false, CURRENT_TIMESTAMP
FROM users u CROSS JOIN tenants t 
WHERE u.username = 'USERNAME_HERE' AND t.code = 'IHC' AND u.is_active = true
ON CONFLICT (user_id, tenant_id) DO NOTHING;

INSERT INTO cmms_user_roles (user_id, tenant_id, role, granted_at)
SELECT u.id, t.id, 'ROLE_HERE', CURRENT_TIMESTAMP
FROM users u CROSS JOIN tenants t 
WHERE u.username = 'USERNAME_HERE' AND t.code = 'IHC' AND u.is_active = true
ON CONFLICT DO NOTHING;
*/

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- Your Shop1FinishLine database now has CMMS functionality integrated!
-- Next steps:
-- 1. Update your role codes in the admin user sections above to match your actual admin roles
-- 2. Test the integration with your Phoenix application
-- 3. Add more users to CMMS as needed using the helper functions
-- 4. Configure additional sites and tenants as required
