alias Shop1Cmms.{Repo, Assets}
alias Shop1Cmms.Assets.Asset
import Ecto.Query

# Get a few assets for testing
assets = Assets.list_assets(1) |> Enum.take(3)

IO.puts("=== TESTING ASSET ROUTES ===")
IO.puts("")

if length(assets) == 0 do
  IO.puts("❌ No assets found!")
else
  Enum.each(assets, fn asset ->
    IO.puts("Asset: #{asset.name}")
    IO.puts("  ID: #{asset.id}")
    IO.puts("  Asset Number: #{asset.asset_number}")
    IO.puts("  Detail URL: /assets/#{asset.id}")
    IO.puts("  Edit URL: /assets/#{asset.id}/edit")
    IO.puts("")

    # Test if we can retrieve the asset by ID
    try do
      retrieved_asset = Assets.get_asset!(1, asset.id)
      IO.puts("  ✅ Can retrieve asset by ID: #{retrieved_asset.name}")
    rescue
      e -> IO.puts("  ❌ Error retrieving asset: #{inspect(e)}")
    end

    # Test if we can get asset with details
    try do
      detailed_asset = Assets.get_asset_with_details!(asset.id, 1)
      IO.puts("  ✅ Can get asset with details: #{detailed_asset.name}")
    rescue
      e -> IO.puts("  ❌ Error getting asset details: #{inspect(e)}")
    end

    IO.puts("  ---")
  end)
end

IO.puts("")
IO.puts("=== END TEST ===")
