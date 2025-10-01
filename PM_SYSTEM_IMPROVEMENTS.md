# PM System - Features Review & Improvement Plan

**Date:** January 2026
**Status:** Enhancement Planning
**Related Docs:** PM_SCHEDULING_CORE.md

---

## 🔍 Current PM System Features (Based on Documentation)

### Core PM Features Implemented:
1. **PM Templates** - Reusable maintenance templates
   - Name, description
   - Time-based frequency (days)
   - Meter-based frequency
   - Hybrid mode (both time and meter)
   - Task list (array of strings)
   - Estimated duration
   - Required skills list
   - Required parts (JSON)
   
2. **PM Schedules** - Individual PM assignments to assets
   - Links PM template to specific asset or component
   - Tracks last completed date/meter
   - Calculates next due date/meter
   - Days overdue tracking
   - Assignment to technicians
   
3. **PM Calculations** - Automated scheduling
   - Auto-calculate next due dates
   - Meter-based triggering
   - Time-based triggering
   - Hybrid triggering logic
   
4. **Auto Work Order Generation**
   - Generate WOs from due PMs
   - Create tasks from template
   - Auto-assign based on PM schedule
   
### Current Workflow:
```
1. Create PM Template → Define maintenance procedure
2. Create PM Schedule → Assign template to asset
3. System calculates next due date
4. System generates WO when PM is due
5. Complete WO → Updates PM schedule → Recalculates next due
```

---

## ✨ Requested Improvements & Additions

### 1. **Work Instructions** ⭐⭐⭐ (HIGH PRIORITY)
**Requirement:** Add detailed step-by-step instructions for PMs

#### Current State:
- ✅ PM Template has `task_list` (array of strings)
- ❌ No rich formatting or attachments
- ❌ No images or diagrams
- ❌ No checklist-style tasks

#### Proposed Enhancement:
Add a comprehensive `work_instructions` field to PM Templates:

```elixir
# Enhanced PM Template Schema
schema "maint_pm_templates" do
  # Existing fields...
  field :task_list, {:array, :string}, default: []
  
  # NEW: Detailed work instructions
  field :work_instructions, :text  # Rich text or markdown
  field :safety_notes, :text
  field :special_tools_required, {:array, :string}
  field :reference_documents, {:array, :map}  # [{name, url, type}]
  
  # Structured tasks with more detail
  field :detailed_tasks, {:array, :map}, default: []
  # Example: [
  #   %{
  #     step: 1,
  #     title: "Check oil level",
  #     instructions: "Locate dipstick...",
  #     estimated_minutes: 5,
  #     requires_signature: true,
  #     has_measurement: true,
  #     measurement_spec: "Between MIN and MAX marks"
  #   }
  # ]
end
```

#### UI Implementation:
- Rich text editor for work instructions (use Quill.js or TipTap)
- Drag-and-drop task ordering
- Image upload for visual instructions
- PDF viewer for reference documents
- Print-friendly PM work instruction sheets

---

### 2. **Multi-Component PM Schedules** ⭐⭐⭐ (HIGH PRIORITY)
**Requirement:** Allow PMs to target multiple parts/components of one asset

#### Current State:
- ✅ PM Schedule links to ONE asset OR ONE component
- ❌ Cannot schedule PM for multiple components at once
- ❌ No component groups

#### Proposed Enhancement:

**Option A: PM Schedule Component Groups**
```elixir
# New table: maint_pm_schedule_components
# Allows one PM schedule to apply to multiple components

schema "maint_pm_schedule_components" do
  belongs_to :pm_schedule, PMSchedule
  belongs_to :component, Component
  field :last_completed_at, :utc_datetime
  field :notes, :string
end

# PM Schedule becomes a parent that can have multiple component schedules
```

**Option B: Component Groups**
```elixir
# New schema: ComponentGroup
schema "component_groups" do
  field :name, :string
  field :description, :string
  belongs_to :asset, Asset
  many_to_many :components, Component, join_through: "component_group_members"
end

# PM Schedule can target a component group
schema "maint_pm_schedules" do
  # ...existing fields...
  belongs_to :component_group, ComponentGroup
end
```

**Recommendation:** Implement Option A first (simpler), then Option B if needed.

#### UI Implementation:
- Multi-select component picker when creating PM schedule
- Component checklist in PM work order
- Per-component completion tracking
- Visual component diagram/tree view

---

### 3. **Document Management** ⭐⭐⭐ (HIGH PRIORITY)
**Requirement:** Attach manuals, certs, calibration records, etc.

#### Current State:
- ❌ No document management system
- ❌ No file uploads
- ❌ No document versioning

#### Proposed Enhancement:

**New Document System:**
```elixir
# New schema: Documents
schema "documents" do
  field :name, :string
  field :description, :text
  field :file_path, :string  # S3 or local storage path
  field :file_size, :integer
  field :file_type, :string  # PDF, JPG, PNG, DOCX, etc.
  field :document_type, :string  # manual, certificate, calibration, drawing
  field :version, :string
  field :expiration_date, :date  # For certifications
  field :is_current, :boolean, default: true
  
  belongs_to :tenant, Tenant
  belongs_to :uploaded_by, User
  
  # Polymorphic association - can attach to multiple entity types
  field :entity_type, :string  # "asset", "pm_template", "work_order"
  field :entity_id, :id
  
  timestamps()
end

# Index on entity_type + entity_id for fast lookups
```

**Document Categories:**
1. **Manuals** - Equipment manuals, user guides
2. **Certificates** - Calibration certificates, compliance docs
3. **Drawings** - Technical drawings, schematics
4. **Procedures** - SOPs, work instructions
5. **Photos** - Equipment photos, before/after
6. **Calibration Records** - (future Gage System integration)

#### File Storage Options:
- **Local:** `priv/static/uploads/documents/` (development)
- **Production:** AWS S3 or Azure Blob Storage
- Use `Arc` or `Waffle` Elixir libraries for uploads

#### UI Implementation:
- Drag-and-drop file upload
- Document library page
- Documents tab on Asset detail page
- Documents tab on PM Template detail page
- Inline PDF viewer
- Version history
- Expiration alerts for certificates
- Document search

---

### 4. **PM Template Enhancements** ⭐⭐ (MEDIUM PRIORITY)

#### Additional Fields Needed:
```elixir
schema "maint_pm_templates" do
  # ...existing fields...
  
  # NEW FIELDS
  field :category, :string  # "Inspection", "Lubrication", "Calibration", etc.
  field :compliance_standard, :string  # ISO, OSHA, etc.
  field :criticality, :integer, default: 2  # 1=low, 2=medium, 3=high, 4=critical
  field :requires_downtime, :boolean, default: false
  field :downtime_minutes, :integer
  field :requires_lockout, :boolean, default: false
  field :lockout_procedure, :text
  field :measurement_points, {:array, :map}  # Structured data for measurements
  # Example: [
  #   %{
  #     name: "Vibration Level",
  #     unit: "mm/s",
  #     min: 0.5,
  #     max: 2.5,
  #     target: 1.5
  #   }
  # ]
  
  # Seasonal/Conditional
  field :season, :string  # "spring", "summer", "fall", "winter", "all"
  field :weather_dependent, :boolean, default: false
end
```

---

## 🗂️ New Database Tables Needed

### 1. Documents Table
```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id INTEGER NOT NULL REFERENCES tenants(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  file_path VARCHAR(500) NOT NULL,
  file_size INTEGER,
  file_type VARCHAR(50),
  document_type VARCHAR(50),
  version VARCHAR(20),
  expiration_date DATE,
  is_current BOOLEAN DEFAULT true,
  entity_type VARCHAR(50),
  entity_id UUID,
  uploaded_by INTEGER REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_documents_entity ON documents(entity_type, entity_id);
CREATE INDEX idx_documents_tenant ON documents(tenant_id);
CREATE INDEX idx_documents_expiration ON documents(expiration_date) WHERE expiration_date IS NOT NULL;
```

### 2. PM Schedule Components (Optional - if implementing multi-component)
```sql
CREATE TABLE maint_pm_schedule_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pm_schedule_id UUID NOT NULL REFERENCES maint_pm_schedules(id) ON DELETE CASCADE,
  component_id UUID NOT NULL REFERENCES asset_components(id) ON DELETE CASCADE,
  last_completed_at TIMESTAMP,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(pm_schedule_id, component_id)
);
```

### 3. PM Execution Checklist (for tracking detailed task completion)
```sql
CREATE TABLE maint_pm_execution_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  work_order_id UUID NOT NULL REFERENCES work_orders(id) ON DELETE CASCADE,
  step_number INTEGER NOT NULL,
  title VARCHAR(255) NOT NULL,
  instructions TEXT,
  is_completed BOOLEAN DEFAULT false,
  completed_by INTEGER REFERENCES users(id),
  completed_at TIMESTAMP,
  measurement_value DECIMAL,
  measurement_unit VARCHAR(20),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## 📋 Implementation Phases

### Phase 1: Work Instructions & Document Management (2-3 weeks)
**Priority: HIGH - Core PM functionality**

#### Week 1: Document System
- [ ] Create Document schema and migration
- [ ] Implement file upload (Arc/Waffle)
- [ ] Create document upload component
- [ ] Add documents to Assets
- [ ] Add documents to PM Templates
- [ ] Document viewer component

#### Week 2: Work Instructions
- [ ] Add work_instructions field to PM Template
- [ ] Rich text editor for instructions
- [ ] Enhanced task list with details
- [ ] Safety notes section
- [ ] Reference documents linking
- [ ] Print-friendly PM instruction sheet

#### Week 3: Integration & Testing
- [ ] Document search
- [ ] Version control
- [ ] Expiration alerts
- [ ] Integration with Work Orders
- [ ] Testing and bug fixes

---

### Phase 2: Multi-Component PM Support (1-2 weeks)
**Priority: HIGH - Frequently requested**

#### Week 1:
- [ ] Design multi-component approach
- [ ] Create PM Schedule Components table
- [ ] Update PM Schedule schema
- [ ] Component multi-select UI
- [ ] Per-component tracking

#### Week 2:
- [ ] Component group creation (if needed)
- [ ] Visual component tree
- [ ] Completion tracking
- [ ] Reporting enhancements
- [ ] Testing

---

### Phase 3: PM Template Enhancements (1 week)
**Priority: MEDIUM - Nice to have**

- [ ] Add category field
- [ ] Add compliance standard
- [ ] Add criticality level
- [ ] Downtime tracking
- [ ] Lockout/tagout procedures
- [ ] Measurement points
- [ ] Seasonal scheduling
- [ ] Weather-dependent flags

---

### Phase 4: Advanced PM Features (Future)
**Priority: LOW - Future enhancements**

- [ ] PM Forecasting (predict future PMs)
- [ ] PM Cost Tracking
- [ ] Failure analysis integration
- [ ] Predictive maintenance triggers
- [ ] Mobile-optimized PM execution
- [ ] Offline PM capability
- [ ] PM analytics dashboard

---

## 🎨 UI/UX Mockups Needed

### 1. PM Template Form - Work Instructions Tab
```
┌─────────────────────────────────────────────────────────┐
│ PM Template: Oil Change                                  │
├─────────────────────────────────────────────────────────┤
│ [Basic Info] [Work Instructions] [Documents] [Schedule] │
│                                                          │
│ Work Instructions:                                       │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ [Rich Text Editor]                                   │ │
│ │ 1. Warm up equipment for 5 minutes                  │ │
│ │ 2. Shut down and lock out power                     │ │
│ │ 3. Locate drain plug (see diagram)                  │ │
│ │    [Image: drain_plug.jpg]                          │ │
│ │ ...                                                  │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ Safety Notes:                                            │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ - Wear safety glasses                                │ │
│ │ - Hot oil can cause burns                           │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ Detailed Task Checklist:                                 │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ ☑ Step 1: Check oil level           Est: 5 min      │ │
│ │ ☐ Step 2: Drain old oil              Est: 15 min     │ │
│ │ ☐ Step 3: Replace filter             Est: 10 min     │ │
│ │ ☐ Step 4: Add new oil                Est: 10 min     │ │
│ │   └─ Measurement: ___ quarts (Min: 8, Max: 10)      │ │
│ │ ☐ Step 5: Check for leaks            Est: 5 min      │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ Reference Documents:                                     │
│ 📄 Equipment Manual (Rev 3)                             │
│ 📄 Oil Specifications Sheet                             │
│ 📷 Drain Plug Location Photo                            │
│                                                          │
│ [Save] [Cancel]                                          │
└─────────────────────────────────────────────────────────┘
```

### 2. Asset Detail - Documents Tab
```
┌─────────────────────────────────────────────────────────┐
│ Asset: CNC Mill #001                                     │
├─────────────────────────────────────────────────────────┤
│ [Details] [PMs] [Work Orders] [Documents] [History]     │
│                                                          │
│ Documents (12)                            [Upload File ▼]│
│                                                          │
│ Manuals (3)                                              │
│ ├─ 📘 Operator Manual v2.1               2023-05-15     │
│ ├─ 📘 Service Manual v1.8                2022-11-20     │
│ └─ 📘 Parts Catalog                      2023-01-10     │
│                                                          │
│ Certificates (4)                                         │
│ ├─ 📜 Calibration Cert              ⚠️ Exp: 2025-03-15 │
│ ├─ 📜 Safety Inspection              ✓ Valid until 2025│
│ ├─ 📜 ISO Compliance                 ✓ Valid until 2026│
│ └─ 📜 Electrical Safety              ✓ Valid until 2025│
│                                                          │
│ Drawings (2)                                             │
│ ├─ 📐 Electrical Schematic           2022-08-15         │
│ └─ 📐 Hydraulic Diagram              2022-08-15         │
│                                                          │
│ Photos (3)                                               │
│ ├─ 📷 Installation Photo             2023-04-01         │
│ ├─ 📷 Control Panel                  2023-04-01         │
│ └─ 📷 Nameplate                      2023-04-01         │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 3. PM Schedule with Multi-Component Selection
```
┌─────────────────────────────────────────────────────────┐
│ Create PM Schedule                                       │
├─────────────────────────────────────────────────────────┤
│                                                          │
│ Asset: *                                                 │
│ [▼ Select Asset...]                                      │
│                                                          │
│ PM Template: *                                           │
│ [▼ Quarterly Inspection]                                 │
│                                                          │
│ Apply to Components:                                     │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Select components (optional):                        │ │
│ │                                                      │ │
│ │ ☑ Main Spindle Motor                                │ │
│ │ ☑ Coolant Pump                                      │ │
│ │ ☐ Hydraulic Unit                                    │ │
│ │ ☑ X-Axis Drive                                      │ │
│ │ ☑ Y-Axis Drive                                      │ │
│ │ ☑ Z-Axis Drive                                      │ │
│ │ ☐ Tool Changer                                      │ │
│ │                                                      │ │
│ │ [Select All] [Select None]                          │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
│ Start Date: [2025-01-15]                                 │
│                                                          │
│ Assign To: [▼ John Smith]                               │
│                                                          │
│ [Create Schedule] [Cancel]                               │
└─────────────────────────────────────────────────────────┘
```

---

## 🔗 Integration with Future Gage/Calibration System

The document management system will integrate seamlessly with the future Gage & Calibration module:

### Shared Document Types:
- **Calibration Certificates** - Link to gages and assets
- **Calibration Procedures** - PM templates for calibration
- **Compliance Documents** - ISO 17025, etc.

### Data Flow:
```
Gage/Calibration System → Calibration PM → Work Order → Document Upload → Cert Storage
```

---

## 📊 Success Metrics

### How to Measure Success:
1. **PM Completion Rate** - % of PMs completed on time
2. **Document Accessibility** - Time to find needed document
3. **Work Instruction Usage** - % of WOs with instructions viewed
4. **Multi-Component Efficiency** - Time saved vs individual PMs
5. **User Satisfaction** - Technician feedback scores

---

## 🚀 Next Steps

1. **Review & Approve** this enhancement plan
2. **Prioritize** features based on business needs
3. **Create** detailed technical specifications
4. **Design** UI mockups
5. **Implement** Phase 1 (Work Instructions & Documents)
6. **Test** with real users
7. **Iterate** based on feedback

---

## ✅ Checklist for Implementation

### Work Instructions:
- [ ] Add work_instructions text field to PM Template
- [ ] Add safety_notes field
- [ ] Add detailed_tasks JSON field
- [ ] Rich text editor component
- [ ] Task ordering/reordering UI
- [ ] Image upload in instructions
- [ ] Print view for PM instructions

### Document Management:
- [ ] Create Document schema
- [ ] File upload functionality
- [ ] S3/storage integration
- [ ] Document viewer component
- [ ] Document search
- [ ] Version control
- [ ] Expiration tracking
- [ ] Document permissions

### Multi-Component PMs:
- [ ] PM Schedule Components table
- [ ] Component multi-select UI
- [ ] Per-component completion tracking
- [ ] Component tree view
- [ ] Reporting updates

---

**This plan provides a comprehensive roadmap for enhancing the PM system with work instructions, document management, and multi-component support!**
