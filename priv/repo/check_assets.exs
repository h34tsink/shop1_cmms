alias Shop1Cmms.{Repo, Assets}
alias Shop1Cmms.Assets.Asset
import Ecto.Query

# Get all assets for tenant 1
assets = Assets.list_assets(1)

IO.puts("=== DATABASE CHECK ===")
IO.puts("Found #{length(assets)} assets in database:")
IO.puts("")

if length(assets) == 0 do
  IO.puts("❌ No assets found in database!")
else
  Enum.each(assets, fn asset ->
    IO.puts("  ✓ #{asset.name} (#{asset.asset_number}) - Status: #{asset.status}")
  end)

  # Count by status
  status_counts =
    assets
    |> Enum.group_by(& &1.status)
    |> Enum.map(fn {status, assets} -> {status, length(assets)} end)
    |> Enum.into(%{})

  IO.puts("")
  IO.puts("📊 Status Summary:")
  Enum.each(status_counts, fn {status, count} ->
    IO.puts("   • #{status}: #{count} assets")
  end)

  # Count TEST assets specifically
  test_assets = Enum.filter(assets, fn asset -> String.starts_with?(asset.asset_number, "TEST-") end)
  IO.puts("")
  IO.puts("🧪 TEST Assets: #{length(test_assets)} of #{length(assets)} total")
end

IO.puts("")
IO.puts("=== END CHECK ===")
