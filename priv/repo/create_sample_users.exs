alias Shop1Cmms.{Repo, Accounts, Tenants}
alias Shop1Cmms.Accounts.{User, UserTenantAssignment, CMMSUserRole}
alias Shop1Cmms.Tenants.Tenant
import Ecto.Query

IO.puts("Creating sample users for testing...")

# Create or get tenant
tenant = Repo.get_by(Tenant, name: "Shop1") ||
  Repo.insert!(%Tenant{
    name: "Shop1",
    code: "SHOP1",
    description: "Shop1 CMMS System"
  })

# Delete existing test users first
from(u in User, where: u.username in ["admin", "manager", "technician"])
|> Repo.delete_all()

# Create test users with simple passwords
%User{}
|> User.changeset(%{
  username: "admin",
  password_hash: "admin123", # Legacy plaintext for testing
  is_active: true,
  cmms_enabled: true
})
|> Repo.insert!()

%User{}
|> User.changeset(%{
  username: "manager",
  password_hash: "manager123",
  is_active: true,
  cmms_enabled: true
})
|> Repo.insert!()

%User{}
|> User.changeset(%{
  username: "technician",
  password_hash: "tech123",
  is_active: true,
  cmms_enabled: true
})
|> Repo.insert!()

# Enable CMMS access for all test users
Repo.update_all(
  from(u in User, where: u.username in ["admin", "manager", "technician"]),
  set: [cmms_enabled: true, updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)]
)

# Get the users we just created
admin_user = Repo.get_by!(User, username: "admin")
manager_user = Repo.get_by!(User, username: "manager")
tech_user = Repo.get_by!(User, username: "technician")

# Get roles
admin_role = Repo.get_by!(CMMSUserRole, name: "tenant_admin")
manager_role = Repo.get_by!(CMMSUserRole, name: "maintenance_manager")
tech_role = Repo.get_by!(CMMSUserRole, name: "technician")

# Create user assignments
now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

Repo.insert!(%UserTenantAssignment{
  user_id: admin_user.id,
  tenant_id: tenant.id,
  role_id: admin_role.id,
  assigned_at: now
})

Repo.insert!(%UserTenantAssignment{
  user_id: manager_user.id,
  tenant_id: tenant.id,
  role_id: manager_role.id,
  assigned_at: now
})

Repo.insert!(%UserTenantAssignment{
  user_id: tech_user.id,
  tenant_id: tenant.id,
  role_id: tech_role.id,
  assigned_at: now
})

IO.puts("✅ Sample users created successfully!")
IO.puts("")
IO.puts("🔐 Login credentials:")
IO.puts("   Username: admin     Password: admin123     (Tenant Admin)")
IO.puts("   Username: manager   Password: manager123   (Maintenance Manager)")
IO.puts("   Username: technician Password: tech123     (Technician)")
IO.puts("")
IO.puts("🌐 Access the application at: http://localhost:4000")
IO.puts("📋 User Management at: http://localhost:4000/admin/users")
