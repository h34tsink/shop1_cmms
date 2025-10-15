defmodule Shop1CmmsWeb.AssetFormLiveTest do
  use Shop1CmmsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shop1Cmms.DataCase

  alias Shop1Cmms.{Assets, Tenants, Accounts}

  describe "AssetFormLive Component" do
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

      # Create test user
      user_attrs = %{
        username: "testuser",
        password_hash: "test_password_hash",
        is_active: true,
        cmms_enabled: true
      }

      {:ok, user} = Accounts.create_user(user_attrs)

      # Get existing CMMS user role (created by migration)
      role = Shop1Cmms.Repo.get_by(Shop1Cmms.Accounts.CMMSUserRole, name: "tenant_admin")

      # Create user-tenant assignment
      assignment_attrs = %{
        user_id: user.id,
        tenant_id: tenant.id,
        role_id: role.id,
        is_active: true
      }

      {:ok, _assignment} = Accounts.create_user_tenant_assignment(assignment_attrs)

      # Create test asset type
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

      %{
        tenant: tenant,
        user: user,
        asset_type: asset_type,
        location: location
      }
    end

    test "renders new asset form", %{conn: conn, tenant: tenant, user: user} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, form_live, _html} = live(conn, "/assets/new")

      assert render(form_live) =~ "Add New Asset"
      assert render(form_live) =~ "Asset Name"
      assert render(form_live) =~ "Asset Number"
      assert render(form_live) =~ "Status"
    end

    test "validates required fields", %{conn: conn, tenant: tenant, user: user} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, form_live, _html} = live(conn, "/assets/new")

      # Try to submit form with empty required fields
      form_live
      |> form("#asset-form-form", asset: %{name: "", asset_number: ""})
      |> render_submit()

      # Should show validation errors
      html = render(form_live)
      assert html =~ "can&#39;t be blank" || html =~ "can't be blank"
    end

    test "shows asset type and location dropdowns", %{conn: conn, tenant: tenant, user: user, asset_type: asset_type, location: location} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, form_live, _html} = live(conn, "/assets/new")

      html = render(form_live)
      assert html =~ asset_type.name
      assert html =~ location.name
    end

    test "can close modal", %{conn: conn, tenant: tenant, user: user} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, form_live, _html} = live(conn, "/assets/new")

      # Test close button functionality
      form_live
      |> element("button", "Cancel")
      |> render_click()

      # Should patch to assets index (LiveView uses push_patch, not redirect)
      assert_patched(form_live, "/assets")
    end

    test "creates asset with valid data", %{conn: conn, tenant: tenant, user: user, asset_type: asset_type, location: location} do
      conn =
        conn
        |> init_test_session(%{
          "user_id" => user.id,
          "tenant_id" => tenant.id,
          "user_token" => "test_token"
        })
        |> assign(:current_user, user)
        |> assign(:current_tenant, tenant)

      {:ok, form_live, _html} = live(conn, "/assets/new")

      # Submit form with valid data
      form_live
      |> form("#asset-form-form", asset: %{
        name: "Test Asset",
        asset_number: "TST001",
        status: :operational,
        criticality: :medium,
        asset_type_id: asset_type.id,
        location_id: location.id
      })
      |> render_submit()

      # Should patch to assets index (LiveView uses push_patch, not redirect)
      assert_patched(form_live, "/assets")
    end
  end
end
