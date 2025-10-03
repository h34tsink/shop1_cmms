# PM Tags Configuration System

## Overview
The PM Tags system provides a centralized, tenant-specific configuration for managing Skills, Tools, and PPE (Personal Protective Equipment) tags used across PM schedules.

## Database Schema

### Table: `pm_tags`
```sql
CREATE TABLE pm_tags (
  id UUID PRIMARY KEY,
  name VARCHAR NOT NULL,
  tag_type VARCHAR NOT NULL,  -- 'skill', 'tool', 'ppe'
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  usage_count INTEGER DEFAULT 0,
  tenant_id INTEGER REFERENCES tenants(id),
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP,
  
  UNIQUE INDEX: (tenant_id, tag_type, name)
)
```

## Tag Types

### 1. Skills
Technical and safety certifications required for maintenance tasks.

**Categories:**
- **Certifications & Safety**: LOTO Certified, Confined Space Entry, Hot Work Permit, Arc Flash Certified, Forklift Certified, Crane Operator
- **Mechanical Skills**: Mechanical, Hydraulic Systems, Pneumatic Systems, Equipment Lubrication, Belt & Chain Systems, Bearing Installation, Alignment Procedures, Vibration Analysis
- **Electrical Skills**: Electrical, Electrical Safety, PLC Programming, Motor Control, VFD Programming, Instrumentation, Control Panel
- **Specialized Skills**: CNC Operation, CNC Programming, Calibration Certified, Welding, HVAC Systems, Refrigeration, Boiler Operation
- **Inspection & Testing**: Equipment Inspection, Non-Destructive Testing, Thermography, Oil Analysis, Leak Detection
- **Maintenance Procedures**: Preventive Maintenance, Predictive Maintenance, Root Cause Analysis, Blueprint Reading, Equipment Troubleshooting
- **Basic Skills**: Basic Equipment Operation, Hand Tools, Power Tools, Measurement Tools, Filter Replacement
- **Documentation**: CMMS Data Entry, Work Order Documentation, Safety Documentation

**Total Skills**: 46

### 2. Tools
Physical tools and equipment required for maintenance work.

**Categories:**
- **Hand Tools - Basic**: Standard Wrench Set, Socket Set, Screwdriver Set, Allen Key Set, Pliers Set, Hammer Set, Pry Bar Set
- **Hand Tools - Specialized**: Torque Wrench, Breaker Bar, Impact Wrench, Pipe Wrench, Adjustable Wrench, Strap Wrench
- **Power Tools**: Drill, Impact Driver, Angle Grinder, Reciprocating Saw, Cut-Off Saw, Drill Press
- **Measurement Tools**: Dial Indicator, Micrometer Set, Caliper, Feeler Gauge, Tape Measure, Level, Laser Alignment Tool, Straightedge
- **Electrical Tools**: Multimeter, Clamp Meter, Megohmmeter, Wire Stripper, Crimping Tool, Cable Cutter, Fish Tape
- **Diagnostic Tools**: Vibration Meter, Infrared Camera, Ultrasonic Detector, Sound Level Meter, Tachometer, Stroboscope, Pressure Gauge, Flow Meter
- **Lubrication Tools**: Grease Gun, Oil Can, Lubricant, Oil Sample Kit
- **Lifting & Rigging**: Chain Hoist, Come Along, Jack, Lifting Sling, Spreader Bar
- **Hydraulic & Pneumatic**: Hydraulic Pump, Bearing Puller, Press, Air Compressor
- **Cleaning & Maintenance**: Cleaning Rags, Cleaning Supplies, Degreaser, Wire Brush, Compressed Air
- **Specialized Equipment**: Welding Equipment, Test Parts, Calibration Standards, Filters, Fluids, Seals Kit, Full Maintenance Tool Set
- **Documentation Tools**: Camera, Tablet, Barcode Scanner

**Total Tools**: 70

### 3. PPE (Personal Protective Equipment)
Safety equipment required for maintenance personnel.

**Categories:**
- **Eye & Face Protection**: Safety Glasses, Safety Goggles, Face Shield, Welding Helmet
- **Hand Protection**: Gloves, Chemical Gloves, Cut-Resistant Gloves, Electrical Gloves, Heat-Resistant Gloves, Nitrile Gloves
- **Foot Protection**: Steel-Toed Boots, Metatarsal Guards, Electrical Hazard Boots, Chemical Boots
- **Head Protection**: Hard Hat, Bump Cap
- **Hearing Protection**: Hearing Protection, Earplugs, Earmuffs
- **Respiratory Protection**: Dust Mask, Respirator, Supplied Air
- **Body Protection**: Safety Vest, Coveralls, Apron, Arc Flash Suit, Flame-Resistant Clothing
- **Fall Protection**: Safety Harness, Lanyard
- **Other**: Knee Pads, Back Support, Sun Protection

**Total PPE**: 32

## Usage

### Access Configuration Page
Navigate to: `/metadata/pm_tags`

### Managing Tags

#### Create a New Tag
1. Go to the PM Tags configuration page
2. Click "Add New PM Tag"
3. Fill in:
   - **Tag Name**: The display name (e.g., "LOTO Certified")
   - **Tag Type**: Select from Skills, Tools, or PPE
   - **Description**: Optional description
4. Click "Save"

#### Edit a Tag
1. Find the tag in the list
2. Click the edit icon
3. Modify the fields
4. Click "Save"

#### Deactivate a Tag
- Deactivating a tag hides it from tag selection but preserves historical data
- Tags are soft-deleted (is_active = false) rather than hard-deleted

### Using Tags in PM Schedules

#### During PM Creation
Tags are automatically suggested as you type using the TagInputComponent:
```elixir
<.live_component
  module={Shop1CmmsWeb.TagInputComponent}
  id="skills-input"
  tags={@required_skills}
  tag_type={:skill}
  field_name="required_skills"
  label="Required Skills"
  placeholder="Type skills..."
  tenant_id={@current_tenant_id}
/>
```

#### Auto-Creation
- If a user types a tag that doesn't exist, it's automatically created
- Usage count is automatically incremented when tags are used

#### Tag Autocomplete
- Type to search existing tags
- Comma-separated for multiple tags
- Most-used tags appear first
- Fuzzy matching supported

## Context Functions

### Maintenance Context (`Shop1Cmms.Maintenance`)

```elixir
# List all tags for a tenant
list_pm_tags(tenant_id, opts \\ [])
  # Options:
  #   type: :skill | :tool | :ppe  - Filter by tag type
  #   active_only: true | false    - Show only active tags
  #   order_by: :usage | :name     - Sort order

# Search tags
search_pm_tags(tenant_id, search_term, type \\ nil)

# Get or create tag (auto-create functionality)
get_or_create_pm_tag(tenant_id, name, type)

# CRUD operations
create_pm_tag(attrs)
get_pm_tag!(id)
update_pm_tag(pm_tag, attrs)
delete_pm_tag(pm_tag)

# Track usage
increment_pm_tag_usage(tag_id)
```

## Schema Functions

### PmTag Schema Queries

```elixir
# Filter queries
PmTag.by_tenant(query, tenant_id)
PmTag.by_type(query, :skill | :tool | :ppe)
PmTag.active_only(query)

# Search
PmTag.search(query, search_term)

# Ordering
PmTag.order_by_usage(query)  # Most used first
PmTag.order_by_name(query)   # Alphabetical
```

## Data Seeding

### Initial Seed
Run to populate default tags for all tenants:
```bash
mix run priv/repo/seed_pm_tags.exs
```

### Adding New Default Tags
Edit `priv/repo/seed_pm_tags.exs` and add to the appropriate list (skills, tools, or ppe), then re-run the seed script.

## Integration Points

### 1. PM Schedule Creation/Edit
- TagInputComponent provides autocomplete interface
- Tags are stored as arrays in pm_schedules table:
  - `required_skills` (array of strings)
  - `required_tools` (array of strings)
  - `ppe_required` (array of strings)

### 2. Search & Filtering
- PM schedules can be searched by tags
- Global search includes tag matching
- Filter PM schedules by specific skills/tools/PPE

### 3. Reporting & Analytics
- Most-used skills/tools/PPE
- Skills gap analysis
- Equipment utilization by required tools
- PPE compliance tracking

### 4. Work Assignment
- Match technicians to PM schedules based on skills
- Verify tool availability before scheduling
- PPE checklist generation

## Best Practices

### Naming Conventions
- Use title case (e.g., "LOTO Certified", "Torque Wrench")
- Be specific but concise
- Avoid abbreviations unless industry-standard (e.g., "PPE", "CNC", "HVAC")
- Use consistent terminology across similar tags

### Tag Management
- Regularly review and consolidate duplicate tags
- Archive unused tags rather than deleting
- Update descriptions for clarity
- Monitor usage_count to identify popular tags

### Standardization
- Establish company-wide naming standards
- Create tag guidelines for users
- Periodically audit and clean up tags
- Consider industry certifications for skills

## Migration Information

### Migration File
`priv/repo/migrations/20251003172551_create_pm_tags_configuration.exs`

### Rollback
```bash
mix ecto.rollback
```

## Future Enhancements

### Planned Features
1. **Tag Hierarchies**: Parent-child relationships (e.g., "Mechanical" → "Hydraulic Systems")
2. **Tag Synonyms**: Multiple names for same tag (e.g., "Safety Glasses" = "Eye Protection")
3. **Tag Categories**: Group related tags for easier browsing
4. **Bulk Import/Export**: CSV import for tag management
5. **Usage Analytics**: Detailed reporting on tag usage patterns
6. **Skill Certification Tracking**: Link to employee certifications
7. **Tool Inventory Integration**: Connect to physical tool inventory
8. **PPE Compliance Rules**: Automatic PPE requirement enforcement

### API Endpoints (Future)
- GET `/api/tags` - List tags with filters
- GET `/api/tags/search?q=term` - Search tags
- POST `/api/tags` - Create tag
- PUT `/api/tags/:id` - Update tag
- DELETE `/api/tags/:id` - Deactivate tag

## Troubleshooting

### Tags Not Appearing in Autocomplete
1. Check tag is active: `is_active = true`
2. Verify tenant_id matches current tenant
3. Check tag_type matches field (skill vs tool vs ppe)

### Duplicate Tags
- Unique constraint prevents exact duplicates per tenant
- Case-sensitive matching may allow "Safety Glasses" and "safety glasses"
- Consolidate by updating PM schedules to use consistent casing

### Performance Issues
- Usage count index helps with ordering
- Consider pagination for tenants with many tags (>1000)
- Cache frequently-used tag lists in LiveView assigns

## Related Files
- Schema: `lib/shop1_cmms/maintenance/pm_tag.ex`
- Context: `lib/shop1_cmms/maintenance.ex`
- Migration: `priv/repo/migrations/20251003172551_create_pm_tags_configuration.exs`
- Seed: `priv/repo/seed_pm_tags.exs`
- LiveView: `lib/shop1_cmms_web/live/metadata_live.ex`
- Component: `lib/shop1_cmms_web/live/tag_input_component.ex`
