defmodule Shop1Cmms.AuditTest do
  use Shop1Cmms.DataCase
  
  alias Shop1Cmms.{Audit, Factory}

  describe "log_component_created/4" do
    test "creates audit log with component details" do
      component = Factory.insert(:component)
      user = Factory.insert(:user)
      
      assert {:ok, log} = Audit.log_component_created(
        component,
        user.id,
        component.tenant_id,
        %{note: "Test creation"}
      )
      
      assert log.entity_type == "component"
      assert log.entity_id == component.id
      assert log.action == "created"
      assert log.performed_by_id == user.id
      assert log.tenant_id == component.tenant_id
      assert log.changes["name"] == component.name
      assert log.metadata["note"] == "Test creation"
    end
  end

  describe "log_component_updated/5" do
    test "logs component update with changes" do
      component = Factory.insert(:component, name: "Old Name")
      user = Factory.insert(:user)
      changes = %{name: "New Name", manufacturer: "ABB"}
      
      assert {:ok, log} = Audit.log_component_updated(
        component,
        changes,
        user.id,
        component.tenant_id
      )
      
      assert log.action == "updated"
      assert log.changes == changes
    end
  end

  describe "log_component_deleted/4" do
    test "logs component deletion" do
      component = Factory.insert(:component)
      user = Factory.insert(:user)
      
      assert {:ok, log} = Audit.log_component_deleted(
        component,
        user.id,
        component.tenant_id,
        %{reason: "Obsolete"}
      )
      
      assert log.action == "deleted"
      assert log.metadata["reason"] == "Obsolete"
      assert log.changes["name"] == component.name
    end
  end

  describe "log_component_status_changed/6" do
    test "logs status change with old and new values" do
      component = Factory.insert(:component, status: :active)
      user = Factory.insert(:user)
      
      assert {:ok, log} = Audit.log_component_status_changed(
        component,
        :active,
        :maintenance,
        user.id,
        component.tenant_id,
        "Scheduled maintenance"
      )
      
      assert log.action == "status_changed"
      assert log.changes["old_status"] == :active
      assert log.changes["new_status"] == :maintenance
      assert log.metadata["reason"] == "Scheduled maintenance"
    end
  end

  describe "log_component_replaced/5" do
    test "logs component replacement with both component details" do
      asset = Factory.insert(:asset)
      old_component = Factory.insert(:component, asset_id: asset.id, serial_number: "SN-OLD")
      new_component = Factory.insert(:component, asset_id: asset.id, serial_number: "SN-NEW")
      user = Factory.insert(:user)
      
      assert {:ok, log} = Audit.log_component_replaced(
        old_component,
        new_component,
        user.id,
        old_component.tenant_id,
        "Failed bearing"
      )
      
      assert log.action == "replaced"
      assert log.entity_id == old_component.id
      assert log.changes["old_serial_number"] == "SN-OLD"
      assert log.changes["new_serial_number"] == "SN-NEW"
      assert log.changes["new_component_id"] == new_component.id
      assert log.metadata["reason"] == "Failed bearing"
    end
  end

  describe "get_component_history/2" do
    test "returns all audit logs for a component in chronological order" do
      component = Factory.insert(:component)
      user = Factory.insert(:user)
      
      # Create multiple audit logs
      Audit.log_component_created(component, user.id, component.tenant_id)
      :timer.sleep(10) # Ensure different timestamps
      Audit.log_component_updated(component, %{name: "Updated"}, user.id, component.tenant_id)
      :timer.sleep(10)
      Audit.log_component_status_changed(component, :active, :maintenance, user.id, component.tenant_id)
      
      history = Audit.get_component_history(component.id, component.tenant_id)
      
      assert length(history) == 3
      
      # Should be ordered newest first
      [first, second, third] = history
      assert first.action == "status_changed"
      assert second.action == "updated"
      assert third.action == "created"
      
      # Check performed_by is preloaded
      assert first.performed_by.id == user.id
    end

    test "returns empty list for component with no history" do
      component = Factory.insert(:component)
      history = Audit.get_component_history(component.id, component.tenant_id)
      
      assert history == []
    end

    test "filters by tenant_id" do
      component = Factory.insert(:component, tenant_id: 1)
      user = Factory.insert(:user)
      
      Audit.log_component_created(component, user.id, 1)
      
      history = Audit.get_component_history(component.id, 999)
      assert history == []
    end
  end

  describe "get_recent_activity/2" do
    test "returns recent audit logs across all entities" do
      user = Factory.insert(:user)
      
      # Create various audit logs
      component1 = Factory.insert(:component, tenant_id: 1)
      component2 = Factory.insert(:component, tenant_id: 1)
      
      Audit.log_component_created(component1, user.id, 1)
      Audit.log_component_created(component2, user.id, 1)
      
      activity = Audit.get_recent_activity(1, 10)
      
      assert length(activity) == 2
      assert Enum.all?(activity, fn log -> log.tenant_id == 1 end)
    end

    test "limits results to specified count" do
      user = Factory.insert(:user)
      
      # Create more logs than limit
      Enum.each(1..10, fn _ ->
        component = Factory.insert(:component, tenant_id: 1)
        Audit.log_component_created(component, user.id, 1)
      end)
      
      activity = Audit.get_recent_activity(1, 5)
      
      assert length(activity) == 5
    end

    test "orders by newest first" do
      user = Factory.insert(:user)
      
      component1 = Factory.insert(:component, tenant_id: 1, name: "First")
      :timer.sleep(10)
      component2 = Factory.insert(:component, tenant_id: 1, name: "Second")
      
      Audit.log_component_created(component1, user.id, 1)
      Audit.log_component_created(component2, user.id, 1)
      
      activity = Audit.get_recent_activity(1, 10)
      
      [first, second] = activity
      assert first.changes["name"] == "Second"
      assert second.changes["name"] == "First"
    end
  end

  describe "get_audit_logs/2" do
    setup do
      user = Factory.insert(:user)
      tenant_id = 1
      
      component1 = Factory.insert(:component, tenant_id: tenant_id)
      component2 = Factory.insert(:component, tenant_id: tenant_id)
      
      Audit.log_component_created(component1, user.id, tenant_id)
      Audit.log_component_status_changed(component1, :active, :maintenance, user.id, tenant_id)
      Audit.log_component_created(component2, user.id, tenant_id)
      
      %{user: user, tenant_id: tenant_id, component1: component1, component2: component2}
    end

    test "filters by entity_type", %{tenant_id: tenant_id} do
      logs = Audit.get_audit_logs(tenant_id, entity_type: "component")
      
      assert length(logs) == 3
      assert Enum.all?(logs, fn log -> log.entity_type == "component" end)
    end

    test "filters by action", %{tenant_id: tenant_id} do
      logs = Audit.get_audit_logs(tenant_id, action: "created")
      
      assert length(logs) == 2
      assert Enum.all?(logs, fn log -> log.action == "created" end)
    end

    test "filters by date range", %{tenant_id: tenant_id} do
      today = DateTime.utc_now()
      yesterday = DateTime.add(today, -1, :day)
      tomorrow = DateTime.add(today, 1, :day)
      
      logs = Audit.get_audit_logs(tenant_id, from_date: yesterday, to_date: tomorrow)
      
      assert length(logs) == 3
    end

    test "respects limit option", %{tenant_id: tenant_id} do
      logs = Audit.get_audit_logs(tenant_id, limit: 2)
      
      assert length(logs) == 2
    end

    test "combines multiple filters", %{tenant_id: tenant_id} do
      logs = Audit.get_audit_logs(tenant_id,
        entity_type: "component",
        action: "created",
        limit: 1
      )
      
      assert length(logs) == 1
      assert hd(logs).action == "created"
      assert hd(logs).entity_type == "component"
    end
  end

  describe "tenant isolation" do
    test "audit logs are isolated by tenant" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      
      component1 = Factory.insert(:component, tenant_id: 1)
      component2 = Factory.insert(:component, tenant_id: 2)
      
      Audit.log_component_created(component1, user1.id, 1)
      Audit.log_component_created(component2, user2.id, 2)
      
      tenant1_logs = Audit.get_recent_activity(1)
      tenant2_logs = Audit.get_recent_activity(2)
      
      assert length(tenant1_logs) == 1
      assert length(tenant2_logs) == 1
      assert hd(tenant1_logs).tenant_id == 1
      assert hd(tenant2_logs).tenant_id == 2
    end
  end
end
