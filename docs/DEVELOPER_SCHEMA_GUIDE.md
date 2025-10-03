# Developer Onboarding - Schema & Database Guide

**For:** New developers or when working with schemas after a break  
**Purpose:** Prevent common mistakes and schema mismatches

---

## 🚨 Common Mistakes to Avoid

### 1. Wrong Field Names (Most Common!)

❌ **DON'T USE:**
```elixir
# PM Schedules
@schedule.frequency_value     # Doesn't exist!
@schedule.frequency_unit      # Doesn't exist!
@schedule.priority            # Doesn't exist!

# Components
Component.has_many :pm_schedules  # Invalid association!
```

✅ **USE INSTEAD:**
```elixir
# PM Schedules
@schedule.frequency           # Enum: :daily, :weekly, :monthly, etc.
@schedule.frequency_interval  # Integer: 1, 2, 3, etc.
@schedule.estimated_duration  # Not priority!

# Components - use join table
# Components are linked through pm_schedule_components table
```

### 2. Wrong Association Types

❌ **DON'T:**
```elixir
belongs_to :user, User, type: :binary_id  # Users are bigint!
```

✅ **DO:**
```elixir
belongs_to :user, User  # No type specified = integer/bigint (correct)
```

### 3. Querying Non-Existent Tables

❌ **DON'T:**
```elixir
from u in "user_details"  # Table doesn't exist!
```

✅ **DO:**
```elixir
from u in "users"  # Actual table name
# For extended profile info, join user_profiles
```

---

## 📚 Essential Documentation

### Start Here (Priority Order):

1. **SCHEMA_FIELD_REFERENCE.md** ← Quick field lookup
2. **DATABASE_TABLE_MAP.md** ← Complete schema map
3. **SCHEMA_CONFORMANCE_AUDIT.md** ← Known issues & fixes
4. **AUTH_STATUS_REPORT.md** ← Auth system details

---

## 🔍 How to Find the Right Field

### Step 1: Check the Reference
Open `docs/SCHEMA_FIELD_REFERENCE.md` and search for your table

### Step 2: Check the Schema File
```bash
# Schema files are organized by context:
lib/shop1_cmms/assets/        # Asset-related schemas
lib/shop1_cmms/accounts/      # User & auth schemas
lib/shop1_cmms/maintenance/   # PM & maintenance schemas
lib/shop1_cmms/work_orders/   # Work order schemas
lib/shop1_cmms/tenants/       # Tenant & site schemas
```

### Step 3: Verify in Database
```elixir
# Quick field check in iex
YourSchema.__schema__(:fields)

# Or check database directly
mix ecto.reset  # If needed
```

---

## 🎯 Quick Reference Card

Print this and keep it nearby!

### PM Schedules
```
✅ frequency (enum)
✅ frequency_interval (integer)
✅ estimated_duration (decimal)
❌ frequency_value (doesn't exist)
❌ frequency_unit (doesn't exist)
❌ priority (doesn't exist)
```

### ID Types
```
bigint:     users, tenants, sites
binary_id:  assets, pm_schedules, work_orders, components
```

### Associations
```
User foreign keys:     Always integer/bigint
Asset foreign keys:    Always binary_id
```

### Timestamps
```
utc_datetime:    pm_schedules, asset_documents, checklist_items
naive_datetime:  users, components, work_orders, tenants
```

---

## 🛠️ Before You Code Checklist

- [ ] I checked SCHEMA_FIELD_REFERENCE.md for field names
- [ ] I verified the schema file has the field I need
- [ ] I checked the ID type (bigint vs binary_id)
- [ ] I'm using the correct timestamp type
- [ ] I reviewed similar code in the same LiveView/module

---

## 🐛 When You Get an Error

### "Key :field_name not found"
→ Field doesn't exist. Check SCHEMA_FIELD_REFERENCE.md for correct name

### "Invalid association"
→ Check if association is valid. See SCHEMA_CONFORMANCE_AUDIT.md

### "Module not found"
→ Check spelling (e.g., CMMSUserRole vs CmmsUserRole)

### "Type mismatch"
→ Check if you're using correct ID type (bigint vs binary_id)

---

## 📝 Adding New Fields (Process)

1. **Create Migration**
   ```bash
   mix ecto.gen.migration add_field_to_table
   ```

2. **Update Schema File**
   ```elixir
   # lib/shop1_cmms/<context>/<schema>.ex
   field :new_field, :type
   ```

3. **Update Documentation**
   - Update `docs/SCHEMA_FIELD_REFERENCE.md`
   - Update `docs/DATABASE_TABLE_MAP.md`

4. **Test Your Changes**
   ```bash
   mix test
   mix compile --warnings-as-errors
   ```

---

## 🔄 Schema Validation Command

Run this to check for issues:
```bash
# Compile and check for warnings
mix compile --warnings-as-errors

# The critical warning to watch for:
# "invalid association" - means schema doesn't match DB
```

---

## 💡 Pro Tips

### Tip 1: Use Schema Inspection
```elixir
# In iex:
Shop1Cmms.Maintenance.PmSchedule.__schema__(:fields)
# Returns: [:id, :schedule_number, :title, :frequency, ...]
```

### Tip 2: Check Database Directly
```bash
# PostgreSQL CLI
\d+ pm_schedules  # Describes table structure
```

### Tip 3: Search Before You Code
```bash
# Find examples of field usage
grep -r "frequency_interval" lib/shop1_cmms_web/live/
```

### Tip 4: Module Name Casing
```elixir
# ✅ Correct
Shop1Cmms.Accounts.CMMSUserRole  # CMMS is all caps

# ❌ Wrong
Shop1Cmms.Accounts.CmmsUserRole  # Module doesn't exist
```

---

## 🎓 Learning Resources

1. **Ecto Schema Docs:** https://hexdocs.pm/ecto/Ecto.Schema.html
2. **Project Schemas:** `lib/shop1_cmms/*/` directories
3. **Migrations:** `priv/repo/migrations/`
4. **This Codebase Docs:** `docs/` directory

---

## 🆘 Still Stuck?

1. Check `docs/SCHEMA_CONFORMANCE_AUDIT.md` for similar issues
2. Search the codebase for examples
3. Review recent commits related to the schema
4. Ask: "Did this field name change recently?"

---

## ✅ Success Indicators

You're doing it right when:
- ✅ Mix compiles without schema warnings
- ✅ LiveView pages load without KeyError
- ✅ Tests pass
- ✅ No "undefined" warnings in compilation

---

**Remember:** When in doubt, check the docs first! 📖

**Pro Tip:** Bookmark `docs/SCHEMA_FIELD_REFERENCE.md` in your browser or editor!
