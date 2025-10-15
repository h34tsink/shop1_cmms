defmodule Shop1CmmsWeb.MetadataLiveTest do
  use Shop1CmmsWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shop1Cmms.MaintenanceFixtures
  import Shop1Cmms.AccountsFixtures

  alias Shop1Cmms.Maintenance

  describe "PM Tags Filter" do
    setup [:create_user_and_tenant, :create_pm_tags, :register_and_log_in_user]

    test "displays all pm tags by default", %{conn: conn, tags: tags} do
      {:ok, _view, html} = live(conn, ~p"/configuration/pm_tags")

      assert html =~ "PM Tags"
      # All tags should be visible
      assert html =~ tags.skill1.name
      assert html =~ tags.skill2.name
      assert html =~ tags.tool1.name
      assert html =~ tags.tool2.name
      assert html =~ tags.ppe1.name
      assert html =~ tags.ppe2.name
    end

    test "filter dropdown shows correct options", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")
      
      html = render(view)
      
      # Check that filter dropdown exists with all options
      assert html =~ "All Types"
      assert html =~ "Skills"
      assert html =~ "Tools"
      assert html =~ "PPE"
    end

    test "filters by skill type", %{conn: conn, tags: tags} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Change filter to "skill"
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "skill"})
        |> render_change()

      # Should show only skill tags
      assert html =~ tags.skill1.name
      assert html =~ tags.skill2.name
      
      # Should not show tool or ppe tags
      refute html =~ tags.tool1.name
      refute html =~ tags.tool2.name
      refute html =~ tags.ppe1.name
      refute html =~ tags.ppe2.name
      
      # Should show correct count
      assert html =~ ~r/>2<\/span>\s+items/
    end

    test "filters by tool type", %{conn: conn, tags: tags} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Change filter to "tool"
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "tool"})
        |> render_change()

      # Should show only tool tags
      assert html =~ tags.tool1.name
      assert html =~ tags.tool2.name
      
      # Should not show skill or ppe tags
      refute html =~ tags.skill1.name
      refute html =~ tags.skill2.name
      refute html =~ tags.ppe1.name
      refute html =~ tags.ppe2.name
      
      # Should show correct count
      assert html =~ ~r/>2<\/span>\s+items/
    end

    test "filters by ppe type", %{conn: conn, tags: tags} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Change filter to "ppe"
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "ppe"})
        |> render_change()

      # Should show only ppe tags
      assert html =~ tags.ppe1.name
      assert html =~ tags.ppe2.name
      
      # Should not show skill or tool tags
      refute html =~ tags.skill1.name
      refute html =~ tags.skill2.name
      refute html =~ tags.tool1.name
      refute html =~ tags.tool2.name
      
      # Should show correct count
      assert html =~ ~r/>2<\/span>\s+items/
    end

    test "switching between filters works correctly", %{conn: conn, tags: tags} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Filter by skill
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "skill"})
        |> render_change()

      assert html =~ tags.skill1.name
      refute html =~ tags.tool1.name

      # Switch to tool
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "tool"})
        |> render_change()

      refute html =~ tags.skill1.name
      assert html =~ tags.tool1.name

      # Switch back to all
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "all"})
        |> render_change()

      assert html =~ tags.skill1.name
      assert html =~ tags.tool1.name
      assert html =~ tags.ppe1.name
    end

    test "filter dropdown highlights when active", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Default state - no highlighting
      html = render(view)
      refute html =~ ~r/border-blue-500.*bg-blue-50.*font-medium/s

      # Filter by skill - dropdown should be highlighted
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "skill"})
        |> render_change()

      assert html =~ "border-blue-500"
      assert html =~ "bg-blue-50"
    end

    test "filter persists with search", %{conn: conn, tags: tags} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Filter by skill
      view
      |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "skill"})
      |> render_change()

      # Perform search
      html =
        view
        |> form("form[phx-change='search']", search: %{query: tags.skill1.name})
        |> render_change()

      # Should show only the searched skill tag
      assert html =~ tags.skill1.name
      refute html =~ tags.skill2.name
      refute html =~ tags.tool1.name
      
      # Should indicate filtered results
      assert html =~ ~r/>1<\/span>\s+item\b/
    end

    test "shows correct tag type badges", %{conn: conn, tags: tags} do
      {:ok, _view, html} = live(conn, ~p"/configuration/pm_tags")

      # Check for skill badge
      assert html =~ ~r/bg-blue-100.*text-blue-800.*Skill/s
      
      # Check for tool badge
      assert html =~ ~r/bg-purple-100.*text-purple-800.*Tool/s
      
      # Check for ppe badge
      assert html =~ ~r/bg-orange-100.*text-orange-800.*PPE/s
    end

    test "empty filter results show appropriate message", %{conn: conn, tenant: tenant} do
      # Delete all tags
      Maintenance.list_pm_tags(tenant.id)
      |> Enum.each(&Maintenance.delete_pm_tag/1)

      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Filter by skill
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "skill"})
        |> render_change()

      assert html =~ "No pm tags (skills, tools, ppe) found"
      assert html =~ ~r/>0<\/span>\s+items/
    end

    test "filter works with inactive tags", %{conn: conn, tags: tags, tenant: tenant} do
      # Make skill1 inactive
      Maintenance.update_pm_tag(tags.skill1, %{is_active: false})

      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Filter by skill - should only show active skill (skill2)
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "skill"})
        |> render_change()

      # Only skill2 should be visible (skill1 is inactive)
      refute html =~ tags.skill1.name
      assert html =~ tags.skill2.name
    end

    test "filter displays usage count correctly", %{conn: conn, tags: tags, tenant: tenant} do
      # Update usage counts
      Maintenance.update_pm_tag(tags.skill1, %{usage_count: 5})
      Maintenance.update_pm_tag(tags.tool1, %{usage_count: 10})

      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Filter by skill
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "skill"})
        |> render_change()

      # Should show usage count for skill1
      assert html =~ "5"
      
      # Switch to tool filter
      html =
        view
        |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "tool"})
        |> render_change()

      # Should show usage count for tool1
      assert html =~ "10"
    end

    test "sortable columns work with filter", %{conn: conn, tags: tags} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Filter by skill first
      view
      |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "skill"})
      |> render_change()

      # Sort by name
      html =
        view
        |> element("th[phx-click='sort'][phx-value-field='name']")
        |> render_click()

      # Should still show only skills
      assert html =~ tags.skill1.name
      assert html =~ tags.skill2.name
      refute html =~ tags.tool1.name
      
      # Check for sort indicator
      assert html =~ ~r/svg.*w-4 h-4/s
    end
  end

  describe "PM Tags CRUD with Filter Active" do
    setup [:create_user_and_tenant, :create_pm_tags, :register_and_log_in_user]

    test "creating a new tag while filter is active", %{conn: conn, tenant: tenant} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Apply skill filter
      view
      |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "skill"})
      |> render_change()

      # Click new button
      view
      |> element("button[phx-click='new']")
      |> render_click()

      assert_patch(view, ~p"/configuration/pm_tags/new")

      # Create a new skill tag
      assert view
             |> form("form[phx-submit='save']",
               pm_tag: %{
                 name: "New Skill",
                 tag_type: "skill",
                 description: "New skill description"
               }
             )
             |> render_submit()

      assert_patch(view, ~p"/configuration/pm_tags")

      # New tag should appear in the filtered list
      html = render(view)
      assert html =~ "New Skill"
    end

    test "editing a tag preserves filter state", %{conn: conn, tags: tags} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Apply tool filter
      view
      |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "tool"})
      |> render_change()

      # Edit a tool tag
      view
      |> element("button[phx-click='edit'][phx-value-id='#{tags.tool1.id}']")
      |> render_click()

      assert_patch(view, ~p"/configuration/pm_tags/#{tags.tool1.id}/edit")

      # Update the tag
      assert view
             |> form("form[phx-submit='save']",
               pm_tag: %{
                 name: "Updated Tool Name"
               }
             )
             |> render_submit()

      assert_patch(view, ~p"/configuration/pm_tags")

      # Filter should still be active and show updated tag
      html = render(view)
      assert html =~ "Updated Tool Name"
      assert html =~ tags.tool2.name
      refute html =~ tags.skill1.name
    end

    test "deleting a tag updates filtered list", %{conn: conn, tags: tags} do
      {:ok, view, _html} = live(conn, ~p"/configuration/pm_tags")

      # Apply ppe filter
      view
      |> form("form[phx-change='filter_tag_type']", filter: %{tag_type: "ppe"})
      |> render_change()

      html = render(view)
      assert html =~ ~r/>2<\/span>\s+items/ # ppe1 and ppe2

      # Delete ppe1
      view
      |> element("button[phx-click='delete'][phx-value-id='#{tags.ppe1.id}']")
      |> render_click()

      html = render(view)
      
      # Should now show only 1 item
      assert html =~ ~r/>1<\/span>\s+item\b/
      refute html =~ tags.ppe1.name
      assert html =~ tags.ppe2.name
    end
  end

  defp create_user_and_tenant(_) do
    tenant = tenant_fixture()
    user = user_fixture(%{email: "test@example.com", tenant_id: tenant.id})
    
    # Get or create a role
    role = Shop1Cmms.Factory.get_or_create_role("technician")
    
    # Create user-tenant assignment
    Shop1Cmms.Accounts.create_user_tenant_assignment(%{
      user_id: user.id,
      tenant_id: tenant.id,
      role_id: role.id,
      is_active: true
    })
    
    # Add tenant_id to user for log_in_user helper
    user = Map.put(user, :tenant_id, tenant.id)
    
    %{user: user, tenant: tenant}
  end

  defp create_pm_tags(%{tenant: tenant}) do
    skill1 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Electrical", tag_type: :skill})
    skill2 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Mechanical", tag_type: :skill})
    tool1 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Torque Wrench", tag_type: :tool})
    tool2 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Multimeter", tag_type: :tool})
    ppe1 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Safety Glasses", tag_type: :ppe})
    ppe2 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Gloves", tag_type: :ppe})

    %{
      tags: %{
        skill1: skill1,
        skill2: skill2,
        tool1: tool1,
        tool2: tool2,
        ppe1: ppe1,
        ppe2: ppe2
      }
    }
  end
end

