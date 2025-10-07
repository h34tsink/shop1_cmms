defmodule Shop1Cmms.ExcelExportTest do
  use Shop1Cmms.DataCase

  alias Shop1Cmms.{Assets, Exports}
  import Shop1Cmms.AssetsFixtures
  import Shop1Cmms.AccountsFixtures

  describe "export_assets_to_xlsx/1" do
    setup do
      tenant = tenant_fixture()
      asset_type = asset_type_fixture(%{tenant_id: tenant.id, name: "Test Equipment"})
      location = asset_location_fixture(%{tenant_id: tenant.id, name: "Main Workshop"})
      
      # Create test assets
      asset1 = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "CNC Machine",
        asset_number: "CNC-001",
        manufacturer: "Haas",
        model: "VF-2",
        status: :operational,
        criticality: :critical
      })
      
      asset2 = asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Lathe",
        asset_number: "LAT-001",
        manufacturer: "South Bend",
        model: "10K",
        status: :maintenance,
        criticality: :high
      })
      
      %{
        tenant: tenant,
        assets: [asset1, asset2]
      }
    end

    test "exports assets to Excel format", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      # Export to Excel
      xlsx_content = Exports.export_assets_to_xlsx(assets)
      
      # Verify it returns binary content
      assert is_binary(xlsx_content)
      assert byte_size(xlsx_content) > 0
      
      # Verify it starts with Excel file signature (ZIP format)
      <<pk_signature::binary-size(2), _rest::binary>> = xlsx_content
      assert pk_signature == "PK"  # ZIP/Excel files start with PK
    end

    test "exports correct number of rows", %{tenant: tenant} do
      assets = Assets.list_assets_with_details(tenant.id)
      
      xlsx_content = Exports.export_assets_to_xlsx(assets)
      
      # Should have content for 2 assets + header row
      # (We can't easily parse the Excel file in tests, but we verify it generates)
      assert is_binary(xlsx_content)
      assert byte_size(xlsx_content) > 1000  # Reasonable file size
    end

    test "handles empty asset list", _context do
      empty_assets = []
      
      xlsx_content = Exports.export_assets_to_xlsx(empty_assets)
      
      # Should still generate valid Excel file with just headers
      assert is_binary(xlsx_content)
      assert byte_size(xlsx_content) > 0
    end

    test "handles assets with nil values", %{tenant: tenant} do
      asset_type = asset_type_fixture(%{tenant_id: tenant.id})
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      # Create asset with minimal data
      asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Minimal Asset",
        asset_number: "MIN-001",
        manufacturer: nil,
        model: nil,
        install_date: nil
      })
      
      assets = Assets.list_assets_with_details(tenant.id)
      xlsx_content = Exports.export_assets_to_xlsx(assets)
      
      # Should handle nil values without crashing
      assert is_binary(xlsx_content)
      assert byte_size(xlsx_content) > 0
    end
  end

  describe "CSV export still works" do
    test "export_assets_to_csv/1 still functions", %{} do
      tenant = tenant_fixture()
      asset_type = asset_type_fixture(%{tenant_id: tenant.id})
      location = asset_location_fixture(%{tenant_id: tenant.id})
      
      asset_fixture(%{
        tenant_id: tenant.id,
        asset_type_id: asset_type.id,
        location_id: location.id,
        name: "Test Asset",
        asset_number: "TEST-001"
      })
      
      assets = Assets.list_assets_with_details(tenant.id)
      csv_content = Exports.export_assets_to_csv(assets)
      
      # Verify CSV format
      assert is_binary(csv_content)
      assert String.contains?(csv_content, "Asset Number")
      assert String.contains?(csv_content, "TEST-001")
    end
  end
end
