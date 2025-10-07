# PM System - Comprehensive Enhancement Plan

**Date:** January 2026
**Branch:** ui-ux-improvements
**Status:** Ready for Implementation

---

## 🎯 Overview

This plan addresses the following enhancements to the PM system:

1. **Components belong to Equipment** - Not separate PM entities
2. **Multiple PMs per Equipment/Component** - Full flexibility
3. **Interactive Work Instructions** - Checkbox-style completion tracking
4. **Equipment Documents** - Manuals, certs, calibration records
5. **PM Completion History** - Full audit trail
6. **Enhanced PM View** - Tabbed interface with all related data

---

## 📋 Implementation Phases

### **Phase 1: Data Model Enhancements** ⭐ (Foundation)

#### 1.1 - Equipment Components Schema
**Current:** Components are separate entities
**New:** Components belong to Equipment

Components table already exists with asset_id relationship.
Verify: components -> assets relationship is working.

#### 1.2 - Equipment Documents Schema
**New Table:** equipment_documents

Fields:
- id, name, description
- document_type (manual, drawing, certificate, calibration, photo, spec, warranty, other)
- file_path, file_name, file_size, mime_type
- version, expiry_date, issued_date, notes
- asset_id (FK to assets)
- pm_template_id (optional FK to pm_templates)
- uploaded_by_user_id (FK to users)
- tenant_id, timestamps

#### 1.3 - Enhanced PM Template Work Instructions
**Update:** maint_pm_templates table

Add fields:
- work_instructions (text) - Rich text/Markdown
- safety_notes (text)
- special_tools (array of strings)
- estimated_duration_minutes (integer)
- instruction_steps (jsonb array) - Structured step-by-step instructions

Instruction step format:
`json
{
  "step_number": 1,
  "title": "Check oil level",
  "description": "Locate dipstick...",
  "is_critical": true,
  "requires_signature": false,
  "has_measurement": true,
  "measurement_unit": "inches",
  "min_value": 2.0,
  "max_value": 3.5,
  "photo_required": false
}
`

#### 1.4 - PM Execution/Completion Tracking
**New Table:** pm_executions

Fields:
- id, execution_number (e.g., "PMX-2025-000001")
- execution_date, completed_date
- status (in_progress, completed, incomplete, cancelled)
- pm_schedule_id, work_order_id, completed_by_user_id
- asset_id, component_id
- step_results (jsonb) - Results for each step
- tech_notes, parts_used (jsonb), actual_duration_minutes
- meter_reading
- tenant_id, timestamps

Step result format:
`json
{
  "step_number": 1,
  "completed": true,
  "completed_at": "2025-01-15T10:30:00Z",
  "notes": "Oil level OK",
  "measured_value": 2.8,
  "passed": true,
  "photo_urls": []
}
`

#### 1.5 - PM Schedule Enhancement
**Update:** maint_pm_schedules table

Add stats fields:
- total_completions (integer)
- on_time_completions (integer)
- completion_rate (decimal)

---

### **Phase 2: Context & Business Logic** ⭐

#### 2.1 - Equipment Documents Context

Create: lib/shop1_cmms/equipment_documents.ex

Functions:
- list_documents_for_equipment(asset_id, filters)
- get_document!(id)
- create_document(attrs)
- update_document(document, attrs)
- delete_document(document)
- upload_document_file(asset_id, upload, attrs)
- download_document(document)
- get_document_url(document)
- get_expired_certificates()
- get_expiring_certificates(days)
- search_documents(query, filters)

#### 2.2 - PM Execution Context

Create: lib/shop1_cmms/maintenance/pm_execution.ex

Functions:
- start_pm_execution(pm_schedule_id, user_id)
- complete_pm_step(execution_id, step_number, result)
- complete_pm_execution(execution_id, attrs)
- cancel_pm_execution(execution_id, reason)
- get_execution_history(pm_schedule_id, opts)
- get_execution_with_details(execution_id)
- list_in_progress_executions(user_id)
- get_completion_stats(pm_schedule_id)
- get_average_duration(pm_schedule_id)
- get_compliance_rate(asset_id, date_range)

#### 2.3 - Enhanced Components Context

Update: lib/shop1_cmms/assets/components.ex

Add functions:
- list_pm_schedules_for_component(component_id)
- get_component_with_pms(component_id)
- get_component_status(component_id)
- get_component_history(component_id)

---

### **Phase 3: UI Components** ⭐

#### 3.1 - Equipment Documents Tab
- View documents by type (manuals, certs, photos, etc.)
- Upload new documents
- Download/view documents
- Track expiry dates for certificates
- Visual indicators for expired/expiring docs

#### 3.2 - Interactive PM Execution View
- Step-by-step checklist interface
- Mark steps complete
- Add notes per step
- Record measurements
- Upload photos
- Safety warnings
- Progress tracking
- Final completion

#### 3.3 - PM History/Audit Component
- List all past executions
- Completion stats
- View execution details
- Export history
- Compliance metrics

#### 3.4 - Enhanced PM Schedule View (Tabs)
Tabs:
1. Details - Schedule info, frequency
2. Instructions - Work instructions from template
3. History - Past executions
4. Documents - Related documents
5. Equipment - Equipment/component details

---

### **Phase 4: Integration Points** ⭐

#### 4.1 - Equipment View Enhancement
Add tabs to equipment detail view:
- Details
- Components
- PM Schedules
- Documents
- History

#### 4.2 - PM Execution from Schedule
- "Execute PM" button on schedule
- Opens interactive execution view
- Auto-creates PM execution record
- Tracks progress in real-time

#### 4.3 - Document Linking
- Link documents to equipment
- Link documents to PM templates
- Auto-display relevant docs during PM execution

#### 4.4 - Notifications
- Alert on expired certificates
- Alert on expiring certificates (30 days)
- Alert on PM completion
- Alert on overdue PMs

---

### **Phase 5: Database Migrations** ⭐

Migration order:
1. Create equipment_documents table
2. Enhance maint_pm_templates table
3. Create pm_executions table
4. Add stats to maint_pm_schedules table

---

## 🧪 Testing Strategy

### Context Tests:
- EquipmentDocuments CRUD
- PMExecution lifecycle
- Document file operations
- PM calculation updates

### LiveView Tests:
- Documents component rendering
- PM execution flow
- History display
- Tab navigation

### Integration Tests:
- Full PM execution cycle
- Document upload/download
- Multi-component PM
- History tracking

---

## 📱 UI/UX Design Principles

1. **Desktop-First, Business Professional**
   - Full-width layouts
   - Tight, efficient spacing
   - Professional color scheme
   - Windows desktop app feel

2. **Maximize Screen Space**
   - Minimize padding/margins
   - Multi-column layouts
   - Compact forms
   - Efficient tables

3. **Clear Visual Hierarchy**
   - Headers stand out
   - Actions clearly visible
   - Status indicators prominent
   - Consistent styling

4. **Keyboard-Friendly**
   - Tab navigation
   - Keyboard shortcuts
   - Enter to submit
   - Escape to cancel

---

## 🚀 Implementation Order

### Week 1: Foundation
1. Database migrations
2. Schema definitions
3. Context modules (basic CRUD)

### Week 2: Equipment Documents
1. Equipment documents context
2. File upload/storage
3. Documents tab component
4. Document viewer

### Week 3: PM Execution
1. PM execution context
2. PM execution LiveView
3. Interactive checklist UI
4. Step completion logic

### Week 4: PM History & Enhancement
1. PM history component
2. Enhanced PM schedule view
3. Tabbed interface
4. Statistics/analytics

### Week 5: Integration & Polish
1. Connect all components
2. Notifications
3. Export/import
4. UI polish

### Week 6: Testing & Documentation
1. Comprehensive testing
2. Bug fixes
3. User documentation
4. Deployment preparation

---

## ✅ Phase-by-Phase Checklist

### Phase 1: Data Model ✓
- [ ] equipment_documents migration
- [ ] Enhanced PM templates migration
- [ ] pm_executions migration
- [ ] PM schedule stats migration
- [ ] Run migrations, verify schema

### Phase 2: Contexts ✓
- [ ] EquipmentDocuments context
- [ ] PMExecution context
- [ ] Enhanced Components functions
- [ ] Unit tests for contexts

### Phase 3: UI Components ✓
- [ ] Equipment documents tab
- [ ] PM execution LiveView
- [ ] PM history component
- [ ] Enhanced PM schedule view
- [ ] File upload component

### Phase 4: Integration ✓
- [ ] Equipment detail tabs
- [ ] PM execution workflow
- [ ] Document linking
- [ ] Notifications

### Phase 5: Testing ✓
- [ ] Context tests
- [ ] LiveView tests
- [ ] Integration tests
- [ ] Manual QA

### Phase 6: Polish & Deploy ✓
- [ ] UI/UX refinements
- [ ] Performance optimization
- [ ] Documentation
- [ ] Deployment

---

## 🎯 Success Metrics

**PM Compliance:**
- % of PMs completed on time
- Average completion time
- Step completion rate

**Document Management:**
- Documents per equipment
- Certificate expiry compliance
- Document access frequency

**User Adoption:**
- Interactive PM usage rate
- User satisfaction scores
- Time savings vs. old method

**System Health:**
- Page load times < 2s
- Zero data loss
- 99.9% uptime

---

## 📝 Notes

- All changes maintain backward compatibility
- Existing PM data remains intact
- Gradual rollout possible
- Mobile-responsive design
- Multi-tenant support throughout

---

**This comprehensive plan provides a complete roadmap for transforming the PM system into a world-class maintenance management solution!** 🚀
