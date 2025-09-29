alias Shop1Cmms.Accounts

# Check if sysop user exists
user = Accounts.get_user_by_username("sysop")
if user do
  IO.puts("Sysop user exists: #{user.username}")
else
  IO.puts("Sysop user not found")
end

# List all users
users = Accounts.list_users()
IO.puts("\nAll users (#{length(users)}):")
Enum.each(users, fn u ->
  IO.puts("  - #{u.username} (#{u.email})")
end)
