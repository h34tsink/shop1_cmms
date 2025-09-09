# Phoenix Context Modules for PM Scheduling

## Overview
This document outlines the core Elixir context modules for the PM scheduling system, focusing on the business logic for preventive maintenance.

## Context Structure

```
lib/shop1_cmms/
├── maintenance/           # PM Scheduling Context
│   ├── pm_template.ex    # PM Template schema
│   ├── pm_schedule.ex    # PM Schedule schema  
│   └── pm_calculator.ex  # Scheduling calculations
├── work/                 # Work Order Context
│   ├── work_order.ex     # Work Order schema
│   └── work_order_task.ex# Work Order Task schema
├── assets/               # Asset Management Context
│   ├── asset.ex          # Asset schema
│   ├── component.ex      # Component schema
│   ├── meter.ex          # Meter schema
│   └── meter_reading.ex  # Meter Reading schema
└── maintenance.ex        # Main context module
```

## Core Context Modules

### 1. Maintenance Context (lib/shop1_cmms/maintenance.ex)

```elixir
defmodule Shop1Cmms.Maintenance do
  @moduledoc """
  The Maintenance context handles PM templates, schedules, and calculations.
  Focus on PM scheduling as the core feature.
  """

  import Ecto.Query, warn: false
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Maintenance.{PMTemplate, PMSchedule, PMCalculator}
  alias Shop1Cmms.Work.WorkOrder

  ## PM Templates

  def list_pm_templates(tenant_id) do
    PMTemplate
    |> where([t], t.tenant_id == ^tenant_id and t.active == true)
    |> order_by([t], t.name)
    |> Repo.all()
  end

  def get_pm_template!(id, tenant_id) do
    PMTemplate
    |> where([t], t.id == ^id and t.tenant_id == ^tenant_id)
    |> Repo.one!()
  end

  def create_pm_template(attrs \\ %{}) do
    %PMTemplate{}
    |> PMTemplate.changeset(attrs)
    |> Repo.insert()
  end

  def update_pm_template(%PMTemplate{} = template, attrs) do
    template
    |> PMTemplate.changeset(attrs)
    |> Repo.update()
  end

  ## PM Schedules

  def list_pm_schedules(tenant_id, opts \\ []) do
    query = PMSchedule
    |> where([s], s.tenant_id == ^tenant_id and s.active == true)
    |> preload([:pm_template, :asset, :component, :assigned_to])

    query = case Keyword.get(opts, :overdue_only) do
      true -> where(query, [s], s.days_overdue > 0)
      _ -> query
    end

    query
    |> order_by([s], [asc: s.next_due_date, desc: s.days_overdue])
    |> Repo.all()
  end

  def get_overdue_pms(tenant_id) do
    list_pm_schedules(tenant_id, overdue_only: true)
  end

  def create_pm_schedule(attrs \\ %{}) do
    changeset = %PMSchedule{}
    |> PMSchedule.changeset(attrs)

    case Repo.insert(changeset) do
      {:ok, schedule} ->
        # Calculate initial next due date
        calculate_next_due_date(schedule.id)
        {:ok, Repo.get!(PMSchedule, schedule.id)}
      error -> error
    end
  end

  def complete_pm_schedule(schedule_id, completion_attrs \\ %{}) do
    schedule = Repo.get!(PMSchedule, schedule_id)
    
    attrs = Map.merge(completion_attrs, %{
      last_completed_at: DateTime.utc_now(),
      last_completed_by: completion_attrs[:completed_by]
    })

    case update_pm_schedule(schedule, attrs) do
      {:ok, updated_schedule} ->
        # Recalculate next due date
        calculate_next_due_date(schedule_id)
        {:ok, Repo.get!(PMSchedule, schedule_id)}
      error -> error
    end
  end

  ## PM Calculations

  def calculate_next_due_date(schedule_id) do
    PMCalculator.calculate_and_update_next_due(schedule_id)
  end

  def recalculate_all_schedules(tenant_id) do
    tenant_id
    |> list_pm_schedules()
    |> Enum.each(fn schedule ->
      calculate_next_due_date(schedule.id)
    end)
  end

  ## Auto Work Order Generation

  def generate_due_work_orders(tenant_id) do
    due_schedules = PMSchedule
    |> where([s], s.tenant_id == ^tenant_id)
    |> where([s], s.active == true)
    |> where([s], s.next_due_date <= ^Date.utc_today())
    |> preload([:pm_template, :asset, :component])
    |> Repo.all()

    Enum.map(due_schedules, &create_work_order_from_schedule/1)
  end

  defp create_work_order_from_schedule(schedule) do
    attrs = %{
      tenant_id: schedule.tenant_id,
      site_id: schedule.asset.site_id, # Assuming asset has site_id
      number: generate_work_order_number(schedule.tenant_id),
      title: "PM: #{schedule.pm_template.name}",
      description: schedule.pm_template.description,
      work_type: "preventive",
      asset_id: schedule.asset_id,
      component_id: schedule.component_id,
      pm_schedule_id: schedule.id,
      assigned_to: schedule.assigned_to,
      due_date: schedule.next_due_date,
      estimated_hours: schedule.pm_template.estimated_duration_hours,
      status: "new",
      priority: 3 # Default priority
    }

    case Shop1Cmms.Work.create_work_order(attrs) do
      {:ok, work_order} ->
        # Create tasks from PM template
        create_tasks_from_template(work_order, schedule.pm_template)
        {:ok, work_order}
      error -> error
    end
  end

  defp create_tasks_from_template(work_order, template) do
    template.task_list
    |> Enum.with_index(1)
    |> Enum.each(fn {task_description, index} ->
      Shop1Cmms.Work.create_work_order_task(%{
        work_order_id: work_order.id,
        tenant_id: work_order.tenant_id,
        sequence_no: index,
        description: task_description
      })
    end)
  end

  defp generate_work_order_number(tenant_id) do
    # Simple WO number generation - can be enhanced
    count = Repo.aggregate(
      from(w in WorkOrder, where: w.tenant_id == ^tenant_id),
      :count
    )
    "WO-#{Date.utc_today() |> Date.to_string() |> String.replace("-", "")}-#{count + 1}"
  end
end
```

### 2. PM Template Schema (lib/shop1_cmms/maintenance/pm_template.ex)

```elixir
defmodule Shop1Cmms.Maintenance.PMTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "maint_pm_templates" do
    field :name, :string
    field :description, :string
    field :frequency_days, :integer
    field :meter_type, :string
    field :meter_frequency, :decimal
    field :use_meter_and_time, :boolean, default: false
    field :task_list, {:array, :string}, default: []
    field :estimated_duration_hours, :decimal, default: 1.0
    field :required_skills, {:array, :string}, default: []
    field :required_parts, :map, default: %{}
    field :active, :boolean, default: true

    belongs_to :tenant, Shop1Cmms.Tenants.Tenant
    belongs_to :created_by, Shop1Cmms.Accounts.User

    has_many :pm_schedules, Shop1Cmms.Maintenance.PMSchedule

    timestamps()
  end

  @doc false
  def changeset(template, attrs) do
    template
    |> cast(attrs, [
      :tenant_id, :name, :description, :frequency_days, 
      :meter_type, :meter_frequency, :use_meter_and_time,
      :task_list, :estimated_duration_hours, :required_skills,
      :required_parts, :active, :created_by
    ])
    |> validate_required([:tenant_id, :name])
    |> validate_length(:name, min: 3, max: 255)
    |> validate_number(:frequency_days, greater_than: 0)
    |> validate_number(:meter_frequency, greater_than: 0)
    |> validate_number(:estimated_duration_hours, greater_than: 0)
    |> validate_pm_frequency()
    |> foreign_key_constraint(:tenant_id)
  end

  defp validate_pm_frequency(changeset) do
    frequency_days = get_field(changeset, :frequency_days)
    meter_frequency = get_field(changeset, :meter_frequency)

    if is_nil(frequency_days) and is_nil(meter_frequency) do
      add_error(changeset, :frequency_days, "must specify either time-based or meter-based frequency")
    else
      changeset
    end
  end
end
```

### 3. PM Schedule Schema (lib/shop1_cmms/maintenance/pm_schedule.ex)

```elixir
defmodule Shop1Cmms.Maintenance.PMSchedule do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  @foreign_key_type :id

  schema "maint_pm_schedules" do
    field :last_completed_at, :utc_datetime
    field :last_completed_meter, :decimal
    field :next_due_date, :date
    field :next_due_meter, :decimal
    field :days_overdue, :integer, virtual: true  # Computed in database
    field :active, :boolean, default: true

    belongs_to :tenant, Shop1Cmms.Tenants.Tenant
    belongs_to :asset, Shop1Cmms.Assets.Asset
    belongs_to :component, Shop1Cmms.Assets.Component
    belongs_to :pm_template, Shop1Cmms.Maintenance.PMTemplate
    belongs_to :meter, Shop1Cmms.Assets.Meter
    belongs_to :last_completed_by, Shop1Cmms.Accounts.User
    belongs_to :assigned_to, Shop1Cmms.Accounts.User

    has_many :work_orders, Shop1Cmms.Work.WorkOrder

    timestamps()
  end

  @doc false
  def changeset(schedule, attrs) do
    schedule
    |> cast(attrs, [
      :tenant_id, :asset_id, :component_id, :pm_template_id, :meter_id,
      :last_completed_at, :last_completed_meter, :next_due_date, 
      :next_due_meter, :active, :last_completed_by, :assigned_to
    ])
    |> validate_required([:tenant_id, :pm_template_id])
    |> validate_asset_or_component()
    |> foreign_key_constraint(:tenant_id)
    |> foreign_key_constraint(:pm_template_id)
    |> foreign_key_constraint(:asset_id)
    |> foreign_key_constraint(:component_id)
    |> unique_constraint([:asset_id, :component_id, :pm_template_id])
  end

  defp validate_asset_or_component(changeset) do
    asset_id = get_field(changeset, :asset_id)
    component_id = get_field(changeset, :component_id)

    if is_nil(asset_id) and is_nil(component_id) do
      add_error(changeset, :asset_id, "must specify either asset or component")
    else
      changeset
    end
  end
end
```

### 4. PM Calculator Module (lib/shop1_cmms/maintenance/pm_calculator.ex)

```elixir
defmodule Shop1Cmms.Maintenance.PMCalculator do
  @moduledoc """
  Handles all PM scheduling calculations and next-due date logic.
  This is the core of the PM scheduling system.
  """

  import Ecto.Query
  alias Shop1Cmms.Repo
  alias Shop1Cmms.Maintenance.{PMSchedule, PMTemplate}
  alias Shop1Cmms.Assets.{Meter, MeterReading}

  def calculate_and_update_next_due(schedule_id) do
    schedule = Repo.get!(PMSchedule, schedule_id)
    |> Repo.preload([:pm_template, :meter])

    next_due_date = calculate_next_due_date(schedule)
    next_due_meter = calculate_next_due_meter(schedule)

    schedule
    |> PMSchedule.changeset(%{
      next_due_date: next_due_date,
      next_due_meter: next_due_meter
    })
    |> Repo.update()
  end

  defp calculate_next_due_date(%PMSchedule{pm_template: template} = schedule) do
    case template.frequency_days do
      nil -> nil
      days ->
        base_date = schedule.last_completed_at || schedule.inserted_at
        base_date
        |> DateTime.to_date()
        |> Date.add(days)
    end
  end

  defp calculate_next_due_meter(%PMSchedule{pm_template: template} = schedule) do
    case {template.meter_frequency, schedule.meter_id} do
      {nil, _} -> nil
      {_, nil} -> nil
      {freq, meter_id} ->
        last_meter = schedule.last_completed_meter || get_initial_meter_reading(meter_id)
        Decimal.add(last_meter || 0, freq)
    end
  end

  defp get_initial_meter_reading(meter_id) do
    MeterReading
    |> where([r], r.meter_id == ^meter_id)
    |> order_by([r], asc: r.reading_at)
    |> limit(1)
    |> select([r], r.reading)
    |> Repo.one()
    |> case do
      nil -> Decimal.new(0)
      reading -> reading
    end
  end

  def get_current_meter_reading(meter_id) do
    MeterReading
    |> where([r], r.meter_id == ^meter_id)
    |> order_by([r], desc: r.reading_at)
    |> limit(1)
    |> select([r], r.reading)
    |> Repo.one()
  end

  def is_meter_based_due?(schedule) do
    case {schedule.next_due_meter, schedule.meter_id} do
      {nil, _} -> false
      {_, nil} -> false
      {due_meter, meter_id} ->
        current = get_current_meter_reading(meter_id)
        current && Decimal.compare(current, due_meter) != :lt
    end
  end

  def is_time_based_due?(schedule) do
    case schedule.next_due_date do
      nil -> false
      due_date -> Date.compare(Date.utc_today(), due_date) != :lt
    end
  end

  def is_schedule_due?(schedule) do
    is_time_based_due?(schedule) || is_meter_based_due?(schedule)
  end

  def days_until_due(schedule) do
    case schedule.next_due_date do
      nil -> nil
      due_date -> Date.diff(due_date, Date.utc_today())
    end
  end

  def meter_units_until_due(schedule) do
    case {schedule.next_due_meter, schedule.meter_id} do
      {nil, _} -> nil
      {_, nil} -> nil
      {due_meter, meter_id} ->
        current = get_current_meter_reading(meter_id)
        if current do
          Decimal.sub(due_meter, current)
        else
          nil
        end
    end
  end
end
```

## Oban Jobs for PM Automation

### 1. Recalculate Next Due Job (lib/shop1_cmms/workers/recalculate_pm_job.ex)

```elixir
defmodule Shop1Cmms.Workers.RecalculatePMJob do
  @moduledoc """
  Daily job to recalculate all PM next due dates.
  Handles meter readings and time-based calculations.
  """
  
  use Oban.Worker, queue: :maintenance, max_attempts: 3

  alias Shop1Cmms.Maintenance

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tenant_id" => tenant_id}}) do
    Maintenance.recalculate_all_schedules(tenant_id)
    :ok
  end

  def schedule_daily_recalculation(tenant_id) do
    %{tenant_id: tenant_id}
    |> __MODULE__.new(scheduled_at: next_midnight())
    |> Oban.insert()
  end

  defp next_midnight do
    DateTime.utc_now()
    |> DateTime.to_date()
    |> Date.add(1)
    |> DateTime.new!(~T[00:00:00])
  end
end
```

### 2. Auto Work Order Generation Job (lib/shop1_cmms/workers/auto_wo_job.ex)

```elixir
defmodule Shop1Cmms.Workers.AutoWOJob do
  @moduledoc """
  Hourly job to generate work orders for due PMs.
  """
  
  use Oban.Worker, queue: :maintenance, max_attempts: 3

  alias Shop1Cmms.Maintenance

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tenant_id" => tenant_id}}) do
    case Maintenance.generate_due_work_orders(tenant_id) do
      work_orders when is_list(work_orders) ->
        # Log successful generation
        IO.puts("Generated #{length(work_orders)} work orders for tenant #{tenant_id}")
        :ok
      {:error, reason} ->
        {:error, reason}
    end
  end

  def schedule_hourly_generation(tenant_id) do
    %{tenant_id: tenant_id}
    |> __MODULE__.new(scheduled_at: next_hour())
    |> Oban.insert()
  end

  defp next_hour do
    DateTime.utc_now()
    |> DateTime.add(3600, :second)
    |> DateTime.truncate(:second)
  end
end
```

## Usage Examples

### Creating a PM Template

```elixir
# Create a time-based PM template
{:ok, template} = Maintenance.create_pm_template(%{
  tenant_id: 1,
  name: "Monthly Motor Inspection",
  description: "Check motor bearings, belts, and lubrication",
  frequency_days: 30,
  task_list: [
    "Check bearing temperature",
    "Inspect drive belts for wear",
    "Check lubrication levels",
    "Test vibration levels"
  ],
  estimated_duration_hours: 2.0,
  required_skills: ["electrical", "mechanical"]
})

# Create a meter-based PM template  
{:ok, meter_template} = Maintenance.create_pm_template(%{
  tenant_id: 1,
  name: "Oil Change - 500 Hours",
  frequency_days: nil,
  meter_type: "runtime_hours",
  meter_frequency: Decimal.new(500),
  task_list: ["Drain oil", "Replace filter", "Refill with new oil"]
})
```

### Setting up PM Schedules

```elixir
# Link PM template to specific asset
{:ok, schedule} = Maintenance.create_pm_schedule(%{
  tenant_id: 1,
  asset_id: 123,
  pm_template_id: template.id,
  assigned_to: technician.id
})
```

This core PM scheduling system provides the foundation for your CMMS with automated work order generation and flexible scheduling options.
