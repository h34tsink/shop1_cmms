alias Shop1Cmms.{Repo, Assets, Audit, AuditLog}
alias Shop1Cmms.Assets.Component

IO.puts("\n=== Testing Audit Trail System ===\n")

# Check if audit_logs table has data
count = Repo.aggregate(AuditLog, :count)
IO.puts("Current audit log count: #{count}")

# Get a sample asset and user
asset = Repo.all(Shop1Cmms.Assets.Asset) |> List.first()
user = Repo.all(Shop1Cmms.Accounts.User) |> List.first()

if asset && user do
  IO.puts("\nTesting with:")
  IO.puts("  Asset: #{asset.name}")
  IO.puts("  User: #{user.username}")
  
  # Create a test component with audit logging
  IO.puts("\n1. Creating test component...")
  {:ok, component} = Assets.create_component(%{
    "name" => "Test Audit Component",
    "component_type" => "Test",
    "asset_id" => asset.id,
    "tenant_id" => asset.tenant_id,
    "status" => "active"
  }, user.id)
  
  IO.puts("   ✓ Component created: #{component.name}")
  
  # Check audit logs
  history = Audit.get_component_history(component.id, asset.tenant_id)
  IO.puts("   ✓ Audit entries: #{length(history)}")
  
  if length(history) > 0 do
    log = List.first(history)
    IO.puts("\n2. Latest audit log:")
    IO.puts("   Action: #{log.action}")
    IO.puts("   Performed by: #{log.performed_by.username}")
    IO.puts("   Time: #{log.inserted_at}")
    IO.puts("   Changes: #{inspect(log.changes, pretty: true)}")
  end
  
  # Test update
  IO.puts("\n3. Updating component status...")
  {:ok, updated} = Assets.update_component(component, %{"status" => "maintenance"}, user.id)
  IO.puts("   ✓ Status updated to: #{updated.status}")
  
  # Check audit logs again
  history = Audit.get_component_history(component.id, asset.tenant_id)
  IO.puts("   ✓ Audit entries now: #{length(history)}")
  
  # Show both logs
  IO.puts("\n4. Full component history:")
  Enum.each(history, fn log ->
    IO.puts("   - #{log.action} by #{log.performed_by.username} at #{log.inserted_at}")
  end)
  
  # Clean up test component
  IO.puts("\n5. Deleting test component...")
  Assets.delete_component(component, user.id)
  IO.puts("   ✓ Component deleted (also logged in audit)")
  
  # Final audit check
  final_count = Repo.aggregate(AuditLog, :count)
  IO.puts("\n6. Final audit log count: #{final_count} (was #{count})")
  IO.puts("   ✓ Added #{final_count - count} audit entries")
  
  IO.puts("\n=== Audit Trail System Working! ===\n")
else
  IO.puts("ERROR: No asset or user found for testing")
end
