defmodule Shop1Cmms.MaintenancePmTagsTest do
  use Shop1Cmms.DataCase

  alias Shop1Cmms.Maintenance
  import Shop1Cmms.MaintenanceFixtures
  import Shop1Cmms.AccountsFixtures

  describe "list_pm_tags/2 with tag_type filter" do
    setup do
      tenant = tenant_fixture()
      
      # Create tags of different types
      skill1 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Electrical", tag_type: :skill})
      skill2 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Mechanical", tag_type: :skill})
      tool1 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Torque Wrench", tag_type: :tool})
      tool2 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Multimeter", tag_type: :tool})
      ppe1 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Safety Glasses", tag_type: :ppe})
      ppe2 = pm_tag_fixture(%{tenant_id: tenant.id, name: "Gloves", tag_type: :ppe})
      
      %{
        tenant: tenant,
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

    test "returns all tags when no filter is provided", %{tenant: tenant, tags: tags} do
      results = Maintenance.list_pm_tags(tenant.id)
      
      assert length(results) == 6
      assert Enum.any?(results, &(&1.id == tags.skill1.id))
      assert Enum.any?(results, &(&1.id == tags.tool1.id))
      assert Enum.any?(results, &(&1.id == tags.ppe1.id))
    end

    test "filters by skill type using atom", %{tenant: tenant, tags: tags} do
      results = Maintenance.list_pm_tags(tenant.id, tag_type: :skill)
      
      assert length(results) == 2
      assert Enum.all?(results, &(&1.tag_type == :skill))
      assert Enum.any?(results, &(&1.id == tags.skill1.id))
      assert Enum.any?(results, &(&1.id == tags.skill2.id))
    end

    test "filters by skill type using string", %{tenant: tenant, tags: tags} do
      results = Maintenance.list_pm_tags(tenant.id, tag_type: "skill")
      
      assert length(results) == 2
      assert Enum.all?(results, &(&1.tag_type == :skill))
      assert Enum.any?(results, &(&1.id == tags.skill1.id))
      assert Enum.any?(results, &(&1.id == tags.skill2.id))
    end

    test "filters by tool type using atom", %{tenant: tenant, tags: tags} do
      results = Maintenance.list_pm_tags(tenant.id, tag_type: :tool)
      
      assert length(results) == 2
      assert Enum.all?(results, &(&1.tag_type == :tool))
      assert Enum.any?(results, &(&1.id == tags.tool1.id))
      assert Enum.any?(results, &(&1.id == tags.tool2.id))
    end

    test "filters by tool type using string", %{tenant: tenant, tags: tags} do
      results = Maintenance.list_pm_tags(tenant.id, tag_type: "tool")
      
      assert length(results) == 2
      assert Enum.all?(results, &(&1.tag_type == :tool))
      assert Enum.any?(results, &(&1.id == tags.tool1.id))
      assert Enum.any?(results, &(&1.id == tags.tool2.id))
    end

    test "filters by ppe type using atom", %{tenant: tenant, tags: tags} do
      results = Maintenance.list_pm_tags(tenant.id, tag_type: :ppe)
      
      assert length(results) == 2
      assert Enum.all?(results, &(&1.tag_type == :ppe))
      assert Enum.any?(results, &(&1.id == tags.ppe1.id))
      assert Enum.any?(results, &(&1.id == tags.ppe2.id))
    end

    test "filters by ppe type using string", %{tenant: tenant, tags: tags} do
      results = Maintenance.list_pm_tags(tenant.id, tag_type: "ppe")
      
      assert length(results) == 2
      assert Enum.all?(results, &(&1.tag_type == :ppe))
      assert Enum.any?(results, &(&1.id == tags.ppe1.id))
      assert Enum.any?(results, &(&1.id == tags.ppe2.id))
    end

    test "ignores invalid tag_type filter", %{tenant: tenant} do
      results = Maintenance.list_pm_tags(tenant.id, tag_type: "invalid")
      
      # Should return all tags when filter is invalid
      assert length(results) == 6
    end

    test "combines tag_type filter with active_only", %{tenant: tenant, tags: tags} do
      # Make one skill inactive
      Maintenance.update_pm_tag(tags.skill1, %{is_active: false})
      
      results = Maintenance.list_pm_tags(tenant.id, tag_type: :skill, active_only: true)
      
      # Should only return skill2 (active skill)
      assert length(results) == 1
      assert hd(results).id == tags.skill2.id
    end

    test "combines tag_type filter with search", %{tenant: tenant, tags: tags} do
      results = Maintenance.list_pm_tags(tenant.id, tag_type: :skill, search: "Electrical")
      
      # Should only return skill1 (Electrical)
      assert length(results) == 1
      assert hd(results).id == tags.skill1.id
      assert hd(results).name == "Electrical"
    end

    test "respects tenant isolation", %{tags: tags} do
      other_tenant = tenant_fixture()
      
      results = Maintenance.list_pm_tags(other_tenant.id, tag_type: :skill)
      
      # Should return no results for other tenant
      assert length(results) == 0
      assert not Enum.any?(results, &(&1.id == tags.skill1.id))
    end

    test "sorts by usage_count when specified", %{tenant: tenant, tags: tags} do
      # Set different usage counts
      Maintenance.update_pm_tag(tags.skill1, %{usage_count: 10})
      Maintenance.update_pm_tag(tags.skill2, %{usage_count: 5})
      
      results = Maintenance.list_pm_tags(tenant.id, tag_type: :skill, sort_by: "usage_count", sort_order: "desc")
      
      assert length(results) == 2
      assert hd(results).id == tags.skill1.id  # Higher usage count first
      assert Enum.at(results, 1).id == tags.skill2.id
    end

    test "sorts by name when specified", %{tenant: tenant, tags: tags} do
      results = Maintenance.list_pm_tags(tenant.id, tag_type: :skill, sort_by: "name", sort_order: "asc")
      
      assert length(results) == 2
      # "Electrical" comes before "Mechanical" alphabetically
      assert hd(results).id == tags.skill1.id
      assert Enum.at(results, 1).id == tags.skill2.id
    end
  end
end
