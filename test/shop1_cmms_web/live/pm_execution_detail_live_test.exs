defmodule Shop1CmmsWeb.PmExecutionDetailLiveTest do
  use Shop1CmmsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shop1Cmms.MaintenanceFixtures
  import Shop1Cmms.AccountsFixtures
  import Shop1Cmms.AssetsFixtures

  setup :register_and_log_in_user

  describe "PM Execution Detail Page" do
    setup %{user: user} do
      tenant_id = user.tenant_id || 1
      
      # Create asset
      asset = asset_fixture(%{tenant_id: tenant_id})
      
      # Create PM schedule
      schedule = pm_schedule_fixture(%{
        tenant_id: tenant_id,
        asset_id: asset.id,
        title: "Test PM Schedule"
      })
      
      # Create a completed PM execution
      execution = pm_execution_fixture(%{
        tenant_id: tenant_id,
        pm_schedule_id: schedule.id,
        asset_id: asset.id,
        status: :completed,
        execution_date: DateTime.utc_now(),
        completed_date: DateTime.utc_now(),
        completed_by_user_id: user.id,
        execution_number: "PMX-00000001",
        actual_duration_minutes: 120,
        tech_notes: "All systems checked and operational"
      })

      %{execution: execution, schedule: schedule, asset: asset}
    end

    test "displays PM execution details", %{conn: conn, execution: execution} do
      {:ok, view, html} = live(conn, ~p"/pm-executions/#{execution.id}")

      assert html =~ "PM Execution Details"
      assert html =~ execution.execution_number
      assert html =~ "All systems checked and operational"
    end

    test "shows completed status badge", %{conn: conn, execution: execution} do
      {:ok, _view, html} = live(conn, ~p"/pm-executions/#{execution.id}")

      assert html =~ "Completed"
      assert html =~ "bg-green-100"
    end

    test "displays read-only message", %{conn: conn, execution: execution} do
      {:ok, _view, html} = live(conn, ~p"/pm-executions/#{execution.id}")

      assert html =~ "This is a completed PM execution"
      assert html =~ "read-only"
    end

    test "navigates back to history", %{conn: conn, execution: execution} do
      {:ok, view, _html} = live(conn, ~p"/pm-executions/#{execution.id}")

      view
      |> element("button", "Back to History")
      |> render_click()

      assert_redirect(view, "/maintenance-history")
    end

    test "shows error for non-existent execution", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      
      {:ok, _view, _html} = live(conn, ~p"/pm-executions/#{non_existent_id}")

      assert_redirected(conn, "/maintenance-history")
    end
  end
end
