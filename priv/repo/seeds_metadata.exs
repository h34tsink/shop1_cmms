# Script for populating the database with metadata seed data

alias Shop1Cmms.{Repo, Metadata}
alias Shop1Cmms.Metadata.{
  Manufacturer,
  Department,
  Supplier,
  PriorityCode,
  MaintenanceCategory,
  CustomField
}

# Ensure tenant context is set for RLS
Ecto.Adapters.SQL.query!(Repo, "SET app.current_tenant_id = 1")

# Clear existing metadata
Repo.delete_all(CustomField)
Repo.delete_all(MaintenanceCategory)
Repo.delete_all(PriorityCode)
Repo.delete_all(Supplier)
Repo.delete_all(Department)
Repo.delete_all(Manufacturer)

# Seed manufacturers - including all manufacturers found in existing assets
manufacturers = [
  %{
    name: "Atlas Copco",
    code: "AC",
    description: "Industrial compressors, vacuum solutions and air treatment systems",
    website: "https://www.atlascopco.com",
    contact_email: "info@atlascopco.com",
    contact_phone: "+1-866-546-3588",
    address: "1776 Mentor Ave, Cincinnati, OH 45212, USA",
    notes: "Swedish industrial company specializing in compressors and industrial tools",
    tenant_id: 1
  },
  %{
    name: "Carrier",
    code: "CAR",
    description: "HVAC, refrigeration, fire, security and building automation",
    website: "https://www.carrier.com",
    contact_email: "support@carrier.com",
    contact_phone: "+1-800-227-7437",
    address: "13995 Pasteur Blvd, Palm Beach Gardens, FL 33418, USA",
    notes: "Leading provider of HVAC and refrigeration solutions",
    tenant_id: 1
  },
  %{
    name: "Caterpillar",
    code: "CAT",
    description: "Construction and mining equipment manufacturer",
    website: "https://www.caterpillar.com",
    contact_email: "support@cat.com",
    contact_phone: "+1-800-CAT-3000",
    address: "100 N.E. Adams Street, Peoria, IL 61629, USA",
    notes: "Leading global manufacturer of construction equipment",
    tenant_id: 1
  },
  %{
    name: "Crown Equipment",
    code: "CRN",
    description: "Material handling and warehouse equipment",
    website: "https://www.crown.com",
    contact_email: "info@crown.com",
    contact_phone: "+1-419-629-2311",
    address: "44 S Washington St, New Bremen, OH 45869, USA",
    notes: "Leading manufacturer of electric forklifts and material handling equipment",
    tenant_id: 1
  },
  %{
    name: "Dorner Manufacturing",
    code: "DOR",
    description: "Conveyor systems and material handling solutions",
    website: "https://www.dornerconveyors.com",
    contact_email: "sales@dorner.com",
    contact_phone: "+1-800-397-8664",
    address: "975 Cottonwood Ave, Hartland, WI 53029, USA",
    notes: "Precision conveyor systems for industrial applications",
    tenant_id: 1
  },
  %{
    name: "FANUC",
    code: "FAN",
    description: "Industrial robotics and CNC systems",
    website: "https://www.fanuc.com",
    contact_email: "info@fanuc.com",
    contact_phone: "+1-248-377-7000",
    address: "3900 W Hamlin Rd, Rochester Hills, MI 48309, USA",
    notes: "Leading manufacturer of industrial robots and CNC systems",
    tenant_id: 1
  },
  %{
    name: "Ford",
    code: "FRD",
    description: "Automotive and industrial equipment",
    website: "https://www.ford.com",
    contact_email: "support@ford.com",
    contact_phone: "+1-800-392-3673",
    address: "One American Rd, Dearborn, MI 48126, USA",
    notes: "Automotive manufacturer with industrial equipment division",
    tenant_id: 1
  },
  %{
    name: "Grundfos",
    code: "GRU",
    description: "Pump solutions and water technology",
    website: "https://www.grundfos.com",
    contact_email: "info@grundfos.com",
    contact_phone: "+1-913-227-3400",
    address: "17100 W 118th Terrace, Olathe, KS 66061, USA",
    notes: "Global leader in advanced pump solutions and water technology",
    tenant_id: 1
  },
  %{
    name: "Haas Automation",
    code: "HAAS",
    description: "CNC machine tools and manufacturing systems",
    website: "https://www.haascnc.com",
    contact_email: "info@haas.com",
    contact_phone: "+1-805-278-1800",
    address: "2800 Sturgis Rd, Oxnard, CA 93030, USA",
    notes: "Leading manufacturer of CNC machine tools including mills and lathes",
    tenant_id: 1
  },
  %{
    name: "Hytrol",
    code: "HYT",
    description: "Conveyor systems and material handling",
    website: "https://www.hytrol.com",
    contact_email: "info@hytrol.com",
    contact_phone: "+1-479-996-5556",
    address: "2020 Hytrol Circle, Jonesboro, AR 72401, USA",
    notes: "Leading conveyor manufacturer for material handling systems",
    tenant_id: 1
  },
  %{
    name: "Ingersoll Rand",
    code: "IR",
    description: "Industrial equipment and compressed air systems",
    website: "https://www.ingersollrand.com",
    contact_email: "info@irco.com",
    contact_phone: "+1-704-655-4000",
    address: "800B Beaty St, Davidson, NC 28036, USA",
    notes: "Global provider of mission-critical flow control and compression equipment",
    tenant_id: 1
  },
  %{
    name: "Konecranes",
    code: "KON",
    description: "Lifting equipment and services",
    website: "https://www.konecranes.com",
    contact_email: "info@konecranes.com",
    contact_phone: "+1-847-461-0010",
    address: "4401 Gateway Blvd, Springfield, OH 45502, USA",
    notes: "Leading provider of lifting equipment, services and parts",
    tenant_id: 1
  },
  %{
    name: "Mazak",
    code: "MAZ",
    description: "Machine tools and manufacturing solutions",
    website: "https://www.mazakusa.com",
    contact_email: "info@mazak.com",
    contact_phone: "+1-859-342-1700",
    address: "8025 Production Dr, Florence, KY 41042, USA",
    notes: "Leading manufacturer of advanced machine tools and manufacturing systems",
    tenant_id: 1
  },
  %{
    name: "Rexroth",
    code: "REX",
    description: "Drive and control technologies",
    website: "https://www.boschrexroth.com",
    contact_email: "info@boschrexroth.com",
    contact_phone: "+1-610-694-8300",
    address: "14001 Carowinds Blvd, Charlotte, NC 28273, USA",
    notes: "Leading provider of drive and control technologies for industrial applications",
    tenant_id: 1
  },
  %{
    name: "Safety-Kleen",
    code: "SK",
    description: "Environmental and industrial services",
    website: "https://www.safety-kleen.com",
    contact_email: "info@safety-kleen.com",
    contact_phone: "+1-800-669-5740",
    address: "42 Longwater Dr, Norwell, MA 02061, USA",
    notes: "Leading provider of environmental and industrial services",
    tenant_id: 1
  },
  %{
    name: "Toyota",
    code: "TOY",
    description: "Automotive and material handling equipment",
    website: "https://www.toyota.com",
    contact_email: "info@toyota.com",
    contact_phone: "+1-800-GO-TOYOTA",
    address: "6565 Headquarters Dr, Plano, TX 75024, USA",
    notes: "Global automotive manufacturer with material handling equipment division",
    tenant_id: 1
  },
  %{
    name: "Trane",
    code: "TRA",
    description: "HVAC systems and building services",
    website: "https://www.trane.com",
    contact_email: "info@trane.com",
    contact_phone: "+1-800-TRANE-20",
    address: "800 Long Blvd, Lansdale, PA 19446, USA",
    notes: "Leading provider of HVAC systems and building services",
    tenant_id: 1
  }
]

Enum.each(manufacturers, fn attrs ->
  %Manufacturer{}
  |> Manufacturer.changeset(attrs)
  |> Repo.insert!()
end)

# Seed departments
departments = [
  %{
    name: "Operations",
    code: "OPS",
    description: "Main operations department",
    manager_name: "John Smith",
    manager_email: "john.smith@company.com",
    cost_center: "CC001",
    budget_code: "BC001",
    tenant_id: 1
  },
  %{
    name: "Maintenance",
    code: "MAINT",
    description: "Equipment maintenance and repair",
    manager_name: "Sarah Johnson",
    manager_email: "sarah.johnson@company.com",
    cost_center: "CC002",
    budget_code: "BC002",
    tenant_id: 1
  },
  %{
    name: "Safety & Quality",
    code: "SAFE",
    description: "Safety compliance and quality control",
    manager_name: "Mike Wilson",
    manager_email: "mike.wilson@company.com",
    cost_center: "CC003",
    budget_code: "BC003",
    tenant_id: 1
  },
  %{
    name: "Logistics",
    code: "LOG",
    description: "Supply chain and logistics management",
    manager_name: "Emily Davis",
    manager_email: "emily.davis@company.com",
    cost_center: "CC004",
    budget_code: "BC004",
    tenant_id: 1
  }
]

Enum.each(departments, fn attrs ->
  %Department{}
  |> Department.changeset(attrs)
  |> Repo.insert!()
end)

# Seed suppliers
suppliers = [
  %{
    name: "Industrial Parts Supply Co.",
    code: "IPS",
    description: "General industrial parts and supplies",
    contact_name: "Robert Miller",
    contact_email: "robert.miller@ipsco.com",
    contact_phone: "+1-555-0123",
    address: "123 Industrial Ave, Detroit, MI 48201, USA",
    website: "https://www.ipsco.com",
    notes: "Primary supplier for hydraulic components",
    tenant_id: 1
  },
  %{
    name: "Heavy Equipment Parts Ltd.",
    code: "HEP",
    description: "Specialized heavy equipment replacement parts",
    contact_name: "Jennifer Brown",
    contact_email: "j.brown@hepltd.com",
    contact_phone: "+1-555-0456",
    address: "456 Parts Street, Chicago, IL 60601, USA",
    website: "https://www.hepltd.com",
    notes: "OEM and aftermarket parts specialist",
    tenant_id: 1
  },
  %{
    name: "Fluid Systems Inc.",
    code: "FSI",
    description: "Hydraulic fluids and lubricants",
    contact_name: "David Clark",
    contact_email: "d.clark@fluidsys.com",
    contact_phone: "+1-555-0789",
    address: "789 Fluid Way, Houston, TX 77001, USA",
    website: "https://www.fluidsys.com",
    notes: "Premium lubricants and hydraulic fluids",
    tenant_id: 1
  }
]

Enum.each(suppliers, fn attrs ->
  %Supplier{}
  |> Supplier.changeset(attrs)
  |> Repo.insert!()
end)

# Seed priority codes
priority_codes = [
  %{
    name: "Emergency",
    code: "EMRG",
    description: "Immediate attention required - safety critical",
    level: 1,
    sla_hours: 1,
    color: "#FF0000",
    tenant_id: 1
  },
  %{
    name: "High Priority",
    code: "HIGH",
    description: "High priority - production impact",
    level: 2,
    sla_hours: 4,
    color: "#FF8000",
    tenant_id: 1
  },
  %{
    name: "Medium Priority",
    code: "MED",
    description: "Standard priority work order",
    level: 3,
    sla_hours: 24,
    color: "#FFFF00",
    tenant_id: 1
  },
  %{
    name: "Low Priority",
    code: "LOW",
    description: "Non-urgent maintenance task",
    level: 4,
    sla_hours: 72,
    color: "#00FF00",
    tenant_id: 1
  }
]

Enum.each(priority_codes, fn attrs ->
  %PriorityCode{}
  |> PriorityCode.changeset(attrs)
  |> Repo.insert!()
end)

# Seed maintenance categories
maintenance_categories = [
  %{
    name: "Preventive Maintenance",
    code: "PM",
    description: "Scheduled preventive maintenance tasks",
    type: "preventive",
    default_frequency_days: 30,
    tenant_id: 1
  },
  %{
    name: "Corrective Maintenance",
    code: "CM",
    description: "Repair and corrective maintenance",
    type: "corrective",
    default_frequency_days: nil,
    tenant_id: 1
  },
  %{
    name: "Predictive Maintenance",
    code: "PdM",
    description: "Condition-based predictive maintenance",
    type: "predictive",
    default_frequency_days: 90,
    tenant_id: 1
  },
  %{
    name: "Emergency Repair",
    code: "ER",
    description: "Emergency breakdown repairs",
    type: "emergency",
    default_frequency_days: nil,
    tenant_id: 1
  },
  %{
    name: "Safety Inspection",
    code: "SI",
    description: "Safety and compliance inspections",
    type: "condition_based",
    default_frequency_days: 7,
    tenant_id: 1
  },
  %{
    name: "CNC Machine Service",
    code: "CNC",
    description: "Specialized maintenance for CNC machines and machining centers",
    type: "preventive",
    default_frequency_days: 90,
    tenant_id: 1
  },
  %{
    name: "HVAC Maintenance",
    code: "HVAC",
    description: "Heating, ventilation, and air conditioning system maintenance",
    type: "preventive",
    default_frequency_days: 180,
    tenant_id: 1
  },
  %{
    name: "Conveyor Maintenance",
    code: "CONV",
    description: "Material handling and conveyor system maintenance",
    type: "preventive",
    default_frequency_days: 60,
    tenant_id: 1
  },
  %{
    name: "Pump & Compressor Service",
    code: "P&C",
    description: "Maintenance for pumps, compressors, and fluid handling equipment",
    type: "preventive",
    default_frequency_days: 120,
    tenant_id: 1
  },
  %{
    name: "Vehicle Maintenance",
    code: "VEH",
    description: "Fleet and vehicle maintenance services",
    type: "preventive",
    default_frequency_days: 90,
    tenant_id: 1
  }
]

Enum.each(maintenance_categories, fn attrs ->
  %MaintenanceCategory{}
  |> MaintenanceCategory.changeset(attrs)
  |> Repo.insert!()
end)

# Seed custom fields
custom_fields = [
  %{
    field_label: "Warranty Status",
    field_name: "warranty_status",
    entity_type: "asset",
    field_type: "select",
    field_options: %{"options" => ["Under Warranty", "Expired", "Extended", "Not Applicable"]},
    default_value: "Not Applicable",
    is_required: false,
    help_text: "Current warranty status of equipment",
    tenant_id: 1
  },
  %{
    field_label: "Last Service Date",
    field_name: "last_service_date",
    entity_type: "asset",
    field_type: "date",
    field_options: nil,
    default_value: nil,
    is_required: false,
    help_text: "Date of last major service",
    tenant_id: 1
  },
  %{
    field_label: "Technician Level Required",
    field_name: "tech_level_required",
    entity_type: "work_order",
    field_type: "select",
    field_options: %{"options" => ["Level 1", "Level 2", "Level 3", "Certified Specialist"]},
    default_value: "Level 1",
    is_required: true,
    help_text: "Minimum technician certification level required",
    tenant_id: 1
  },
  %{
    field_label: "Environmental Conditions",
    field_name: "env_conditions",
    entity_type: "asset",
    field_type: "text",
    field_options: nil,
    default_value: "Normal indoor conditions",
    is_required: false,
    help_text: "Environmental conditions during operation",
    tenant_id: 1
  }
]

Enum.each(custom_fields, fn attrs ->
  %CustomField{}
  |> CustomField.changeset(attrs)
  |> Repo.insert!()
end)

IO.puts("✅ Metadata seed data created successfully!")
IO.puts("Created:")
IO.puts("  - #{length(manufacturers)} Manufacturers")
IO.puts("  - #{length(departments)} Departments")
IO.puts("  - #{length(suppliers)} Suppliers")
IO.puts("  - #{length(priority_codes)} Priority Codes")
IO.puts("  - #{length(maintenance_categories)} Maintenance Categories")
IO.puts("  - #{length(custom_fields)} Custom Fields")
