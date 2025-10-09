defmodule Shop1CmmsWeb.PageLoadingTest do
  use Shop1CmmsWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Shop1Cmms.{Assets, Accounts, Tenants}

  setup do
    # Use factory for cleaner setup
    user = Shop1Cmms.Factory.insert_user_with_tenant(tenant_id: 1)
    tenant = Shop1Cmms.Repo.get(Shop1Cmms.Tenants.Tenant, 1)

    # Create asset with dependencies
    %{asset: asset, asset_type: asset_type, location: location} = 
      Shop1Cmms.Factory.insert_asset_with_components(tenant_id: tenant.id, component_count: 0)

    %{
      user: user,
      tenant: tenant,
      asset: asset,
      asset_type: asset_type,
      location: location
    }
  end

  describe "Page Loading Tests" do
    test "assets index page loads without errors", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      assert {:ok, _view, html} = live(conn, "/assets")
      assert html =~ "Assets"
    end

    test "asset detail page loads without errors", %{conn: conn, user: user, asset: asset} do
      conn = log_in_user(conn, user)

      assert {:ok, _view, html} = live(conn, "/assets/#{asset.id}")
      assert html =~ asset.name
      assert html =~ asset.asset_number
    end

    test "work orders index page loads without errors", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      assert {:ok, _view, html} = live(conn, "/work_orders")
      assert html =~ "Work Orders"
    end

    test "dashboard page loads without errors", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      assert {:ok, _view, html} = live(conn, "/")
      assert html =~ "Dashboard" or html =~ "Home"
    end
  end
end
