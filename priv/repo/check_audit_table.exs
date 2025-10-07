# Check what columns exist in audit_logs table
result = Shop1Cmms.Repo.query!("
  SELECT column_name, data_type, is_nullable
  FROM information_schema.columns 
  WHERE table_name = 'audit_logs'
  ORDER BY ordinal_position
")

IO.puts("\n=== Current audit_logs table structure ===\n")
IO.puts("Column Name          | Data Type        | Nullable")
IO.puts(String.duplicate("-", 60))

Enum.each(result.rows, fn [col, type, nullable] ->
  IO.puts(String.pad_trailing(col, 20) <> " | " <> String.pad_trailing(type, 16) <> " | " <> nullable)
end)

IO.puts("\n")
