# PM and Work Order History Implementation Plan

**Date:** February 1, 2026  
**Branch:** ui-ux-improvements  
**Purpose:** Add comprehensive history and audit capabilities for PM schedules and Work Orders

---

## 📋 Overview

This plan implements:
1. **PM Execution History** - Complete audit trail of all PM completions
2. **Work Order History** - Track all work orders with full details
3. **Combined Equipment History** - See all maintenance activity for an asset
4. **Audit Reports** - Export history for compliance
5. **Statistics & Metrics** - Performance tracking

---

## ✅ What Already Exists

### Database Tables ✓
- ✅ `pm_executions` table (migrated)
- ✅ `work_orders` table (migrated)
- ✅ `pm_schedules` table with stats fields
- ✅ `assets` and `components` tables

### Schemas
- ✅ `Shop1Cmms.WorkOrders.WorkOrder` schema exists
- ⚠️ `Shop1Cmms.Maintenance.PmExecution` schema - **NEEDS TO BE CREATED**
- ✅ `Shop1Cmms.Maintenance.PmSchedule` schema exists

### LiveViews
- ✅ `pm_schedules_live.ex` - PM list and management
- ✅ `pm_schedule_detail_live.ex` - PM detail view
- ✅ `work_orders_live.ex` - Work order list
- ✅ `work_order_detail_live.ex` - Work order detail
- ⚠️ History components - **NEED TO BE CREATED**

---

## 🎯 Implementation Phases

### Phase 1: Create PM Execution Schema & Context ⏳
**Estimated Time:** 2 hours

#### 1.1 Create PM Execution Schema
**File:** `lib/shop1_cmms/maintenance/pm_execution.ex`

```elixir
defmodule Shop1Cmms.Maintenance.PmExecution do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "pm_executions" do
    field :execution_number, :string
    field :execution_date, :utc_datetime
    field :completed_date, :utc_datetime
    field :status, Ecto.Enum, 
      values: [:in_progress, :completed, :incomplete, :cancelled],
      default: :in_progress
    
    # Execution details
    field :step_results, {:array, :map}, default: []
    field :tech_notes, :string
    field :parts_used, {:array, :map}, default: []
    field :actual_duration_minutes, :integer
    field :meter_reading, :decimal
    
    # Relationships
    belongs_to :pm_schedule, Shop1Cmms.Maintenance.PmSchedule
    belongs_to :work_order, Shop1Cmms.WorkOrders.WorkOrder
    belongs_to :completed_by_user, Shop1Cmms.Accounts.User, 
      foreign_key: :completed_by_user_id, type: :integer
    belongs_to :asset, Shop1Cmms.Assets.Asset
    belongs_to :component, Shop1Cmms.Assets.Component
    
    field :tenant_id, :integer
    timestamps(type: :naive_datetime)
  end

  def changeset(execution, attrs) do
    execution
    |> cast(attrs, [
      :execution_number, :execution_date, :completed_date, :status,
      :step_results, :tech_notes, :parts_used, 
      :actual_duration_minutes, :meter_reading,
      :pm_schedule_id, :work_order_id, :completed_by_user_id,
      :asset_id, :component_id, :tenant_id
    ])
    |> validate_required([
      :execution_number, :execution_date, :status,
      :pm_schedule_id, :asset_id, :tenant_id
    ])
    |> unique_constraint(:execution_number)
  end
end
```

#### 1.2 Add Context Functions
**File:** `lib/shop1_cmms/maintenance.ex`

Add functions:
- `list_pm_executions(tenant_id, filters \\ %{})`
- `get_pm_execution!(id)`
- `list_pm_executions_for_schedule(schedule_id)`
- `list_pm_executions_for_asset(asset_id)`
- `create_pm_execution(attrs)`
- `update_pm_execution(execution, attrs)`
- `complete_pm_execution(execution_id, attrs)`
- `get_pm_execution_stats(schedule_id)`

---

### Phase 2: Add History Components 📊
**Estimated Time:** 4 hours

#### 2.1 PM Execution History Component
**File:** `lib/shop1_cmms_web/live/pm_schedules_live/history_component.ex`

**Features:**
- Table showing all past executions for a PM schedule
- Columns:
  - Execution Number
  - Execution Date
  - Completed Date
  - Completed By (user name)
  - Status
  - Duration (actual vs estimated)
  - Pass/Fail indicators
  - Actions (View Details)
- Sortable by date, status
- Filter by date range, status, completed by
- Pagination
- Export to CSV/PDF

#### 2.2 Equipment History Component
**File:** `lib/shop1_cmms_web/live/assets_live/maintenance_history_component.ex`

**Features:**
- Combined view of ALL maintenance for an asset
- Shows both PM executions AND work orders
- Unified timeline view
- Columns:
  - Date
  - Type (PM / Work Order)
  - Title/Description
  - Status
  - Technician
  - Duration
  - Cost
  - Actions
- Filter by type, date range, status
- Statistics summary at top

#### 2.3 Work Order History View
**File:** `lib/shop1_cmms_web/live/work_orders_live/history_component.ex`

**Features:**
- Shows completed work orders
- Filter by:
  - Date range
  - Equipment
  - Assigned technician
  - Type (corrective, preventive, emergency, project)
  - Priority
- Export capabilities
- Statistics dashboard

---

### Phase 3: Enhanced PM Detail View with Tabs 🏗️
**Estimated Time:** 3 hours

#### 3.1 Update PM Schedule Detail View
**File:** `lib/shop1_cmms_web/live/pm_schedule_detail_live.ex`

**Add Tabbed Interface:**

```elixir
# Tabs structure
tabs = [
  %{id: "details", label: "Details", active: true},
  %{id: "instructions", label: "Work Instructions"},
  %{id: "history", label: "Execution History"},
  %{id: "documents", label: "Documents"},
  %{id: "equipment", label: "Equipment"}
]
```

**Tab Content:**

1. **Details Tab** - Schedule info, frequency, next due, assigned to
2. **Instructions Tab** - Interactive checklist (existing functionality)
3. **History Tab** - PM execution history component
4. **Documents Tab** - Related documents from asset_documents
5. **Equipment Tab** - Equipment/component details

#### 3.2 Template Structure
**File:** `lib/shop1_cmms_web/live/pm_schedule_detail_live.html.heex`

```heex
<!-- Tab Navigation -->
<div class="border-b border-gray-200">
  <nav class="flex space-x-4">
    <%= for tab <- @tabs do %>
      <button
        phx-click="switch_tab"
        phx-value-tab={tab.id}
        class={"px-4 py-2 #{if @active_tab == tab.id, do: "border-b-2 border-blue-500 text-blue-600", else: "text-gray-500"}"}
      >
        <%= tab.label %>
      </button>
    <% end %>
  </nav>
</div>

<!-- Tab Content -->
<div class="mt-4">
  <%= case @active_tab do %>
    <% "details" -> %>
      <%= render_details_tab(assigns) %>
    <% "instructions" -> %>
      <%= render_instructions_tab(assigns) %>
    <% "history" -> %>
      <.live_component
        module={Shop1CmmsWeb.PmSchedulesLive.HistoryComponent}
        id="pm-history"
        pm_schedule={@pm_schedule}
        tenant_id={@current_tenant_id}
      />
    <% "documents" -> %>
      <%= render_documents_tab(assigns) %>
    <% "equipment" -> %>
      <%= render_equipment_tab(assigns) %>
  <% end %>
</div>
```

---

### Phase 4: Statistics & Reporting 📈
**Estimated Time:** 2 hours

#### 4.1 PM Compliance Dashboard
**Location:** Dashboard page or PM Schedules page

**Metrics:**
- Overall PM completion rate
- On-time completion rate
- Average completion time
- Overdue PMs count
- PM completion trend (last 30/90 days)
- Top performing technicians
- Equipment with most PM activity

#### 4.2 Export Functionality
**Features:**
- Export PM execution history to CSV/Excel
- Export work order history
- Export equipment maintenance history
- PDF reports for audits
- Date range selection
- Custom field selection

---

### Phase 5: Work Order Completion Flow 🔄
**Estimated Time:** 3 hours

#### 5.1 Complete Work Order Form
**Enhancement to:** `work_order_detail_live.ex`

**When completing a work order:**
- Capture completion details:
  - Actual start/end time
  - Work performed (detailed notes)
  - Parts used
  - Actual hours
  - Actual cost
  - Completion notes
  - Photos/attachments
- Auto-update status to "completed"
- Store completion data for history

#### 5.2 Work Order Audit View
**Read-only view of completed work order**
- All details locked
- Shows completion info
- Shows who completed and when
- Shows all changes (audit trail)

---

### Phase 6: Interactive PM Execution (Future Enhancement) 🚀
**Estimated Time:** 6 hours  
**Note:** This is a more advanced feature for later

**Real-time PM Execution Interface:**
- Start PM execution (creates pm_execution record)
- Step-by-step checklist interface
- Check off steps as completed
- Add notes per step
- Record measurements
- Upload photos per step
- Timer for tracking duration
- Pause/resume execution
- Complete execution (saves all data)

---

## 🗂️ File Structure

```
lib/shop1_cmms/
├── maintenance/
│   └── pm_execution.ex (NEW)
├── maintenance.ex (UPDATE - add functions)

lib/shop1_cmms_web/live/
├── pm_schedules_live/
│   ├── history_component.ex (NEW)
│   └── history_component.html.heex (NEW)
├── assets_live/
│   ├── maintenance_history_component.ex (NEW)
│   └── maintenance_history_component.html.heex (NEW)
├── work_orders_live/
│   ├── history_component.ex (NEW)
│   └── history_component.html.heex (NEW)
├── pm_schedule_detail_live.ex (UPDATE - add tabs)
└── pm_schedule_detail_live.html.heex (UPDATE - add tab UI)
```

---

## 📊 Database Queries

### Key Queries for History

```elixir
# Get PM execution history for a schedule
def list_pm_executions_for_schedule(schedule_id) do
  from(e in PmExecution,
    where: e.pm_schedule_id == ^schedule_id,
    order_by: [desc: e.execution_date],
    preload: [:completed_by_user, :asset, :component]
  )
  |> Repo.all()
end

# Get all maintenance history for an asset (PMs + Work Orders)
def get_asset_maintenance_history(asset_id) do
  pm_executions = 
    from(e in PmExecution,
      where: e.asset_id == ^asset_id,
      select: %{
        type: "PM",
        date: e.execution_date,
        title: e.execution_number,
        status: e.status,
        technician_id: e.completed_by_user_id,
        duration: e.actual_duration_minutes,
        id: e.id
      }
    )
  
  work_orders = 
    from(w in WorkOrder,
      where: w.asset_id == ^asset_id,
      select: %{
        type: "Work Order",
        date: w.actual_start_date,
        title: w.title,
        status: w.status,
        technician_id: w.assigned_to,
        duration: w.actual_hours,
        id: w.id
      }
    )
  
  pm_executions
  |> union(^work_orders)
  |> order_by([desc: :date])
  |> Repo.all()
end

# Get PM compliance statistics
def get_pm_compliance_stats(tenant_id) do
  from(s in PmSchedule,
    where: s.tenant_id == ^tenant_id,
    select: %{
      total_schedules: count(s.id),
      total_completions: sum(s.total_completions),
      on_time_completions: sum(s.on_time_completions),
      avg_completion_rate: avg(s.completion_rate)
    }
  )
  |> Repo.one()
end
```

---

## 🎨 UI Design Notes

### History Table Design
- **Professional Desktop Look:** Tight spacing, efficient layout
- **Sortable Headers:** Click to sort by any column
- **Row Actions:** View, Export, Print buttons
- **Status Indicators:** Color-coded badges
- **Date Formatting:** Clear, consistent date display
- **Pagination:** Shows 25/50/100 per page
- **Search/Filter Bar:** Top of table for quick filtering

### Tab Navigation
- **Clean Tabs:** Horizontal tabs with active indicator
- **Consistent Across Pages:** Same tab style everywhere
- **Blue Accent:** Active tab highlighted in blue
- **Icon Support:** Optional icons for visual clarity

### Export Features
- **Export Button:** Top-right of history tables
- **Format Selection:** CSV, Excel, PDF dropdown
- **Date Range Picker:** Filter before export
- **Progress Indicator:** Show export progress

---

## ✅ Testing Checklist

### Unit Tests
- [ ] PM Execution schema validations
- [ ] Context function tests (create, update, list)
- [ ] Query tests (history queries, stats)

### Integration Tests
- [ ] PM execution history component loads
- [ ] Work order history component loads
- [ ] Equipment maintenance history loads
- [ ] Tab switching works correctly
- [ ] Export functions work

### UI/UX Tests
- [ ] History tables display correctly
- [ ] Sorting works on all columns
- [ ] Filters apply correctly
- [ ] Pagination works
- [ ] Export downloads correct data
- [ ] Mobile responsive (if needed)

---

## 🚀 Implementation Order

### Week 1: Foundation
1. ✅ Review plan and confirm requirements
2. Create PM Execution schema
3. Add Maintenance context functions
4. Write unit tests

### Week 2: History Components
1. Create PM execution history component
2. Create equipment maintenance history component
3. Create work order history component
4. Add to existing pages

### Week 3: Enhanced Detail Views
1. Add tabbed interface to PM detail view
2. Integrate history component into tabs
3. Add documents tab
4. Test all tab functionality

### Week 4: Statistics & Reporting
1. Create compliance dashboard
2. Add export functionality
3. Create PDF report templates
4. Test exports

### Week 5: Polish & Testing
1. UI/UX refinements
2. Performance optimization
3. Comprehensive testing
4. Documentation updates

---

## 📝 Sample Data for Testing

Create sample PM executions:
```elixir
# In seeds or console
alias Shop1Cmms.Maintenance

# Create past executions for a PM schedule
pm_schedule = Maintenance.get_pm_schedule!("some-id")

for i <- 1..10 do
  Maintenance.create_pm_execution(%{
    execution_number: "PMX-#{String.pad_leading("#{i}", 8, "0")}",
    execution_date: DateTime.add(DateTime.utc_now(), -30 * i, :day),
    completed_date: DateTime.add(DateTime.utc_now(), -30 * i + 2, :day),
    status: :completed,
    pm_schedule_id: pm_schedule.id,
    asset_id: pm_schedule.asset_id,
    completed_by_user_id: 1, # Adjust to valid user
    actual_duration_minutes: 45,
    tech_notes: "Completed successfully",
    tenant_id: 1
  })
end
```

---

## 🎯 Success Criteria

1. ✅ PM execution history displays all past completions
2. ✅ Work order history shows completed work orders
3. ✅ Equipment history combines both PM and WO data
4. ✅ All tables are sortable and filterable
5. ✅ Export to CSV/Excel works correctly
6. ✅ Tabbed interface works smoothly
7. ✅ Statistics calculate correctly
8. ✅ UI is professional and efficient
9. ✅ All tests pass
10. ✅ Performance is acceptable (< 500ms load time)

---

## 📚 Next Steps After This Plan

1. **Interactive PM Execution** - Real-time checklist interface
2. **Mobile App** - Field technician mobile interface
3. **Analytics Dashboard** - Advanced metrics and trends
4. **Predictive Maintenance** - ML-based failure prediction
5. **Integration with IoT** - Automatic meter readings
6. **Advanced Reporting** - Custom report builder

---

**Ready to start implementation!** 🚀

Let me know which phase to begin with, or we can start from Phase 1 and work through systematically.
