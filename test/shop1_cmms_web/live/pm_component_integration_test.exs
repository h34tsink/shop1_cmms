defmodule Shop1CmmsWeb.PmComponentIntegrationTest do
  use Shop1CmmsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shop1Cmms.Factory

  alias Shop1Cmms.{Assets, Maintenance, Repo}

  setup %{conn: conn} do
    # Create a tenant
    tenant = insert(:tenant)

    # Create a user
    user = insert(:user, %{is_active: true, cmms_enabled: true})

    # Create a role
    role = insert(:cmms_user_role, %{name: "admin", display_name: "Administrator"})

    # Assign user to tenant
    insert(:user_tenant_assignment, %{user_id: user.id, tenant_id: tenant.id, role_id: role.id})

    # Log in
    conn = log_in_user(conn, user)
    conn = Plug.Test.init_test_session(conn, tenant_id: tenant.id, user_id: user.id)

    # Create an asset
    asset_type = insert(:asset_type, %{tenant_id: tenant.id})
    location_type = insert(:asset_location_type, %{tenant_id: tenant.id})
    location = insert(:asset_location, %{tenant_id: tenant.id, location_type_id: location_type.id})
    
    asset = insert(:asset, %{
      tenant_id: tenant.id,
      asset_type_id: asset_type.id,
      location_id: location.id
    })

    # Create a component for the asset
    component = insert(:component, %{
      tenant_id: tenant.id,
      asset_id: asset.id,
      name: "Test Motor",
      description: "Main drive motor"
    })

    %{
      conn: conn,
      user: user,
      tenant: tenant,
      asset: asset,
      component: component
    }
  end

  describe "PM Schedule with Components" do
    test "creating PM schedule with component association", %{
      tenant: tenant,
      asset: asset,
      component: component
    } do
      # Create PM schedule
      {:ok, pm_schedule} = Maintenance.create_pm_schedule(%{
        tenant_id: tenant.id,
        asset_id: asset.id,
        title: "Motor PM",
        description: "Monthly motor maintenance",
        frequency: :monthly,
        frequency_interval: 1,
        estimated_duration: Decimal.new("2.5")
      })

      assert pm_schedule.title == "Motor PM"
      assert pm_schedule.asset_id == asset.id

      # Create component association
      {:ok, pm_component} = Maintenance.create_pm_schedule_component(%{
        pm_schedule_id: pm_schedule.id,
        component_name: component.name,
        component_description: component.description,
        component_location: nil,
        tenant_id: tenant.id
      })

      assert pm_component.component_name == "Test Motor"
      assert pm_component.component_description == "Main drive motor"

      # Check that component was associated with schedule
      pm_schedule_with_components = 
        Maintenance.get_pm_schedule!(tenant.id, pm_schedule.id)

      components = pm_schedule_with_components.components
      assert length(components) == 1

      retrieved_component = hd(components)
      assert retrieved_component.component_name == "Test Motor"
      assert retrieved_component.component_description == "Main drive motor"
    end

    test "PM schedule components can be deleted and recreated", %{
      tenant: tenant,
      asset: asset,
      component: component
    } do
      # Create PM schedule with component
      {:ok, pm_schedule} = Maintenance.create_pm_schedule(%{
        tenant_id: tenant.id,
        asset_id: asset.id,
        title: "Component PM",
        frequency: :monthly,
        frequency_interval: 1
      })

      # Create component association
      {:ok, _pm_component} = Maintenance.create_pm_schedule_component(%{
        pm_schedule_id: pm_schedule.id,
        component_name: component.name,
        component_description: component.description,
        component_location: nil,
        tenant_id: tenant.id
      })

      # Verify component was created
      pm_schedule_with_components = Maintenance.get_pm_schedule!(tenant.id, pm_schedule.id)
      assert length(pm_schedule_with_components.components) == 1

      # Delete all components for the schedule
      Maintenance.delete_pm_schedule_components(pm_schedule.id)

      # Verify components were deleted
      pm_schedule_after_delete = Maintenance.get_pm_schedule!(tenant.id, pm_schedule.id)
      assert length(pm_schedule_after_delete.components) == 0
    end
  end
end
