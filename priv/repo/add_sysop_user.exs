alias Shop1Cmms.{Repo, Accounts, Tenants}
alias Shop1Cmms.Accounts.{User, UserTenantAssignment, CMMSUserRole}
alias Shop1Cmms.Tenants.Tenant
import Ecto.Query

IO.puts("Adding sysop user...")

# Get or create tenant
tenant = Repo.get_by(Tenant, name: "Shop1") ||
  Repo.insert!(%Tenant{
    name: "Shop1",
    code: "SHOP1",
    description: "Shop1 CMMS System"
  })

# Delete existing sysop user if it exists
from(u in User, where: u.username == "sysop")
|> Repo.delete_all()

# Create sysop user with password "Sysop2933Admin!" (meets all requirements)
{:ok, sysop_user} = Accounts.create_user_with_password(%{
  username: "sysop",
  password: "Sysop2933Admin!",
  password_confirmation: "Sysop2933Admin!",
  is_active: true,
  cmms_enabled: true
})

# Get tenant admin role
admin_role = Repo.get_by!(CMMSUserRole, name: "tenant_admin")

# Create user assignment with tenant admin role
now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

{:ok, _assignment} = Accounts.create_user_tenant_assignment(%{
  user_id: sysop_user.id,
  tenant_id: tenant.id,
  role_id: admin_role.id,
  granted_by: sysop_user.id, # Self-granted for sysop
  is_active: true
})

IO.puts("✅ Sysop user created successfully!")
IO.puts("")
IO.puts("🔐 Login credentials:")
IO.puts("   Username: sysop")
IO.puts("   Password: Sysop2933Admin!")
IO.puts("   Role: Tenant Admin (full access)")
IO.puts("")
IO.puts("🌐 Access the application at: http://localhost:4000")
