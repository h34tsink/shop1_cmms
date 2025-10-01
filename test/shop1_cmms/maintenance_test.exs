defmodule Shop1Cmms.MaintenanceTest do
  use Shop1Cmms.DataCase

  alias Shop1Cmms.Maintenance
  alias Shop1Cmms.Maintenance.{PmSchedule, PmScheduleComponent, PmChecklistItem, AssetDocument}
  alias Shop1Cmms.{Assets, Tenants}

  describe "pm_schedules" do
    setup do
      # Create tenant
      {:ok, tenant} = Tenants.create_tenant(%{
        name: "Test Tenant",
        code: "TEST_TENANT",
        subdomain: "test-maintenance",
        timezone: "America/New_York"
      })

      # Create asset type
      {:ok, asset_type} = Assets.create_asset_type(%{
        name: "Test Equipment",
        code: "TEST_EQUIP",
        category: "Equipment",
        tenant_id: tenant.id
      })

      # Create location
      {:ok, location_type} = Assets.create_asset_location_type(%{
        name: "Test Location Type",
        code: "TEST_LOC_TYPE",
        tenant_id: tenant.id
      })

      {:ok, location} = Assets.create_asset_location(%{
        name: "Test Location",
        code: "TEST_LOC",
        location_type_id: location_type.id,
        tenant_id: tenant.id
      })

      # Create asset
      {:ok, asset} = Assets.create_asset(%{
        asset_number: "TEST-001",
        name: "Test Machine",
        status: :operational,
        asset_type_id: asset_type.id,
        location_id: location.id,
        tenant_id: tenant.id
      })

      %{tenant: tenant, asset: asset}
    end

    test "list_pm_schedules/1 returns all pm schedules for a tenant", %{tenant: tenant, asset: asset} do
      {:ok, _schedule1} = Maintenance.create_pm_schedule(%{
        schedule_number: "PM-001",
        title: "Monthly Inspection",
        frequency: :monthly,
        asset_id: asset.id,
        tenant_id: tenant.id
      })

      {:ok, _schedule2} = Maintenance.create_pm_schedule(%{
        schedule_number: "PM-002",
        title: "Weekly Check",
        frequency: :weekly,
        asset_id: asset.id,
        tenant_id: tenant.id
      })

      schedules = Maintenance.list_pm_schedules(tenant.id)
      assert length(schedules) >= 2
    end

    test "create_pm_schedule/1 with valid data creates a pm schedule", %{tenant: tenant, asset: asset} do
      attrs = %{
        schedule_number: "PM-TEST-001",
        title: "Daily Inspection",
        description: "Check all systems",
        frequency: :daily,
        frequency_interval: 1,
        work_instructions: "1. Check oil level\n2. Inspect for leaks",
        estimated_duration: Decimal.new("1.5"),
        required_skills: ["mechanical", "electrical"],
        required_tools: ["wrench", "multimeter"],
        required_parts: %{"oil" => "SAE 10W-30"},
        safety_notes: "Wear safety glasses",
        ppe_required: ["safety_glasses", "gloves"],
        is_active: true,
        asset_id: asset.id,
        tenant_id: tenant.id
      }

      assert {:ok, %PmSchedule{} = schedule} = Maintenance.create_pm_schedule(attrs)
      assert schedule.schedule_number == "PM-TEST-001"
      assert schedule.title == "Daily Inspection"
      assert schedule.frequency == :daily
      assert schedule.required_skills == ["mechanical", "electrical"]
      assert schedule.safety_notes == "Wear safety glasses"
    end

    test "calculate_next_due_date/1 calculates correctly for different frequencies" do
      base_date = DateTime.utc_now()

      # Daily
      schedule = %PmSchedule{frequency: :daily, frequency_interval: 1, last_completed_date: base_date}
      next = Maintenance.calculate_next_due_date(schedule)
      assert DateTime.diff(next, base_date, :day) == 1

      # Weekly
      schedule = %PmSchedule{frequency: :weekly, frequency_interval: 1, last_completed_date: base_date}
      next = Maintenance.calculate_next_due_date(schedule)
      assert DateTime.diff(next, base_date, :day) == 7

      # Monthly
      schedule = %PmSchedule{frequency: :monthly, frequency_interval: 1, last_completed_date: base_date}
      next = Maintenance.calculate_next_due_date(schedule)
      assert DateTime.diff(next, base_date, :day) == 30
    end
  end

  describe "asset_documents" do
    setup do
      {:ok, tenant} = Tenants.create_tenant(%{
        name: "Test Tenant Docs",
        code: "TEST_DOCS",
        subdomain: "test-docs",
        timezone: "America/New_York"
      })

      {:ok, asset_type} = Assets.create_asset_type(%{
        name: "Test Equipment",
        code: "TEST_EQUIP_DOC",
        category: "Equipment",
        tenant_id: tenant.id
      })

      {:ok, location_type} = Assets.create_asset_location_type(%{
        name: "Test Location Type",
        code: "TEST_LOC_TYPE_DOC",
        tenant_id: tenant.id
      })

      {:ok, location} = Assets.create_asset_location(%{
        name: "Test Location",
        code: "TEST_LOC_DOC",
        location_type_id: location_type.id,
        tenant_id: tenant.id
      })

      {:ok, asset} = Assets.create_asset(%{
        asset_number: "TEST-DOC-001",
        name: "Test Machine",
        status: :operational,
        asset_type_id: asset_type.id,
        location_id: location.id,
        tenant_id: tenant.id
      })

      %{tenant: tenant, asset: asset}
    end

    test "create_asset_document/1 creates a document", %{tenant: tenant, asset: asset} do
      attrs = %{
        document_number: "DOC-001",
        title: "Equipment Manual",
        description: "Operator's manual for test machine",
        document_type: :manual,
        file_name: "manual.pdf",
        file_path: "/uploads/manual.pdf",
        file_size: 1024000,
        mime_type: "application/pdf",
        version: "1.0",
        tags: ["manual", "operator"],
        asset_id: asset.id,
        tenant_id: tenant.id
      }

      assert {:ok, %AssetDocument{} = doc} = Maintenance.create_asset_document(attrs)
      assert doc.title == "Equipment Manual"
      assert doc.document_type == :manual
      assert doc.tags == ["manual", "operator"]
    end

    test "list_asset_documents/2 returns documents for asset", %{tenant: tenant, asset: asset} do
      {:ok, _doc1} = Maintenance.create_asset_document(%{
        title: "Manual",
        document_type: :manual,
        file_path: "/uploads/manual.pdf",
        asset_id: asset.id,
        tenant_id: tenant.id
      })

      {:ok, _doc2} = Maintenance.create_asset_document(%{
        title: "Drawing",
        document_type: :drawing,
        file_path: "/uploads/drawing.pdf",
        asset_id: asset.id,
        tenant_id: tenant.id
      })

      docs = Maintenance.list_asset_documents(tenant.id, asset.id)
      assert length(docs) == 2
    end
  end
end
