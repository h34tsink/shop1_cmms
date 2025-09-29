alias Shop1Cmms.{Repo, Accounts.User, Accounts.UserTenantAssignment}
import Ecto.Query

IO.puts("=== Current Users in Database ===")

users = Repo.all(User)
IO.puts("Total users: #{length(users)}")
IO.puts("")

for user <- users do
  IO.puts("Username: #{user.username}")
  IO.puts("  ID: #{user.id}")
  IO.puts("  Active: #{user.is_active}")
  IO.puts("  CMMS Enabled: #{user.cmms_enabled}")
  IO.puts("  Password Hash: #{String.slice(user.password_hash || "nil", 0, 20)}...")
  IO.puts("")
end

IO.puts("=== User Tenant Assignments ===")
assignments =
  from(uta in UserTenantAssignment,
    preload: [:user, :tenant, :role]
  )
  |> Repo.all()

IO.puts("Total assignments: #{length(assignments)}")
IO.puts("")

for assignment <- assignments do
  IO.puts("User: #{assignment.user.username}")
  IO.puts("  Tenant: #{assignment.tenant.name}")
  IO.puts("  Role: #{assignment.role.display_name}")
  IO.puts("  Active: #{assignment.is_active}")
  IO.puts("")
end

IO.puts("=== Database Tables Structure ===")
IO.puts("The user management system uses these database tables:")
IO.puts("1. users - Core user information with CMMS extensions")
IO.puts("2. tenants - Multi-tenant organization structure")
IO.puts("3. cmms_user_roles - Role definitions with permissions")
IO.puts("4. user_tenant_assignments - Links users to tenants with roles")
