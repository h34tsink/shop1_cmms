defmodule Shop1CmmsWeb.PmSchedulesLiveTest do
  use Shop1CmmsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shop1Cmms.MaintenanceFixtures
  import Shop1Cmms.AssetsFixtures
  import Shop1Cmms.AccountsFixtures

  alias Shop1Cmms.Maintenance

  describe "Index" do
    setup [:create_user_and_tenant, :create_asset, :register_and_log_in_user]

    test "lists all pm_schedules", %{conn: conn, tenant: tenant, asset: asset} do
      pm_schedule = pm_schedule_fixture(%{tenant_id: tenant.id, asset_id: asset.id})
      {:ok, _index_live, html} = live(conn, ~p"/pm-schedules")

      assert html =~ "PM Schedules"
      assert html =~ pm_schedule.title
    end

    test "displays work instructions in schedule list", %{conn: conn, tenant: tenant, asset: asset} do
      pm_schedule = pm_schedule_fixture(%{
        tenant_id: tenant.id,
        asset_id: asset.id,
        work_instructions: "Test work instructions for maintenance"
      })
      
      {:ok, index_live, _html} = live(conn, ~p"/pm-schedules")
      
      # Click on the schedule to view details
      html = index_live
      |> element("tr", pm_schedule.schedule_number)
      |> render_click()
      
      assert html =~ pm_schedule.work_instructions
    end

    test "saves new pm_schedule with work instructions", %{conn: conn, asset: asset} do
      {:ok, index_live, _html} = live(conn, ~p"/pm-schedules")

      assert index_live |> element("a", "New PM Schedule") |> render_click() =~
               "New PM Schedule"

      assert_patch(index_live, ~p"/pm-schedules/new")

      form_data = %{
        "schedule_number" => "PM-TEST-001",
        "title" => "Test PM Schedule",
        "description" => "Test Description",
        "frequency" => "monthly",
        "work_instructions" => "1. Turn off equipment\n2. Check oil level\n3. Inspect belts",
        "asset_id" => asset.id
      }

      assert index_live
             |> form("#pm-schedule-form", pm_schedule: form_data)
             |> render_submit()

      assert_patch(index_live, ~p"/pm-schedules")

      html = render(index_live)
      assert html =~ "PM schedule created successfully"
      assert html =~ "PM-TEST-001"
    end

    test "updates pm_schedule work instructions", %{conn: conn, tenant: tenant, asset: asset} do
      pm_schedule = pm_schedule_fixture(%{
        tenant_id: tenant.id,
        asset_id: asset.id,
        work_instructions: "Old instructions"
      })

      {:ok, index_live, _html} = live(conn, ~p"/pm-schedules")

      assert index_live
             |> element("a[href='/pm-schedules/#{pm_schedule.id}/edit']")
             |> render_click() =~
               "Edit PM Schedule"

      assert_patch(index_live, ~p"/pm-schedules/#{pm_schedule.id}/edit")

      updated_instructions = "1. New step one\n2. New step two\n3. New step three"

      assert index_live
             |> form("#pm-schedule-form", pm_schedule: %{work_instructions: updated_instructions})
             |> render_submit()

      assert_patch(index_live, ~p"/pm-schedules")

      # Verify the instructions were updated
      updated_schedule = Maintenance.get_pm_schedule!(tenant.id, pm_schedule.id)
      assert updated_schedule.work_instructions == updated_instructions
    end
  end

  describe "PM Schedule Components" do
    setup [:create_user_and_tenant, :create_asset, :register_and_log_in_user]

    test "displays components for multi-component PM schedules", %{conn: conn, tenant: tenant, asset: asset} do
      pm_schedule = pm_schedule_fixture(%{tenant_id: tenant.id, asset_id: asset.id})
      
      # Add components to the schedule
      component1 = pm_schedule_component_fixture(%{
        pm_schedule_id: pm_schedule.id,
        tenant_id: tenant.id,
        component_name: "Hydraulic System",
        instructions: "Check hydraulic fluid level"
      })
      
      component2 = pm_schedule_component_fixture(%{
        pm_schedule_id: pm_schedule.id,
        tenant_id: tenant.id,
        component_name: "Electrical System",
        instructions: "Inspect wiring connections"
      })

      {:ok, index_live, _html} = live(conn, ~p"/pm-schedules")
      
      # View schedule details
      html = index_live
      |> element("tr", pm_schedule.schedule_number)
      |> render_click()
      
      assert html =~ component1.component_name
      assert html =~ component1.instructions
      assert html =~ component2.component_name
      assert html =~ component2.instructions
    end
  end

  describe "PM Schedule Documents" do
    setup [:create_user_and_tenant, :create_asset, :register_and_log_in_user]

    test "lists documents attached to PM schedule", %{conn: conn, tenant: tenant, asset: asset} do
      pm_schedule = pm_schedule_fixture(%{tenant_id: tenant.id, asset_id: asset.id})
      
      # Create documents attached to the PM schedule
      doc1 = asset_document_fixture(%{
        pm_schedule_id: pm_schedule.id,
        tenant_id: tenant.id,
        title: "Maintenance Manual",
        document_type: :manual
      })
      
      doc2 = asset_document_fixture(%{
        pm_schedule_id: pm_schedule.id,
        tenant_id: tenant.id,
        title: "Work Instruction Sheet",
        document_type: :work_instruction
      })

      {:ok, index_live, _html} = live(conn, ~p"/pm-schedules")
      
      # View schedule details with documents
      html = index_live
      |> element("tr", pm_schedule.schedule_number)
      |> render_click()
      
      assert html =~ doc1.title
      assert html =~ doc2.title
    end

    test "uploads new document to PM schedule", %{conn: conn, tenant: tenant, asset: asset} do
      pm_schedule = pm_schedule_fixture(%{tenant_id: tenant.id, asset_id: asset.id})

      {:ok, index_live, _html} = live(conn, ~p"/pm-schedules/#{pm_schedule.id}/edit")
      
      # Simulate document upload
      assert index_live
             |> element("button", "Add Document")
             |> render_click() =~ "Upload Document"
    end
  end

  defp create_user_and_tenant(_) do
    tenant = tenant_fixture()
    user = user_fixture(%{email: "test@example.com", tenant_id: tenant.id})
    %{user: user, tenant: tenant}
  end

  defp create_asset(%{tenant: tenant}) do
    asset_type = asset_type_fixture(%{tenant_id: tenant.id})
    location = asset_location_fixture(%{tenant_id: tenant.id})
    asset = asset_fixture(%{
      tenant_id: tenant.id,
      asset_type_id: asset_type.id,
      location_id: location.id
    })
    %{asset: asset, asset_type: asset_type, location: location}
  end

  defp register_and_log_in_user(%{conn: conn, user: user}) do
    %{conn: log_in_user(conn, user)}
  end
end
