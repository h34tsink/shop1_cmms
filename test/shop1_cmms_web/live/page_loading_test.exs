defmodule Shop1CmmsWeb.PageLoadingTest do
  use Shop1CmmsWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Shop1Cmms.{Assets, Accounts, Tenants}

  setup do
    # Create tenant
    {:ok, tenant} = Tenants.create_tenant(%{name: "Test Company", subdomain: "test#{System.unique_integer([:positive])}"})

    # Create a role
    {:ok, role} = Accounts.create_role(%{
      name: "Admin",
      tenant_id: tenant.id,
      permissions: %{"assets" => ["manage"], "work_orders" => ["manage"]}
    })

    # Create user with that role
    {:ok, user} = Accounts.register_user(%{
      email: "user#{System.unique_integer([:positive])}@example.com",
      password: "password123456"
    })

    # Assign user to tenant with role
    {:ok, _assignment} = Accounts.assign_user_to_tenant(user, tenant.id, role.id)

    # Create asset type
    {:ok, asset_type} = Assets.create_asset_type(%{
      name: "Test Equipment",
      code: "TEST_EQUIP",
      tenant_id: tenant.id
    })

    # Create asset location
    {:ok, location} = Assets.create_asset_location(%{
      name: "Test Location",
      code: "TEST_LOC",
      tenant_id: tenant.id
    })

    # Create an asset
    {:ok, asset} = Assets.create_asset(%{
      name: "Test Asset",
      asset_number: "TEST-001",
      asset_type_id: asset_type.id,
      location_id: location.id,
      status: :operational,
      criticality: :medium,
      tenant_id: tenant.id
    })

    %{
      user: user,
      tenant: tenant,
      asset: asset,
      asset_type: asset_type,
      location: location
    }
  end

  describe "Page Loading Tests" do
    test "assets index page loads without errors", %{user: user, tenant: tenant} do
      conn = build_conn()
      conn = Plug.Test.init_test_session(conn, %{user_token: Accounts.generate_user_session_token(user)})
      conn = assign(conn, :current_user, user)
      conn = assign(conn, :current_tenant_id, tenant.id)
      conn = assign(conn, :current_tenant, tenant)

      assert {:ok, _view, html} = live(conn, "/assets")
      assert html =~ "Assets"
    end

    test "asset detail page loads without errors", %{user: user, tenant: tenant, asset: asset} do
      conn = build_conn()
      conn = Plug.Test.init_test_session(conn, %{user_token: Accounts.generate_user_session_token(user)})
      conn = assign(conn, :current_user, user)
      conn = assign(conn, :current_tenant_id, tenant.id)
      conn = assign(conn, :current_tenant, tenant)

      assert {:ok, _view, html} = live(conn, "/assets/#{asset.id}")
      assert html =~ asset.name
      assert html =~ asset.asset_number
    end

    test "work orders index page loads without errors", %{user: user, tenant: tenant} do
      conn = build_conn()
      conn = Plug.Test.init_test_session(conn, %{user_token: Accounts.generate_user_session_token(user)})
      conn = assign(conn, :current_user, user)
      conn = assign(conn, :current_tenant_id, tenant.id)
      conn = assign(conn, :current_tenant, tenant)

      assert {:ok, _view, html} = live(conn, "/work_orders")
      assert html =~ "Work Orders"
    end

    test "dashboard page loads without errors", %{user: user, tenant: tenant} do
      conn = build_conn()
      conn = Plug.Test.init_test_session(conn, %{user_token: Accounts.generate_user_session_token(user)})
      conn = assign(conn, :current_user, user)
      conn = assign(conn, :current_tenant_id, tenant.id)
      conn = assign(conn, :current_tenant, tenant)

      assert {:ok, _view, html} = live(conn, "/")
      assert html =~ "Dashboard" or html =~ "Home"
    end
  end
end
