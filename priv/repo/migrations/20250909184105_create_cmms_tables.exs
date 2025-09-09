defmodule Shop1Cmms.Repo.Migrations.CreateCmmsTables do
  use Ecto.Migration

  def change do
    # Add CMMS fields to existing users table (if they don't exist)
    execute """
    DO $$ 
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'cmms_enabled') THEN
        ALTER TABLE users ADD COLUMN cmms_enabled boolean DEFAULT false;
      END IF;
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'last_cmms_login') THEN
        ALTER TABLE users ADD COLUMN last_cmms_login timestamp;
      END IF;
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'preferences') THEN
        ALTER TABLE users ADD COLUMN preferences jsonb DEFAULT '{}';
      END IF;
    END $$;
    """, """
    ALTER TABLE users DROP COLUMN IF EXISTS cmms_enabled;
    ALTER TABLE users DROP COLUMN IF EXISTS last_cmms_login;
    ALTER TABLE users DROP COLUMN IF EXISTS preferences;
    """

    # Create tenants table (if it doesn't exist)
    execute """
    CREATE TABLE IF NOT EXISTS tenants (
      id bigserial PRIMARY KEY,
      name varchar(255) NOT NULL,
      display_name varchar(255),
      description text,
      address text,
      phone varchar(255),
      email varchar(255),
      website varchar(255),
      timezone varchar(255) DEFAULT 'America/Chicago',
      is_active boolean DEFAULT true,
      settings jsonb DEFAULT '{}',
      inserted_at timestamp NOT NULL DEFAULT NOW(),
      updated_at timestamp NOT NULL DEFAULT NOW()
    );
    """, "DROP TABLE IF EXISTS tenants CASCADE;"
    
    execute "CREATE UNIQUE INDEX IF NOT EXISTS tenants_name_index ON tenants (name);", "DROP INDEX IF EXISTS tenants_name_index;"

    # Create sites table (if it doesn't exist)
    execute """
    CREATE TABLE IF NOT EXISTS sites (
      id bigserial PRIMARY KEY,
      tenant_id bigint NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
      name varchar(255) NOT NULL,
      display_name varchar(255),
      description text,
      address text,
      phone varchar(255),
      email varchar(255),
      timezone varchar(255),
      is_active boolean DEFAULT true,
      settings jsonb DEFAULT '{}',
      inserted_at timestamp NOT NULL DEFAULT NOW(),
      updated_at timestamp NOT NULL DEFAULT NOW()
    );
    """, "DROP TABLE IF EXISTS sites CASCADE;"
    
    execute "CREATE INDEX IF NOT EXISTS sites_tenant_id_index ON sites (tenant_id);", "DROP INDEX IF EXISTS sites_tenant_id_index;"
    execute "CREATE UNIQUE INDEX IF NOT EXISTS sites_tenant_id_name_index ON sites (tenant_id, name);", "DROP INDEX IF EXISTS sites_tenant_id_name_index;"

    # Note: user_details exists as a view in Shop1 database, so we skip creating it
    # Just create indexes if user_details is a table (not a view)
    execute """
    DO $$
    BEGIN
        IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'user_details') THEN
            CREATE UNIQUE INDEX IF NOT EXISTS user_details_user_id_index ON user_details (user_id);
        END IF;
    END $$;
    """, ""

    # Create CMMS user roles lookup table (if it doesn't exist)
    execute """
    CREATE TABLE IF NOT EXISTS cmms_user_roles (
      id bigserial PRIMARY KEY,
      name varchar(255) NOT NULL,
      display_name varchar(255) NOT NULL,
      description text,
      permissions text[] DEFAULT '{}',
      is_system_role boolean DEFAULT false,
      is_active boolean DEFAULT true,
      inserted_at timestamp NOT NULL DEFAULT NOW(),
      updated_at timestamp NOT NULL DEFAULT NOW()
    );
    """, "DROP TABLE IF EXISTS cmms_user_roles CASCADE;"
    
    execute """
    DO $$
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cmms_user_roles' AND column_name = 'name') THEN
            CREATE UNIQUE INDEX IF NOT EXISTS cmms_user_roles_name_index ON cmms_user_roles (name);
        END IF;
    END $$;
    """, "DROP INDEX IF EXISTS cmms_user_roles_name_index;"

    # Create user-tenant assignments table (if it doesn't exist)
    execute """
    CREATE TABLE IF NOT EXISTS user_tenant_assignments (
      id bigserial PRIMARY KEY,
      user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      tenant_id bigint NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
      role_id bigint NOT NULL REFERENCES cmms_user_roles(id) ON DELETE RESTRICT,
      default_site_id bigint REFERENCES sites(id) ON DELETE SET NULL,
      assigned_by_id bigint REFERENCES users(id) ON DELETE SET NULL,
      assigned_at timestamp NOT NULL,
      is_active boolean DEFAULT true,
      notes text,
      inserted_at timestamp NOT NULL DEFAULT NOW(),
      updated_at timestamp NOT NULL DEFAULT NOW()
    );
    """, "DROP TABLE IF EXISTS user_tenant_assignments CASCADE;"
    
    execute """
    DO $$
    BEGIN
        IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'user_tenant_assignments') THEN
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_tenant_assignments' AND column_name = 'user_id') THEN
                CREATE INDEX IF NOT EXISTS user_tenant_assignments_user_id_index ON user_tenant_assignments (user_id);
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_tenant_assignments' AND column_name = 'tenant_id') THEN
                CREATE INDEX IF NOT EXISTS user_tenant_assignments_tenant_id_index ON user_tenant_assignments (tenant_id);
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_tenant_assignments' AND column_name = 'role_id') THEN
                CREATE INDEX IF NOT EXISTS user_tenant_assignments_role_id_index ON user_tenant_assignments (role_id);
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_tenant_assignments' AND column_name = 'user_id') 
               AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_tenant_assignments' AND column_name = 'tenant_id') THEN
                CREATE UNIQUE INDEX IF NOT EXISTS user_tenant_assignments_user_id_tenant_id_index ON user_tenant_assignments (user_id, tenant_id);
            END IF;
        END IF;
    END $$;
    """, """
    DROP INDEX IF EXISTS user_tenant_assignments_user_id_index;
    DROP INDEX IF EXISTS user_tenant_assignments_tenant_id_index;
    DROP INDEX IF EXISTS user_tenant_assignments_role_id_index;
    DROP INDEX IF EXISTS user_tenant_assignments_user_id_tenant_id_index;
    """

    # Insert default roles (only if the table has the expected structure)
    execute """
    DO $$
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cmms_user_roles' AND column_name = 'name')
           AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'cmms_user_roles' AND column_name = 'display_name') THEN
            INSERT INTO cmms_user_roles (name, display_name, description, permissions, is_system_role, inserted_at, updated_at) 
            SELECT 'tenant_admin', 'Tenant Admin', 'Full access to tenant data and settings', '{}', true, NOW(), NOW()
            WHERE NOT EXISTS (SELECT 1 FROM cmms_user_roles WHERE name = 'tenant_admin');
            
            INSERT INTO cmms_user_roles (name, display_name, description, permissions, is_system_role, inserted_at, updated_at) 
            SELECT 'maintenance_manager', 'Maintenance Manager', 'Manage assets, PMs, and work orders', '{}', true, NOW(), NOW()
            WHERE NOT EXISTS (SELECT 1 FROM cmms_user_roles WHERE name = 'maintenance_manager');
            
            INSERT INTO cmms_user_roles (name, display_name, description, permissions, is_system_role, inserted_at, updated_at) 
            SELECT 'supervisor', 'Supervisor', 'Supervise work orders and assign tasks', '{}', true, NOW(), NOW()
            WHERE NOT EXISTS (SELECT 1 FROM cmms_user_roles WHERE name = 'supervisor');
            
            INSERT INTO cmms_user_roles (name, display_name, description, permissions, is_system_role, inserted_at, updated_at) 
            SELECT 'technician', 'Technician', 'Execute work orders and update asset status', '{}', true, NOW(), NOW()
            WHERE NOT EXISTS (SELECT 1 FROM cmms_user_roles WHERE name = 'technician');
            
            INSERT INTO cmms_user_roles (name, display_name, description, permissions, is_system_role, inserted_at, updated_at) 
            SELECT 'operator', 'Operator', 'Basic asset interaction and work request creation', '{}', true, NOW(), NOW()
            WHERE NOT EXISTS (SELECT 1 FROM cmms_user_roles WHERE name = 'operator');
        END IF;
    END $$;
    """, """
    DELETE FROM cmms_user_roles WHERE is_system_role = true
    """

    # Create RLS policies for multi-tenant data isolation
    execute "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\"", ""
    
    # Enable RLS on tenant-specific tables
    execute "ALTER TABLE tenants ENABLE ROW LEVEL SECURITY", "ALTER TABLE tenants DISABLE ROW LEVEL SECURITY"
    execute "ALTER TABLE sites ENABLE ROW LEVEL SECURITY", "ALTER TABLE sites DISABLE ROW LEVEL SECURITY" 
    execute "ALTER TABLE user_tenant_assignments ENABLE ROW LEVEL SECURITY", "ALTER TABLE user_tenant_assignments DISABLE ROW LEVEL SECURITY"
  end
end
