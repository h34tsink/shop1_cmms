defmodule Shop1Cmms.ComponentTest do
  use Shop1Cmms.DataCase
  
  alias Shop1Cmms.Assets
  alias Shop1Cmms.Factory

  describe "list_components_for_asset/2" do
    setup do
      %{asset: asset, components: components} = Factory.insert_asset_with_components(component_count: 3)
      %{asset: asset, components: components}
    end

    test "returns all components for an asset", %{asset: asset, components: components} do
      result = Assets.list_components_for_asset(asset.id, asset.tenant_id)
      
      assert length(result) == 3
      assert Enum.all?(result, fn c -> c.asset_id == asset.id end)
      
      component_ids = Enum.map(components, & &1.id) |> MapSet.new()
      result_ids = Enum.map(result, & &1.id) |> MapSet.new()
      assert MapSet.equal?(component_ids, result_ids)
    end

    test "returns empty list for asset with no components" do
      asset = Factory.insert(:asset, tenant_id: 1)
      result = Assets.list_components_for_asset(asset.id, asset.tenant_id)
      
      assert result == []
    end

    test "filters by tenant_id", %{asset: asset} do
      result = Assets.list_components_for_asset(asset.id, 999)
      assert result == []
    end

    test "orders components by name", %{asset: asset} do
      # Components created by factory have sequential names
      result = Assets.list_components_for_asset(asset.id, asset.tenant_id)
      names = Enum.map(result, & &1.name)
      
      assert names == Enum.sort(names)
    end
  end

  describe "get_component!/2" do
    test "returns component when exists and tenant matches" do
      %{components: [component | _]} = Factory.insert_asset_with_components()
      
      result = Assets.get_component!(component.id, component.tenant_id)
      
      assert result.id == component.id
      assert result.name == component.name
    end

    test "raises error when tenant doesn't match" do
      %{components: [component | _]} = Factory.insert_asset_with_components()
      
      assert_raise Ecto.NoResultsError, fn ->
        Assets.get_component!(component.id, 999)
      end
    end

    test "raises error when component doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Assets.get_component!(Ecto.UUID.generate(), 1)
      end
    end

    test "preloads asset association" do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components()
      
      result = Assets.get_component!(component.id, component.tenant_id)
      
      assert result.asset.id == asset.id
    end
  end

  describe "create_component/2" do
    setup do
      asset = Factory.insert(:asset, tenant_id: 1)
      user = Factory.insert(:user)
      %{asset: asset, user: user}
    end

    test "creates component with valid attrs", %{asset: asset, user: user} do
      attrs = %{
        "name" => "Test Motor",
        "component_type" => "Motor",
        "manufacturer" => "Siemens",
        "model" => "1LA7",
        "serial_number" => "SN-12345",
        "status" => "active",
        "asset_id" => asset.id,
        "tenant_id" => asset.tenant_id
      }
      
      assert {:ok, component} = Assets.create_component(attrs, user.id)
      assert component.name == "Test Motor"
      assert component.component_type == "Motor"
      assert component.asset_id == asset.id
    end

    test "creates audit log when user_id provided", %{asset: asset, user: user} do
      attrs = %{
        "name" => "Audited Component",
        "asset_id" => asset.id,
        "tenant_id" => asset.tenant_id
      }
      
      assert {:ok, component} = Assets.create_component(attrs, user.id)
      
      audit_logs = Shop1Cmms.Audit.get_component_history(component.id, asset.tenant_id)
      assert length(audit_logs) == 1
      
      [log] = audit_logs
      assert log.action == "created"
      assert log.entity_id == component.id
      assert log.performed_by_id == user.id
    end

    test "works without user_id", %{asset: asset} do
      attrs = %{
        "name" => "No Audit Component",
        "asset_id" => asset.id,
        "tenant_id" => asset.tenant_id
      }
      
      assert {:ok, component} = Assets.create_component(attrs, nil)
      assert component.name == "No Audit Component"
    end

    test "fails without required fields", %{asset: asset} do
      attrs = %{
        "asset_id" => asset.id,
        "tenant_id" => asset.tenant_id
      }
      
      assert {:error, changeset} = Assets.create_component(attrs, nil)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "validates status enum", %{asset: asset} do
      attrs = %{
        "name" => "Test",
        "status" => "invalid_status",
        "asset_id" => asset.id,
        "tenant_id" => asset.tenant_id
      }
      
      assert {:error, changeset} = Assets.create_component(attrs, nil)
      assert changeset.errors[:status]
    end
  end

  describe "update_component/3" do
    setup do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components()
      user = Factory.insert(:user)
      %{component: component, asset: asset, user: user}
    end

    test "updates component with valid attrs", %{component: component, user: user} do
      attrs = %{"name" => "Updated Name", "manufacturer" => "ABB"}
      
      assert {:ok, updated} = Assets.update_component(component, attrs, user.id)
      assert updated.name == "Updated Name"
      assert updated.manufacturer == "ABB"
    end

    test "creates audit log for update", %{component: component, user: user} do
      attrs = %{"name" => "New Name"}
      
      assert {:ok, _updated} = Assets.update_component(component, attrs, user.id)
      
      audit_logs = Shop1Cmms.Audit.get_component_history(component.id, component.tenant_id)
      assert length(audit_logs) >= 1
      
      [log | _] = audit_logs
      assert log.action in ["updated", "status_changed"]
    end

    test "creates special audit log for status change", %{component: component, user: user} do
      attrs = %{"status" => "maintenance"}
      
      assert {:ok, _updated} = Assets.update_component(component, attrs, user.id)
      
      audit_logs = Shop1Cmms.Audit.get_component_history(component.id, component.tenant_id)
      [log | _] = audit_logs
      
      assert log.action == "status_changed"
      assert log.changes["old_status"]
      assert log.changes["new_status"]
    end

    test "doesn't create audit log without user_id", %{component: component} do
      initial_count = length(Shop1Cmms.Audit.get_component_history(component.id, component.tenant_id))
      
      attrs = %{"name" => "No Audit"}
      assert {:ok, _updated} = Assets.update_component(component, attrs, nil)
      
      final_count = length(Shop1Cmms.Audit.get_component_history(component.id, component.tenant_id))
      assert final_count == initial_count
    end
  end

  describe "delete_component/2" do
    setup do
      %{asset: asset, components: [component | _]} = Factory.insert_asset_with_components()
      user = Factory.insert(:user)
      %{component: component, asset: asset, user: user}
    end

    test "deletes component", %{component: component, user: user} do
      assert {:ok, deleted} = Assets.delete_component(component, user.id)
      assert deleted.id == component.id
      
      assert_raise Ecto.NoResultsError, fn ->
        Assets.get_component!(component.id, component.tenant_id)
      end
    end

    test "creates audit log for deletion", %{component: component, user: user, asset: asset} do
      component_id = component.id
      tenant_id = component.tenant_id
      
      assert {:ok, _deleted} = Assets.delete_component(component, user.id)
      
      # Audit logs persist even after entity deletion
      audit_logs = Shop1Cmms.Audit.get_component_history(component_id, tenant_id)
      
      deleted_log = Enum.find(audit_logs, fn log -> log.action == "deleted" end)
      assert deleted_log
      assert deleted_log.performed_by_id == user.id
    end
  end

  describe "change_component/2" do
    test "returns changeset for new component" do
      changeset = Assets.change_component(%Shop1Cmms.Assets.Component{})
      assert %Ecto.Changeset{} = changeset
    end

    test "returns changeset with changes" do
      component = Factory.build(:component)
      changeset = Assets.change_component(component, %{name: "Changed"})
      
      assert changeset.changes.name == "Changed"
    end
  end
end
