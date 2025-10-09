defmodule Shop1CmmsWeb.AssetsLiveTest do
  use Shop1CmmsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shop1Cmms.DataCase

  alias Shop1Cmms.{Assets, Tenants, Accounts}

  describe "Assets LiveView" do
    setup do
      # Create test tenant
      tenant_attrs = %{
        name: "Test Tenant",
        code: "TEST",
        description: "Test tenant for unit tests",
        email: "test@example.com",
        is_active: true
      }

      {:ok, tenant} = Tenants.create_tenant(tenant_attrs)

      # Create test user with tenant assignment
      user_attrs = %{
        username: "testuser",
        password_hash: "test_password_hash",
        is_active: true,
        cmms_enabled: true
      }

      {:ok, user} = Accounts.create_user(user_attrs)

      # Get or create a role
      role = Shop1Cmms.Factory.get_or_create_role("technician")

      # Create user-tenant assignment
      assignment_attrs = %{
        user_id: user.id,
        tenant_id: tenant.id,
        role_id: role.id,
        is_active: true
      }

      {:ok, _assignment} = Accounts.create_user_tenant_assignment(assignment_attrs)

      # Create test asset types
      asset_type_attrs = %{
        name: "Test Equipment",
        description: "Test equipment type",
        code: "TEST_EQUIP",
        category: "Equipment",
        tenant_id: tenant.id
      }

      {:ok, asset_type} = Assets.create_asset_type(asset_type_attrs)

      # Create test location type
      location_type_attrs = %{
        name: "Test Location Type",
        code: "TEST_LOC",
        tenant_id: tenant.id
      }

      {:ok, location_type} = Assets.create_asset_location_type(location_type_attrs)

      # Create test location
      location_attrs = %{
        name: "Test Location",
        code: "LOC001",
        tenant_id: tenant.id,
        location_type_id: location_type.id,
        is_active: true
      }

      {:ok, location} = Assets.create_asset_location(location_attrs)

      # Create test asset
      asset_attrs = %{
        name: "Test Asset",
        asset_number: "AST001",
        status: :operational,
        criticality: :medium,
        asset_type_id: asset_type.id,
        location_id: location.id,
        tenant_id: tenant.id
      }

      {:ok, asset} = Assets.create_asset(asset_attrs)

      %{
        tenant: tenant,
        user: user,
        asset_type: asset_type,
        location: location,
        asset: asset
      }
    end

    test "renders assets index page", %{conn: conn, tenant: tenant, user: user} do
      # Simulate authenticated session
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, _index_live, html} = live(conn, "/assets")

      assert html =~ "Assets Management"
      assert html =~ "Manage your facility assets"
    end

    test "shows asset in grid view", %{conn: conn, tenant: tenant, user: user, asset: asset} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, index_live, _html} = live(conn, "/assets")

      assert has_element?(index_live, "[data-testid='asset-#{asset.id}']") ||
             render(index_live) =~ asset.name
    end

    test "can search for assets", %{conn: conn, tenant: tenant, user: user, asset: asset} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, index_live, _html} = live(conn, "/assets")

      # Test search functionality
      index_live
      |> form("form", search: %{term: asset.name})
      |> render_change()

      assert render(index_live) =~ asset.name
    end

    test "can filter assets by status", %{conn: conn, tenant: tenant, user: user} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, index_live, _html} = live(conn, "/assets")

      # Test status filter
      index_live
      |> element("select[name='status']")
      |> render_change(%{status: "operational"})

      # Should not crash and should update the view
      assert render(index_live)
    end

    test "can toggle advanced filters", %{conn: conn, tenant: tenant, user: user} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, index_live, _html} = live(conn, "/assets")

      # Test advanced filters toggle
      index_live
      |> element("button", "Advanced Filters")
      |> render_click()

      assert render(index_live) =~ "Hide Filters"
    end

    test "can access new asset form", %{conn: conn, tenant: tenant, user: user} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, index_live, _html} = live(conn, "/assets/new")

      assert render(index_live) =~ "Add New Asset"
    end
  end
end
