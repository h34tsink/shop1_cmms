alias Shop1Cmms.Repo
alias Shop1Cmms.Tenants.Site
alias Shop1Cmms.Assets.Asset

# Check what's in the database
site_count = Repo.aggregate(Site, :count, :id)
asset_count = Repo.aggregate(Asset, :count, :id)

IO.puts("Current database state:")
IO.puts("Sites: #{site_count}")
IO.puts("Assets: #{asset_count}")

if site_count > 0 do
  IO.puts("\nExisting sites:")
  Repo.all(Site) |> Enum.each(fn site ->
    IO.puts("- #{site.code}: #{site.name}")
  end)
end

if asset_count > 0 do
  IO.puts("\nExisting assets:")
  Repo.all(Asset) |> Enum.each(fn asset ->
    IO.puts("- #{asset.asset_number}: #{asset.name}")
  end)
end
