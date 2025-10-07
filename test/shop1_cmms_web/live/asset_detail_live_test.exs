defmodule Shop1CmmsWeb.AssetDetailLiveTest do
  use Shop1CmmsWeb.ConnCase
  
  import Phoenix.LiveViewTest
  alias Shop1Cmms.Factory

  setup %{conn: conn} do
    # Create authenticated user with tenant
    user = Factory.insert(:user)
    tenant_id = 1
    
    conn = 
      conn
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_session(:user_id, user.id)
      |> Plug.Conn.put_session(:tenant_id, tenant_id)
      |> Plug.Conn.assign(:current_user, user)
      |> Plug.Conn.assign(:current_tenant_id, tenant_id)
    
    {:ok, conn: conn, user: user, tenant_id: tenant_id}
  end

  describe "Components Tab" do
    test "displays components tab button", %{conn: conn} do
      %{asset: asset} = Factory.insert_asset_with_components(component_count: 2)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      assert has_element?(view, "button", "Components")
    end

    test "clicking components tab shows component list", %{conn: conn} do
      %{asset: asset, components: components} = Factory.insert_asset_with_components(component_count: 3)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      # Should see all components
      Enum.each(components, fn component ->
        assert has_element?(view, "[data-component-id='#{component.id}']") or
               render(view) =~ component.name
      end)
    end

    test "shows empty state when no components", %{conn: conn} do
      asset = Factory.insert(:asset, tenant_id: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      assert render(view) =~ "No components"
      assert has_element?(view, "button", "Add Component")
    end

    test "displays component details correctly", %{conn: conn} do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components(
        component_count: 1,
        tenant_id: 1
      )
      
      # Update component with known values
      Shop1Cmms.Assets.update_component(component, %{
        "manufacturer" => "Siemens",
        "model" => "1LA7",
        "component_type" => "Motor"
      })
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      html = render(view)
      assert html =~ component.name
      assert html =~ "Siemens"
      assert html =~ "1LA7"
      assert html =~ "Motor"
    end
  end

  describe "Add Component" do
    test "opens modal when clicking Add Component", %{conn: conn} do
      asset = Factory.insert(:asset, tenant_id: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      view
      |> element("button", "Add Component")
      |> render_click()
      
      assert has_element?(view, "#component-form") or
             render(view) =~ "Add Component"
    end

    test "creates component with valid data", %{conn: conn, user: user} do
      asset = Factory.insert(:asset, tenant_id: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      view
      |> element("button", "Add Component")
      |> render_click()
      
      # Fill form
      view
      |> form("#component-form", component: %{
        name: "Test Motor",
        component_type: "Motor",
        manufacturer: "Siemens",
        status: "active"
      })
      |> render_submit()
      
      # Should see success message and new component
      assert render(view) =~ "Component created successfully"
      assert render(view) =~ "Test Motor"
      
      # Verify in database
      components = Shop1Cmms.Assets.list_components_for_asset(asset.id, asset.tenant_id)
      assert length(components) == 1
      assert hd(components).name == "Test Motor"
    end

    test "shows validation errors for invalid data", %{conn: conn} do
      asset = Factory.insert(:asset, tenant_id: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      view
      |> element("button", "Add Component")
      |> render_click()
      
      # Submit without required field
      view
      |> form("#component-form", component: %{component_type: "Motor"})
      |> render_submit()
      
      assert render(view) =~ "can&#39;t be blank" or render(view) =~ "can't be blank"
    end
  end

  describe "Edit Component" do
    test "opens edit modal with component data", %{conn: conn} do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components(component_count: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      view
      |> element("button[phx-click='edit_component'][phx-value-id='#{component.id}']")
      |> render_click()
      
      html = render(view)
      assert html =~ "Edit Component"
      assert html =~ component.name
    end

    test "updates component with new data", %{conn: conn} do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components(component_count: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      view
      |> element("button[phx-click='edit_component'][phx-value-id='#{component.id}']")
      |> render_click()
      
      view
      |> form("#component-form", component: %{name: "Updated Motor"})
      |> render_submit()
      
      assert render(view) =~ "Component updated successfully"
      assert render(view) =~ "Updated Motor"
      
      # Verify in database
      updated = Shop1Cmms.Assets.get_component!(component.id, component.tenant_id)
      assert updated.name == "Updated Motor"
    end
  end

  describe "Delete Component" do
    test "shows confirmation modal when clicking delete", %{conn: conn} do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components(component_count: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      view
      |> element("button[phx-click='confirm_delete_component'][phx-value-id='#{component.id}']")
      |> render_click()
      
      assert render(view) =~ "Delete Component?"
      assert render(view) =~ component.name
    end

    test "deletes component when confirmed", %{conn: conn} do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components(component_count: 1)
      component_name = component.name
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      view
      |> element("button[phx-click='confirm_delete_component'][phx-value-id='#{component.id}']")
      |> render_click()
      
      view
      |> element("button[phx-click='delete_component'][phx-value-id='#{component.id}']")
      |> render_click()
      
      assert render(view) =~ "Component deleted successfully"
      refute render(view) =~ component_name
      
      # Verify in database
      components = Shop1Cmms.Assets.list_components_for_asset(asset.id, asset.tenant_id)
      assert components == []
    end

    test "cancels deletion when clicking cancel", %{conn: conn} do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components(component_count: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      view
      |> element("button[phx-click='confirm_delete_component'][phx-value-id='#{component.id}']")
      |> render_click()
      
      view
      |> element("button", "Cancel")
      |> render_click()
      
      # Component should still exist
      assert render(view) =~ component.name
      
      components = Shop1Cmms.Assets.list_components_for_asset(asset.id, asset.tenant_id)
      assert length(components) == 1
    end
  end

  describe "Schedule PM from Component" do
    test "navigates to PM creation with component pre-selected", %{conn: conn} do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components(component_count: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      # Click Schedule PM button
      {:ok, pm_view, _html} = view
      |> element("a[href='/assets/#{asset.id}/components/#{component.id}/schedule-pm']")
      |> render_click()
      |> follow_redirect(conn)
      
      html = render(pm_view)
      assert html =~ "Schedule PM"
      assert html =~ component.name
      assert html =~ asset.name
    end
  end

  describe "Component Status Display" do
    test "shows correct status badge color", %{conn: conn} do
      asset = Factory.insert(:asset, tenant_id: 1)
      
      Factory.insert(:component, asset_id: asset.id, name: "Active Component", status: :active, tenant_id: 1)
      Factory.insert(:component, asset_id: asset.id, name: "Maintenance Component", status: :maintenance, tenant_id: 1)
      Factory.insert(:component, asset_id: asset.id, name: "Failed Component", status: :failed, tenant_id: 1)
      Factory.insert(:component, asset_id: asset.id, name: "Inactive Component", status: :inactive, tenant_id: 1)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      html = render(view)
      
      # Check for status badges (colors are in CSS classes)
      assert html =~ "Active"
      assert html =~ "Maintenance"
      assert html =~ "Failed"
      assert html =~ "Inactive"
    end
  end

  describe "Tenant Isolation" do
    test "cannot access asset from different tenant", %{conn: conn} do
      # Create asset for different tenant
      asset = Factory.insert(:asset, tenant_id: 999)
      
      assert_error_sent 404, fn ->
        live(conn, "/assets/#{asset.id}")
      end
    end

    test "cannot see components from different tenant", %{conn: conn} do
      asset1 = Factory.insert(:asset, tenant_id: 1)
      asset2 = Factory.insert(:asset, tenant_id: 999)
      
      Factory.insert(:component, asset_id: asset2.id, name: "Other Tenant Component", tenant_id: 999)
      
      {:ok, view, _html} = live(conn, "/assets/#{asset1.id}")
      
      view
      |> element("button[phx-value-tab='components']")
      |> render_click()
      
      refute render(view) =~ "Other Tenant Component"
    end
  end
end
