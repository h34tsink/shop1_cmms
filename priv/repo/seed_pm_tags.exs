defmodule Shop1Cmms.Repo.SeedPmTags do
  @moduledoc """
  Seeds PM tags (Skills, Tools, PPE) for all tenants.
  Run with: mix run priv/repo/seed_pm_tags.exs
  """

  alias Shop1Cmms.Repo
  alias Shop1Cmms.Maintenance.PmTag
  alias Shop1Cmms.Tenants.Tenant

  def run do
    IO.puts("\n=== Seeding PM Tags ===\n")

    # Get all tenants
    tenants = Repo.all(Tenant)

    Enum.each(tenants, fn tenant ->
      IO.puts("Seeding tags for tenant: #{tenant.name} (ID: #{tenant.id})")
      seed_tags_for_tenant(tenant.id)
    end)

    IO.puts("\n=== PM Tags Seeding Complete ===\n")
  end

  defp seed_tags_for_tenant(tenant_id) do
    # Skills
    skills = [
      # Certifications & Safety
      {"LOTO Certified", "Lockout/Tagout certification required"},
      {"Confined Space Entry", "Confined space entry certification"},
      {"Hot Work Permit", "Hot work permit authorization"},
      {"Arc Flash Certified", "Arc flash safety certification"},
      {"Forklift Certified", "Forklift operation certification"},
      {"Crane Operator", "Overhead crane operation certification"},
      
      # Technical Skills - Mechanical
      {"Mechanical", "General mechanical maintenance skills"},
      {"Hydraulic Systems", "Hydraulic system maintenance and repair"},
      {"Pneumatic Systems", "Pneumatic system maintenance and repair"},
      {"Equipment Lubrication", "Lubrication procedures and best practices"},
      {"Belt & Chain Systems", "Belt and chain maintenance"},
      {"Bearing Installation", "Bearing inspection and replacement"},
      {"Alignment Procedures", "Equipment alignment (shaft, belt, laser)"},
      {"Vibration Analysis", "Equipment vibration measurement and analysis"},
      
      # Technical Skills - Electrical
      {"Electrical", "General electrical maintenance skills"},
      {"Electrical Safety", "Electrical safety procedures"},
      {"PLC Programming", "Programmable Logic Controller programming"},
      {"Motor Control", "Electric motor maintenance and control"},
      {"VFD Programming", "Variable Frequency Drive setup and programming"},
      {"Instrumentation", "Instrumentation calibration and maintenance"},
      {"Control Panel", "Electrical control panel maintenance"},
      
      # Technical Skills - Specialized
      {"CNC Operation", "CNC machine operation and maintenance"},
      {"CNC Programming", "CNC programming (G-code, CAM)"},
      {"Calibration Certified", "Equipment calibration certification"},
      {"Welding", "Welding and fabrication skills"},
      {"HVAC Systems", "HVAC maintenance and repair"},
      {"Refrigeration", "Refrigeration system maintenance"},
      {"Boiler Operation", "Boiler operation and maintenance"},
      
      # Inspection & Testing
      {"Equipment Inspection", "Equipment inspection procedures"},
      {"Non-Destructive Testing", "NDT methods (ultrasonic, magnetic particle)"},
      {"Thermography", "Infrared thermography inspection"},
      {"Oil Analysis", "Lubrication oil analysis interpretation"},
      {"Leak Detection", "Air, gas, and fluid leak detection"},
      
      # Maintenance Procedures
      {"Preventive Maintenance", "Preventive maintenance procedures"},
      {"Predictive Maintenance", "Predictive maintenance techniques"},
      {"Root Cause Analysis", "Problem analysis and troubleshooting"},
      {"Blueprint Reading", "Read and interpret technical drawings"},
      {"Equipment Troubleshooting", "Systematic troubleshooting procedures"},
      
      # Basic Skills
      {"Basic Equipment Operation", "Basic equipment operation skills"},
      {"Hand Tools", "Proper use of hand tools"},
      {"Power Tools", "Proper use of power tools"},
      {"Measurement Tools", "Use of precision measurement tools"},
      {"Filter Replacement", "Filter inspection and replacement"},
      
      # Documentation
      {"CMMS Data Entry", "CMMS system data entry"},
      {"Work Order Documentation", "Work order completion and documentation"},
      {"Safety Documentation", "Safety procedure documentation"}
    ]

    # Tools
    tools = [
      # Hand Tools - Basic
      {"Standard Wrench Set", "SAE and metric wrench sets"},
      {"Socket Set", "Socket wrench set with extensions"},
      {"Screwdriver Set", "Flathead and Phillips screwdriver set"},
      {"Allen Key Set", "Hex key set (SAE and metric)"},
      {"Pliers Set", "Various pliers (needle-nose, slip-joint, locking)"},
      {"Hammer Set", "Ball-peen, rubber, and dead-blow hammers"},
      {"Pry Bar Set", "Various pry bars and alignment tools"},
      
      # Hand Tools - Specialized
      {"Torque Wrench", "Calibrated torque wrench"},
      {"Breaker Bar", "Socket wrench breaker bar"},
      {"Impact Wrench", "Pneumatic or electric impact wrench"},
      {"Pipe Wrench", "Pipe wrench set"},
      {"Adjustable Wrench", "Crescent wrench"},
      {"Strap Wrench", "Strap wrench for cylinders"},
      
      # Power Tools
      {"Drill", "Corded or cordless drill"},
      {"Impact Driver", "Impact driver set"},
      {"Angle Grinder", "Angle grinder with guards"},
      {"Reciprocating Saw", "Reciprocating saw"},
      {"Cut-Off Saw", "Portable cut-off saw"},
      {"Drill Press", "Stationary drill press"},
      
      # Measurement Tools
      {"Dial Indicator", "Dial indicator with magnetic base"},
      {"Micrometer Set", "Outside micrometer set"},
      {"Caliper", "Digital or dial caliper"},
      {"Feeler Gauge", "Feeler gauge set"},
      {"Tape Measure", "25-foot tape measure"},
      {"Level", "Machinist level"},
      {"Laser Alignment Tool", "Laser shaft alignment system"},
      {"Straightedge", "Precision straightedge"},
      
      # Electrical Tools
      {"Multimeter", "Digital multimeter (DMM)"},
      {"Clamp Meter", "Clamp-on ammeter"},
      {"Megohmmeter", "Insulation resistance tester"},
      {"Wire Stripper", "Wire stripping tool"},
      {"Crimping Tool", "Electrical crimping tool"},
      {"Cable Cutter", "Electrical cable cutter"},
      {"Fish Tape", "Wire pulling fish tape"},
      
      # Diagnostic Tools
      {"Vibration Meter", "Vibration analysis meter"},
      {"Infrared Camera", "Thermal imaging camera"},
      {"Ultrasonic Detector", "Ultrasonic leak detector"},
      {"Sound Level Meter", "Noise measurement meter"},
      {"Tachometer", "Optical or contact tachometer"},
      {"Stroboscope", "Timing light/stroboscope"},
      {"Pressure Gauge", "Hydraulic/pneumatic pressure gauge"},
      {"Flow Meter", "Fluid flow measurement device"},
      
      # Lubrication Tools
      {"Grease Gun", "Manual or pneumatic grease gun"},
      {"Oil Can", "Oil can or oiler"},
      {"Lubricant", "Various lubricants and oils"},
      {"Oil Sample Kit", "Oil sampling equipment"},
      
      # Lifting & Rigging
      {"Chain Hoist", "Manual or electric chain hoist"},
      {"Come Along", "Hand-operated cable puller"},
      {"Jack", "Hydraulic or mechanical jack"},
      {"Lifting Sling", "Certified lifting slings"},
      {"Spreader Bar", "Load spreader bar"},
      
      # Hydraulic & Pneumatic
      {"Hydraulic Pump", "Portable hydraulic pump"},
      {"Bearing Puller", "Mechanical or hydraulic bearing puller"},
      {"Press", "Hydraulic or arbor press"},
      {"Air Compressor", "Portable air compressor"},
      
      # Cleaning & Maintenance
      {"Cleaning Rags", "Shop towels and rags"},
      {"Cleaning Supplies", "General cleaning supplies"},
      {"Degreaser", "Industrial degreaser"},
      {"Wire Brush", "Wire brush set"},
      {"Compressed Air", "Compressed air supply"},
      
      # Specialized Equipment
      {"Welding Equipment", "Welding machine and supplies"},
      {"Test Parts", "Calibration test pieces"},
      {"Calibration Standards", "Certified calibration standards"},
      {"Filters", "Replacement filters (air, hydraulic, coolant)"},
      {"Fluids", "Replacement fluids (hydraulic, coolant, etc.)"},
      {"Seals Kit", "O-rings and seal assortment"},
      {"Full Maintenance Tool Set", "Complete maintenance toolkit"},
      
      # Documentation Tools
      {"Camera", "Digital camera for documentation"},
      {"Tablet", "Mobile device for CMMS access"},
      {"Barcode Scanner", "Asset tag scanner"}
    ]

    # PPE (Personal Protective Equipment)
    ppe = [
      # Eye & Face Protection
      {"Safety Glasses", "ANSI Z87.1 safety glasses"},
      {"Safety Goggles", "Chemical splash goggles"},
      {"Face Shield", "Full face shield"},
      {"Welding Helmet", "Auto-darkening welding helmet"},
      
      # Hand Protection
      {"Gloves", "General work gloves"},
      {"Chemical Gloves", "Chemical-resistant gloves"},
      {"Cut-Resistant Gloves", "Cut-resistant work gloves"},
      {"Electrical Gloves", "Insulated electrical gloves"},
      {"Heat-Resistant Gloves", "Heat-resistant welding gloves"},
      {"Nitrile Gloves", "Disposable nitrile gloves"},
      
      # Foot Protection
      {"Steel-Toed Boots", "Steel-toed safety boots"},
      {"Metatarsal Guards", "Metatarsal guard boots"},
      {"Electrical Hazard Boots", "EH-rated safety boots"},
      {"Chemical Boots", "Chemical-resistant boots"},
      
      # Head Protection
      {"Hard Hat", "ANSI Type I or II hard hat"},
      {"Bump Cap", "Lightweight bump cap"},
      
      # Hearing Protection
      {"Hearing Protection", "Earplugs or earmuffs"},
      {"Earplugs", "Disposable or reusable earplugs"},
      {"Earmuffs", "Noise-canceling earmuffs"},
      
      # Respiratory Protection
      {"Dust Mask", "N95 or equivalent dust mask"},
      {"Respirator", "Half or full-face respirator"},
      {"Supplied Air", "Supplied air breathing apparatus"},
      
      # Body Protection
      {"Safety Vest", "High-visibility safety vest"},
      {"Coveralls", "Protective coveralls"},
      {"Apron", "Chemical or welding apron"},
      {"Arc Flash Suit", "Arc-rated protective clothing"},
      {"Flame-Resistant Clothing", "FR-rated work clothing"},
      
      # Fall Protection
      {"Safety Harness", "Full-body safety harness"},
      {"Lanyard", "Shock-absorbing lanyard"},
      
      # Other
      {"Knee Pads", "Protective knee pads"},
      {"Back Support", "Back support belt"},
      {"Sun Protection", "Sun protection (hat, sunscreen)"}
    ]

    # Insert skills
    Enum.each(skills, fn {name, description} ->
      insert_tag(tenant_id, :skill, name, description)
    end)

    # Insert tools
    Enum.each(tools, fn {name, description} ->
      insert_tag(tenant_id, :tool, name, description)
    end)

    # Insert PPE
    Enum.each(ppe, fn {name, description} ->
      insert_tag(tenant_id, :ppe, name, description)
    end)

    IO.puts("  ✓ Seeded #{length(skills)} skills, #{length(tools)} tools, #{length(ppe)} PPE items")
  end

  defp insert_tag(tenant_id, type, name, description) do
    %PmTag{}
    |> PmTag.changeset(%{
      tenant_id: tenant_id,
      tag_type: type,
      name: name,
      description: description,
      is_active: true
    })
    |> Repo.insert(on_conflict: :nothing)
  end
end

# Run the seeder
Shop1Cmms.Repo.SeedPmTags.run()
