# Script to create test PM schedules for equipment

alias Shop1Cmms.Repo
alias Shop1Cmms.Assets
alias Shop1Cmms.Maintenance

# Get all assets
assets = Assets.list_assets()

IO.puts("Found #{length(assets)} equipment items")

# Create PM schedules for each asset
Enum.with_index(assets, 1) |> Enum.each(fn {asset, index} ->
  IO.puts("\nCreating PM schedules for: #{asset.name} (#{asset.asset_number})")
  
  # Daily PM - Daily inspection
  {:ok, _} = Maintenance.create_pm_schedule(%{
    asset_id: asset.id,
    schedule_number: "PM-#{String.pad_leading(Integer.to_string(index * 10 + 1), 4, "0")}",
    title: "Daily Inspection - #{asset.name}",
    description: "Daily visual inspection and basic checks",
    frequency: :daily,
    frequency_interval: 1,
    estimated_duration: Decimal.new("0.25"),
    work_instructions: """
    Daily Inspection Checklist:
    1. Visual inspection for damage or wear
    2. Check for unusual noises or vibrations
    3. Verify all safety guards are in place
    4. Check fluid levels (if applicable)
    5. Clean work area around equipment
    6. Report any abnormalities immediately
    """,
    safety_notes: "Ensure equipment is in safe state before inspection",
    ppe_required: ["Safety Glasses", "Steel-Toed Boots"],
    required_skills: ["Basic Equipment Operation"],
    is_active: true,
    tenant_id: asset.tenant_id
  })
  IO.puts("  ✓ Created daily inspection PM")
  
  # Weekly PM - Lubrication
  {:ok, _} = Maintenance.create_pm_schedule(%{
    asset_id: asset.id,
    schedule_number: "PM-#{String.pad_leading(Integer.to_string(index * 10 + 2), 4, "0")}",
    title: "Weekly Lubrication - #{asset.name}",
    description: "Weekly lubrication of moving parts",
    frequency: :weekly,
    frequency_interval: 1,
    estimated_duration: Decimal.new("0.5"),
    work_instructions: """
    Weekly Lubrication Procedure:
    1. Ensure equipment is powered off and locked out
    2. Clean grease fittings before lubrication
    3. Apply recommended lubricant to all grease points
    4. Check for proper lubrication flow
    5. Wipe excess lubricant
    6. Document lubricant type and quantity used
    7. Remove lockout and test operation
    """,
    safety_notes: "LOCKOUT/TAGOUT required. Follow company LOTO procedures.",
    ppe_required: ["Safety Glasses", "Gloves", "Steel-Toed Boots"],
    required_skills: ["LOTO Certified", "Equipment Lubrication"],
    required_tools: ["Grease Gun", "Cleaning Rags", "Lubricant"],
    is_active: true,
    tenant_id: asset.tenant_id
  })
  IO.puts("  ✓ Created weekly lubrication PM")
  
  # Monthly PM - Detailed inspection
  {:ok, _} = Maintenance.create_pm_schedule(%{
    asset_id: asset.id,
    schedule_number: "PM-#{String.pad_leading(Integer.to_string(index * 10 + 3), 4, "0")}",
    title: "Monthly Inspection - #{asset.name}",
    description: "Comprehensive monthly inspection and maintenance",
    frequency: :monthly,
    frequency_interval: 1,
    estimated_duration: Decimal.new("2.0"),
    work_instructions: """
    Monthly Comprehensive Inspection:
    1. Lock out and tag out equipment
    2. Inspect all belts for wear and proper tension
    3. Check all electrical connections for tightness
    4. Inspect bearings for wear or unusual heat
    5. Check alignment and level of equipment
    6. Test all safety systems and interlocks
    7. Clean equipment thoroughly
    8. Update maintenance log
    9. Remove lockout and perform test run
    10. Document all findings
    """,
    safety_notes: "LOCKOUT/TAGOUT required. Electrical work requires qualified electrician.",
    ppe_required: ["Safety Glasses", "Gloves", "Steel-Toed Boots", "Hearing Protection"],
    required_skills: ["LOTO Certified", "Equipment Inspection", "Electrical Safety"],
    required_tools: ["Tension Meter", "Thermometer", "Level", "Cleaning Supplies"],
    is_active: true,
    tenant_id: asset.tenant_id
  })
  IO.puts("  ✓ Created monthly inspection PM")
  
  # Quarterly PM - Calibration/adjustment
  {:ok, _} = Maintenance.create_pm_schedule(%{
    asset_id: asset.id,
    schedule_number: "PM-#{String.pad_leading(Integer.to_string(index * 10 + 4), 4, "0")}",
    title: "Quarterly Calibration - #{asset.name}",
    description: "Quarterly calibration and precision checks",
    frequency: :quarterly,
    frequency_interval: 1,
    estimated_duration: Decimal.new("3.0"),
    work_instructions: """
    Quarterly Calibration Procedure:
    1. Lock out equipment per safety procedures
    2. Perform backlash and play measurements
    3. Check and adjust spindle alignment
    4. Verify tool holder taper accuracy
    5. Test and calibrate positioning accuracy
    6. Check and adjust all axis travel limits
    7. Verify coolant system operation
    8. Update calibration records
    9. Attach calibration certification
    10. Test equipment with qualified part
    """,
    safety_notes: "Equipment must be fully isolated. Calibration requires qualified technician.",
    ppe_required: ["Safety Glasses", "Gloves", "Steel-Toed Boots"],
    required_skills: ["LOTO Certified", "Calibration Certified", "CNC Operation"],
    required_tools: ["Calibration Standards", "Dial Indicators", "Test Parts"],
    is_active: true,
    tenant_id: asset.tenant_id
  })
  IO.puts("  ✓ Created quarterly calibration PM")
  
  # Annual PM - Major overhaul
  {:ok, _} = Maintenance.create_pm_schedule(%{
    asset_id: asset.id,
    schedule_number: "PM-#{String.pad_leading(Integer.to_string(index * 10 + 5), 4, "0")}",
    title: "Annual Overhaul - #{asset.name}",
    description: "Annual comprehensive overhaul and preventive maintenance",
    frequency: :annual,
    frequency_interval: 1,
    estimated_duration: Decimal.new("8.0"),
    work_instructions: """
    Annual Comprehensive Overhaul:
    1. Schedule downtime with production planning
    2. Complete equipment shutdown and lockout
    3. Replace all filters (hydraulic, air, coolant)
    4. Change all fluids (hydraulic, lubricants, coolant)
    5. Inspect and replace worn seals and gaskets
    6. Check and service electrical cabinet
    7. Inspect and service pneumatic system
    8. Complete bearing inspection and replacement as needed
    9. Perform full calibration per manufacturer specs
    10. Update equipment records and attach service reports
    11. Perform complete functional testing
    12. Obtain production approval before release
    """,
    safety_notes: "CRITICAL: Extended LOTO required. Coordinate with production. Multiple trades required.",
    ppe_required: ["Safety Glasses", "Gloves", "Steel-Toed Boots", "Hearing Protection"],
    required_skills: ["LOTO Certified", "Mechanical", "Electrical", "Hydraulic", "Pneumatic"],
    required_tools: ["Full Maintenance Tool Set", "Filters", "Fluids", "Seals Kit"],
    required_parts: %{
      "hydraulic_filters" => "3 ea",
      "air_filters" => "2 ea",
      "coolant_filter" => "1 ea",
      "hydraulic_oil" => "20 gal",
      "way_oil" => "5 gal",
      "coolant" => "50 gal"
    },
    is_active: true,
    tenant_id: asset.tenant_id
  })
  IO.puts("  ✓ Created annual overhaul PM")
  
  # Usage-based PM (every 500 hours)
  {:ok, _} = Maintenance.create_pm_schedule(%{
    asset_id: asset.id,
    schedule_number: "PM-#{String.pad_leading(Integer.to_string(index * 10 + 6), 4, "0")}",
    title: "500-Hour Service - #{asset.name}",
    description: "Maintenance required every 500 operating hours",
    frequency: :meter_based,
    frequency_interval: 1,
    meter_threshold: Decimal.new("500"),
    meter_unit: "hours",
    estimated_duration: Decimal.new("1.5"),
    work_instructions: """
    500-Hour Service Procedure:
    1. Record current hour meter reading
    2. Perform oil analysis (send sample to lab)
    3. Inspect and clean coolant tank
    4. Replace air filters
    5. Check belt tension and condition
    6. Inspect chip conveyor operation
    7. Clean and inspect tool changer
    8. Test emergency stop functions
    9. Update service records with meter reading
    10. Schedule next service at current hours + 500
    """,
    safety_notes: "LOCKOUT/TAGOUT required. Use proper PPE when handling fluids.",
    ppe_required: ["Safety Glasses", "Chemical Gloves", "Steel-Toed Boots", "Face Shield"],
    required_skills: ["LOTO Certified", "Oil Analysis", "Filter Replacement"],
    required_tools: ["Oil Sample Kit", "Air Filters", "Cleaning Supplies"],
    is_active: true,
    tenant_id: asset.tenant_id
  })
  IO.puts("  ✓ Created usage-based (500hr) PM")
end)

IO.puts("\n✅ All test PM schedules created successfully!")

# Print summary
total_schedules = Maintenance.list_pm_schedules(1) |> length()
IO.puts("\nTotal PM schedules in system: #{total_schedules}")
