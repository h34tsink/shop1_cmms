defmodule Shop1Cmms.MaintenanceFixtures do
  @moduledoc """
  This module defines test fixtures for Maintenance context.
  """

  alias Shop1Cmms.Maintenance
  alias Shop1Cmms.Repo

  @doc """
  Generate a PM schedule.
  """
  def pm_schedule_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"
    asset_id = attrs[:asset_id] || raise "asset_id is required"

    {:ok, pm_schedule} =
      attrs
      |> Enum.into(%{
        # schedule_number is auto-generated, don't provide it unless explicitly set
        title: "Test PM Schedule",
        description: "Test PM Description",
        frequency: :monthly,
        frequency_interval: 1,
        work_instructions: "Test work instructions",
        estimated_duration: Decimal.new("2.5"),
        is_active: true,
        tenant_id: tenant_id,
        asset_id: asset_id
      })
      |> Maintenance.create_pm_schedule()

    pm_schedule
  end

  @doc """
  Generate a PM schedule component.
  """
  def pm_schedule_component_fixture(attrs \\ %{}) do
    pm_schedule_id = attrs[:pm_schedule_id] || raise "pm_schedule_id is required"
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"

    component_attrs =
      attrs
      |> Enum.into(%{
        component_name: "Test Component",
        component_type: "Test Type",
        instructions: "Test component instructions",
        estimated_duration: Decimal.new("1.0"),
        sequence_order: 1,
        is_required: true,
        tenant_id: tenant_id,
        pm_schedule_id: pm_schedule_id
      })

    {:ok, component} = Maintenance.create_pm_schedule_component(component_attrs)
    component
  end

  @doc """
  Generate a PM checklist item.
  """
  def pm_checklist_item_fixture(attrs \\ %{}) do
    pm_schedule_id = attrs[:pm_schedule_id] || raise "pm_schedule_id is required"
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"

    item_attrs =
      attrs
      |> Enum.into(%{
        item_text: "Test checklist item",
        item_type: :checkbox,
        sequence_order: 1,
        is_required: true,
        tenant_id: tenant_id,
        pm_schedule_id: pm_schedule_id
      })

    {:ok, item} = Maintenance.create_pm_checklist_item(item_attrs)
    item
  end

  @doc """
  Generate a PM execution.
  """
  def pm_execution_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"
    pm_schedule_id = attrs[:pm_schedule_id] || raise "pm_schedule_id is required"
    asset_id = attrs[:asset_id] || raise "asset_id is required"

    execution_attrs =
      attrs
      |> Enum.into(%{
        execution_number: "PMX-#{String.pad_leading("#{System.unique_integer([:positive])}", 8, "0")}",
        execution_date: DateTime.utc_now(),
        status: :scheduled,
        tenant_id: tenant_id,
        pm_schedule_id: pm_schedule_id,
        asset_id: asset_id
      })

    {:ok, execution} = Maintenance.create_pm_execution(execution_attrs)
    execution
  end

  @doc """
  Generate an asset document.
  """
  def asset_document_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"

    document_attrs =
      attrs
      |> Enum.into(%{
        document_number: "DOC-#{System.unique_integer([:positive])}",
        title: "Test Document",
        description: "Test document description",
        document_type: :manual,
        file_name: "test.pdf",
        file_path: "/uploads/test.pdf",
        file_size: 1024,
        mime_type: "application/pdf",
        is_active: true,
        tenant_id: tenant_id
      })

    {:ok, document} = Maintenance.create_asset_document(document_attrs)
    document
  end

  @doc """
  Generate a PM tag.
  """
  def pm_tag_fixture(attrs \\ %{}) do
    tenant_id = attrs[:tenant_id] || raise "tenant_id is required"
    
    tag_attrs =
      attrs
      |> Enum.into(%{
        name: "Test Tag #{System.unique_integer([:positive])}",
        tag_type: :skill,
        description: "Test tag description",
        is_active: true,
        usage_count: 0,
        tenant_id: tenant_id
      })

    {:ok, tag} = Maintenance.create_pm_tag(tag_attrs)
    tag
  end
end
